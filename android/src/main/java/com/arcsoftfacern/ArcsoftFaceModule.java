package com.arcsoftfacern;

import android.content.Context;
import android.util.Base64;

import androidx.annotation.NonNull;

import com.arcsoft.face.ErrorInfo;
import com.arcsoft.face.FaceEngine;
import com.arcsoft.face.FaceFeature;
import com.arcsoft.face.FaceInfo;
import com.arcsoft.face.FaceSimilar;
import com.arcsoft.face.VersionInfo;
import com.arcsoft.face.enums.DetectFaceOrientPriority;
import com.arcsoft.face.enums.DetectMode;
import com.arcsoft.face.enums.ImageFormat;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;

import java.util.ArrayList;
import java.util.List;

/**
 * ArcSoft ArcFace Android bridge.
 *
 * Notes:
 * - This module wraps ArcSoft FaceEngine (arcsoft_face.jar + native .so).
 * - Input images are expected to be NV21 bytes base64 encoded.
 */
public class ArcsoftFaceModule extends ReactContextBaseJavaModule {

  public static final String NAME = "ArcsoftFace";

  private final ReactApplicationContext reactContext;
  private FaceEngine detectEngine;
  private FaceEngine recognizeEngine;
  private boolean inited = false;

  public ArcsoftFaceModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }

  @NonNull
  @Override
  public String getName() {
    return NAME;
  }

  /**
   * Online activation.
   * @param appId ArcSoft AppId
   * @param sdkKey ArcSoft SDKKey
   */
  @ReactMethod
  public void activateOnline(String appId, String sdkKey, Promise promise) {
    Context ctx = reactContext.getApplicationContext();
    int code = FaceEngine.activeOnline(ctx, appId, sdkKey);
    promise.resolve(code);
  }

  /**
   * Initialize engines for detect + recognize.
   */
  @ReactMethod
  public synchronized void init(ReadableMap options, Promise promise) {
    if (inited) {
      promise.resolve(true);
      return;
    }

    int scale = options.hasKey("scale") ? options.getInt("scale") : 16;
    int maxFaceNum = options.hasKey("maxFaceNum") ? options.getInt("maxFaceNum") : 10;
    String mode = options.hasKey("detectMode") ? options.getString("detectMode") : "video";
    int orientPriority = options.hasKey("orientPriority") ? options.getInt("orientPriority") : 0;

    DetectMode detectMode = "image".equalsIgnoreCase(mode) ? DetectMode.ASF_DETECT_MODE_IMAGE : DetectMode.ASF_DETECT_MODE_VIDEO;

    DetectFaceOrientPriority orient;
    switch (orientPriority) {
      case 90: orient = DetectFaceOrientPriority.ASF_OP_90_ONLY; break;
      case 180: orient = DetectFaceOrientPriority.ASF_OP_180_ONLY; break;
      case 270: orient = DetectFaceOrientPriority.ASF_OP_270_ONLY; break;
      default: orient = DetectFaceOrientPriority.ASF_OP_0_ONLY; break;
    }

    // Mask: detect + recognize + liveness (RGB). You can extend if needed.
    int combinedMask = FaceEngine.ASF_FACE_DETECT
        | FaceEngine.ASF_FACE_RECOGNITION
        | FaceEngine.ASF_LIVENESS;

    Context ctx = reactContext.getApplicationContext();

    detectEngine = new FaceEngine();
    int code1 = detectEngine.init(ctx, detectMode, orient, scale, maxFaceNum, combinedMask);
    if (code1 != ErrorInfo.MOK) {
      cleanup();
      promise.reject("E_INIT_DETECT", "FaceEngine.init detect failed: " + code1);
      return;
    }

    recognizeEngine = new FaceEngine();
    int code2 = recognizeEngine.init(ctx, detectMode, orient, scale, maxFaceNum, combinedMask);
    if (code2 != ErrorInfo.MOK) {
      cleanup();
      promise.reject("E_INIT_RECOGNIZE", "FaceEngine.init recognize failed: " + code2);
      return;
    }

    inited = true;
    promise.resolve(true);
  }

  /**
   * Uninitialize engines.
   */
  @ReactMethod
  public synchronized void unInit(Promise promise) {
    cleanup();
    promise.resolve(null);
  }

  @ReactMethod
  public void getVersion(Promise promise) {
    FaceEngine fe = (detectEngine != null) ? detectEngine : new FaceEngine();
    VersionInfo versionInfo = new VersionInfo();
    int code = fe.getVersion(versionInfo);
    if (code == ErrorInfo.MOK) {
      promise.resolve(versionInfo.getVersion());
    } else {
      promise.reject("E_VERSION", "getVersion failed: " + code);
    }
  }

  /**
   * Detect faces from NV21 base64.
   */
  @ReactMethod
  public void detectFacesBase64(String nv21Base64, int width, int height, int format, int orient, Promise promise) {
    if (!inited || detectEngine == null) {
      promise.reject("E_NOT_INIT", "FaceEngine not initialized");
      return;
    }

    byte[] nv21 = Base64.decode(nv21Base64, Base64.DEFAULT);

    List<FaceInfo> faceInfoList = new ArrayList<>();

    // ArcSoft expects ImageFormat.NV21
    int code = detectEngine.detectFaces(nv21, width, height, ImageFormat.CP_PAF_NV21, faceInfoList);
    if (code != ErrorInfo.MOK) {
      promise.reject("E_DETECT", "detectFaces failed: " + code);
      return;
    }

    WritableArray arr = Arguments.createArray();
    for (FaceInfo fi : faceInfoList) {
      WritableMap m = Arguments.createMap();
      WritableMap r = Arguments.createMap();
      r.putInt("left", fi.getRect().left);
      r.putInt("top", fi.getRect().top);
      r.putInt("right", fi.getRect().right);
      r.putInt("bottom", fi.getRect().bottom);
      m.putMap("rect", r);
      m.putInt("orient", fi.getOrient());
      m.putInt("faceId", fi.getFaceId());
      arr.pushMap(m);
    }

    promise.resolve(arr);
  }

  /**
   * Extract face feature (first face by index) from NV21 base64.
   * Returns feature bytes base64.
   */
  @ReactMethod
  public void extractFeatureBase64(String nv21Base64, int width, int height, int format, int faceIndex, Promise promise) {
    if (!inited || recognizeEngine == null) {
      promise.reject("E_NOT_INIT", "FaceEngine not initialized");
      return;
    }

    byte[] nv21 = Base64.decode(nv21Base64, Base64.DEFAULT);

    List<FaceInfo> faceInfoList = new ArrayList<>();
    int detectCode = recognizeEngine.detectFaces(nv21, width, height, ImageFormat.CP_PAF_NV21, faceInfoList);
    if (detectCode != ErrorInfo.MOK) {
      promise.reject("E_DETECT", "detectFaces failed: " + detectCode);
      return;
    }

    if (faceInfoList.isEmpty() || faceIndex < 0 || faceIndex >= faceInfoList.size()) {
      promise.reject("E_NO_FACE", "No face found (index=" + faceIndex + ")");
      return;
    }

    FaceFeature faceFeature = new FaceFeature();
    int frCode = recognizeEngine.extractFaceFeature(nv21, width, height, ImageFormat.CP_PAF_NV21, faceInfoList.get(faceIndex), faceFeature);
    if (frCode != ErrorInfo.MOK) {
      promise.reject("E_FEATURE", "extractFaceFeature failed: " + frCode);
      return;
    }

    String featureB64 = Base64.encodeToString(faceFeature.getFeatureData(), Base64.NO_WRAP);
    promise.resolve(featureB64);
  }

  /**
   * Compare two feature base64 values.
   * Returns similarity score [0,1].
   */
  @ReactMethod
  public void compareFeatureBase64(String feature1Base64, String feature2Base64, Promise promise) {
    if (!inited || recognizeEngine == null) {
      promise.reject("E_NOT_INIT", "FaceEngine not initialized");
      return;
    }

    byte[] f1 = Base64.decode(feature1Base64, Base64.DEFAULT);
    byte[] f2 = Base64.decode(feature2Base64, Base64.DEFAULT);

    FaceFeature ff1 = new FaceFeature();
    ff1.setFeatureData(f1);
    FaceFeature ff2 = new FaceFeature();
    ff2.setFeatureData(f2);

    FaceSimilar fs = new FaceSimilar();
    int code = recognizeEngine.compareFaceFeature(ff1, ff2, fs);
    if (code != ErrorInfo.MOK) {
      promise.reject("E_COMPARE", "compareFaceFeature failed: " + code);
      return;
    }
    promise.resolve((double) fs.getScore());
  }

  private synchronized void cleanup() {
    inited = false;

    if (detectEngine != null) {
      try { detectEngine.unInit(); } catch (Throwable ignored) {}
      detectEngine = null;
    }

    if (recognizeEngine != null) {
      try { recognizeEngine.unInit(); } catch (Throwable ignored) {}
      recognizeEngine = null;
    }
  }
}
