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
import java.util.concurrent.ConcurrentHashMap;

public class ArcsoftFaceProcessorPlugin extends FrameProcessorPlugin {
  private static final String TAG = "ArcsoftFacePlugin";
  private final ArcsoftEngineManager engineManager;

  // 优化策略：记录已处理的 faceId 和重试次数
  private final Map<Integer, String> processedFaceIds = new ConcurrentHashMap<>(); // faceId -> userId (if recognized)
  private final Map<Integer, Integer> faceRetryCounts = new ConcurrentHashMap<>(); // faceId -> retry count
  private final Map<Integer, Double> faceScores = new ConcurrentHashMap<>(); // faceId -> score
  private final Map<Integer, String> faceFeatures = new ConcurrentHashMap<>(); // faceId -> featureBase64
  private static final int DEFAULT_MAX_RETRY_COUNT = 5;

  public ArcsoftFaceProcessorPlugin(@NonNull VisionCameraProxy proxy, @Nullable Map<String, Object> options) {
    super();
    this.engineManager = ArcsoftEngineManager.getInstance(null);
  }

  @Nullable
  @Override
  public Object callback(@NonNull Frame frame, @Nullable Map<String, Object> arguments) {
    try {
      Image image = frame.getImage();
      if (image == null) {
        return null;
      }

      // 1. 解析参数
      boolean saveImage = false;
      boolean extractFeature = false;
      double scoreThreshold = 0.8; // 默认阈值
      int maxRetryCount = DEFAULT_MAX_RETRY_COUNT;
      
      if (arguments != null) {
        if (arguments.containsKey("saveImage")) {
          Object val = arguments.get("saveImage");
          if (val instanceof Boolean) saveImage = (Boolean) val;
          else if (val instanceof String) saveImage = Boolean.parseBoolean((String) val);
        }
        if (arguments.containsKey("extractFeature")) {
          Object val = arguments.get("extractFeature");
          if (val instanceof Boolean) extractFeature = (Boolean) val;
          else if (val instanceof String) extractFeature = Boolean.parseBoolean((String) val);
        }
        if (arguments.containsKey("score")) {
            Object val = arguments.get("score");
            if (val instanceof Number) scoreThreshold = ((Number) val).doubleValue();
            else if (val instanceof String) scoreThreshold = Double.parseDouble((String) val);
        }
        if (arguments.containsKey("maxRetryCount")) {
            Object val = arguments.get("maxRetryCount");
            if (val instanceof Number) maxRetryCount = ((Number) val).intValue();
            else if (val instanceof String) maxRetryCount = Integer.parseInt((String) val);
        }
      }

      // 2. 转换数据
      byte[] nv21 = yuv420ToNv21(image);
      if (nv21 == null) {
          Log.e(TAG, "Failed to convert YUV420 to NV21");
          return null;
      }

      // 3. 保存图片 (可选)
      String imagePath = null;
      if (saveImage) {
        imagePath = saveFrame(image, nv21);
      }

      // 4. 人脸检测
      int width = image.getWidth();
      int height = image.getHeight();
      List<FaceInfo> faces = engineManager.detectFacesNV21(nv21, width, height);

      // 清理离开画面的人脸状态
      cleanUpFaceStates(faces);

      // 5. 结果封装 & 特征提取
      List<Map<String, Object>> faceList = new ArrayList<>();
      for (FaceInfo face : faces) {
        Map<String, Object> map = new HashMap<>();
        Rect r = face.getRect();
        Map<String, Object> rectMap = new HashMap<>();
        rectMap.put("left", (double) r.left);
        rectMap.put("top", (double) r.top);
        rectMap.put("right", (double) r.right);
        rectMap.put("bottom", (double) r.bottom);

        map.put("rect", rectMap);
        map.put("orient", (double) face.getOrient());
        map.put("faceId", (double) face.getFaceId());

        int faceId = face.getFaceId();

        if (extractFeature) {
            // 优化策略：检查是否已识别
            if (processedFaceIds.containsKey(faceId)) {
                // 已识别，直接返回缓存的 userId
                String userId = processedFaceIds.get(faceId);
                if (userId != null && !userId.isEmpty()) {
                    map.put("userId", userId);
                    // 使用缓存的分数，如果没有则默认为 1.0
                    Double cachedScore = faceScores.get(faceId);
                    map.put("score", cachedScore != null ? cachedScore : 1.0);
                    
                    // 使用缓存的特征值
                    String cachedFeature = faceFeatures.get(faceId);
                    if (cachedFeature != null) {
                        map.put("featureBase64", cachedFeature);
                    }
                }
            } else {
                // 未识别或识别失败，检查重试次数
                int retryCount = faceRetryCounts.containsKey(faceId) ? faceRetryCounts.get(faceId) : 0;

                if (retryCount < maxRetryCount) {
                    FaceFeature feature = engineManager.extractFeatureNV21(nv21, width, height, face);
                    if (feature != null && feature.getFeatureData() != null) {
                        String b64 = Base64.encodeToString(feature.getFeatureData(), Base64.NO_WRAP);
                        map.put("featureBase64", b64);
                        
                        // 只要提取成功，就更新特征缓存 (即使是陌生人)
                        faceFeatures.put(faceId, b64);

                        // 自动搜索人脸库
                        SearchResult searchResult = engineManager.faceDBSearchTop1(b64);
                        if (searchResult != null && searchResult.getFaceFeatureInfo() != null) {
                            String tag = searchResult.getFaceFeatureInfo().getFaceTag();
                            float score = searchResult.getMaxSimilar();
                            // 使用传入的阈值
                            if (tag != null && score >= scoreThreshold) {
                                map.put("userId", tag);
                                map.put("score", (double) score);

                                // 识别成功，缓存状态
                                processedFaceIds.put(faceId, tag);
                                faceScores.put(faceId, (double) score); // 缓存分数
                                faceRetryCounts.remove(faceId);
                            } else {
                                // 识别失败（分数低），增加重试计数
                                faceRetryCounts.put(faceId, retryCount + 1);
                            }
                        } else {
                            // 搜索无结果，增加重试计数
                            faceRetryCounts.put(faceId, retryCount + 1);
                        }
                    } else {
                        Log.w(TAG, "Feature extraction failed for faceId=" + faceId);
                        faceRetryCounts.put(faceId, retryCount + 1);
                    }
                } else {
                    // 超过重试次数，不再尝试提取和搜索
                    // 但如果之前有缓存的特征值，返回它 (方便注册陌生人)
                    String cachedFeature = faceFeatures.get(faceId);
                    if (cachedFeature != null) {
                        map.put("featureBase64", cachedFeature);
                    }
                }
            }
        }

        faceList.add(map);
      }

      Map<String, Object> result = new HashMap<>();
      result.put("faces", faceList);
      if (imagePath != null) {
        result.put("imagePath", imagePath);
      }

      return result;
    } catch (Throwable e) {
      Log.e(TAG, "Error processing frame", e);
      return null;
    }
  }

  // 清理不再画面中的人脸状态
  private void cleanUpFaceStates(List<FaceInfo> currentFaces) {
      List<Integer> currentIds = new ArrayList<>();
      for (FaceInfo face : currentFaces) {
          currentIds.add(face.getFaceId());
      }

      // 移除 processedFaceIds 中不存在于 currentIds 的键
      List<Integer> toRemoveProcessed = new ArrayList<>();
      for (Integer id : processedFaceIds.keySet()) {
          if (!currentIds.contains(id)) {
              toRemoveProcessed.add(id);
          }
      }
      for (Integer id : toRemoveProcessed) {
          processedFaceIds.remove(id);
          faceScores.remove(id); // 同时移除分数缓存
      }
      
      // 移除 faceFeatures 中不存在于 currentIds 的键
      List<Integer> toRemoveFeatures = new ArrayList<>();
      for (Integer id : faceFeatures.keySet()) {
          if (!currentIds.contains(id)) {
              toRemoveFeatures.add(id);
          }
      }
      for (Integer id : toRemoveFeatures) {
          faceFeatures.remove(id);
      }

      // 移除 faceRetryCounts 中不存在于 currentIds 的键
      List<Integer> toRemoveRetry = new ArrayList<>();
      for (Integer id : faceRetryCounts.keySet()) {
          if (!currentIds.contains(id)) {
              toRemoveRetry.add(id);
          }
      }
      for (Integer id : toRemoveRetry) {
          faceRetryCounts.remove(id);
      }
  }

  private String saveFrame(Image image, byte[] nv21) {
    try {
      Context context = engineManager.getContext();
      if (context == null) {
        return null;
      }

      File file = new File(context.getExternalCacheDir(), "frame_" + System.currentTimeMillis() + ".jpg");
      FileOutputStream fos = new FileOutputStream(file);

      YuvImage yuvImage = new YuvImage(nv21, ImageFormat.NV21, image.getWidth(), image.getHeight(), null);
      yuvImage.compressToJpeg(new Rect(0, 0, image.getWidth(), image.getHeight()), 80, fos);

      fos.close();
      Log.i(TAG, "Saved frame to " + file.getAbsolutePath());
      return "file://" + file.getAbsolutePath();
    } catch (Exception e) {
      Log.e(TAG, "Failed to save frame", e);
      return null;
    }
  }

  private byte[] yuv420ToNv21(Image image) {
    try {
        int width = image.getWidth();
        int height = image.getHeight();

        Image.Plane[] planes = image.getPlanes();
        ByteBuffer yBuffer = planes[0].getBuffer();
        ByteBuffer uBuffer = planes[1].getBuffer();
        ByteBuffer vBuffer = planes[2].getBuffer();

        int yRowStride = planes[0].getRowStride();
        int uvRowStride = planes[1].getRowStride();
        int uvPixelStride = planes[1].getPixelStride();

        byte[] nv21 = new byte[width * height * 3 / 2];
        int pos = 0;

        // Y plane
        if (yRowStride == width) {
            yBuffer.get(nv21, 0, width * height);
            pos += width * height;
        } else {
            for (int row = 0; row < height; row++) {
                yBuffer.position(row * yRowStride);
                yBuffer.get(nv21, pos, width);
                pos += width;
            }
        }

        // UV plane (NV21: V first, then U)
        // For NV21, we need V U V U ...
        // ImageProxy usually gives semi-planar (pixelStride=2) or planar (pixelStride=1).

        // We need to handle stride carefully.
        // V buffer
        vBuffer.position(0);
        uBuffer.position(0);

        // Optimized for pixelStride == 2 (common case)
        if (uvPixelStride == 2 && uvRowStride == width && vBuffer.remaining() == (width * height / 2 - 1)) {
             // This is a special case where V buffer is almost exactly what we need for NV21 (V U V U...)
             // But wait, NV21 is V U V U.
             // If pixelStride is 2, V buffer is V x V x ... and U buffer is U x U x ...
             // Actually, often uBuffer and vBuffer overlap in memory for semi-planar.
             // vBuffer[0] = V, vBuffer[1] = U (if it's NV21 layout in memory)
             // Let's check if we can just copy.

             // Safe fallback: copy byte by byte
        }

        int uvHeight = height / 2;
        int uvWidth = width / 2;

        byte[] vData = new byte[vBuffer.remaining()];
        byte[] uData = new byte[uBuffer.remaining()];
        vBuffer.get(vData);
        uBuffer.get(uData);

        for (int row = 0; row < uvHeight; row++) {
             for (int col = 0; col < uvWidth; col++) {
                 int vIndex = row * uvRowStride + col * uvPixelStride;
                 int uIndex = row * uvRowStride + col * uvPixelStride;

                 // NV21: V then U
                 if (vIndex < vData.length) {
                     nv21[pos++] = vData[vIndex];
                 } else {
                     nv21[pos++] = 0;
                 }

                 if (uIndex < uData.length) {
                     nv21[pos++] = uData[uIndex];
                 } else {
                     nv21[pos++] = 0;
                 }
             }
        }

        return nv21;
    } catch (Exception e) {
        Log.e(TAG, "YUV conversion failed", e);
        return null;
    }
  }
}
