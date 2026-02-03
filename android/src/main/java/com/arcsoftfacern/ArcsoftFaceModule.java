package com.arcsoftfacern;

import com.arcsoft.face.FaceFeature;
import com.arcsoft.face.FaceInfo;
import com.facebook.react.bridge.*;

import android.content.Context;

import java.util.List;

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
  public void init(Promise promise) {
    int code = engineManager.init(getReactApplicationContext());
    if (code == 0) {
      promise.resolve(true);
    } else {
      promise.reject("INIT_FAILED", "ArcSoft init failed: " + code);
    }
  }

  @ReactMethod
  public void release() {
    engineManager.release();
  }

  /**
   * 人脸检测（返回人脸数量）
   */
  @ReactMethod
  public void detect(
          ReadableArray nv21,
          int width,
          int height,
          Promise promise
  ) {
    byte[] data = new byte[nv21.size()];
    for (int i = 0; i < nv21.size(); i++) {
      data[i] = (byte) nv21.getInt(i);
    }

    List<FaceInfo> faces = engineManager.detectFaces(data, width, height);
    promise.resolve(faces.size());
  }

  /**
   * 特征比对（示例：传两张 NV21）
   */
  @ReactMethod
  public void compare(
          ReadableArray nv21a,
          ReadableArray nv21b,
          int width,
          int height,
          Promise promise
  ) {
    byte[] a = new byte[nv21a.size()];
    byte[] b = new byte[nv21b.size()];

    for (int i = 0; i < a.length; i++) a[i] = (byte) nv21a.getInt(i);
    for (int i = 0; i < b.length; i++) b[i] = (byte) nv21b.getInt(i);

    List<FaceInfo> fa = engineManager.detectFaces(a, width, height);
    List<FaceInfo> fb = engineManager.detectFaces(b, width, height);

    if (fa.isEmpty() || fb.isEmpty()) {
      promise.resolve(0);
      return;
    }

    FaceFeature f1 = engineManager.extractFeature(a, width, height, fa.get(0));
    FaceFeature f2 = engineManager.extractFeature(b, width, height, fb.get(0));

    float score = engineManager.compare(f1, f2);
    promise.resolve(score);
  }
}
