package com.arcsoftface.reactnative;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Base64;
import android.util.Log;

import com.arcsoft.face.AgeInfo;
import com.arcsoft.face.ErrorInfo;
import com.arcsoft.face.Face3DAngle;
import com.arcsoft.face.FaceEngine;
import com.arcsoft.face.FaceFeature;
import com.arcsoft.face.FaceInfo;
import com.arcsoft.face.FaceSimilar;
import com.arcsoft.face.GenderInfo;
import com.arcsoft.face.LivenessInfo;
import com.arcsoft.face.enums.CompareModel;
import com.arcsoft.face.enums.DetectFaceOrientPriority;
import com.arcsoft.face.enums.DetectMode;
import com.arcsoft.face.enums.DetectModel;
import com.arcsoft.face.enums.ExtractType;
import com.arcsoft.imageutil.ArcSoftImageFormat;
import com.arcsoft.imageutil.ArcSoftImageUtil;
import com.arcsoft.imageutil.ArcSoftImageUtilError;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.io.File;
import java.util.List;

public class ArcsoftFaceModule extends ReactContextBaseJavaModule {
    private static final String TAG = "ArcsoftFaceModule";
    private FaceEngine faceEngine;
    private ReactApplicationContext reactContext;

    static {
        try {
            // 先加载基础库，再加载引擎库
            System.loadLibrary("arcsoft_face");
            System.loadLibrary("arcsoft_face_engine");
            Log.d("ArcsoftFaceModule", "Native libraries loaded successfully");
        } catch (UnsatisfiedLinkError e) {
            Log.e("ArcsoftFaceModule", "Failed to load native libraries", e);
        }
    }

    public ArcsoftFaceModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        // 延迟初始化 FaceEngine，直到需要时才创建
    }

    @Override
    public String getName() {
        return "ArcsoftFaceModule";
    }

    @ReactMethod
    public void init(String appId, String sdkKey, String activeKey, Promise promise) {
        try {
            Log.d(TAG, "Starting ArcSoft Face Engine initialization...");
            Log.d(TAG, "APP_ID: " + (appId != null ? appId.substring(0, Math.min(8, appId.length())) + "..." : "null"));
            Log.d(TAG, "SDK_KEY: " + (sdkKey != null ? sdkKey.substring(0, Math.min(8, sdkKey.length())) + "..." : "null"));
            Log.d(TAG, "ACTIVE_KEY: " + (activeKey != null ? activeKey.substring(0, Math.min(8, activeKey.length())) + "..." : "null"));
            
            // 检查参数有效性
            if (appId == null || appId.isEmpty() || appId.equals("YOUR_ARCSOFT_APP_ID")) {
                Log.e(TAG, "Invalid APP_ID provided: " + appId);
                promise.reject("INVALID_CREDENTIALS", "APP_ID is invalid or not configured. Please set a valid APP_ID in config.");
                return;
            }
            
            if (sdkKey == null || sdkKey.isEmpty() || sdkKey.equals("YOUR_ARCSOFT_SDK_KEY")) {
                Log.e(TAG, "Invalid SDK_KEY provided");
                promise.reject("INVALID_CREDENTIALS", "SDK_KEY is invalid or not configured. Please set a valid SDK_KEY in config.");
                return;
            }

            // activeKey 可以为空字符串或null（用于在线激活）
            if (activeKey == null) {
                activeKey = "";
                Log.d(TAG, "Using empty activeKey for online activation");
            }

            // 创建 FaceEngine 实例
            if (faceEngine == null) {
                faceEngine = new FaceEngine();
                Log.d(TAG, "FaceEngine instance created");
            }

            // 激活引擎 - 在V5.0中，激活方法是静态方法
            Log.d(TAG, "Attempting to activate ArcSoft Face Engine...");
            Log.d(TAG, "APP_ID: " + appId.substring(0, Math.min(8, appId.length())) + "...");
            Log.d(TAG, "SDK_KEY: " + sdkKey.substring(0, Math.min(8, sdkKey.length())) + "...");
            Log.d(TAG, "ACTIVE_KEY: " + (activeKey.isEmpty() ? "(empty for online activation)" : activeKey.substring(0, Math.min(8, activeKey.length())) + "..."));
            Log.d(TAG, "Package name: " + reactContext.getPackageName());
            
            // 使用正确的参数顺序：context, activeKey, appId, sdkKey
            int code = FaceEngine.activeOnline(reactContext, activeKey, appId, sdkKey);
            Log.d(TAG, "Activation result code: " + code);
            
            if (code != ErrorInfo.MOK && code != ErrorInfo.MERR_ASF_ALREADY_ACTIVATED) {
                String errorMsg = getActivationErrorMessage(code);
                Log.e(TAG, "Activation failed: " + errorMsg);
                Log.e(TAG, "Package name verification: " + reactContext.getPackageName());
                Log.e(TAG, "Please verify:");
                Log.e(TAG, "1. APP_ID and SDK_KEY are correct");
                Log.e(TAG, "2. Package name '" + reactContext.getPackageName() + "' is registered in ArcSoft console");
                Log.e(TAG, "3. Network connection is available");
                Log.e(TAG, "4. SDK quota is not exceeded");
                promise.reject("ACTIVE_ERROR", "ArcSoft Face Engine active failed: " + code + " (" + errorMsg + ")");
                return;
            }
            
            Log.d(TAG, "ArcSoft Face Engine activated successfully");

            // 初始化引擎
            Log.d(TAG, "Initializing face engine with features...");
            int combinedMask = FaceEngine.ASF_FACE_DETECT
                | FaceEngine.ASF_FACE_RECOGNITION
                | FaceEngine.ASF_AGE
                | FaceEngine.ASF_GENDER
                | FaceEngine.ASF_LIVENESS;
            code = faceEngine.init(reactContext, DetectMode.ASF_DETECT_MODE_IMAGE, 
                DetectFaceOrientPriority.ASF_OP_0_ONLY,
                2, // 最大检测人脸数
                combinedMask);

            if (code != ErrorInfo.MOK) {
                String errorMsg = getInitErrorMessage(code);
                Log.e(TAG, "Engine init failed: " + errorMsg);
                promise.reject("INIT_ERROR", "ArcSoft Face Engine init failed: " + code + " (" + errorMsg + ")");
                return;
            }

            Log.d(TAG, "ArcSoft Face Engine initialized successfully");
            promise.resolve(true);
        } catch (Exception e) {
            Log.e(TAG, "Init error", e);
            promise.reject("INIT_ERROR", "Exception during initialization: " + e.getMessage());
        }
    }
    
    private String getActivationErrorMessage(int code) {
        switch (code) {
            case ErrorInfo.MOK:
                return "Success";
            case ErrorInfo.MERR_ASF_ALREADY_ACTIVATED:
                return "Already activated";
            case ErrorInfo.MERR_ASF_NETWORK_COULDNT_RESOLVE_HOST:
                return "Network error - could not resolve host";
            case ErrorInfo.MERR_ASF_NETWORK_CONNECT_TIMEOUT:
                return "Network timeout";
            case ErrorInfo.MERR_ASF_ACTIVEKEY_ACTIVEKEY_ACTIVATED:
                return "Key already activated on another device";
            case 2:
                return "Invalid APP_ID or SDK_KEY - please check your credentials";
            case 3:
                return "Activation quota exceeded";
            case 4:
                return "Network connection failed";
            case 5:
                return "Invalid package name - must match ArcSoft console configuration";
            case 6:
                return "Device not authorized";
            case 7:
                return "License expired";
            case 8:
                return "Invalid license format";
            default:
                return "Activation failed (code: " + code + ") - please check credentials and network";
        }
    }
    
    private String getInitErrorMessage(int code) {
        switch (code) {
            case ErrorInfo.MERR_ASF_ACTIVATION_FAIL:
                return "Activation required";
            default:
                return "Unknown initialization error";
        }
    }

    @ReactMethod
    public void uninit(Promise promise) {
        try {
            if (faceEngine != null) {
                int code = faceEngine.unInit();
                if (code != ErrorInfo.MOK) {
                    promise.reject("UNINIT_ERROR", "ArcSoft Face Engine uninit failed: " + code);
                    return;
                }
            }
            promise.resolve(true);
        } catch (Exception e) {
            Log.e(TAG, "Uninit error", e);
            promise.reject("UNINIT_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void detectFaces(String imagePath, Promise promise) {
        try {
            if (faceEngine == null) {
                promise.reject("ENGINE_NOT_INIT", "Face engine not initialized. Please call init() first.");
                return;
            }

            // 加载图片
            Bitmap bitmap = BitmapFactory.decodeFile(imagePath);
            if (bitmap == null) {
                promise.reject("IMAGE_LOAD_ERROR", "Failed to load image: " + imagePath);
                return;
            }
            bitmap = ArcSoftImageUtil.getAlignedBitmap(bitmap, true);

            // 转换bitmap为BGR24格式
            int width = bitmap.getWidth();
            int height = bitmap.getHeight();
            byte[] bgr24 = ArcSoftImageUtil.createImageData(width, height, ArcSoftImageFormat.BGR24);
            int transformCode = ArcSoftImageUtil.bitmapToImageData(bitmap, bgr24, ArcSoftImageFormat.BGR24);
            if (transformCode != ArcSoftImageUtilError.CODE_SUCCESS) {
                promise.reject("TRANSFORM_ERROR", "Failed to transform bitmap to BGR24: " + transformCode);
                return;
            }

            // 检测人脸 - 使用新的API
            List<FaceInfo> faceInfoList = new java.util.ArrayList<>();
            int detectCode = faceEngine.detectFaces(bgr24, width, height, FaceEngine.CP_PAF_BGR24, DetectModel.RGB, faceInfoList);
            
            if (detectCode != ErrorInfo.MOK) {
                promise.reject("DETECT_ERROR", "Face detection failed: " + detectCode);
                return;
            }
            
            WritableArray faceArray = Arguments.createArray();
            if (faceInfoList != null && !faceInfoList.isEmpty()) {
                for (FaceInfo faceInfo : faceInfoList) {
                    WritableMap faceMap = Arguments.createMap();
                    faceMap.putInt("left", faceInfo.getRect().left);
                    faceMap.putInt("top", faceInfo.getRect().top);
                    faceMap.putInt("right", faceInfo.getRect().right);
                    faceMap.putInt("bottom", faceInfo.getRect().bottom);
                    faceMap.putInt("orient", faceInfo.getOrient());
                    faceArray.pushMap(faceMap);
                }
            }

            bitmap.recycle();
            promise.resolve(faceArray);
        } catch (Exception e) {
            Log.e(TAG, "Detect faces error", e);
            promise.reject("DETECT_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void extractFeature(String imagePath, int extractType, Promise promise) {
        try {
            if (faceEngine == null) {
                promise.reject("ENGINE_NOT_INIT", "Face engine not initialized");
                return;
            }

            // 加载图片
            Bitmap bitmap = BitmapFactory.decodeFile(imagePath);
            if (bitmap == null) {
                promise.reject("IMAGE_LOAD_ERROR", "Failed to load image: " + imagePath);
                return;
            }

            // 转换bitmap为BGR24格式
            int width = bitmap.getWidth();
            int height = bitmap.getHeight();
            byte[] bgr24 = ArcSoftImageUtil.createImageData(width, height, ArcSoftImageFormat.BGR24);
            int transformCode = ArcSoftImageUtil.bitmapToImageData(bitmap, bgr24, ArcSoftImageFormat.BGR24);
            if (transformCode != ArcSoftImageUtilError.CODE_SUCCESS) {
                bitmap.recycle();
                promise.reject("TRANSFORM_ERROR", "Failed to transform bitmap to BGR24: " + transformCode);
                return;
            }

            // 检测人脸
            List<FaceInfo> faceInfoList = new java.util.ArrayList<>();
            int detectCode = faceEngine.detectFaces(bgr24, width, height, FaceEngine.CP_PAF_BGR24, DetectModel.RGB, faceInfoList);
            
            if (detectCode != ErrorInfo.MOK || faceInfoList.isEmpty()) {
                bitmap.recycle();
                promise.reject("NO_FACE", "No face detected in image");
                return;
            }

            // 提取第一个人脸的特征
            FaceFeature faceFeature = new FaceFeature();
            int code = faceEngine.extractFaceFeature(bgr24, width, height, FaceEngine.CP_PAF_BGR24, faceInfoList.get(0), extractType == ExtractType.REGISTER.getExtractType() ? ExtractType.REGISTER : ExtractType.RECOGNIZE, 0, faceFeature);

            bitmap.recycle();
            
            if (code != ErrorInfo.MOK) {
                promise.reject("EXTRACT_ERROR", "Extract feature failed: " + code);
                return;
            }

            // 将特征数据转换为 Base64
            String featureBase64 = Base64.encodeToString(faceFeature.getFeatureData(), Base64.NO_WRAP);
            promise.resolve(featureBase64);
        } catch (Exception e) {
            Log.e(TAG, "Extract feature error", e);
            promise.reject("EXTRACT_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void compareFaces(String feature1, String feature2, Promise promise) {
        try {
            if (faceEngine == null) {
                promise.reject("ENGINE_NOT_INIT", "Face engine not initialized");
                return;
            }

            // 验证输入参数
            if (feature1 == null || feature1.isEmpty()) {
                promise.reject("INVALID_PARAMETER", "Feature1 is null or empty");
                return;
            }
            
            if (feature2 == null || feature2.isEmpty()) {
                promise.reject("INVALID_PARAMETER", "Feature2 is null or empty");
                return;
            }

            // 解码 Base64 特征数据
            byte[] featureData1 = Base64.decode(feature1, Base64.NO_WRAP);
            byte[] featureData2 = Base64.decode(feature2, Base64.NO_WRAP);

            // 创建 FaceFeature 对象并设置特征数据
            FaceFeature faceFeature1 = new FaceFeature(featureData1);
            FaceFeature faceFeature2 = new FaceFeature(featureData2);

            // 比较特征 - 使用新的API
            FaceSimilar faceSimilar = new FaceSimilar();
            int compareCode = faceEngine.compareFaceFeature(faceFeature1, faceFeature2, faceSimilar);

            if (faceFeature1 != null && faceFeature1.getFeatureData() != null && faceFeature2 != null && faceFeature2.getFeatureData() != null && faceSimilar != null) {
                Log.d(TAG, "Feature1 length: " + faceFeature1.getFeatureData().length);
                Log.d(TAG, "Feature2 length: " + faceFeature2.getFeatureData().length);
            }

            if (compareCode == ErrorInfo.MOK) {
                promise.resolve(faceSimilar.getScore());
            } else {
                promise.reject("COMPARE_ERROR", "Face comparison failed: " + compareCode);
            }
        } catch (Exception e) {
            Log.e(TAG, "Compare faces error", e);
            promise.reject("COMPARE_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void livenessDetection(String imagePath, Promise promise) {
        try {
            if (faceEngine == null) {
                promise.reject("ENGINE_NOT_INIT", "Face engine not initialized");
                return;
            }

            // 加载图片
            Bitmap bitmap = BitmapFactory.decodeFile(imagePath);
            if (bitmap == null) {
                promise.reject("IMAGE_LOAD_ERROR", "Failed to load image: " + imagePath);
                return;
            }

            // 转换bitmap为BGR24格式
            int width = bitmap.getWidth();
            int height = bitmap.getHeight();
            byte[] bgr24 = ArcSoftImageUtil.createImageData(width, height, ArcSoftImageFormat.BGR24);
            int transformCode = ArcSoftImageUtil.bitmapToImageData(bitmap, bgr24, ArcSoftImageFormat.BGR24);
            if (transformCode != ArcSoftImageUtilError.CODE_SUCCESS) {
                bitmap.recycle();
                promise.reject("TRANSFORM_ERROR", "Failed to transform bitmap to BGR24: " + transformCode);
                return;
            }

            // 检测人脸
            List<FaceInfo> faceInfoList = new java.util.ArrayList<>();
            int detectCode = faceEngine.detectFaces(bgr24, width, height, FaceEngine.CP_PAF_BGR24, DetectModel.RGB, faceInfoList);
            
            if (detectCode != ErrorInfo.MOK || faceInfoList.isEmpty()) {
                bitmap.recycle();
                promise.reject("NO_FACE", "No face detected in image");
                return;
            }

            // 活体检测 - 使用简化的process方法
            int processCode = faceEngine.process(bgr24, width, height, FaceEngine.CP_PAF_BGR24, faceInfoList, FaceEngine.ASF_LIVENESS);
            
            bitmap.recycle();

            if (processCode == ErrorInfo.MOK) {
                // 获取活体检测结果
                List<LivenessInfo> livenessInfoList = new java.util.ArrayList<>();
                int getLivenessCode = faceEngine.getLiveness(livenessInfoList);
                
                if (getLivenessCode == ErrorInfo.MOK && livenessInfoList != null && !livenessInfoList.isEmpty()) {
                    LivenessInfo livenessInfo = livenessInfoList.get(0);
                    boolean isLive = livenessInfo.getLiveness() == LivenessInfo.ALIVE;
                    promise.resolve(isLive);
                } else {
                    promise.resolve(false);
                }
            } else {
                promise.reject("PROCESS_ERROR", "Liveness process failed: " + processCode);
            }
        } catch (Exception e) {
            Log.e(TAG, "Liveness detection error", e);
            promise.reject("LIVENESS_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void detectAge(String imagePath, Promise promise) {
        try {
            if (faceEngine == null) {
                promise.reject("ENGINE_NOT_INIT", "Face engine not initialized");
                return;
            }

            // 加载图片
            Bitmap bitmap = BitmapFactory.decodeFile(imagePath);
            if (bitmap == null) {
                promise.reject("IMAGE_LOAD_ERROR", "Failed to load image: " + imagePath);
                return;
            }

            // 转换bitmap为BGR24格式
            int width = bitmap.getWidth();
            int height = bitmap.getHeight();
            byte[] bgr24 = ArcSoftImageUtil.createImageData(width, height, ArcSoftImageFormat.BGR24);
            int transformCode = ArcSoftImageUtil.bitmapToImageData(bitmap, bgr24, ArcSoftImageFormat.BGR24);
            if (transformCode != ArcSoftImageUtilError.CODE_SUCCESS) {
                bitmap.recycle();
                promise.reject("TRANSFORM_ERROR", "Failed to transform bitmap to BGR24: " + transformCode);
                return;
            }

            // 检测人脸
            List<FaceInfo> faceInfoList = new java.util.ArrayList<>();
            int detectCode = faceEngine.detectFaces(bgr24, width, height, FaceEngine.CP_PAF_BGR24, DetectModel.RGB, faceInfoList);
            
            if (detectCode != ErrorInfo.MOK || faceInfoList.isEmpty()) {
                bitmap.recycle();
                promise.reject("NO_FACE", "No face detected in image");
                return;
            }

            // 年龄检测 - 使用简化的process方法
            int processCode = faceEngine.process(bgr24, width, height, FaceEngine.CP_PAF_BGR24, faceInfoList, FaceEngine.ASF_AGE);
            
            bitmap.recycle();

            if (processCode == ErrorInfo.MOK) {
                // 获取年龄检测结果
                List<AgeInfo> ageInfoList = new java.util.ArrayList<>();
                int getAgeCode = faceEngine.getAge(ageInfoList);
                
                if (getAgeCode == ErrorInfo.MOK && ageInfoList != null && !ageInfoList.isEmpty()) {
                    AgeInfo ageInfo = ageInfoList.get(0);
                    promise.resolve(ageInfo.getAge());
                } else {
                    promise.resolve(0);
                }
            } else {
                promise.reject("PROCESS_ERROR", "Age process failed: " + processCode);
            }
        } catch (Exception e) {
            Log.e(TAG, "Age detection error", e);
            promise.reject("AGE_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void detectGender(String imagePath, Promise promise) {
        try {
            if (faceEngine == null) {
                promise.reject("ENGINE_NOT_INIT", "Face engine not initialized");
                return;
            }

            // 加载图片
            Bitmap bitmap = BitmapFactory.decodeFile(imagePath);
            if (bitmap == null) {
                promise.reject("IMAGE_LOAD_ERROR", "Failed to load image: " + imagePath);
                return;
            }

            // 转换bitmap为BGR24格式
            int width = bitmap.getWidth();
            int height = bitmap.getHeight();
            byte[] bgr24 = ArcSoftImageUtil.createImageData(width, height, ArcSoftImageFormat.BGR24);
            int transformCode = ArcSoftImageUtil.bitmapToImageData(bitmap, bgr24, ArcSoftImageFormat.BGR24);
            if (transformCode != ArcSoftImageUtilError.CODE_SUCCESS) {
                bitmap.recycle();
                promise.reject("TRANSFORM_ERROR", "Failed to transform bitmap to BGR24: " + transformCode);
                return;
            }

            // 检测人脸
            List<FaceInfo> faceInfoList = new java.util.ArrayList<>();
            int detectCode = faceEngine.detectFaces(bgr24, width, height, FaceEngine.CP_PAF_BGR24, DetectModel.RGB, faceInfoList);
            
            if (detectCode != ErrorInfo.MOK || faceInfoList.isEmpty()) {
                bitmap.recycle();
                promise.reject("NO_FACE", "No face detected in image");
                return;
            }

            // 性别检测 - 使用简化的process方法
            int processCode = faceEngine.process(bgr24, width, height, FaceEngine.CP_PAF_BGR24, faceInfoList, FaceEngine.ASF_GENDER);
            
            bitmap.recycle();

            if (processCode == ErrorInfo.MOK) {
                // 获取性别检测结果
                List<GenderInfo> genderInfoList = new java.util.ArrayList<>();
                int getGenderCode = faceEngine.getGender(genderInfoList);
                
                if (getGenderCode == ErrorInfo.MOK && genderInfoList != null && !genderInfoList.isEmpty()) {
                    GenderInfo genderInfo = genderInfoList.get(0);
                    String gender = genderInfo.getGender() == GenderInfo.MALE ? "male" : "female";
                    promise.resolve(gender);
                } else {
                    promise.resolve("unknown");
                }
            } else {
                promise.reject("PROCESS_ERROR", "Gender process failed: " + processCode);
            }
        } catch (Exception e) {
            Log.e(TAG, "Gender detection error", e);
            promise.reject("GENDER_ERROR", e.getMessage());
        }
    }

    // 发送事件到 React Native
    private void sendEvent(String eventName, WritableMap params) {
        if (reactContext.hasActiveCatalystInstance()) {
            reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                    .emit(eventName, params);
        }
    }
}
