package com.arcsoft.arcfacedemo.ui.viewmodel;

import android.content.Context;
import android.graphics.Point;
import android.graphics.Rect;
import android.media.Image;
import android.os.CountDownTimer;
import android.os.Handler;
import android.os.SystemClock;
import android.util.Log;
import android.util.Size;

import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

import com.arcsoft.arcfacedemo.ArcFaceApplication;
import com.arcsoft.arcfacedemo.util.Camera2TimestampHelper;
import com.arcsoft.arcfacedemo.util.ConfigUtil;
import com.arcsoft.arcfacedemo.util.FaceRectTransformer;
import com.arcsoft.arcfacedemo.util.ImageUtil;
import com.arcsoft.arcfacedemo.util.face.FaceHelper;
import com.arcsoft.arcfacedemo.util.face.constants.LivenessType;
import com.arcsoft.arcfacedemo.util.face.constants.RecognizeColor;
import com.arcsoft.arcfacedemo.util.face.model.FacePreviewInfo;
import com.arcsoft.arcfacedemo.util.face.model.RecognizeConfiguration;
import com.arcsoft.arcfacedemo.widget.FaceRectView;
import com.arcsoft.face.AgeInfo;
import com.arcsoft.face.ErrorInfo;
import com.arcsoft.face.FaceEngine;
import com.arcsoft.face.FaceInfo;
import com.arcsoft.face.GenderInfo;
import com.arcsoft.face.LivenessInfo;
import com.arcsoft.face.enums.DetectMode;
import com.arcsoft.face.enums.LivenessColorOrderMode;
import com.arcsoft.face.enums.LivenessImageColorMode;
import com.arcsoft.face.enums.LivenessInteractiveMode;
import com.arcsoft.face.model.LivenessDetectResult;

import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

public class InteractiveGlareLivenessCamera2ViewModel extends ViewModel {

    private static final String TAG = "InteractiveGlareLivenessCamera2ViewModel";
    private static final long WHITE = 0XFFFFFFFFL;
    private static final long RED = 0xFFFF0000L;
    private static final long GREEN = 0xFF00FF00L;
    private static final long BLUE = 0xFF0000FFL;
    private static final long PINK = 0xFFFF00FFL;
    private static final long YELLOW = 0xFFFFFF00L;

    private FaceEngine flEngine;
    private FaceEngine ftEngine;
    private FaceHelper faceHelper;
    private Size previewSize;

    private MutableLiveData<Integer> ftInitCode = new MutableLiveData<>();
    private MutableLiveData<Integer> flInitCode = new MutableLiveData<>();
    private MutableLiveData<Long> currentColor = new MutableLiveData<>();
    private MutableLiveData<String> actionTip = new MutableLiveData<>();
    private MutableLiveData<Boolean> collectColorImageLiveData = new MutableLiveData<>();
    private MutableLiveData<Boolean> endProcessLd = new MutableLiveData<>();

    private boolean beginCollectColorImage;
    private long[] currentColorArray = new long[4];
    private int collectColorImageCount = 0;
    private LivenessColorOrderMode colorOrderMode;
    private ConcurrentHashMap<Integer, Integer> rgbLivenessMap;
    /**
     * 当前炫光背景颜色检测状态
     */
    private ConcurrentMap<LivenessImageColorMode, Integer> currentColorImageStatusMap;

    private int actionCompletedCount;
    private boolean beginInteractiveLiveness;
    private ConcurrentMap<Integer, Integer> actionLiveStatusMap;
    private CountDownTimer countDownTimer;

    /**
     * 炫光活体屏幕背光颜色发生改变时的时间戳
     */
    private long colorImageChangeTimeBase;

    public MutableLiveData<Long> getCurrentColor() {
        return currentColor;
    }

    public MutableLiveData<String> getActionTip() {
        return actionTip;
    }

    public MutableLiveData<Boolean> getCollectColorImageLiveData() {
        return collectColorImageLiveData;
    }

    public MutableLiveData<Boolean> getEndProcessLd() {
        return endProcessLd;
    }

    public void init() {
        Context context = ArcFaceApplication.getApplication();
        rgbLivenessMap = new ConcurrentHashMap<>();
        currentColorImageStatusMap = new ConcurrentHashMap<>(4);
        actionLiveStatusMap = new ConcurrentHashMap<>();

        ftEngine = new FaceEngine();
        ftInitCode.postValue(ftEngine.init(context, DetectMode.ASF_DETECT_MODE_VIDEO, ConfigUtil.getFtOrient(context),
                ConfigUtil.getRecognizeMaxDetectFaceNum(context), FaceEngine.ASF_FACE_DETECT));

        flEngine = new FaceEngine();
        flInitCode.postValue(flEngine.init(context, DetectMode.ASF_DETECT_MODE_VIDEO, ConfigUtil.getFtOrient(context),
                ConfigUtil.getRecognizeMaxDetectFaceNum(context), FaceEngine.ASF_MASK_LIVENESS_SCREENFLASH));
    }

    public void onRgbCameraOpened(Size size) {
        Size lastPreviewSize = previewSize;
        previewSize = size;
        if (faceHelper == null || lastPreviewSize == null || lastPreviewSize.getWidth() != previewSize.getWidth() ||
                lastPreviewSize.getHeight() != previewSize.getHeight()) {
            Integer trackedFaceCount = null;
            if (faceHelper != null) {
                trackedFaceCount = faceHelper.getTrackedFaceCount();
                faceHelper.release();
            }
            Context context = ArcFaceApplication.getApplication().getApplicationContext();
            faceHelper = new FaceHelper.Builder()
                    .ftEngine(ftEngine)
                    .previewSize(previewSize)
                    .onlyDetectLiveness(true)
                    .recognizeConfiguration(new RecognizeConfiguration.Builder().keepMaxFace(true).build())
                    .trackedFaceCount(trackedFaceCount == null ? ConfigUtil.getTrackedFaceCount(context) : trackedFaceCount)
                    .build();
        }
    }

    public void setRgbFaceRectTransformer(FaceRectTransformer rgbFaceRectTransformer) {
        faceHelper.setRgbFaceRectTransformer(rgbFaceRectTransformer);
    }

    public void setIrFaceRectTransformer(FaceRectTransformer irFaceRectTransformer) {
        faceHelper.setIrFaceRectTransformer(irFaceRectTransformer);
    }

    /**
     * 开始检测
     * 1.先执行交互式动作检测，从以下四个动作里面选择一个进行检测
     * type == 1 --> 眨眼
     * type == 2 --> 张嘴
     * type == 3 --> 左摇头
     * type == 4 --> 右摇头
     */
    public void startDetect() {
        actionLiveStatusMap.clear();
        endProcessLd.setValue(false);
        Random random = new Random();
        //交互式动作随机四选一，默认值为-1（检测结果未知）
        int randomValue = random.nextInt(4) + 1;
        Integer[] actionArray = {randomValue};
        for (Integer i : actionArray) {
            actionLiveStatusMap.put(i, -1);
        }
        actionCompletedCount = 0;
        //将交互式动作检测开关设置为true
        beginInteractiveLiveness = true;
    }

    /**
     * 开始执行炫光活体检测流程
     */
    public void startColorDetect() {
        collectColorImageCount = 0;
        //从三组颜色模式中选择一种
        currentColorArray = getNewColorOrderArray();
        currentColorImageStatusMap.clear();
        //每种颜色模式包含四种颜色，需要定时500ms（应用层自定义配配置）更新一种背光颜色
        long time = 2000;
        countDownTimer = new CountDownTimer(time, time / 4) {
            @Override
            public void onTick(long millisUntilFinished) {
                Log.i(TAG, "onTick time:" + millisUntilFinished);
                //通知UI更新背光颜色
                currentColor.setValue(currentColorArray[collectColorImageCount]);
            }

            @Override
            public void onFinish() {
                //背光颜色更新结束
                beginCollectColorImage = false;
                collectColorImageCount = 0;
                countDownTimer.cancel();
            }
        }.start();
    }

    /**
     * UI更新背光颜色后，更新时间戳
     */
    public void updateBeginCollectColorImageTime() {
        colorImageChangeTimeBase = System.currentTimeMillis();
        Log.i(TAG, "colorImageChangeTimeBase:" + colorImageChangeTimeBase);
    }

    /**
     * 获取当前摄像头时间戳（转换成了系统时间）和UI背光颜色修改时间戳差值
     *
     * @param image
     * @return 差值
     */
    private long getCameraSubTime(Image image) {
        //获取当前摄像头时间戳（转换成了系统时间）
        long systemTimeMs = Camera2TimestampHelper.getInstance().getSystemTimeMs(image);

//        long systemTime = System.currentTimeMillis();
//        Log.i(TAG, "getCameraSubTime: " + (systemTime - systemTimeMs) + "ms");
//        long startTime = image.getTimestamp();
//        long endTime = SystemClock.elapsedRealtimeNanos();
//        Log.i(TAG, "getCameraSubTime2: " + (startTime - endTime) / 1_000_000 + "ms");

        //UI背光颜色修改时间戳
        long imageChangeTime = colorImageChangeTimeBase;
        //计算差值
        return systemTimeMs - imageChangeTime;
    }

    /**
     * 如果当前摄像头时间戳晚于UI背光时间100ms（范围可根据实际情况配置），
     * 说明UI背光环境已准备好，允许执行炫光活体检测逻辑
     * 否则需要继续等待
     *
     * @param subTime
     * @return t
     */
    private boolean enableTime(long subTime) {
        int baseTime = 100;
        int upperLimit = 200;
        return subTime >= baseTime && subTime < upperLimit;
    }

    /**
     * UI背光环境已准备好，允许执行炫光活体检测逻辑
     */
    private void setEnableCollectColorImage() {
        beginCollectColorImage = true;
        collectColorImageCount++;
        if (collectColorImageCount >= 3) {
            collectColorImageCount = 3;
        }
    }

    public List<FacePreviewInfo> onPreviewFrame(Image image) {
        long subTime = getCameraSubTime(image);

        /*
         * 执行人脸框检测逻辑
         */
        byte[] rgbNv21 = ImageUtil.getNV21FromImage(image);
        List<FacePreviewInfo> facePreviewInfoList = faceHelper.onPreviewFrame(rgbNv21, null, false);
        clearLeftFace(facePreviewInfoList);

        if (enableTime(subTime)) {
            Log.i(TAG, "onPreviewFrame subTime:" + subTime);
            colorImageChangeTimeBase = Long.MAX_VALUE;
            setEnableCollectColorImage();
        }
        /*
         * 执行活体检测逻辑
         */
        return processLiveness(rgbNv21, facePreviewInfoList);
    }

    /**
     * 执行算法SDK，传入当前摄像头图像帧数据，执行交互式动作检测和炫光活体检测
     *
     * @param rgbNv21         当前摄像头图像帧数据
     * @param previewInfoList 当前摄像头图像帧人脸框数据
     * @return 更新后的人脸框数据
     */
    private List<FacePreviewInfo> processLiveness(byte[] rgbNv21, List<FacePreviewInfo> previewInfoList) {
        /*
         * 当某一帧未检测到人脸，中断检测流程
         */
        if (previewInfoList == null || previewInfoList.size() == 0) {
            if (endProcessLd.getValue() != null && !endProcessLd.getValue()) {
                beginCollectColorImage = false;
                if (countDownTimer != null) {
                    countDownTimer.cancel();
                }
                currentColor.setValue(WHITE);
                endProcessLd.setValue(true);
            }
            return null;
        }
        if (beginInteractiveLiveness) {
            /*
             * 开始交互式动作检测流程
             */
            LivenessInteractiveMode mode = getInteractionMode(actionLiveStatusMap);
            if (mode != null) {
                rgbLivenessMap.put(previewInfoList.get(0).getTrackId(), -1);
                actionTip.postValue(getInteractionModeTip(mode));
                LivenessDetectResult detectResult = new LivenessDetectResult();
                int result = flEngine.livenessInteractiveDetect(rgbNv21, previewSize.getWidth(), previewSize.getHeight(), FaceEngine.CP_PAF_NV21,
                        previewInfoList.get(0).getFaceInfoRgb(), mode, false, detectResult);
                if (result == ErrorInfo.MOK) {
                    if (detectResult.result == LivenessInfo.ALIVE) {
                        /*
                         * 交互式动作检测成功
                         */
                        actionLiveStatusMap.put(mode.getMode(), LivenessInfo.ALIVE);
                        actionCompletedCount++;
//                        Log.i(TAG, "interactiveDetect mode:" + mode.getMode() + ", result=" + detectResult.result + ", actionCompletedCount:" +
//                                actionCompletedCount);
                        //上一个动作检测完成后，重置检测状态，为下一次动作检测做准备
                        flEngine.livenessInteractiveDetect(rgbNv21, previewSize.getWidth(), previewSize.getHeight(), FaceEngine.CP_PAF_NV21,
                                previewInfoList.get(0).getFaceInfoRgb(), mode, true, detectResult);
                        if (actionCompletedCount == actionLiveStatusMap.size()) {
                            actionTip.postValue("");
                            beginInteractiveLiveness = false;
                            //交互式动作检测成功，执行炫光活体检测流程
                            collectColorImageLiveData.setValue(true);
                        }
                    }
                }
            }
        }
        /*
         * 开始炫光活体检测流程
         */
        if (beginCollectColorImage) {
            beginCollectColorImage = false;
            if (currentColor != null && currentColor.getValue() != null) {
                LivenessImageColorMode colorMode = getImageColorMode(currentColor.getValue());
                if (currentColorImageStatusMap.get(colorMode) == null) {
                    currentColorImageStatusMap.put(colorMode, 0);
                    FaceInfo faceInfo = previewInfoList.get(0).getFaceInfoRgb();
                    boolean reset = (currentColorImageStatusMap.size() == 1);
                    LivenessDetectResult detectColorResult = new LivenessDetectResult();
                    flEngine.livenessGlareDetect(rgbNv21, previewSize.getWidth(), previewSize.getHeight(), FaceEngine.CP_PAF_NV21, faceInfo,
                            colorOrderMode, colorMode, reset, detectColorResult);

                    if (colorOrderMode != null) {
                        Log.i(TAG, "glareDetect ret:" + 0 + ", colorOrderMode:" + colorMode+ ", dataSize:" + rgbNv21.length
                                + "faceInfo:" + faceInfo.getFaceData().length + ", reset:" + reset + ", imageCount:" + collectColorImageCount + ", time" +
                                System.currentTimeMillis() + ", result:" + detectColorResult.result);
                    }
//                    String path = "/sdcard/Android/data/com.wlq.arcfacedemo.tes/files/cameraImage/" + colorMode + "_" + System.currentTimeMillis() +
//                            "_1280x720.NV21";
//                    FileIOUtils.writeFileFromBytesByStream(path, rgbNv21);

                    rgbLivenessMap.put(previewInfoList.get(0).getTrackId(), detectColorResult.result);
                    if (detectColorResult.result == 1 || detectColorResult.result == 0) {
                        //炫光活体检测完成，结果1 活体；0 非活体
                        endProcessLd.setValue(true);
                        if (countDownTimer != null) {
                            countDownTimer.cancel();
                        }
                        changeUIWhite();
                    } else if (detectColorResult.result == -18) {   //-18: 流程检测中，请继续调用此接口
                        if (currentColorImageStatusMap.size() == currentColorArray.length) {
                            rgbLivenessMap.put(previewInfoList.get(0).getTrackId(), -1);
                            //四个背光颜色都已执行完，但结果错误，最终检测结果失败
                            endProcessLd.setValue(true);
                            if (countDownTimer != null) {
                                countDownTimer.cancel();
                            }
                            changeUIWhite();
                        }
                    } else if (detectColorResult.result == -4) {    //-4: 人脸角度过大
                        if (currentColorImageStatusMap.size() == currentColorArray.length) {
                            rgbLivenessMap.put(previewInfoList.get(0).getTrackId(), -1);
                            //四个背光颜色都已执行完，但结果错误，最终检测结果失败
                            endProcessLd.setValue(true);
                            if (countDownTimer != null) {
                                countDownTimer.cancel();
                            }
                            changeUIWhite();
                        }
                    } else {    //其他错误
                        if (currentColorImageStatusMap.size() == currentColorArray.length) {
                            rgbLivenessMap.put(previewInfoList.get(0).getTrackId(), -1);
                            //四个背光颜色都已执行完，但结果错误，最终检测结果失败
                            endProcessLd.setValue(true);
                            if (countDownTimer != null) {
                                countDownTimer.cancel();
                            }
                            changeUIWhite();
                        }
                    }
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

    /**
     * 延迟300ms（可根据实际调整）显示白色背光，UI效果体验更流畅。
     */
    private void changeUIWhite() {
        new Handler().postDelayed(() -> {
            Log.i(TAG, "changeUIWhite:" + Thread.currentThread().getName());
            currentColor.setValue(WHITE);
        }, 300);
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

    /**
     * 随机获取一组颜色模式，每个模式包含四种颜色
     *
     * @return
     */
    private long[] getNewColorOrderArray() {
        Random random = new Random();
        int randomColorMode = random.nextInt(3);
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

    public Point loadPreviewSize() {
        String[] size = ConfigUtil.getPreviewSize(ArcFaceApplication.getApplication()).split("x");
        return new Point(Integer.parseInt(size[0]), Integer.parseInt(size[1]));
    }

    private LivenessInteractiveMode getInteractionMode(ConcurrentMap<Integer, Integer> statusMap) {
        int type = -1;
        for (Map.Entry<Integer, Integer> entry : statusMap.entrySet()) {
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
            Rect rect = livenessType == LivenessType.RGB ? facePreviewInfoList.get(i).getRgbTransformedRect() : facePreviewInfoList.get(i).getIrTransformedRect();
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
                    name = ("检测失败，错误码：" + liveness);
                    break;
            }
            drawInfoList.add(new FaceRectView.DrawInfo(rect, GenderInfo.UNKNOWN, AgeInfo.UNKNOWN_AGE, liveness, color, name));
        }
        return drawInfoList;
    }
}
