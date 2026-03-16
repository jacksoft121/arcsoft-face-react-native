package com.arcsoftfacern;

import android.content.Context;
import android.graphics.ImageFormat;
import android.graphics.Rect;
import android.graphics.YuvImage;
import android.media.Image;
import android.util.Base64;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.arcsoft.face.FaceFeature;
import com.arcsoft.face.FaceInfo;
import com.arcsoft.face.SearchResult;
import com.mrousavy.camera.frameprocessors.Frame;
import com.mrousavy.camera.frameprocessors.FrameProcessorPlugin;
import com.mrousavy.camera.frameprocessors.VisionCameraProxy;

import java.io.File;
import java.io.FileOutputStream;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;

public class ArcsoftFaceProcessorPlugin2 extends FrameProcessorPlugin {
    private static final String TAG = "ArcsoftFacePlugin";
    private static final int DEFAULT_MAX_RETRY_COUNT = 5;

    private final ArcsoftEngineManager engineManager;

    /**
     * 单飞锁：
     * 上一帧没处理完，下一帧直接跳过，避免 Camera 分析队列堆积。
     */
    private final AtomicBoolean isProcessing = new AtomicBoolean(false);

    /**
     * 复用缓冲区，减少每帧频繁 new byte[]
     */
    private byte[] nv21Buffer;
    private byte[] uBufferArray;
    private byte[] vBufferArray;

    /**
     * 缓冲区锁
     */
    private final Object bufferLock = new Object();

    public ArcsoftFaceProcessorPlugin2(@NonNull VisionCameraProxy proxy, @Nullable Map<String, Object> options) {
        super();
        this.engineManager = ArcsoftEngineManager.getInstance(null);
    }

    @Nullable
    @Override
    public Object callback(@NonNull Frame frame, @Nullable Map<String, Object> arguments) {
        // 单飞：上一帧没处理完就直接丢
        if (!isProcessing.compareAndSet(false, true)) {
            Log.w(TAG, "Skip frame: previous frame still processing");
            return null;
        }

        try {
            final Image image = frame.getImage();
            if (image == null) {
                return null;
            }

            // 1. 解析参数
            final boolean saveImage = getBoolean(arguments, "saveImage", false);
            final boolean extractFeature = getBoolean(arguments, "extractFeature", false);
            final boolean retExtractFeatureBase64 = getBoolean(arguments, "retExtractFeatureBase64", false);
            final double scoreThreshold = getDouble(arguments, "score", 0.8);
            final int maxRetryCount = getInt(arguments, "maxRetryCount", DEFAULT_MAX_RETRY_COUNT);

            final int width = image.getWidth();
            final int height = image.getHeight();

            // 2. 转换数据
            final byte[] nv21 = yuv420ToNv21(image);
            if (nv21 == null) {
                Log.e(TAG, "Failed to convert YUV420 to NV21");
                return null;
            }

            // 3. 保存图片（可选）
            String imagePath = null;
            if (saveImage) {
                imagePath = saveFrame(width, height, nv21);
            }

            // 4. 人脸检测
            final List<FaceInfo> faces = engineManager.detectFacesNV21(nv21, width, height);

            // 清理离开画面的人脸状态
            engineManager.cleanUpFaceStates(faces);

            // 5. 结果封装
            final List<Map<String, Object>> faceList = new ArrayList<>(faces.size());

            for (FaceInfo face : faces) {
                final Map<String, Object> map = new HashMap<>(8);

                final Rect r = face.getRect();
                final Map<String, Object> rectMap = new HashMap<>(4);
                rectMap.put("left", (double) r.left);
                rectMap.put("top", (double) r.top);
                rectMap.put("right", (double) r.right);
                rectMap.put("bottom", (double) r.bottom);

                map.put("rect", rectMap);
                map.put("orient", (double) face.getOrient());
                map.put("faceId", (double) face.getFaceId());
                final int faceId = face.getFaceId();

                if (extractFeature) {
                    handleFeatureExtraction(
                            map,
                            face,
                            faceId,
                            nv21,
                            width,
                            height,
                            retExtractFeatureBase64,
                            scoreThreshold,
                            maxRetryCount
                    );
                }

                faceList.add(map);
            }

            final Map<String, Object> result = new HashMap<>(2);
            result.put("faces", faceList);
            if (imagePath != null) {
                result.put("imagePath", imagePath);
            }

            return result;
        } catch (Throwable e) {
            Log.e(TAG, "Error processing frame", e);
            return null;
        } finally {
            isProcessing.set(false);
        }
    }

    private void handleFeatureExtraction(
            @NonNull Map<String, Object> map,
            @NonNull FaceInfo face,
            int faceId,
            @NonNull byte[] nv21,
            int width,
            int height,
            boolean retExtractFeatureBase64,
            double scoreThreshold,
            int maxRetryCount
    ) {
        try {
            // 已识别/重试超限：直接读缓存
            if (!engineManager.shouldProcessFace(faceId, maxRetryCount)) {
                Map<String, Object> cachedInfo = engineManager.getCachedFaceInfo(faceId);
                if (cachedInfo != null) {
                    if (!retExtractFeatureBase64 && cachedInfo.containsKey("featureBase64")) {
                        Map<String, Object> safeCached = new HashMap<>(cachedInfo);
                        safeCached.remove("featureBase64");
                        map.putAll(safeCached);
                    } else {
                        map.putAll(cachedInfo);
                    }
                }
                return;
            }

            // 提取特征
            FaceFeature feature = engineManager.extractFeatureNV21(nv21, width, height, face);
            if (feature == null || feature.getFeatureData() == null) {
                Log.w(TAG, "Feature extraction failed for faceId=" + faceId);
                engineManager.updateRetryCount(faceId);
                return;
            }

            // 目前 faceDBSearchTop1 需要 Base64，这里先保留
            String b64 = Base64.encodeToString(feature.getFeatureData(), Base64.NO_WRAP);

            if (retExtractFeatureBase64) {
                map.put("featureBase64", b64);
            }

            SearchResult searchResult = engineManager.faceDBSearchTop1(b64);
            if (searchResult != null && searchResult.getFaceFeatureInfo() != null) {
                String tag = searchResult.getFaceFeatureInfo().getFaceTag();
                float score = searchResult.getMaxSimilar();

                if (tag != null && score >= scoreThreshold) {
                    map.put("userId", tag);
                    map.put("score", (double) score);

                    // 识别成功，更新缓存
                    engineManager.updateFaceCache(faceId, tag, score, b64);
                } else {
                    // 识别失败（分数低）
                    engineManager.updateRetryCount(faceId);
                    engineManager.updateFaceCache(faceId, null, 0, b64);
                }
            } else {
                // 搜索无结果
                engineManager.updateRetryCount(faceId);
                engineManager.updateFaceCache(faceId, null, 0, b64);
            }
        } catch (Throwable e) {
            Log.e(TAG, "handleFeatureExtraction error, faceId=" + faceId, e);
            engineManager.updateRetryCount(faceId);
        }
    }

    private String saveFrame(int width, int height, byte[] nv21) {
        try {
            Context context = engineManager.getContext();
            if (context == null) {
                return null;
            }

            File cacheDir = context.getExternalCacheDir();
            if (cacheDir == null) {
                return null;
            }

            File file = new File(cacheDir, "frame_" + System.currentTimeMillis() + ".jpg");
            YuvImage yuvImage = new YuvImage(nv21, ImageFormat.NV21, width, height, null);

            try (FileOutputStream fos = new FileOutputStream(file)) {
                boolean ok = yuvImage.compressToJpeg(new Rect(0, 0, width, height), 80, fos);
                if (!ok) {
                    Log.e(TAG, "compressToJpeg failed");
                    return null;
                }
            }

            Log.i(TAG, "Saved frame to " + file.getAbsolutePath());
            return "file://" + file.getAbsolutePath();
        } catch (Exception e) {
            Log.e(TAG, "Failed to save frame", e);
            return null;
        }
    }

    private byte[] yuv420ToNv21(@NonNull Image image) {
        try {
            final int width = image.getWidth();
            final int height = image.getHeight();
            final int frameSize = width * height;
            final int totalSize = frameSize * 3 / 2;

            final Image.Plane[] planes = image.getPlanes();
            if (planes == null || planes.length < 3) {
                Log.e(TAG, "Invalid image planes");
                return null;
            }

            final ByteBuffer yBuffer = planes[0].getBuffer();
            final ByteBuffer uBuffer = planes[1].getBuffer();
            final ByteBuffer vBuffer = planes[2].getBuffer();

            final int yRowStride = planes[0].getRowStride();
            final int uvRowStride = planes[1].getRowStride();
            final int uvPixelStride = planes[1].getPixelStride();

            synchronized (bufferLock) {
                ensureCapacity(totalSize, uBuffer.remaining(), vBuffer.remaining());

                final byte[] nv21 = nv21Buffer;

                // 处理 Y
                int pos = 0;
                yBuffer.rewind();

                if (yRowStride == width) {
                    yBuffer.get(nv21, 0, frameSize);
                    pos = frameSize;
                } else {
                    for (int row = 0; row < height; row++) {
                        yBuffer.position(row * yRowStride);
                        yBuffer.get(nv21, pos, width);
                        pos += width;
                    }
                }

                // 处理 UV
                uBuffer.rewind();
                vBuffer.rewind();

                final int uRemaining = uBuffer.remaining();
                final int vRemaining = vBuffer.remaining();

                uBuffer.get(uBufferArray, 0, uRemaining);
                vBuffer.get(vBufferArray, 0, vRemaining);

                final int uvHeight = height / 2;
                final int uvWidth = width / 2;

                // NV21: V U V U ...
                for (int row = 0; row < uvHeight; row++) {
                    int rowStart = row * uvRowStride;
                    for (int col = 0; col < uvWidth; col++) {
                        int index = rowStart + col * uvPixelStride;

                        nv21[pos++] = index < vRemaining ? vBufferArray[index] : 0;
                        nv21[pos++] = index < uRemaining ? uBufferArray[index] : 0;
                    }
                }

                return nv21;
            }
        } catch (Exception e) {
            Log.e(TAG, "YUV conversion failed", e);
            return null;
        }
    }

    private void ensureCapacity(int nv21Size, int uSize, int vSize) {
        if (nv21Buffer == null || nv21Buffer.length < nv21Size) {
            nv21Buffer = new byte[nv21Size];
        }
        if (uBufferArray == null || uBufferArray.length < uSize) {
            uBufferArray = new byte[uSize];
        }
        if (vBufferArray == null || vBufferArray.length < vSize) {
            vBufferArray = new byte[vSize];
        }
    }

    private boolean getBoolean(@Nullable Map<String, Object> arguments, @NonNull String key, boolean defaultValue) {
        if (arguments == null || !arguments.containsKey(key)) {
            return defaultValue;
        }
        Object val = arguments.get(key);
        if (val instanceof Boolean) return (Boolean) val;
        if (val instanceof String) return Boolean.parseBoolean((String) val);
        return defaultValue;
    }

    private double getDouble(@Nullable Map<String, Object> arguments, @NonNull String key, double defaultValue) {
        if (arguments == null || !arguments.containsKey(key)) {
            return defaultValue;
        }
        Object val = arguments.get(key);
        try {
            if (val instanceof Number) return ((Number) val).doubleValue();
            if (val instanceof String) return Double.parseDouble((String) val);
        } catch (Exception ignore) {
        }
        return defaultValue;
    }

    private int getInt(@Nullable Map<String, Object> arguments, @NonNull String key, int defaultValue) {
        if (arguments == null || !arguments.containsKey(key)) {
            return defaultValue;
        }
        Object val = arguments.get(key);
        try {
            if (val instanceof Number) return ((Number) val).intValue();
            if (val instanceof String) return Integer.parseInt((String) val);
        } catch (Exception ignore) {
        }
        return defaultValue;
    }
}
