package com.arcsoft.arcfacedemo.ui.viewmodel;

import android.content.Context;
import android.graphics.Point;
import android.graphics.Rect;
import android.hardware.Camera;
import android.os.CountDownTimer;
import android.util.Log;
import android.util.Size;

import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

import com.arcsoft.arcfacedemo.ArcFaceApplication;
import com.arcsoft.arcfacedemo.util.ConfigUtil;
import com.arcsoft.arcfacedemo.util.FaceRectTransformer;
import com.arcsoft.arcfacedemo.util.FileUtil;
import com.arcsoft.arcfacedemo.util.face.FaceHelper;
import com.arcsoft.arcfacedemo.util.face.constants.LivenessType;
import com.arcsoft.arcfacedemo.util.face.constants.RecognizeColor;
import com.arcsoft.arcfacedemo.util.face.model.FacePreviewInfo;
import com.arcsoft.arcfacedemo.util.face.model.RecognizeConfiguration;
import com.arcsoft.arcfacedemo.widget.FaceRectView;
import com.arcsoft.face.AgeInfo;
import com.arcsoft.face.FaceEngine;
import com.arcsoft.face.FaceInfo;
import com.arcsoft.face.GenderInfo;
import com.arcsoft.face.LivenessInfo;
import com.arcsoft.face.enums.DetectMode;
import com.arcsoft.face.enums.LivenessColorOrderMode;
import com.arcsoft.face.enums.LivenessImageColorMode;
import com.arcsoft.face.model.LivenessDetectResult;

import java.io.File;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;
import java.util.Random;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

public class GlareLivenessViewModel extends ViewModel {

    private static final String TAG = "InteractiveLivenessViewModel";
    private static final long WHITE = 0XFFFFFFFFL;
    private static final long RED = 0xFFFF0000L;
    private static final long GREEN = 0xFF00FF00L;
    private static final long BLUE = 0xFF0000FFL;
    private static final long PINK = 0xFFFF00FFL;
    private static final long YELLOW = 0xFFFFFF00L;

    private FaceEngine flEngine;
    private FaceEngine ftEngine;

    private FaceHelper faceHelper;
    private Camera.Size previewSize;

    private MutableLiveData<Integer> ftInitCode = new MutableLiveData<>();
    private MutableLiveData<Integer> flInitCode = new MutableLiveData<>();
    private MutableLiveData<Long> currentColor = new MutableLiveData<>();

    private long[] currentColorArray;
    private ConcurrentHashMap<Integer, Integer> rgbLivenessMap;
    private boolean beginCollectColorImage;
    private int collectColorImageCount = 0;
    private int randomColorMode;
    private LivenessColorOrderMode colorOrderMode;
    private ConcurrentMap<LivenessImageColorMode, byte[]> colorImageMap;
    private CountDownTimer countDownTimer;

    public MutableLiveData<Long> getCurrentColor() {
        return currentColor;
    }

    public void init() {
        Context context = ArcFaceApplication.getApplication();
        rgbLivenessMap = new ConcurrentHashMap<>();
        colorImageMap = new ConcurrentHashMap<>(4);

        ftEngine = new FaceEngine();
        ftInitCode.postValue(ftEngine.init(context, DetectMode.ASF_DETECT_MODE_VIDEO, ConfigUtil.getFtOrient(context),
                ConfigUtil.getRecognizeMaxDetectFaceNum(context), FaceEngine.ASF_FACE_DETECT));

        flEngine = new FaceEngine();
        flInitCode.postValue(flEngine.init(context, DetectMode.ASF_DETECT_MODE_VIDEO, ConfigUtil.getFtOrient(context),
                ConfigUtil.getRecognizeMaxDetectFaceNum(context), FaceEngine.ASF_MASK_LIVENESS_SCREENFLASH));
    }

    public void onRgbCameraOpened(Camera camera) {
        Camera.Size lastPreviewSize = previewSize;
        previewSize = camera.getParameters().getPreviewSize();
        // 切换相机的时候可能会导致预览尺寸发生变化
        initFaceHelper(lastPreviewSize);
        Log.i(TAG, "onRgbCameraOpened");
    }

    public void setRgbFaceRectTransformer(FaceRectTransformer rgbFaceRectTransformer) {
        faceHelper.setRgbFaceRectTransformer(rgbFaceRectTransformer);
    }

    public void setIrFaceRectTransformer(FaceRectTransformer irFaceRectTransformer) {
        faceHelper.setIrFaceRectTransformer(irFaceRectTransformer);
    }

    public void startDetect() {
        collectColorImageCount = 0;
        currentColorArray = getNewColorArray();
        colorImageMap.clear();
        long time = 1600;
        countDownTimer = new CountDownTimer(time, time / 4) {
            @Override
            public void onTick(long millisUntilFinished) {
                currentColor.setValue(currentColorArray[collectColorImageCount]);
            }

            @Override
            public void onFinish() {
                beginCollectColorImage = false;
                collectColorImageCount = 0;
            }
        }.start();
    }

    public void setEnableCollectColorImage() {
        Log.i(TAG, "setEnableCollectColorImage");
        beginCollectColorImage = true;
        collectColorImageCount ++;
    }

    public List<FacePreviewInfo> onPreviewFrame(byte[] rgbNv21) {
        List<FacePreviewInfo> facePreviewInfoList = faceHelper.onPreviewFrame(rgbNv21, null, false);
        clearLeftFace(facePreviewInfoList);
        return processLiveness(rgbNv21, facePreviewInfoList);
    }

    /**
     * 删除已经离开的人脸
     *
     * @param facePreviewInfoList 人脸和trackId列表
     */
    private void clearLeftFace(List<FacePreviewInfo> facePreviewInfoList) {
        Enumeration<Integer> keys = rgbLivenessMap.keys();
        while (keys.hasMoreElements()) {
            int key = keys.nextElement();
            boolean contained = false;
            for (FacePreviewInfo facePreviewInfo : facePreviewInfoList) {
                if (facePreviewInfo.getTrackId() == key) {
                    contained = true;
                    break;
                }
            }
            if (!contained) {
                rgbLivenessMap.remove(key);
            }
        }
    }

    private List<FacePreviewInfo> processLiveness(byte[] rgbNv21, List<FacePreviewInfo> previewInfoList) {
        if (previewInfoList == null || previewInfoList.size() == 0) {
            return null;
        }
        if (beginCollectColorImage) {
            beginCollectColorImage = false;
            LivenessImageColorMode mode = getImageColorMode(currentColor.getValue());
            if (colorImageMap.get(mode) == null) {
                colorImageMap.put(mode, rgbNv21);

                FaceInfo faceInfo = previewInfoList.get(0).getFaceInfoRgb();
                boolean reset = (colorImageMap.size() == 1);
                Log.i(TAG, "glareDetect1 ret:" + 0 + ", colorOrderMode:" + colorOrderMode.getMode() +", mode:" + mode + ", dataSize:" + rgbNv21.length
                        + "faceInfo:" + faceInfo.getFaceData().length + ", reset:" + reset + ", imageCount:" + collectColorImageCount + ", time" + System.currentTimeMillis());
                LivenessDetectResult detectResult = new LivenessDetectResult();
                int ret = flEngine.livenessGlareDetect(rgbNv21, previewSize.width, previewSize.height, FaceEngine.CP_PAF_NV21, faceInfo,
                        colorOrderMode, mode, reset, detectResult);
                Log.i(TAG, "glareDetect2 ret:" + ret + ", result:" + detectResult.result);
                rgbLivenessMap.put(previewInfoList.get(0).getTrackId(), detectResult.result);
                if (detectResult.result == 1 || detectResult.result == 0) {
                    currentColor.setValue(WHITE);
                    countDownTimer.cancel();
                } else if (detectResult.result == -18) {

                } else if (detectResult.result == -4) {
                    countDownTimer.cancel();
                    currentColor.setValue(WHITE);
                } else {
                    countDownTimer.cancel();
                    currentColor.setValue(WHITE);
                }
            }
        }
        for (FacePreviewInfo facePreviewInfo : previewInfoList) {
            Integer rgbLiveness = rgbLivenessMap.get(facePreviewInfo.getTrackId());
            if (rgbLiveness != null) {
                facePreviewInfo.setRgbLiveness(rgbLiveness);
            }
        }
        return previewInfoList;
    }

    private void initFaceHelper(Camera.Size lastPreviewSize) {
        if (faceHelper == null ||
                lastPreviewSize == null ||
                lastPreviewSize.width != previewSize.width || lastPreviewSize.height != previewSize.height) {
            Integer trackedFaceCount = null;
            // 记录切换时的人脸序号
            if (faceHelper != null) {
                trackedFaceCount = faceHelper.getTrackedFaceCount();
                faceHelper.release();
            }
            Context context = ArcFaceApplication.getApplication().getApplicationContext();
            Size size = new Size(previewSize.width, previewSize.height);
            faceHelper = new FaceHelper.Builder()
                    .ftEngine(ftEngine)
                    .previewSize(size)
                    .onlyDetectLiveness(true)
                    .recognizeConfiguration(new RecognizeConfiguration.Builder().keepMaxFace(true).build())
                    .trackedFaceCount(trackedFaceCount == null ? ConfigUtil.getTrackedFaceCount(context) : trackedFaceCount)
                    .build();
            Log.i(TAG, "initFaceHelper");
        }
    }

    /**
     * 根据预览信息生成绘制信息
     *
     * @param facePreviewInfoList 预览信息
     * @return 绘制信息
     */
    public List<FaceRectView.DrawInfo> getDrawInfo(List<FacePreviewInfo> facePreviewInfoList, LivenessType livenessType) {
        List<FaceRectView.DrawInfo> drawInfoList = new ArrayList<>();
        for (int i = 0; i < facePreviewInfoList.size(); i++) {
            int liveness = livenessType == LivenessType.RGB ? facePreviewInfoList.get(i).getRgbLiveness() : facePreviewInfoList.get(i).getIrLiveness();
            Rect rect = livenessType == LivenessType.RGB ?
                    facePreviewInfoList.get(i).getRgbTransformedRect() : facePreviewInfoList.get(i).getIrTransformedRect();
            // 根据识别结果和活体结果设置颜色
            int color;
            String name;
            switch (liveness) {
                case 1:
                    color = RecognizeColor.COLOR_SUCCESS;
                    name = "检测完成：活体";
                    break;
                case 0:
                    color = RecognizeColor.COLOR_UNKNOWN;
                    name = "检测完成：非活体";
                    break;
                case -18:
                    color = RecognizeColor.COLOR_UNKNOWN;
                    name = "检测中";
                    break;
                case -1:
                    color = RecognizeColor.COLOR_UNKNOWN;
                    name = ("检测未开始");
                    break;
                case -4:
                    color = RecognizeColor.COLOR_UNKNOWN;
                    name = ("检测错误，角度过大");
                    break;
                default:
                    color = RecognizeColor.COLOR_UNKNOWN;
                    name = ("检测错误，错误码：" + liveness);
                    break;
            }

            drawInfoList.add(new FaceRectView.DrawInfo(rect, GenderInfo.UNKNOWN,
                    AgeInfo.UNKNOWN_AGE, liveness, color, name));
        }
        return drawInfoList;
    }

    public Point loadPreviewSize() {
        String[] size = ConfigUtil.getPreviewSize(ArcFaceApplication.getApplication()).split("x");
        return new Point(Integer.parseInt(size[0]), Integer.parseInt(size[1]));
    }

    /**
     * 销毁引擎，faceHelper中可能会有特征提取耗时操作仍在执行，加锁防止crash
     */
    private void unInit() {
        if (ftEngine != null) {
            synchronized (ftEngine) {
                int ftUnInitCode = ftEngine.unInit();
                Log.i(TAG, "unInitEngine: " + ftUnInitCode);
            }
        }
        if (flEngine != null) {
            synchronized (flEngine) {
                int frUnInitCode = flEngine.unInit();
                Log.i(TAG, "unInitEngine: " + frUnInitCode);
            }
        }
    }

    public void destroy() {
        unInit();
    }

    private long[] getNewColorArray() {
        Random random = new Random();
        randomColorMode =  random.nextInt(3);
        long[] colorArray;
        if (randomColorMode == 0) {
            colorOrderMode = LivenessColorOrderMode.WHITE_RED_GREEN_BLUE;
            colorArray = new long[]{WHITE, RED, GREEN, BLUE};
        } else if (randomColorMode == 1) {
            colorOrderMode = LivenessColorOrderMode.WHITE_RED_GREEN_PINK;
            colorArray = new long[]{WHITE, RED, GREEN, PINK};
        } else {
            colorOrderMode = LivenessColorOrderMode.WHITE_RED_GREEN_YELLOW;
            colorArray = new long[]{WHITE, RED, GREEN, YELLOW};
        }
        return colorArray;
    }

    private LivenessImageColorMode getImageColorMode(long colorValue) {
        if (colorValue == WHITE) {
            return LivenessImageColorMode.WHITE;
        } else if (colorValue == RED) {
            return LivenessImageColorMode.RED;
        } else if (colorValue == GREEN) {
            return LivenessImageColorMode.GREEN;
        } else if (colorValue == BLUE) {
            return LivenessImageColorMode.BLUE;
        } else if (colorValue == PINK) {
            return LivenessImageColorMode.PINK;
        } else {
            return LivenessImageColorMode.YELLOW;
        }
    }
}
