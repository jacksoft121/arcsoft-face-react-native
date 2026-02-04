package com.arcsoftfacern;

import android.content.Context;
import android.util.Base64;

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

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * ArcSoft FaceEngine lifecycle + helper methods.
 * - Strictly use FaceEngine.CP_PAF_NV21 (2050)
 * - DetectMode / DetectFaceOrientPriority from com.arcsoft.face.enums (per official SDK)
 */
public class ArcsoftEngineManager {

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
  }

  public synchronized int activateOnline(String appId, String sdkKey) {
    try {
      return FaceEngine.activeOnline(appContext, appId, sdkKey);
    } catch (Throwable t) {
      // keep same error style as SDK (2 = invalid params) as best-effort fallback
      return ErrorInfo.MERR_UNKNOWN;
    }
  }

  public synchronized int initEngine(
      DetectMode detectMode,
      DetectFaceOrientPriority orientPriority,
      int maxFaceNum,
      int combinedMask
  ) {
    if (inited && engine != null) return 0;

    engine = new FaceEngine();
    int code = engine.init(appContext, detectMode, orientPriority, maxFaceNum, combinedMask);
    inited = (code == ErrorInfo.MOK);
    if (!inited) {
      engine = null;
    }
    return code;
  }

  public synchronized int unInitEngine() {
    if (!inited || engine == null) return 0;
    int code = engine.unInit();
    inited = false;
    engine = null;
    tagToSearchId.clear();
    return code;
  }

  private void ensureInited() {
    if (!inited || engine == null) {
      throw new IllegalStateException("FaceEngine not initialized");
    }
  }

  public synchronized List<FaceInfo> detectFacesNV21(byte[] nv21, int width, int height) {
    ensureInited();
    List<FaceInfo> faces = new ArrayList<>();
    int code = engine.detectFaces(nv21, width, height, FaceEngine.CP_PAF_NV21, faces);
    if (code != ErrorInfo.MOK) {
      // still return empty list; caller uses code? Here we keep JS friendly.
      faces.clear();
    }
    return faces;
  }

  public synchronized FaceFeature extractFeatureNV21(byte[] nv21, int width, int height, FaceInfo faceInfo) {
    ensureInited();
    FaceFeature feature = new FaceFeature();
    int code = engine.extractFaceFeature(nv21, width, height, FaceEngine.CP_PAF_NV21, faceInfo, feature);
    if (code != ErrorInfo.MOK) return null;
    return feature;
  }

  public synchronized float compare(FaceFeature f1, FaceFeature f2) {
    ensureInited();
    FaceSimilar similar = new FaceSimilar();
    int code = engine.compareFaceFeature(f1, f2, CompareModel.LIFE_PHOTO, similar);
    if (code != ErrorInfo.MOK) return 0f;
    return similar.getScore();
  }

  public synchronized float compareBase64(String base64A, String base64B) {
    byte[] a = Base64.decode(base64A, Base64.DEFAULT);
    byte[] b = Base64.decode(base64B, Base64.DEFAULT);
    return compare(new FaceFeature(a), new FaceFeature(b));
  }

  /**
   * Run process() then read age/gender/liveness. 3D is from FaceInfo itself (filled by SDK).
   * NOTE: Need initEngine combinedMask includes ASF_AGE / ASF_GENDER / ASF_LIVENESS to get meaningful results.
   */
  public synchronized AttrResult processAttributes(byte[] nv21, int width, int height, List<FaceInfo> faces, int combinedMask) {
    ensureInited();

    int code = engine.process(nv21, width, height, FaceEngine.CP_PAF_NV21, faces, combinedMask);
    if (code != ErrorInfo.MOK) {
      return new AttrResult(new int[0], new int[0], new int[0], new float[0], new float[0], new float[0]);
    }

    // Age
    List<AgeInfo> ageInfos = new ArrayList<>();
    engine.getAge(ageInfos);
    int[] ages = new int[ageInfos.size()];
    for (int i = 0; i < ageInfos.size(); i++) {
      ages[i] = ageInfos.get(i).getAge();
    }

    // Gender
    List<GenderInfo> genderInfos = new ArrayList<>();
    engine.getGender(genderInfos);
    int[] genders = new int[genderInfos.size()];
    for (int i = 0; i < genderInfos.size(); i++) {
      genders[i] = genderInfos.get(i).getGender();
    }

    // Liveness
    List<LivenessInfo> livenessInfos = new ArrayList<>();
    engine.getLiveness(livenessInfos);
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

  // =========================
  // Face DB (in-engine DB)
  // =========================
  public synchronized boolean faceDBAddOrUpdate(String tag, String featureBase64) {
    ensureInited();
    byte[] bytes = Base64.decode(featureBase64, Base64.DEFAULT);
    Integer existingId = tagToSearchId.get(tag);
    if (existingId != null) {
      int code = engine.updateFaceFeature(new FaceFeatureInfo(existingId, bytes, tag));
      return code == ErrorInfo.MOK;
    }
    int searchId = nextSearchId.getAndIncrement();
    int code = engine.registerFaceFeature(new FaceFeatureInfo(searchId, bytes, tag));
    if (code == ErrorInfo.MOK) {
      tagToSearchId.put(tag, searchId);
      return true;
    }
    return false;
  }

  public synchronized boolean faceDBRemove(String tag) {
    ensureInited();
    Integer id = tagToSearchId.remove(tag);
    if (id == null) return false;
    int code = engine.removeFaceFeature(id);
    return code == ErrorInfo.MOK;
  }

  public synchronized void faceDBClear() {
    ensureInited();
    for (Integer id : tagToSearchId.values()) {
      try { engine.removeFaceFeature(id); } catch (Throwable ignore) {}
    }
    tagToSearchId.clear();
  }

  public synchronized int faceDBCount() {
    ensureInited();
    try { return engine.getFaceCount(); } catch (Throwable t) { return 0; }
  }

  public synchronized SearchResult faceDBSearchTop1(String featureBase64) {
    ensureInited();
    byte[] bytes = Base64.decode(featureBase64, Base64.DEFAULT);
    FaceFeature f = new FaceFeature(bytes);
    try {
      return engine.searchFaceFeature(f, CompareModel.LIFE_PHOTO);
    } catch (Throwable t) {
      return null;
    }
  }
}
