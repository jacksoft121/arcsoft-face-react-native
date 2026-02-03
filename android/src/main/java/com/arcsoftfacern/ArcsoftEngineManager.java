package com.arcsoftfacern;

import android.content.Context;

import com.arcsoft.face.enums.DetectFaceOrientPriority;
import com.arcsoft.face.enums.DetectMode;
import com.arcsoft.face.FaceEngine;
import com.arcsoft.face.FaceFeature;
import com.arcsoft.face.FaceInfo;
import com.arcsoft.face.FaceSimilar;

import java.util.ArrayList;
import java.util.List;

/**
 * ArcSoft FaceEngine 管理器
 * 严格匹配你当前使用的 ArcSoft Android SDK
 */
public class ArcsoftEngineManager {

  private FaceEngine engine;
  private boolean inited = false;

  public int init(Context context) {
    if (engine != null) {
      return 0;
    }

    engine = new FaceEngine();

    // ⚠️ 注意：你这套 SDK 只有 5 参数 init
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

  public List<FaceInfo> detectFaces(byte[] nv21, int width, int height) {
    List<FaceInfo> faceInfos = new ArrayList<>();

    if (!inited) return faceInfos;

    engine.detectFaces(
            nv21,
            width,
            height,
            FaceEngine.CP_PAF_NV21, // ✅ 必须是 int
            faceInfos
    );
    return faceInfos;
  }

  public FaceFeature extractFeature(
          byte[] nv21,
          int width,
          int height,
          FaceInfo faceInfo
  ) {
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
}
