package com.arcsoftfacern;

import android.graphics.Rect;
import android.util.Base64;
import android.util.Log;

import androidx.annotation.NonNull;

import com.arcsoft.face.ActiveFileInfo;
import com.arcsoft.face.Face3DAngle;
import com.arcsoft.face.FaceFeature;
import com.arcsoft.face.FaceEngine;
import com.arcsoft.face.FaceInfo;
import com.arcsoft.face.SearchResult;
import com.arcsoft.face.enums.DetectFaceOrientPriority;
import com.arcsoft.face.enums.DetectMode;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;

import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * ArcSoft Face SDK React Native 模块
 * 封装了 ArcSoft SDK 的核心功能，供 JS 层调用。
 */
public class ArcsoftFaceModule extends ReactContextBaseJavaModule {

  private static final String TAG = "ArcsoftFaceRN";

  private final ReactApplicationContext reactContext;
  private ArcsoftEngineManager engineManager;

  public ArcsoftFaceModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
    this.engineManager = ArcsoftEngineManager.getInstance(reactContext);
    Log.i(TAG, "ArcsoftFaceModule created");
  }

  @NonNull
  @Override
  public String getName() {
    return "ArcsoftFace";
  }

  // -------------------------
  // Helpers (辅助方法)
  // -------------------------

  // 将 JS 数组转换为 NV21 byte 数组
  private static byte[] nv21FromReadableArray(ReadableArray arr) {
    int len = arr.size();
    byte[] out = new byte[len];
    for (int i = 0; i < len; i++) {
      out[i] = (byte) (arr.getInt(i) & 0xFF);
    }
    return out;
  }

  // 将 Android Rect 转换为 JS 对象
  private static WritableMap rectToMap(Rect r) {
    WritableMap m = Arguments.createMap();
    m.putInt("left", r.left);
    m.putInt("top", r.top);
    m.putInt("right", r.right);
    m.putInt("bottom", r.bottom);
    return m;
  }

  // 将 JS 对象转换为 Android Rect
  private static Rect rectFromMap(ReadableMap m) {
    return new Rect(
            m.getInt("left"),
            m.getInt("top"),
            m.getInt("right"),
            m.getInt("bottom")
    );
  }

  // 将 3D 角度转换为 JS 对象
  private static WritableMap face3dToMap(Face3DAngle a) {
    WritableMap m = Arguments.createMap();
    m.putDouble("roll", a != null ? a.getRoll() : 0);
    m.putDouble("pitch", a != null ? a.getPitch() : 0);
    m.putDouble("yaw", a != null ? a.getYaw() : 0);
    return m;
  }

  // 将 FaceInfo 转换为 JS 对象
  private static WritableMap faceInfoToMap(FaceInfo fi) {
    WritableMap m = Arguments.createMap();
    m.putMap("rect", rectToMap(fi.getRect()));
    m.putInt("orient", fi.getOrient());

    byte[] faceData = fi.getFaceData();
    if (faceData != null) {
      m.putString("faceDataBase64", Base64.encodeToString(faceData, Base64.NO_WRAP));
    }
    m.putInt("faceId", fi.getFaceId());

    Face3DAngle a = fi.getFace3DAngle();
    if (a != null) {
      m.putMap("angle3D", face3dToMap(a));
    }
    return m;
  }

  // 将 JS 对象转换为 FaceInfo
  private static FaceInfo faceInfoFromMap(ReadableMap m) {
    ReadableMap rectMap = m.getMap("rect");
    int orient = m.getInt("orient");
    FaceInfo fi = new FaceInfo();
    fi.setRect(rectFromMap(rectMap));
    fi.setOrient(orient);

    if (m.hasKey("faceId")) {
      fi.setFaceId(m.getInt("faceId"));
    }
    if (m.hasKey("faceDataBase64") && !m.isNull("faceDataBase64")) {
      String b64 = m.getString("faceDataBase64");
      if (b64 != null && !b64.isEmpty()) {
        fi.setFaceData(Base64.decode(b64, Base64.DEFAULT));
      }
    }
    return fi;
  }

  // 将 JS 数组转换为 FaceInfo 列表
  private static List<FaceInfo> faceInfosFromReadableArray(ReadableArray arr) {
    List<FaceInfo> out = new ArrayList<>();
    for (int i = 0; i < arr.size(); i++) {
      out.add(faceInfoFromMap(arr.getMap(i)));
    }
    return out;
  }

  // -------------------------
  // Public JS methods (导出给 JS 的方法)
  // -------------------------

  /**
   * 设置日志级别
   * @param level 0=OFF, 1=ERROR, 2=WARN, 3=INFO, 4=DEBUG, 5=VERBOSE
   */
  @ReactMethod
  public void setLogLevel(int level, Promise promise) {
    try {
      Log.i(TAG, "setLogLevel(" + level + ")");
      ArcsoftEngineManager.setLogLevel(level);
      promise.resolve(true);
    } catch (Throwable t) {
      promise.reject("setLogLevel_failed", t);
    }
  }

  /**
   * 在线激活 SDK
   * @param appId 应用ID
   * @param sdkKey SDK密钥
   */
  @ReactMethod
  public void activateOnline(String appId, String sdkKey, Promise promise) {
    long t0 = System.currentTimeMillis();
    Log.i(TAG, "activateOnline(appId.len=" + (appId == null ? 0 : appId.length()) + ", sdkKey.len=" + (sdkKey == null ? 0 : sdkKey.length()) + ")");
    try {
      int code = engineManager.activateOnline(appId, sdkKey);
      Log.i(TAG, "activateOnline => code=" + code + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      promise.resolve(code);
    } catch (Throwable t) {
      Log.e(TAG, "activateOnline failed", t);
      promise.reject("activateOnline_failed", t);
    }
  }

  /**
   * 获取激活文件信息
   */
  @ReactMethod
  public void getActiveFileInfo(Promise promise) {
    long t0 = System.currentTimeMillis();
    Log.d(TAG, "getActiveFileInfo()");
    try {
      ActiveFileInfo info = engineManager.getActiveFileInfo();
      if (info == null) {
        promise.resolve(null);
        return;
      }
      WritableMap map = Arguments.createMap();
      map.putString("appId", info.getAppId());
      map.putString("sdkKey", info.getSdkKey());
      map.putString("platform", info.getPlatform());
      map.putString("sdkVersion", info.getSdkVersion());
      map.putString("fileVersion", info.getFileVersion());
      map.putString("expireTime", info.getEndTime()); // Android 使用 getEndTime
      map.putString("deviceFingerprint", ""); // Android 暂无
      Log.d(TAG, "getActiveFileInfo => ok, cost=" + (System.currentTimeMillis() - t0) + "ms");
      promise.resolve(map);
    } catch (Throwable t) {
      Log.e(TAG, "getActiveFileInfo failed", t);
      promise.reject("getActiveFileInfo_failed", t);
    }
  }

  /**
   * 初始化引擎
   * @param optionsJson 配置参数 JSON 字符串
   */
  @ReactMethod
  public void initEngine(String optionsJson, Promise promise) {
    long t0 = System.currentTimeMillis();
    Log.i(TAG, "initEngine(json=" + optionsJson + ")");
    try {
      String detectModeStr = "video";
      int maxFaceNum = 5;
      boolean enableAge = false;
      boolean enableGender = false;
      boolean enableLiveness = false;
      boolean enable3DAngle = false;

      if (optionsJson != null) {
        try {
          JSONObject json = new JSONObject(optionsJson);
          if (json.has("detectMode")) detectModeStr = json.getString("detectMode");
          if (json.has("maxFaceNum")) maxFaceNum = json.getInt("maxFaceNum");
          if (json.has("enableAge")) enableAge = json.getBoolean("enableAge");
          if (json.has("enableGender")) enableGender = json.getBoolean("enableGender");
          if (json.has("enableLiveness")) enableLiveness = json.getBoolean("enableLiveness");
          if (json.has("enable3DAngle")) enable3DAngle = json.getBoolean("enable3DAngle");
        } catch (Exception e) {
          Log.w(TAG, "initEngine: failed to parse JSON string", e);
        }
      }

      DetectMode detectMode = "image".equalsIgnoreCase(detectModeStr) ? DetectMode.ASF_DETECT_MODE_IMAGE : DetectMode.ASF_DETECT_MODE_VIDEO;

      int combinedMask = FaceEngine.ASF_FACE_DETECT | FaceEngine.ASF_FACE_RECOGNITION;
      if (enableAge) combinedMask |= FaceEngine.ASF_AGE;
      if (enableGender) combinedMask |= FaceEngine.ASF_GENDER;
      if (enableLiveness) combinedMask |= FaceEngine.ASF_LIVENESS;

      int code = engineManager.initEngine(
              detectMode,
              DetectFaceOrientPriority.ASF_OP_ALL_OUT,
              maxFaceNum,
              combinedMask
      );

      Log.i(TAG, "initEngine => code=" + code + ", mask=" + combinedMask + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      promise.resolve(code);
    } catch (Throwable t) {
      Log.e(TAG, "initEngine failed", t);
      promise.reject("initEngine_failed", t);
    }
  }

  /**
   * 销毁引擎
   */
  @ReactMethod
  public void unInitEngine(Promise promise) {
    long t0 = System.currentTimeMillis();
    Log.i(TAG, "unInitEngine()");
    try {
      int code = engineManager.unInitEngine();
      Log.i(TAG, "unInitEngine => code=" + code + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      promise.resolve(code);
    } catch (Throwable t) {
      Log.e(TAG, "unInitEngine failed", t);
      promise.reject("unInitEngine_failed", t);
    }
  }

  // =========================
  // NV21 (视频流处理)
  // =========================

  /**
   * NV21 人脸检测
   */
  @ReactMethod
  public void detectFacesNV21(ReadableArray nv21, int width, int height, Promise promise) {
    long t0 = System.currentTimeMillis();
    Log.d(TAG, "detectFacesNV21(w=" + width + ", h=" + height + ", len=" + (nv21 == null ? 0 : nv21.size()) + ")");
    try {
      byte[] bytes = nv21FromReadableArray(nv21);
      List<FaceInfo> faces = engineManager.detectFacesNV21(bytes, width, height);
      WritableArray out = Arguments.createArray();
      for (FaceInfo f : faces) out.pushMap(faceInfoToMap(f));
      Log.d(TAG, "detectFacesNV21 => faces=" + faces.size() + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      promise.resolve(out);
    } catch (Throwable t) {
      Log.e(TAG, "detectFacesNV21 failed", t);
      promise.reject("detectFaces_failed", t);
    }
  }

  /**
   * NV21 特征提取
   */
  @ReactMethod
  public void extractFeatureNV21(ReadableArray nv21, int width, int height, ReadableMap face, Promise promise) {
    long t0 = System.currentTimeMillis();
    Log.d(TAG, "extractFeatureNV21(w=" + width + ", h=" + height + ")");
    try {
      byte[] bytes = nv21FromReadableArray(nv21);
      FaceInfo fi = faceInfoFromMap(face);
      FaceFeature feat = engineManager.extractFeatureNV21(bytes, width, height, fi);
      if (feat == null || feat.getFeatureData() == null) {
        Log.w(TAG, "extractFeatureNV21 => null");
        promise.resolve(null);
        return;
      }
      WritableMap res = Arguments.createMap();
      res.putString("dataBase64", Base64.encodeToString(feat.getFeatureData(), Base64.NO_WRAP));
      Log.d(TAG, "extractFeatureNV21 => ok, cost=" + (System.currentTimeMillis() - t0) + "ms");
      promise.resolve(res);
    } catch (Throwable t) {
      Log.e(TAG, "extractFeatureNV21 failed", t);
      promise.reject("extractFeature_failed", t);
    }
  }

  @ReactMethod
  public void getAgeNV21(ReadableArray nv21, int width, int height, ReadableArray faces, Promise promise) {
    long t0 = System.currentTimeMillis();
    Log.d(TAG, "getAgeNV21(faces=" + (faces == null ? 0 : faces.size()) + ")");
    try {
      ArcsoftEngineManager.AttrResult r = engineManager.processAttributes(
              nv21FromReadableArray(nv21),
              width,
              height,
              faceInfosFromReadableArray(faces),
              FaceEngine.ASF_AGE
      );
      WritableArray out = Arguments.createArray();
      for (int v : r.ages) out.pushInt(v);
      Log.d(TAG, "getAgeNV21 => n=" + r.ages.length + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      promise.resolve(out);
    } catch (Throwable t) {
      Log.e(TAG, "getAgeNV21 failed", t);
      promise.reject("getAge_failed", t);
    }
  }

  @ReactMethod
  public void getGenderNV21(ReadableArray nv21, int width, int height, ReadableArray faces, Promise promise) {
    long t0 = System.currentTimeMillis();
    Log.d(TAG, "getGenderNV21(faces=" + (faces == null ? 0 : faces.size()) + ")");
    try {
      ArcsoftEngineManager.AttrResult r = engineManager.processAttributes(
              nv21FromReadableArray(nv21),
              width,
              height,
              faceInfosFromReadableArray(faces),
              FaceEngine.ASF_GENDER
      );
      WritableArray out = Arguments.createArray();
      for (int v : r.genders) out.pushInt(v);
      Log.d(TAG, "getGenderNV21 => n=" + r.genders.length + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      promise.resolve(out);
    } catch (Throwable t) {
      Log.e(TAG, "getGenderNV21 failed", t);
      promise.reject("getGender_failed", t);
    }
  }

  @ReactMethod
  public void getLivenessNV21(ReadableArray nv21, int width, int height, ReadableArray faces, Promise promise) {
    long t0 = System.currentTimeMillis();
    Log.d(TAG, "getLivenessNV21(faces=" + (faces == null ? 0 : faces.size()) + ")");
    try {
      ArcsoftEngineManager.AttrResult r = engineManager.processAttributes(
              nv21FromReadableArray(nv21),
              width,
              height,
              faceInfosFromReadableArray(faces),
              FaceEngine.ASF_LIVENESS
      );
      WritableArray out = Arguments.createArray();
      for (int v : r.liveness) out.pushInt(v);
      Log.d(TAG, "getLivenessNV21 => n=" + r.liveness.length + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      promise.resolve(out);
    } catch (Throwable t) {
      Log.e(TAG, "getLivenessNV21 failed", t);
      promise.reject("getLiveness_failed", t);
    }
  }

  @ReactMethod
  public void getFace3DAngleNV21(ReadableArray nv21, int width, int height, ReadableArray faces, Promise promise) {
    long t0 = System.currentTimeMillis();
    Log.d(TAG, "getFace3DAngleNV21(faces=" + (faces == null ? 0 : faces.size()) + ")");
    try {
      ArcsoftEngineManager.AttrResult r = engineManager.processAttributes(
              nv21FromReadableArray(nv21),
              width,
              height,
              faceInfosFromReadableArray(faces),
              0
      );
      WritableArray out = Arguments.createArray();
      for (int i = 0; i < r.rolls.length; i++) {
        WritableMap m = Arguments.createMap();
        m.putDouble("roll", r.rolls[i]);
        m.putDouble("pitch", i < r.pitchs.length ? r.pitchs[i] : 0);
        m.putDouble("yaw", i < r.yaws.length ? r.yaws[i] : 0);
        out.pushMap(m);
      }
      Log.d(TAG, "getFace3DAngleNV21 => n=" + r.rolls.length + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      promise.resolve(out);
    } catch (Throwable t) {
      Log.e(TAG, "getFace3DAngleNV21 failed", t);
      promise.reject("get3DAngle_failed", t);
    }
  }

  // =========================
  // Image (Base64 图片处理)
  // =========================

  /**
   * Base64 图片人脸检测
   */
  @ReactMethod
  public void detectFacesImage(String base64, Promise promise) {
    long t0 = System.currentTimeMillis();
    Log.d(TAG, "detectFacesImage(len=" + (base64 == null ? 0 : base64.length()) + ")");
    try {
      List<FaceInfo> faces = engineManager.detectFacesImage(base64);
      WritableArray out = Arguments.createArray();
      for (FaceInfo f : faces) out.pushMap(faceInfoToMap(f));
      Log.d(TAG, "detectFacesImage => faces=" + faces.size() + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      promise.resolve(out);
    } catch (Throwable t) {
      Log.e(TAG, "detectFacesImage failed", t);
      promise.reject("detectFacesImage_failed", t);
    }
  }

  /**
   * Base64 图片特征提取
   */
  @ReactMethod
  public void extractFeatureImage(String base64, ReadableMap face, Promise promise) {
    long t0 = System.currentTimeMillis();
    Log.d(TAG, "extractFeatureImage()");
    try {
      FaceInfo fi = faceInfoFromMap(face);
      FaceFeature feat = engineManager.extractFeatureImage(base64, fi);
      if (feat == null || feat.getFeatureData() == null) {
        Log.w(TAG, "extractFeatureImage => null");
        promise.resolve(null);
        return;
      }
      WritableMap res = Arguments.createMap();
      res.putString("dataBase64", Base64.encodeToString(feat.getFeatureData(), Base64.NO_WRAP));
      Log.d(TAG, "extractFeatureImage => ok, cost=" + (System.currentTimeMillis() - t0) + "ms");
      promise.resolve(res);
    } catch (Throwable t) {
      Log.e(TAG, "extractFeatureImage failed", t);
      promise.reject("extractFeatureImage_failed", t);
    }
  }

  @ReactMethod
  public void getAgeImage(String base64, ReadableArray faces, Promise promise) {
    long t0 = System.currentTimeMillis();
    Log.d(TAG, "getAgeImage(faces=" + (faces == null ? 0 : faces.size()) + ")");
    try {
      ArcsoftEngineManager.AttrResult r = engineManager.processAttributesImage(
              base64,
              faceInfosFromReadableArray(faces),
              FaceEngine.ASF_AGE
      );
      WritableArray out = Arguments.createArray();
      for (int v : r.ages) out.pushInt(v);
      Log.d(TAG, "getAgeImage => n=" + r.ages.length + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      promise.resolve(out);
    } catch (Throwable t) {
      Log.e(TAG, "getAgeImage failed", t);
      promise.reject("getAgeImage_failed", t);
    }
  }

  @ReactMethod
  public void getGenderImage(String base64, ReadableArray faces, Promise promise) {
    long t0 = System.currentTimeMillis();
    Log.d(TAG, "getGenderImage(faces=" + (faces == null ? 0 : faces.size()) + ")");
    try {
      ArcsoftEngineManager.AttrResult r = engineManager.processAttributesImage(
              base64,
              faceInfosFromReadableArray(faces),
              FaceEngine.ASF_GENDER
      );
      WritableArray out = Arguments.createArray();
      for (int v : r.genders) out.pushInt(v);
      Log.d(TAG, "getGenderImage => n=" + r.genders.length + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      promise.resolve(out);
    } catch (Throwable t) {
      Log.e(TAG, "getGenderImage failed", t);
      promise.reject("getGenderImage_failed", t);
    }
  }

  @ReactMethod
  public void getLivenessImage(String base64, ReadableArray faces, Promise promise) {
    long t0 = System.currentTimeMillis();
    Log.d(TAG, "getLivenessImage(faces=" + (faces == null ? 0 : faces.size()) + ")");
    try {
      ArcsoftEngineManager.AttrResult r = engineManager.processAttributesImage(
              base64,
              faceInfosFromReadableArray(faces),
              FaceEngine.ASF_LIVENESS
      );
      WritableArray out = Arguments.createArray();
      for (int v : r.liveness) out.pushInt(v);
      Log.d(TAG, "getLivenessImage => n=" + r.liveness.length + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      promise.resolve(out);
    } catch (Throwable t) {
      Log.e(TAG, "getLivenessImage failed", t);
      promise.reject("getLivenessImage_failed", t);
    }
  }

  @ReactMethod
  public void getFace3DAngleImage(String base64, ReadableArray faces, Promise promise) {
    long t0 = System.currentTimeMillis();
    Log.d(TAG, "getFace3DAngleImage(faces=" + (faces == null ? 0 : faces.size()) + ")");
    try {
      ArcsoftEngineManager.AttrResult r = engineManager.processAttributesImage(
              base64,
              faceInfosFromReadableArray(faces),
              0
      );
      WritableArray out = Arguments.createArray();
      for (int i = 0; i < r.rolls.length; i++) {
        WritableMap m = Arguments.createMap();
        m.putDouble("roll", r.rolls[i]);
        m.putDouble("pitch", i < r.pitchs.length ? r.pitchs[i] : 0);
        m.putDouble("yaw", i < r.yaws.length ? r.yaws[i] : 0);
        out.pushMap(m);
      }
      Log.d(TAG, "getFace3DAngleImage => n=" + r.rolls.length + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      promise.resolve(out);
    } catch (Throwable t) {
      Log.e(TAG, "getFace3DAngleImage failed", t);
      promise.reject("getFace3DAngleImage_failed", t);
    }
  }

  /**
   * 特征比对 (1:1)
   */
  @ReactMethod
  public void compareFeature(ReadableMap f1, ReadableMap f2, Promise promise) {
    long t0 = System.currentTimeMillis();
    Log.d(TAG, "compareFeature()");
    try {
      String a = f1.getString("dataBase64");
      String b = f2.getString("dataBase64");
      float score = engineManager.compareBase64(a, b);
      Log.d(TAG, "compareFeature => score=" + score + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      promise.resolve((double) score);
    } catch (Throwable t) {
      Log.e(TAG, "compareFeature failed", t);
      promise.reject("compareFeature_failed", t);
    }
  }

  // -------------------------
  // Face DB (人脸库管理)
  // -------------------------

  /**
   * 注册人脸特征
   */
  @ReactMethod
  public void registerFaceFeature(String id, ReadableMap feature, Promise promise) {
    long t0 = System.currentTimeMillis();
    Log.d(TAG, "registerFaceFeature(id=" + id + ")");
    try {
      String b64 = feature.getString("dataBase64");
      boolean ok = engineManager.faceDBAddOrUpdate(id, b64);
      Log.d(TAG, "registerFaceFeature => ok=" + ok + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      promise.resolve(ok);
    } catch (Throwable t) {
      Log.e(TAG, "registerFaceFeature failed", t);
      promise.reject("registerFaceFeature_failed", t);
    }
  }

  /**
   * 移除人脸特征
   */
  @ReactMethod
  public void removeFaceFeature(String id, Promise promise) {
    long t0 = System.currentTimeMillis();
    Log.d(TAG, "removeFaceFeature(id=" + id + ")");
    try {
      boolean ok = engineManager.faceDBRemove(id);
      Log.d(TAG, "removeFaceFeature => ok=" + ok + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      promise.resolve(ok);
    } catch (Throwable t) {
      Log.e(TAG, "removeFaceFeature failed", t);
      promise.reject("removeFaceFeature_failed", t);
    }
  }

  /**
   * 清空人脸库
   */
  @ReactMethod
  public void clearAllFaceFeature(Promise promise) {
    long t0 = System.currentTimeMillis();
    Log.d(TAG, "clearAllFaceFeature()");
    try {
      engineManager.faceDBClear();
      Log.d(TAG, "clearAllFaceFeature => ok, cost=" + (System.currentTimeMillis() - t0) + "ms");
      promise.resolve(null);
    } catch (Throwable t) {
      Log.e(TAG, "clearAllFaceFeature failed", t);
      promise.reject("clearAllFaceFeature_failed", t);
    }
  }

  /**
   * 获取人脸库数量
   */
  @ReactMethod
  public void getFaceCount(Promise promise) {
    long t0 = System.currentTimeMillis();
    Log.d(TAG, "getFaceCount()");
    try {
      int c = engineManager.faceDBCount();
      Log.d(TAG, "getFaceCount => " + c + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      promise.resolve(c);
    } catch (Throwable t) {
      Log.e(TAG, "getFaceCount failed", t);
      promise.reject("getFaceCount_failed", t);
    }
  }

  /**
   * 获取所有人脸列表
   */
  @ReactMethod
  public void getAllFaces(String userId, Promise promise) {
    long t0 = System.currentTimeMillis();
    Log.d(TAG, "getAllFaces(userId=" + userId + ")");
    try {
      List<Map<String, String>> faces = engineManager.faceDBGetAllFaces(userId);
      WritableArray out = Arguments.createArray();
      for (Map<String, String> face : faces) {
        WritableMap map = Arguments.createMap();
        map.putString("id", face.get("id"));
        map.putString("userId", face.get("userId"));
        map.putString("registerTime", face.get("registerTime"));
        out.pushMap(map);
      }
      Log.d(TAG, "getAllFaces => count=" + faces.size() + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      promise.resolve(out);
    } catch (Throwable t) {
      Log.e(TAG, "getAllFaces failed", t);
      promise.reject("getAllFaces_failed", t);
    }
  }

  /**
   * 搜索人脸 (1:N)
   */
  @ReactMethod
  public void searchFaceFeature(ReadableMap feature, double threshold, Promise promise) {
    long t0 = System.currentTimeMillis();
    Log.d(TAG, "searchFaceFeature(threshold=" + threshold + ")");
    try {
      String b64 = feature.getString("dataBase64");
      SearchResult sr = engineManager.faceDBSearchTop1(b64);
      WritableMap res = Arguments.createMap();
      if (sr == null || sr.getFaceFeatureInfo() == null) {
        res.putNull("id");
        res.putDouble("score", 0);
        Log.d(TAG, "searchFaceFeature => null, cost=" + (System.currentTimeMillis() - t0) + "ms");
        promise.resolve(res);
        return;
      }
      String tag = sr.getFaceFeatureInfo().getFaceTag();
      float score = sr.getMaxSimilar();
      if (tag == null || score < (float) threshold) {
        res.putNull("id");
        res.putDouble("score", score);
      } else {
        res.putString("id", tag);
        res.putDouble("score", score);
      }
      Log.d(TAG, "searchFaceFeature => id=" + tag + ", score=" + score + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      promise.resolve(res);
    } catch (Throwable t) {
      Log.e(TAG, "searchFaceFeature failed", t);
      promise.reject("searchFaceFeature_failed", t);
    }
  }
}
