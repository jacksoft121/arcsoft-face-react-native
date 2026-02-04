package com.arcsoftfacern;

import android.util.Base64;

import com.arcsoft.face.ActiveFileInfo;
import com.arcsoft.face.FaceFeature;
import com.arcsoft.face.FaceFeatureInfo;
import com.arcsoft.face.FaceInfo;
import com.arcsoft.face.SearchResult;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;

import java.util.ArrayList;
import java.util.List;

/**
 * React Native Bridge: ArcsoftFace
 * 说明：
 * - 只依赖你提供的 arcsoft_face.jar API
 * - 统一 TS 侧用 base64 传 FaceFeature（2056 bytes）
 * - detect 返回 FaceInfo 列表（rect/orient/faceId）
 */
public class ArcsoftFaceModule extends ReactContextBaseJavaModule {

  private final ArcsoftEngineManager engineManager;

  public ArcsoftFaceModule(ReactApplicationContext reactContext) {
    super(reactContext);
    engineManager = new ArcsoftEngineManager();
  }

  @Override
  public String getName() {
    return "ArcsoftFace";
  }

  private static byte[] readableArrayToBytes(ReadableArray arr) {
    byte[] data = new byte[arr.size()];
    for (int i = 0; i < arr.size(); i++) {
      // RN ReadableArray 没有 byte，通常是 int(0~255)
      data[i] = (byte) (arr.getInt(i) & 0xFF);
    }
    return data;
  }

  private static WritableMap faceInfoToMap(FaceInfo fi) {
    WritableMap m = Arguments.createMap();
    if (fi == null) return m;
    m.putInt("faceId", fi.getFaceId());
    m.putInt("orient", fi.getOrient());

    WritableMap rect = Arguments.createMap();
    if (fi.getRect() != null) {
      rect.putInt("left", fi.getRect().left);
      rect.putInt("top", fi.getRect().top);
      rect.putInt("right", fi.getRect().right);
      rect.putInt("bottom", fi.getRect().bottom);
    }
    m.putMap("rect", rect);
    return m;
  }

  // ===== SDK 注册/激活 =====
  @ReactMethod
  public void activeOnline(String appId, String sdkKey, Promise promise) {
    int code = ArcsoftEngineManager.activeOnline(getReactApplicationContext(), appId, sdkKey);
    promise.resolve(code);
  }

  @ReactMethod
  public void getActiveFileInfo(Promise promise) {
    ActiveFileInfo info = ArcsoftEngineManager.getActiveFileInfo(getReactApplicationContext());
    if (info == null) {
      promise.resolve(null);
      return;
    }
    WritableMap m = Arguments.createMap();
    m.putString("appId", info.getAppId());
    m.putString("sdkKey", info.getSdkKey());
    m.putString("platform", info.getPlatform());
    m.putString("sdkType", info.getSdkType());
    m.putString("sdkVersion", info.getSdkVersion());
    m.putString("fileVersion", info.getFileVersion());
    m.putString("startTime", info.getStartTime());
    m.putString("endTime", info.getEndTime());
    promise.resolve(m);
  }

  // ===== Engine init/release =====
  @ReactMethod
  public void init(Promise promise) {
    int mask =
            com.arcsoft.face.FaceEngine.ASF_FACE_DETECT
                    | com.arcsoft.face.FaceEngine.ASF_FACE_RECOGNITION
                    | com.arcsoft.face.FaceEngine.ASF_AGE
                    | com.arcsoft.face.FaceEngine.ASF_GENDER
                    | com.arcsoft.face.FaceEngine.ASF_LIVENESS;

    int code = engineManager.init(getReactApplicationContext(), mask, 10);
    if (code == 0) promise.resolve(true);
    else promise.reject("INIT_FAILED", "ArcSoft init failed: " + code);
  }

  @ReactMethod
  public void release() {
    engineManager.release();
  }

  // ===== Detect / Feature / Compare =====
  @ReactMethod
  public void detect(ReadableArray nv21, int width, int height, Promise promise) {
    byte[] data = readableArrayToBytes(nv21);
    List<FaceInfo> faces = engineManager.detectFaces(data, width, height);

    WritableArray arr = Arguments.createArray();
    for (FaceInfo fi : faces) {
      arr.pushMap(faceInfoToMap(fi));
    }
    promise.resolve(arr);
  }

  @ReactMethod
  public void extractFeature(ReadableArray nv21, int width, int height, int faceIndex, Promise promise) {
    byte[] data = readableArrayToBytes(nv21);
    List<FaceInfo> faces = engineManager.detectFaces(data, width, height);
    if (faces.isEmpty() || faceIndex < 0 || faceIndex >= faces.size()) {
      promise.resolve("");
      return;
    }
    FaceFeature feature = engineManager.extractFeature(data, width, height, faces.get(faceIndex));
    String base64 = ArcsoftEngineManager.featureToBase64(feature);
    promise.resolve(base64);
  }

  @ReactMethod
  public void compareFeatures(String featureABytesBase64, String featureBBytesBase64, Promise promise) {
    float score = engineManager.compareBase64(featureABytesBase64, featureBBytesBase64);
    promise.resolve((double) score);
  }

  // ===== Age / Gender / Liveness =====
  @ReactMethod
  public void processAttributes(ReadableArray nv21, int width, int height, Promise promise) {
    byte[] data = readableArrayToBytes(nv21);
    List<FaceInfo> faces = engineManager.detectFaces(data, width, height);
    ArcsoftEngineManager.AttrResult attrs = engineManager.processAttributes(data, width, height, faces);

    WritableMap res = Arguments.createMap();
    if (attrs == null) {
      res.putArray("ages", Arguments.createArray());
      res.putArray("genders", Arguments.createArray());
      res.putArray("liveness", Arguments.createArray());
      promise.resolve(res);
      return;
    }

    WritableArray ages = Arguments.createArray();
    WritableArray genders = Arguments.createArray();
    WritableArray liveness = Arguments.createArray();

    for (int v : attrs.ages) ages.pushInt(v);
    for (int v : attrs.genders) genders.pushInt(v);
    for (int v : attrs.liveness) liveness.pushInt(v);

    res.putArray("ages", ages);
    res.putArray("genders", genders);
    res.putArray("liveness", liveness);
    promise.resolve(res);
  }

  // ===== Face DB =====
  @ReactMethod
  public void registerFace(String faceTag, String featureBytesBase64, Promise promise) {
    int id = engineManager.registerFace(faceTag, featureBytesBase64);
    promise.resolve(id);
  }

  @ReactMethod
  public void searchFace(String featureBytesBase64, int topN, Promise promise) {
    List<SearchResult> results = engineManager.searchFace(featureBytesBase64, topN);

    WritableArray arr = Arguments.createArray();
    for (SearchResult r : results) {
      WritableMap m = Arguments.createMap();
      m.putDouble("score", r.getMaxSimilar());
      FaceFeatureInfo info = r.getFaceFeatureInfo();
      if (info != null) {
        m.putInt("searchId", info.getSearchId());
        m.putString("faceTag", info.getFaceTag());
      } else {
        m.putInt("searchId", -1);
        m.putString("faceTag", "");
      }
      arr.pushMap(m);
    }
    promise.resolve(arr);
  }

  @ReactMethod
  public void removeFace(int searchId, Promise promise) {
    int code = engineManager.removeFace(searchId);
    promise.resolve(code);
  }

  @ReactMethod
  public void getFaceCount(Promise promise) {
    promise.resolve(engineManager.getFaceCount());
  }

  @ReactMethod
  public void clearRegisteredFaces(Promise promise) {
    promise.resolve(engineManager.clearRegisteredFaces());
  }
}
