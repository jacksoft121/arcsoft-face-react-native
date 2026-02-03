package com.arcsoft.rn;

import com.facebook.react.bridge.*;

import android.util.Base64;

import com.arcsoft.face.*;

import java.util.List;

/**
 * ✅ RN 唯一出口
 */
public class ArcsoftFaceModule extends ReactContextBaseJavaModule {

  private final ArcsoftEngineManager engineManager;

  public ArcsoftFaceModule(ReactApplicationContext reactContext) {
    super(reactContext);
    engineManager = new ArcsoftEngineManager();
  }

  @Override
  public String getName() {
    return "ArcSoftFace";
  }

  /** SDK 激活 */
  @ReactMethod
  public void activate(String appId, String sdkKey, Promise promise) {
    int code = engineManager.activate(getReactApplicationContext(), appId, sdkKey);
    promise.resolve(code);
  }

  /** 初始化 */
  @ReactMethod
  public void init(Promise promise) {
    int code = engineManager.init(getReactApplicationContext());
    promise.resolve(code);
  }

  /** 人脸检测 */
  @ReactMethod
  public void detectFaces(String nv21Base64, int width, int height, Promise promise) {
    byte[] nv21 = Base64.decode(nv21Base64, Base64.DEFAULT);

    List<FaceInfo> faces = engineManager.detectFaces(nv21, width, height);

    WritableArray arr = Arguments.createArray();
    for (FaceInfo f : faces) {
      WritableMap m = Arguments.createMap();
      m.putInt("left", f.getRect().left);
      m.putInt("top", f.getRect().top);
      m.putInt("right", f.getRect().right);
      m.putInt("bottom", f.getRect().bottom);
      m.putInt("orient", f.getOrient());
      arr.pushMap(m);
    }

    promise.resolve(arr);
  }

  /** 特征提取 */
  @ReactMethod
  public void extractFeature(
          String nv21Base64,
          int width,
          int height,
          int faceIndex,
          Promise promise
  ) {
    byte[] nv21 = Base64.decode(nv21Base64, Base64.DEFAULT);

    List<FaceInfo> faces = engineManager.detectFaces(nv21, width, height);
    FaceFeature feature = engineManager.extractFeature(
            nv21,
            width,
            height,
            faces.get(faceIndex)
    );

    WritableMap res = Arguments.createMap();
    res.putString(
            "feature",
            Base64.encodeToString(feature.getFeatureData(), Base64.NO_WRAP)
    );

    promise.resolve(res);
  }
}
