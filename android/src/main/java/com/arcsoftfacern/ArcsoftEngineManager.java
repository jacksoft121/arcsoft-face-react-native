package com.arcsoftfacern;

import android.content.Context;
import com.arcsoft.face.*;
import com.arcsoft.face.enums.*;
import java.util.*;

public class ArcsoftEngineManager {

  private FaceEngine engine;
  private boolean inited = false;

  public int init(Context context) {
    if (engine != null) return 0;

    engine = new FaceEngine();
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

  public List<FaceInfo> detectFaces(byte[] nv21, int w, int h) {
    List<FaceInfo> list = new ArrayList<>();
    if (!inited) return list;
    engine.detectFaces(nv21, w, h, FaceEngine.CP_PAF_NV21, list);
    return list;
  }

  public FaceFeature extract(byte[] nv21, int w, int h, FaceInfo face) {
    if (!inited) return null;
    FaceFeature f = new FaceFeature();
    int code = engine.extractFaceFeature(
            nv21, w, h, FaceEngine.CP_PAF_NV21, face, f
    );
    return code == 0 ? f : null;
  }

  public float compare(FaceFeature f1, FaceFeature f2) {
    FaceSimilar s = new FaceSimilar();
    engine.compareFaceFeature(f1, f2, s);
    return s.getScore();
  }

  public FaceEngine engine() {
    return engine;
  }
}
