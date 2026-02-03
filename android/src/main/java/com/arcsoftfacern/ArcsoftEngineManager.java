package com.arcsoftfacern;

import android.content.Context;
import android.util.Base64;

import com.arcsoft.face.FaceEngine;
import com.arcsoft.face.ErrorInfo;
import com.arcsoft.face.FaceFeature;
import com.arcsoft.face.FaceInfo;
import com.arcsoft.face.FaceSimilar;
import com.arcsoft.face.LivenessInfo;
import com.arcsoft.face.VersionInfo;
import com.arcsoft.face.enums.DetectFaceOrientPriority;
import com.arcsoft.face.enums.DetectMode;

import java.util.ArrayList;
import java.util.List;

/**
 * Thin wrapper around ArcSoft FaceEngine for RN.
 *
 * Notes:
 * - Thread-safe: synchronized entry points.
 * - Uses a single FaceEngine instance for detect+feature+compare by default.
 * - Input image format: NV21 base64 (YUV420sp).
 */
public final class ArcsoftEngineManager {
  private static ArcsoftEngineManager sInstance;

  public static synchronized ArcsoftEngineManager getInstance() {
    if (sInstance == null) sInstance = new ArcsoftEngineManager();
    return sInstance;
  }

  private FaceEngine engine;
  private boolean inited = false;

  private ArcsoftEngineManager() {}

  public synchronized int activateOnline(Context ctx, String appId, String sdkKey) {
    return FaceEngine.activeOnline(ctx, appId, sdkKey);
  }

  public synchronized int init(Context ctx, DetectMode mode, DetectFaceOrientPriority orient, int scale, int maxFaceNum, int combinedMask) {
    if (engine == null) engine = new FaceEngine();
    int code = engine.init(ctx, mode, orient, scale, maxFaceNum, combinedMask);
    inited = (code == ErrorInfo.MOK);
    return code;
  }

  public synchronized void unInit() {
    if (engine != null) {
      try {
        engine.unInit();
      } catch (Throwable ignored) {}
    }
    inited = false;
  }

  public synchronized boolean isInited() {
    return inited;
  }

  public synchronized String getVersion() {
    if (engine == null) engine = new FaceEngine();
    VersionInfo vi = new VersionInfo();
    int code = engine.getVersion(vi);
    if (code != ErrorInfo.MOK) {
      return "";
    }
    // Example: "V" fields vary by SDK; keep robust.
    return vi.getVersion();
  }

  public static final class DetectResult {
    public final List<FaceInfo> faces;
    public final int code;
    DetectResult(List<FaceInfo> faces, int code) {
      this.faces = faces;
      this.code = code;
    }
  }

  public synchronized DetectResult detectFaces(byte[] nv21, int width, int height, int format) {
    if (!inited || engine == null) return new DetectResult(new ArrayList<FaceInfo>(), ErrorInfo.MERR_UNKNOWN);
    List<FaceInfo> faceInfos = new ArrayList<>();
    int code = engine.detectFaces(nv21, width, height, format, faceInfos);
    return new DetectResult(faceInfos, code);
  }

  public synchronized int extractFeature(byte[] nv21, int width, int height, int format, FaceInfo faceInfo, FaceFeature out) {
    if (!inited || engine == null) return ErrorInfo.MERR_UNKNOWN;
    return engine.extractFaceFeature(nv21, width, height, format, faceInfo, out);
  }

  public synchronized float compare(FaceFeature f1, FaceFeature f2) {
    if (!inited || engine == null) return 0f;
    FaceSimilar similar = new FaceSimilar();
    int code = engine.compareFaceFeature(f1, f2, similar);
    if (code != ErrorInfo.MOK) return 0f;
    return similar.getScore();
  }

  public synchronized int getLiveness(byte[] nv21, int width, int height, int format, List<FaceInfo> faces, List<LivenessInfo> out) {
    if (!inited || engine == null) return ErrorInfo.MERR_UNKNOWN;
    return engine.getLiveness(nv21, width, height, format, faces, out);
  }

  public static byte[] decodeBase64(String b64) {
    if (b64 == null) return null;
    // handle data URI
    int comma = b64.indexOf(',');
    if (comma >= 0) {
      b64 = b64.substring(comma + 1);
    }
    return Base64.decode(b64, Base64.DEFAULT);
  }

  public static String encodeBase64(byte[] bytes) {
    return Base64.encodeToString(bytes, Base64.NO_WRAP);
  }
}
