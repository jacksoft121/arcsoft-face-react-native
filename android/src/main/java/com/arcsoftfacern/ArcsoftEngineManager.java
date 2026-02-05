package com.arcsoftfacern;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Base64;
import android.util.Log;

import com.arcsoft.face.ActiveFileInfo;
import com.arcsoft.face.AgeInfo;
import com.arcsoft.face.ErrorInfo;
import com.arcsoft.face.Face3DAngle;
import com.arcsoft.face.FaceEngine;
import com.arcsoft.face.FaceFeature;
import com.arcsoft.face.FaceFeatureInfo;
import com.arcsoft.face.FaceInfo;
import com.arcsoft.face.FaceSimilar;
import com.arcsoft.face.GenderInfo;
import com.arcsoft.face.LivenessInfo;
import com.arcsoft.face.SearchResult;
import com.arcsoft.face.enums.CompareModel;
import com.arcsoft.face.enums.DetectFaceOrientPriority;
import com.arcsoft.face.enums.DetectMode;
import com.arcsoft.imageutil.ArcSoftImageFormat;
import com.arcsoft.imageutil.ArcSoftImageUtil;
import com.arcsoft.imageutil.ArcSoftImageUtilError;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * ArcSoft FaceEngine lifecycle + helper methods.
 * - Supports NV21 (preview) and BGR24 (image)
 */
public class ArcsoftEngineManager {

  // =========================
  // Logging
  // =========================
  private static final String TAG = "ArcsoftFaceRN";

  // 0=OFF,1=ERROR,2=WARN,3=INFO,4=DEBUG,5=VERBOSE
  private static volatile int sLogLevel = 3;

  public static void setLogLevel(int level) {
    if (level < 0) level = 0;
    if (level > 5) level = 5;
    sLogLevel = level;
    Log.i(TAG, "setLogLevel => " + sLogLevel);
  }

  private static boolean le(int need) { return sLogLevel >= need; }
  private static void e(String msg, Throwable t) { if (le(1)) Log.e(TAG, msg, t); }
  private static void w(String msg) { if (le(2)) Log.w(TAG, msg); }
  private static void i(String msg) { if (le(3)) Log.i(TAG, msg); }
  private static void d(String msg) { if (le(4)) Log.d(TAG, msg); }
  private static void v(String msg) { if (le(5)) Log.v(TAG, msg); }

  public static class AttrResult {
    public final int[] ages;
    public final int[] genders;
    public final int[] liveness;
    public final float[] rolls;
    public final float[] pitchs;
    public final float[] yaws;

    public AttrResult(int[] ages, int[] genders, int[] liveness, float[] rolls, float[] pitchs, float[] yaws) {
      this.ages = ages;
      this.genders = genders;
      this.liveness = liveness;
      this.rolls = rolls;
      this.pitchs = pitchs;
      this.yaws = yaws;
    }
  }

  private static volatile ArcsoftEngineManager sInstance;

  public static ArcsoftEngineManager getInstance(Context context) {
    if (sInstance == null) {
      synchronized (ArcsoftEngineManager.class) {
        if (sInstance == null) {
          sInstance = new ArcsoftEngineManager(context.getApplicationContext());
        }
      }
    }
    return sInstance;
  }

  private final Context appContext;
  private FaceEngine engine;
  private boolean inited = false;

  // JS tag(id) -> engine searchId
  private final Map<String, Integer> tagToSearchId = new ConcurrentHashMap<>();
  private final AtomicInteger nextSearchId = new AtomicInteger(1);

  private ArcsoftEngineManager(Context appContext) {
    this.appContext = appContext;
    i("EngineManager created");
  }

  public synchronized int activateOnline(String appId, String sdkKey) {
    long t0 = System.currentTimeMillis();
    d("activateOnline(appId.len=" + (appId == null ? 0 : appId.length()) + ", sdkKey.len=" + (sdkKey == null ? 0 : sdkKey.length()) + ")");
    try {
      int code = FaceEngine.activeOnline(appContext, appId, sdkKey);
      i("activateOnline => code=" + code + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      return code;
    } catch (Throwable t) {
      e("activateOnline exception", t);
      // best-effort fallback
      return ErrorInfo.MERR_UNKNOWN;
    }
  }

  public synchronized ActiveFileInfo getActiveFileInfo() {
    ActiveFileInfo activeFileInfo = new ActiveFileInfo();
    try {
      int code = FaceEngine.getActiveFileInfo(appContext, activeFileInfo);
      if (code == ErrorInfo.MOK) {
        return activeFileInfo;
      } else {
        w("getActiveFileInfo failed => code=" + code);
        return null;
      }
    } catch (Throwable t) {
      e("getActiveFileInfo exception", t);
      return null;
    }
  }

  public synchronized int initEngine(
          DetectMode detectMode,
          DetectFaceOrientPriority orientPriority,
          int maxFaceNum,
          int combinedMask
  ) {
    long t0 = System.currentTimeMillis();
    d("initEngine(mode=" + detectMode + ", orient=" + orientPriority + ", maxFaceNum=" + maxFaceNum + ", mask=" + combinedMask + ")");
    if (inited && engine != null) {
      i("initEngine => already inited, return 0");
      return 0;
    }

    engine = new FaceEngine();
    int code = engine.init(appContext, detectMode, orientPriority, maxFaceNum, combinedMask);
    inited = (code == ErrorInfo.MOK);
    if (!inited) {
      w("initEngine failed => code=" + code);
      engine = null;
    } else {
      i("initEngine success => code=0, cost=" + (System.currentTimeMillis() - t0) + "ms");
    }
    return code;
  }

  public synchronized int unInitEngine() {
    long t0 = System.currentTimeMillis();
    d("unInitEngine()");
    if (!inited || engine == null) {
      i("unInitEngine => not inited, return 0");
      return 0;
    }
    int code = engine.unInit();
    inited = false;
    engine = null;
    tagToSearchId.clear();
    i("unInitEngine => code=" + code + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
    return code;
  }

  private void ensureInited() {
    if (!inited || engine == null) {
      throw new IllegalStateException("FaceEngine not initialized");
    }
  }

  // =========================
  // NV21 Methods
  // =========================

  public synchronized List<FaceInfo> detectFacesNV21(byte[] nv21, int width, int height) {
    ensureInited();
    long t0 = System.currentTimeMillis();
    v("detectFacesNV21(w=" + width + ", h=" + height + ", len=" + (nv21 == null ? 0 : nv21.length) + ")");
    List<FaceInfo> faces = new ArrayList<>();
    int code = engine.detectFaces(nv21, width, height, FaceEngine.CP_PAF_NV21, faces);
    if (code != ErrorInfo.MOK) {
      w("detectFacesNV21 failed => code=" + code);
      faces.clear();
    }
    d("detectFacesNV21 => faces=" + faces.size() + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
    return faces;
  }

  public synchronized FaceFeature extractFeatureNV21(byte[] nv21, int width, int height, FaceInfo faceInfo) {
    ensureInited();
    long t0 = System.currentTimeMillis();
    v("extractFeatureNV21(w=" + width + ", h=" + height + ")");
    FaceFeature feature = new FaceFeature();
    int code = engine.extractFaceFeature(nv21, width, height, FaceEngine.CP_PAF_NV21, faceInfo, feature);
    if (code != ErrorInfo.MOK) {
      w("extractFeatureNV21 failed => code=" + code);
      return null;
    }
    d("extractFeatureNV21 => ok, cost=" + (System.currentTimeMillis() - t0) + "ms");
    return feature;
  }

  public synchronized AttrResult processAttributes(byte[] nv21, int width, int height, List<FaceInfo> faces, int combinedMask) {
    ensureInited();
    long t0 = System.currentTimeMillis();
    v("processAttributes(mask=" + combinedMask + ", faces=" + (faces == null ? 0 : faces.size()) + ")");

    int code = engine.process(nv21, width, height, FaceEngine.CP_PAF_NV21, faces, combinedMask);
    if (code != ErrorInfo.MOK) {
      w("processAttributes.process failed => code=" + code);
      return new AttrResult(new int[0], new int[0], new int[0], new float[0], new float[0], new float[0]);
    }
    return getAttrResult(faces);
  }

  // =========================
  // Image (BGR24) Methods
  // =========================

  private Object[] decodeImage(String base64) {
    try {
      byte[] decoded = Base64.decode(base64, Base64.DEFAULT);
      Bitmap bitmap = BitmapFactory.decodeByteArray(decoded, 0, decoded.length);
      if (bitmap == null) return null;

      // Align
      bitmap = ArcSoftImageUtil.getAlignedBitmap(bitmap, true);
      int w = bitmap.getWidth();
      int h = bitmap.getHeight();

      byte[] bgr24 = ArcSoftImageUtil.createImageData(w, h, ArcSoftImageFormat.BGR24);
      int code = ArcSoftImageUtil.bitmapToImageData(bitmap, bgr24, ArcSoftImageFormat.BGR24);
      if (code != ArcSoftImageUtilError.CODE_SUCCESS) {
        w("bitmapToImageData failed => " + code);
        return null;
      }
      return new Object[]{ bgr24, w, h };
    } catch (Throwable t) {
      e("decodeImage failed", t);
      return null;
    }
  }

  public synchronized List<FaceInfo> detectFacesImage(String base64) {
    ensureInited();
    long t0 = System.currentTimeMillis();
    Object[] img = decodeImage(base64);
    if (img == null) return new ArrayList<>();

    byte[] bgr24 = (byte[]) img[0];
    int width = (int) img[1];
    int height = (int) img[2];

    v("detectFacesImage(w=" + width + ", h=" + height + ")");
    List<FaceInfo> faces = new ArrayList<>();
    int code = engine.detectFaces(bgr24, width, height, FaceEngine.CP_PAF_BGR24, faces);
    if (code != ErrorInfo.MOK) {
      w("detectFacesImage failed => code=" + code);
      faces.clear();
    }
    d("detectFacesImage => faces=" + faces.size() + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
    return faces;
  }

  public synchronized FaceFeature extractFeatureImage(String base64, FaceInfo faceInfo) {
    ensureInited();
    long t0 = System.currentTimeMillis();
    Object[] img = decodeImage(base64);
    if (img == null) return null;

    byte[] bgr24 = (byte[]) img[0];
    int width = (int) img[1];
    int height = (int) img[2];

    v("extractFeatureImage(w=" + width + ", h=" + height + ")");
    FaceFeature feature = new FaceFeature();
    int code = engine.extractFaceFeature(bgr24, width, height, FaceEngine.CP_PAF_BGR24, faceInfo, feature);
    if (code != ErrorInfo.MOK) {
      w("extractFeatureImage failed => code=" + code);
      return null;
    }
    d("extractFeatureImage => ok, cost=" + (System.currentTimeMillis() - t0) + "ms");
    return feature;
  }

  public synchronized AttrResult processAttributesImage(String base64, List<FaceInfo> faces, int combinedMask) {
    ensureInited();
    long t0 = System.currentTimeMillis();
    Object[] img = decodeImage(base64);
    if (img == null) return new AttrResult(new int[0], new int[0], new int[0], new float[0], new float[0], new float[0]);

    byte[] bgr24 = (byte[]) img[0];
    int width = (int) img[1];
    int height = (int) img[2];

    v("processAttributesImage(mask=" + combinedMask + ", faces=" + (faces == null ? 0 : faces.size()) + ")");

    int code = engine.process(bgr24, width, height, FaceEngine.CP_PAF_BGR24, faces, combinedMask);
    if (code != ErrorInfo.MOK) {
      w("processAttributesImage.process failed => code=" + code);
      return new AttrResult(new int[0], new int[0], new int[0], new float[0], new float[0], new float[0]);
    }
    return getAttrResult(faces);
  }

  // =========================
  // Common
  // =========================

  private AttrResult getAttrResult(List<FaceInfo> faces) {
    // Age
    List<AgeInfo> ageInfos = new ArrayList<>();
    int codeAge = engine.getAge(ageInfos);
    if (codeAge != ErrorInfo.MOK) w("getAge failed => code=" + codeAge);
    int[] ages = new int[ageInfos.size()];
    for (int i = 0; i < ageInfos.size(); i++) {
      ages[i] = ageInfos.get(i).getAge();
    }

    // Gender
    List<GenderInfo> genderInfos = new ArrayList<>();
    int codeGender = engine.getGender(genderInfos);
    if (codeGender != ErrorInfo.MOK) w("getGender failed => code=" + codeGender);
    int[] genders = new int[genderInfos.size()];
    for (int i = 0; i < genderInfos.size(); i++) {
      genders[i] = genderInfos.get(i).getGender();
    }

    // Liveness
    List<LivenessInfo> livenessInfos = new ArrayList<>();
    int codeLive = engine.getLiveness(livenessInfos);
    if (codeLive != ErrorInfo.MOK) w("getLiveness failed => code=" + codeLive);
    int[] liveness = new int[livenessInfos.size()];
    for (int i = 0; i < livenessInfos.size(); i++) {
      liveness[i] = livenessInfos.get(i).getLiveness();
    }

    // 3D angle from FaceInfo
    float[] rolls = new float[faces.size()];
    float[] pitchs = new float[faces.size()];
    float[] yaws = new float[faces.size()];
    for (int i = 0; i < faces.size(); i++) {
      Face3DAngle a = faces.get(i).getFace3DAngle();
      rolls[i] = (a != null) ? a.getRoll() : 0f;
      pitchs[i] = (a != null) ? a.getPitch() : 0f;
      yaws[i] = (a != null) ? a.getYaw() : 0f;
    }

    return new AttrResult(ages, genders, liveness, rolls, pitchs, yaws);
  }

  public synchronized float compare(FaceFeature f1, FaceFeature f2) {
    ensureInited();
    long t0 = System.currentTimeMillis();
    v("compare(featureA, featureB)");
    FaceSimilar similar = new FaceSimilar();
    int code = engine.compareFaceFeature(f1, f2, CompareModel.LIFE_PHOTO, similar);
    if (code != ErrorInfo.MOK) {
      w("compare failed => code=" + code);
      return 0f;
    }
    float score = similar.getScore();
    d("compare => score=" + score + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
    return score;
  }

  public synchronized float compareBase64(String base64A, String base64B) {
    v("compareBase64(lenA=" + (base64A == null ? 0 : base64A.length()) + ", lenB=" + (base64B == null ? 0 : base64B.length()) + ")");
    byte[] a = Base64.decode(base64A, Base64.DEFAULT);
    byte[] b = Base64.decode(base64B, Base64.DEFAULT);
    return compare(new FaceFeature(a), new FaceFeature(b));
  }

  // =========================
  // Face DB (in-engine DB)
  // =========================
  public synchronized boolean faceDBAddOrUpdate(String tag, String featureBase64) {
    ensureInited();
    long t0 = System.currentTimeMillis();
    d("faceDBAddOrUpdate(tag=" + tag + ", featureB64.len=" + (featureBase64 == null ? 0 : featureBase64.length()) + ")");

    byte[] bytes = Base64.decode(featureBase64, Base64.DEFAULT);
    Integer existingId = tagToSearchId.get(tag);
    if (existingId != null) {
      int code = engine.updateFaceFeature(new FaceFeatureInfo(existingId, bytes, tag));
      boolean ok = (code == ErrorInfo.MOK);
      d("faceDB update => ok=" + ok + ", code=" + code + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      return ok;
    }

    int searchId = nextSearchId.getAndIncrement();
    int code = engine.registerFaceFeature(new FaceFeatureInfo(searchId, bytes, tag));
    if (code == ErrorInfo.MOK) {
      tagToSearchId.put(tag, searchId);
      d("faceDB add => ok=true, searchId=" + searchId + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      return true;
    }

    w("faceDB add failed => code=" + code);
    return false;
  }

  public synchronized boolean faceDBRemove(String tag) {
    ensureInited();
    d("faceDBRemove(tag=" + tag + ")");
    Integer id = tagToSearchId.remove(tag);
    if (id == null) return false;
    int code = engine.removeFaceFeature(id);
    boolean ok = (code == ErrorInfo.MOK);
    d("faceDBRemove => ok=" + ok + ", code=" + code);
    return ok;
  }

  public synchronized void faceDBClear() {
    ensureInited();
    d("faceDBClear(count=" + tagToSearchId.size() + ")");
    for (Integer id : tagToSearchId.values()) {
      try { engine.removeFaceFeature(id); } catch (Throwable ignore) {}
    }
    tagToSearchId.clear();
  }

  public synchronized int faceDBCount() {
    ensureInited();
    int c;
    try { c = engine.getFaceCount(); } catch (Throwable t) { c = 0; }
    d("faceDBCount => " + c);
    return c;
  }

  public synchronized SearchResult faceDBSearchTop1(String featureBase64) {
    ensureInited();
    long t0 = System.currentTimeMillis();
    d("faceDBSearchTop1(featureB64.len=" + (featureBase64 == null ? 0 : featureBase64.length()) + ")");
    byte[] bytes = Base64.decode(featureBase64, Base64.DEFAULT);
    FaceFeature f = new FaceFeature(bytes);
    try {
      SearchResult r = engine.searchFaceFeature(f, CompareModel.LIFE_PHOTO);
      d("faceDBSearchTop1 => got=" + (r != null) + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      return r;
    } catch (Throwable t) {
      e("faceDBSearchTop1 exception", t);
      return null;
    }
  }
}
