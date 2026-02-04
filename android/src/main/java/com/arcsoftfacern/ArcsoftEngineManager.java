package com.arcsoftfacern;

import android.content.Context;
import android.util.Base64;

import com.arcsoft.face.ActiveFileInfo;
import com.arcsoft.face.AgeInfo;
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
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * ArcSoft FaceEngine 管理器（Android）
 * - 严格对齐你当前 jar 中的 FaceEngine API（5 参数 init）
 * - 不依赖 com.arcsoft.face.toolkit.*（你这套 SDK 里没有）
 * - 不使用 ImageFormat 枚举（用 FaceEngine.CP_PAF_NV21 常量 int）
 */
public class ArcsoftEngineManager {

  private FaceEngine engine;
  private boolean inited = false;

  // 仅用于“清库”时知道我们注册过哪些 searchId
  private final Set<Integer> registeredIds = new HashSet<>();
  private final AtomicInteger idSeq = new AtomicInteger(1);

  public static int activeOnline(Context context, String appId, String sdkKey) {
    return FaceEngine.activeOnline(context, appId, sdkKey);
  }

  public static ActiveFileInfo getActiveFileInfo(Context context) {
    ActiveFileInfo info = new ActiveFileInfo();
    int code = FaceEngine.getActiveFileInfo(context, info);
    return code == 0 ? info : null;
  }

  public int init(Context context, int combinedMask, int maxFaceNum) {
    if (engine != null && inited) return 0;

    engine = new FaceEngine();

    int code = engine.init(
            context,
            DetectMode.ASF_DETECT_MODE_IMAGE,
            DetectFaceOrientPriority.ASF_OP_0_ONLY,
            maxFaceNum,
            combinedMask
    );

    inited = (code == 0);
    if (!inited) {
      try { engine.unInit(); } catch (Throwable ignore) {}
      engine = null;
    }
    return code;
  }

  public boolean isInited() {
    return inited && engine != null;
  }

  public void release() {
    if (engine != null) {
      try { engine.unInit(); } catch (Throwable ignore) {}
      engine = null;
    }
    inited = false;
    registeredIds.clear();
  }

  public List<FaceInfo> detectFaces(byte[] nv21, int width, int height) {
    List<FaceInfo> faces = new ArrayList<>();
    if (!isInited()) return faces;

    engine.detectFaces(
            nv21,
            width,
            height,
            FaceEngine.CP_PAF_NV21,
            faces
    );
    return faces;
  }

  public FaceFeature extractFeature(byte[] nv21, int width, int height, FaceInfo faceInfo) {
    if (!isInited() || faceInfo == null) return null;

    FaceFeature feature = new FaceFeature();
    int code = engine.extractFaceFeature(
            nv21,
            width,
            height,
            FaceEngine.CP_PAF_NV21,
            faceInfo,
            feature
    );

    return code == 0 ? feature : null;
  }

  public float compare(FaceFeature f1, FaceFeature f2) {
    if (!isInited() || f1 == null || f2 == null) return 0f;

    FaceSimilar similar = new FaceSimilar();
    int code = engine.compareFaceFeature(f1, f2, CompareModel.LIFE_PHOTO, similar);
    return code == 0 ? similar.getScore() : 0f;
  }

  // ===== Base64 helpers (TS/JS 方便传输特征) =====
  public static String featureToBase64(FaceFeature feature) {
    if (feature == null || feature.getFeatureData() == null) return "";
    return Base64.encodeToString(feature.getFeatureData(), Base64.NO_WRAP);
  }

  public static FaceFeature featureFromBase64(String base64) {
    if (base64 == null || base64.length() == 0) return null;
    byte[] data = Base64.decode(base64, Base64.DEFAULT);
    return new FaceFeature(data);
  }

  public float compareBase64(String featureA, String featureB) {
    FaceFeature f1 = featureFromBase64(featureA);
    FaceFeature f2 = featureFromBase64(featureB);
    return compare(f1, f2);
  }

  // ===== Age/Gender/Liveness =====
  public static class AttrResult {
    public int[] ages;
    public int[] genders;
    public int[] liveness;
  }

  public AttrResult processAttributes(byte[] nv21, int width, int height, List<FaceInfo> faces) {
    if (!isInited()) return null;
    if (faces == null || faces.isEmpty()) return null;

    // 先 process，再取 age/gender/liveness
    int mask = FaceEngine.ASF_AGE | FaceEngine.ASF_GENDER | FaceEngine.ASF_LIVENESS;
    int code = engine.process(nv21, width, height, FaceEngine.CP_PAF_NV21, faces, mask);
    if (code != 0) return null;

    List<AgeInfo> ageInfos = new ArrayList<>();
    List<GenderInfo> genderInfos = new ArrayList<>();
    List<LivenessInfo> liveInfos = new ArrayList<>();

    engine.getAge(ageInfos);
    engine.getGender(genderInfos);
    engine.getLiveness(liveInfos);

    int n = Math.max(Math.max(ageInfos.size(), genderInfos.size()), liveInfos.size());
    AttrResult res = new AttrResult();
    res.ages = new int[n];
    res.genders = new int[n];
    res.liveness = new int[n];

    for (int i = 0; i < n; i++) {
      res.ages[i] = i < ageInfos.size() ? ageInfos.get(i).getAge() : -1;
      res.genders[i] = i < genderInfos.size() ? genderInfos.get(i).getGender() : -1;
      res.liveness[i] = i < liveInfos.size() ? liveInfos.get(i).getLiveness() : -1;
    }
    return res;
  }

  // ===== Face DB（register / search / remove / count）=====
  public int registerFace(String faceTag, String featureBase64) {
    if (!isInited()) return -1;

    FaceFeature feature = featureFromBase64(featureBase64);
    if (feature == null || feature.getFeatureData() == null) return -1;

    int searchId = idSeq.getAndIncrement();
    FaceFeatureInfo info = new FaceFeatureInfo(searchId, feature.getFeatureData(), faceTag);

    int code = engine.registerFaceFeature(info);
    if (code == 0) {
      registeredIds.add(searchId);
      return searchId;
    }
    return -1;
  }

  public List<SearchResult> searchFace(String featureBase64, int topN) {
    List<SearchResult> out = new ArrayList<>();
    if (!isInited()) return out;

    FaceFeature feature = featureFromBase64(featureBase64);
    if (feature == null) return out;

    try {
      return engine.searchFaceFeatureTopN(feature, CompareModel.LIFE_PHOTO, Math.max(1, topN));
    } catch (Throwable ignore) {
      return out;
    }
  }

  public int removeFace(int searchId) {
    if (!isInited()) return 5;
    int code = engine.removeFaceFeature(searchId);
    if (code == 0) registeredIds.remove(searchId);
    return code;
  }

  public int getFaceCount() {
    if (!isInited()) return 0;
    try {
      return engine.getFaceCount();
    } catch (Throwable ignore) {
      return 0;
    }
  }

  public int clearRegisteredFaces() {
    if (!isInited()) return 5;
    int ok = 0;
    // 只清我们注册过的 searchId
    for (Integer id : new ArrayList<>(registeredIds)) {
      int code = engine.removeFaceFeature(id);
      if (code == 0) { ok++; registeredIds.remove(id); }
    }
    return ok;
  }
}
