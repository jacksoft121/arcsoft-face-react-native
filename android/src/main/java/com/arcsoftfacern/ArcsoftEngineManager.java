package com.arcsoftfacern;

import android.content.Context;

import com.arcsoft.face.FaceEngine;
import com.arcsoft.face.FaceFeature;
import com.arcsoft.face.FaceInfo;
import com.arcsoft.face.FaceSimilar;
import com.arcsoft.face.FaceFeatureInfo;
import com.arcsoft.face.SearchResult;
import com.arcsoft.face.AgeInfo;
import com.arcsoft.face.GenderInfo;
import com.arcsoft.face.LivenessInfo;
import com.arcsoft.face.enums.DetectFaceOrientPriority;
import com.arcsoft.face.enums.DetectMode;

import java.util.ArrayList;
import java.util.List;

/**
 * ArcSoft FaceEngine 管理器（Android）
 *
 * ✅ 以你提供的“可编译版本”为基线，补齐：SDK 激活/注册、年龄/性别/活体、人脸库注册/检索等能力。
 * ✅ 严格匹配你当前 SDK：FaceEngine.init 只有 5 参数，ImageFormat 需要用 FaceEngine.CP_PAF_NV21（int）。
 */
public class ArcsoftEngineManager {

  private FaceEngine engine;
  private boolean inited = false;
  private boolean activated = false;

  /**
   * SDK 在线激活（官方 SDK：FaceEngine.activeOnline）
   */
  public int activateOnline(Context context, String appId, String sdkKey) {
    int code = FaceEngine.activeOnline(context, appId, sdkKey);
    activated = (code == 0);
    return code;
  }

  /**
   * 初始化引擎（IMAGE 模式）
   */
  public int init(Context context) {
    if (engine != null) {
      return 0;
    }
    engine = new FaceEngine();

    // ⚠️ 你这套 SDK 只有 5 参数 init
    int code = engine.init(
        context,
        DetectMode.ASF_DETECT_MODE_IMAGE,
        DetectFaceOrientPriority.ASF_OP_0_ONLY,
        16,
        10
    );

    inited = (code == 0);
    return code;
  }

  public void release() {
    if (engine != null) {
      engine.unInit();
      engine = null;
      inited = false;
    }
  }

  public boolean isInited() { return inited; }

  public List<FaceInfo> detectFaces(byte[] nv21, int width, int height) {
    List<FaceInfo> faceInfos = new ArrayList<>();
    if (!inited) return faceInfos;

    engine.detectFaces(
        nv21,
        width,
        height,
        FaceEngine.CP_PAF_NV21,
        faceInfos
    );
    return faceInfos;
  }

  public int process(byte[] nv21, int width, int height, List<FaceInfo> faces, int combinedMask) {
    if (!inited) return -1;
    return engine.process(nv21, width, height, FaceEngine.CP_PAF_NV21, faces, combinedMask);
  }

  public FaceFeature extractFeature(byte[] nv21, int width, int height, FaceInfo faceInfo) {
    if (!inited) return null;

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
    if (!inited || f1 == null || f2 == null) return 0f;

    FaceSimilar similar = new FaceSimilar();
    engine.compareFaceFeature(f1, f2, similar);
    return similar.getScore();
  }

  // =====================
  // 属性能力（年龄/性别/活体）
  // =====================

  public List<AgeInfo> getAgeInfo() {
    List<AgeInfo> list = new ArrayList<>();
    if (!inited) return list;
    engine.getAge(list);
    return list;
  }

  public List<GenderInfo> getGenderInfo() {
    List<GenderInfo> list = new ArrayList<>();
    if (!inited) return list;
    engine.getGender(list);
    return list;
  }

  public List<LivenessInfo> getLivenessInfo() {
    List<LivenessInfo> list = new ArrayList<>();
    if (!inited) return list;
    engine.getLiveness(list);
    return list;
  }

  // =====================
  // 人脸库（SDK 内置：register/search）
  // =====================

  public int registerFeature(int searchId, FaceFeature feature, String faceTag) {
    if (!inited || feature == null) return -1;
    FaceFeatureInfo info = new FaceFeatureInfo(searchId, feature.getFeatureData(), faceTag);
    return engine.registerFaceFeature(info);
  }

  public SearchResult searchFaceFeature(FaceFeature feature) {
    if (!inited || feature == null) return null;
    return engine.searchFaceFeature(feature);
  }

  public int clearFaceDatabase() {
    if (!inited) return -1;
    return engine.clearFaceDatabase();
  }
}
