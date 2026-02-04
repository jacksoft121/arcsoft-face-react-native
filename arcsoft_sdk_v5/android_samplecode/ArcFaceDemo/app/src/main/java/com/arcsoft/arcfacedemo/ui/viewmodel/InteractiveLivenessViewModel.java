package com.arcsoft.arcfacedemo.ui.viewmodel;

import android.content.Context;
import android.graphics.Point;
import android.graphics.Rect;
import android.hardware.Camera;
import android.util.Log;
import android.util.Size;

import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

import com.arcsoft.arcfacedemo.ArcFaceApplication;
import com.arcsoft.arcfacedemo.R;
import com.arcsoft.arcfacedemo.util.ConfigUtil;
import com.arcsoft.arcfacedemo.util.FaceRectTransformer;
import com.arcsoft.arcfacedemo.util.face.FaceHelper;
import com.arcsoft.arcfacedemo.util.face.constants.LivenessType;
import com.arcsoft.arcfacedemo.util.face.constants.RecognizeColor;
import com.arcsoft.arcfacedemo.util.face.model.FacePreviewInfo;
import com.arcsoft.arcfacedemo.util.face.model.RecognizeConfiguration;
import com.arcsoft.arcfacedemo.widget.FaceRectView;
import com.arcsoft.face.AgeInfo;
import com.arcsoft.face.ErrorInfo;
import com.arcsoft.face.FaceEngine;
import com.arcsoft.face.GenderInfo;
import com.arcsoft.face.LivenessInfo;
import com.arcsoft.face.enums.DetectMode;
import com.arcsoft.face.enums.LivenessInteractiveMode;
import com.arcsoft.face.model.LivenessDetectResult;

import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

public class InteractiveLivenessViewModel extends ViewModel {

    private static final String TAG = "InteractiveLivenessViewModel";

    private FaceEngine flEngine;
    private FaceEngine ftEngine;

    private FaceHelper faceHelper;
    private Camera.Size previewSize;

    private MutableLiveData<Integer> ftInitCode = new MutableLiveData<>();
    private MutableLiveData<Integer> flInitCode = new MutableLiveData<>();
    private MutableLiveData<String> actionTip = new MutableLiveData<>();

    private ConcurrentHashMap<Integer, Integer> rgbLivenessMap;
    private boolean beginLiveness;
    private ConcurrentMap<Integer, Integer> actionLiveStatusMap;
    private int actionCompletedCount;

    public void init() {
        Context context = ArcFaceApplication.getApplication();
        rgbLivenessMap = new ConcurrentHashMap<>();
        actionLiveStatusMap = new ConcurrentHashMap<>();

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

    public void confirmLiveness(Integer[] actionArray) {
        actionLiveStatusMap.clear();
        for (Integer i : actionArray) {
            actionLiveStatusMap.put(i, -1);
        }
        actionCompletedCount = 0;
        beginLiveness = true;
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

    private String getInteractionModeTip(LivenessInteractiveMode mode) {
        int type = mode.getMode();
        if (type == -1) {
            return "";
        }
        if (type == 1) {
            return "请眨眨眼";
        } else if (type == 2) {
            return "请张张嘴";
        } else if (type == 3) {
            return "请左摇头";
        } else {
            return "请右摇头";
        }
    }

    public MutableLiveData<String> getActionTip() {
        return actionTip;
    }

    private LivenessInteractiveMode getInteractionMode() {
        int type = -1;
        for (Map.Entry<Integer, Integer> entry : actionLiveStatusMap.entrySet()) {
            if (entry.getValue() != LivenessInfo.ALIVE) {
                type = entry.getKey();
                break;
            }
        }
        if (type == -1) {
            return null;
        }
        if (type == 1) {
            return LivenessInteractiveMode.BLINK;
        } else if (type == 2) {
            return LivenessInteractiveMode.MOUTH_OPEN;
        } else if (type == 3) {
            return LivenessInteractiveMode.HEAD_LEFT;
        } else {
            return LivenessInteractiveMode.HEAD_RIGHT;
        }
    }

    private List<FacePreviewInfo> processLiveness(byte[] rgbNv21, List<FacePreviewInfo> previewInfoList) {
        if (previewInfoList == null || previewInfoList.size() == 0) {
            return null;
        }
        if (beginLiveness) {
            LivenessInteractiveMode mode = getInteractionMode();
            if (mode != null) {
                actionTip.postValue(getInteractionModeTip(mode));
                LivenessDetectResult detectResult = new LivenessDetectResult();
                int result = flEngine.livenessInteractiveDetect(rgbNv21, previewSize.width, previewSize.height, FaceEngine.CP_PAF_NV21, previewInfoList.get(0).getFaceInfoRgb(),
                        mode, false, detectResult);
                if (result == ErrorInfo.MOK) {
                    Log.i(TAG, "livenessInteractiveDetect mode:" + mode.getMode() + ", result=" + detectResult.result + ", degree:" + previewInfoList.get(0).getFaceInfoRgb().getOrient());
                    if (detectResult.result == LivenessInfo.ALIVE) {
                        actionLiveStatusMap.put(mode.getMode(), LivenessInfo.ALIVE);
                        actionCompletedCount ++;
                        flEngine.livenessInteractiveDetect(rgbNv21, previewSize.width, previewSize.height, FaceEngine.CP_PAF_NV21, previewInfoList.get(0).getFaceInfoRgb(),
                                mode, true, detectResult);
                        if (actionCompletedCount == actionLiveStatusMap.size()) {
                            FacePreviewInfo facePreviewInfo = previewInfoList.get(0);
                            rgbLivenessMap.put(facePreviewInfo.getTrackId(), LivenessInfo.ALIVE);
                            actionTip.postValue("");
                            /**
                             * 动作检测结束，后续可以根据业务需求进一步调用process检测RGB活体
                             */
                        }
                    } else if (detectResult.result == LivenessInfo.NOT_ALIVE) {
                        actionLiveStatusMap.put(mode.getMode(), LivenessInfo.NOT_ALIVE);
                        FacePreviewInfo facePreviewInfo = previewInfoList.get(0);
                        rgbLivenessMap.put(facePreviewInfo.getTrackId(), LivenessInfo.UNKNOWN);
                    } else {
                        FacePreviewInfo facePreviewInfo = previewInfoList.get(0);
                        rgbLivenessMap.put(facePreviewInfo.getTrackId(), detectResult.result);
                    }
                } else {
                    Log.e(TAG, "livenessInteractiveDetect result=" + result);
                    return previewInfoList;
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
                    facePreviewInfoList.get(i).getRgbTransformedRect() :
                    facePreviewInfoList.get(i).getIrTransformedRect();
            // 根据识别结果和活体结果设置颜色
            int color;
            String name;
            switch (liveness) {
                case LivenessInfo.ALIVE:
                    color = RecognizeColor.COLOR_SUCCESS;
                    name = "动作检测完成";
                    break;
                default:
                    color = RecognizeColor.COLOR_UNKNOWN;
                    name = ("动作检测未知，错误码：" + liveness);
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
}
