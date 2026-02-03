package com.arcsoft.rn;

import android.content.Context;

import com.arcsoft.face.*;
import com.arcsoft.face.enums.*;
import com.arcsoft.face.toolkit.ImageInfo;
import com.arcsoft.imageutil.ArcSoftImageFormat;

import java.util.ArrayList;
import java.util.List;

/**
 * ✅ 对照官方 Demo
 * 作用：集中管理 ArcSoft FaceEngine
 */
public class ArcsoftEngineManager {

  private FaceEngine engine;
  private boolean inited = false;

  /** ===============================
   *  1️⃣ SDK 激活（官方 Demo 第一步）
   * =============================== */
  public int activate(Context ctx, String appId, String sdkKey) {
    engine = new FaceEngine();
    return engine.activeOnline(ctx, appId, sdkKey);
  }

  /** ===============================
   *  2️⃣ 引擎初始化（Detect + Recognize + Liveness）
   * =============================== */
  public int init(Context ctx) {
    if (engine == null) {
      engine = new FaceEngine();
    }

    int code = engine.init(
            ctx,
            DetectMode.ASF_DETECT_MODE_IMAGE,
            DetectFaceOrientPriority.ASF_OP_0_ONLY,
            16,
            10
    );

    inited = (code == ErrorInfo.MOK);
    return code;
  }

  /** ===============================
   *  3️⃣ 人脸检测
   * =============================== */
  public List<FaceInfo> detectFaces(byte[] nv21, int width, int height) {
    List<FaceInfo> faceInfoList = new ArrayList<>();

    engine.detectFaces(
            nv21,
            width,
            height,
            ArcSoftImageFormat.NV21,
            faceInfoList
    );

    return faceInfoList;
  }

  /** ===============================
   *  4️⃣ 特征提取
   * =============================== */
  public FaceFeature extractFeature(
          byte[] nv21,
          int width,
          int height,
          FaceInfo faceInfo
  ) {
    FaceFeature feature = new FaceFeature();

    engine.extractFaceFeature(
            nv21,
            width,
            height,
            ArcSoftImageFormat.NV21,
            faceInfo,
            feature
    );

    return feature;
  }

  /** ===============================
   *  5️⃣ 人脸比对
   * =============================== */
  public float compare(FaceFeature f1, FaceFeature f2) {
    FaceSimilarity similarity = new FaceSimilarity();
    engine.compareFeature(f1, f2, similarity);
    return similarity.getScore();
  }

  /** ===============================
   *  6️⃣ 活体检测（官方标准流程）
   * =============================== */
  public List<LivenessInfo> liveness(
          byte[] nv21,
          int width,
          int height,
          List<FaceInfo> faceInfos
  ) {
    List<LivenessInfo> out = new ArrayList<>();

    engine.process(
            nv21,
            width,
            height,
            ArcSoftImageFormat.NV21,
            faceInfos,
            FaceEngine.ASF_LIVENESS
    );

    engine.getLiveness(out);
    return out;
  }

  public void release() {
    if (engine != null) {
      engine.unInit();
      engine = null;
      inited = false;
    }
  }
}
