package com.arcsoftfacern;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;

import com.arcsoft.face.FaceInfo;
import com.arcsoft.face.FaceFeature;
import com.arcsoft.face.SearchResult;

import java.util.List;

/**
 * React Native Bridge: ArcsoftFace
 *
 * 逐行对照 ArcSoft Android Demo (Java API)：
 * - FaceEngine.activeOnline
 * - FaceEngine.init/unInit
 * - detectFaces/extractFaceFeature/compareFaceFeature
 * - process/getAgeInfo/getGenderInfo/getLiveness
 * - registerFaceFeature/searchFaceFeature
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

  @ReactMethod
  public void activateOnline(String appId, String sdkKey, Promise promise) {
    int code = engineManager.activateOnline(getReactApplicationContext(), appId, sdkKey);
    if (code == 0) {
      promise.resolve(true);
    } else {
      promise.reject("ACTIVATE_FAILED", "ArcSoft activateOnline failed: " + code);
    }
  }

  @ReactMethod
  public void initEngine(Promise promise) {
    int code = engineManager.init(getReactApplicationContext());
    if (code == 0) {
      promise.resolve(true);
    } else {
      promise.reject("INIT_FAILED", "ArcSoft init failed: " + code);
    }
  }

  @ReactMethod
  public void unInitEngine() {
    engineManager.release();
  }

  @ReactMethod
  public void detectFaces(ReadableArray bytes, int width, int height, String format, Promise promise) {
    byte[] nv21 = toByteArray(bytes);
    List<FaceInfo> faces = engineManager.detectFaces(nv21, width, height);

    WritableArray out = Arguments.createArray();
    for (FaceInfo f : faces) {
      WritableMap m = Arguments.createMap();
      WritableMap rect = Arguments.createMap();
      rect.putInt("left", f.getRect().left);
      rect.putInt("top", f.getRect().top);
      rect.putInt("right", f.getRect().right);
      rect.putInt("bottom", f.getRect().bottom);
      m.putMap("rect", rect);
      m.putInt("orient", f.getOrient());
      out.pushMap(m);
    }

    WritableMap res = Arguments.createMap();
    res.putArray("faces", out);
    promise.resolve(res);
  }

  @ReactMethod
  public void extractFeature(ReadableArray bytes, int width, int height, ReadableMap faceInfo, Promise promise) {
    // 为了 TS 统一，这里允许 JS 传入 faceInfo（rect+orient）
    byte[] nv21 = toByteArray(bytes);
    FaceInfo fi = ArcsoftRNConverters.faceInfoFromJS(faceInfo);
    FaceFeature feature = engineManager.extractFeature(nv21, width, height, fi);
    if (feature == null) {
      promise.resolve(null);
      return;
    }
    WritableMap m = Arguments.createMap();
    m.putString("bytesBase64", android.util.Base64.encodeToString(feature.getFeatureData(), android.util.Base64.NO_WRAP));
    promise.resolve(m);
  }

  @ReactMethod
  public void compareFeature(String featureABytesBase64, String featureBBytesBase64, Promise promise) {
    float score = engineManager.compareBase64(featureABytesBase64, featureBBytesBase64);
    promise.resolve((double) score);
  }

  @ReactMethod
  public void processAttributes(ReadableArray bytes, int width, int height, String format, ReadableArray faceInfos, Promise promise) {
    byte[] nv21 = toByteArray(bytes);
    List<FaceInfo> faces = ArcsoftRNConverters.faceInfosFromJS(faceInfos);
    ArcsoftEngineManager.AttrResult attrs = engineManager.processAttributes(nv21, width, height, faces);
    WritableMap res = Arguments.createMap();
    res.putArray("ages", ArcsoftRNConverters.toWritableIntArray(attrs.ages));
    res.putArray("genders", ArcsoftRNConverters.toWritableIntArray(attrs.genders));
    res.putArray("liveness", ArcsoftRNConverters.toWritableIntArray(attrs.liveness));
    promise.resolve(res);
  }

  @ReactMethod
  public void registerFace(String userId, String featureBytesBase64, Promise promise) {
    int faceId = engineManager.registerFace(userId, featureBytesBase64);
    promise.resolve(faceId);
  }

  @ReactMethod
  public void searchFace(String featureBytesBase64, int maxResults, Promise promise) {
    SearchResult r = engineManager.searchFace(featureBytesBase64, maxResults);
    if (r == null) {
      promise.resolve(null);
      return;
    }
    WritableMap res = Arguments.createMap();
    res.putInt("faceId", r.getFaceId());
    res.putDouble("score", r.getScore());
    promise.resolve(res);
  }

  private static byte[] toByteArray(ReadableArray arr) {
    byte[] out = new byte[arr.size()];
    for (int i = 0; i < arr.size(); i++) {
      out[i] = (byte) (arr.getInt(i) & 0xFF);
    }
    return out;
  }
}
