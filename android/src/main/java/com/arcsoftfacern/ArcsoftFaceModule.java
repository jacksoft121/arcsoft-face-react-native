package com.arcsoftfacern;

import com.arcsoft.face.*;
import com.facebook.react.bridge.*;
import android.util.Base64;
import java.util.*;

public class ArcsoftFaceModule extends ReactContextBaseJavaModule {

  private final ArcsoftEngineManager manager = new ArcsoftEngineManager();
  private final ArcsoftFaceDB db = new ArcsoftFaceDB();

  public ArcsoftFaceModule(ReactApplicationContext ctx) {
    super(ctx);
  }

  @Override
  public String getName() {
    return "ArcsoftFace";
  }

  @ReactMethod
  public void activate(String appId, String sdkKey, Promise p) {
    int code = FaceEngine.activeOnline(getReactApplicationContext(), appId, sdkKey);
    if (code == 0 || code == 90114) p.resolve(true);
    else p.reject("ACTIVATE_FAILED", String.valueOf(code));
  }

  @ReactMethod
  public void init(Promise p) {
    int code = manager.init(getReactApplicationContext());
    if (code == 0) p.resolve(true);
    else p.reject("INIT_FAILED", String.valueOf(code));
  }

  @ReactMethod
  public void release() {
    manager.release();
  }

  @ReactMethod
  public void detect(String base64, int w, int h, ReadableMap opt, Promise p) {
    byte[] nv21 = Base64.decode(base64, Base64.DEFAULT);
    List<FaceInfo> faces = manager.detectFaces(nv21, w, h);

    WritableArray arr = Arguments.createArray();
    for (FaceInfo f : faces) {
      WritableMap m = Arguments.createMap();
      m.putInt("left", f.getRect().left);
      m.putInt("top", f.getRect().top);
      m.putInt("right", f.getRect().right);
      m.putInt("bottom", f.getRect().bottom);
      arr.pushMap(m);
    }
    p.resolve(arr);
  }

  @ReactMethod
  public void extractFeature(String base64, int w, int h, int idx, Promise p) {
    byte[] nv21 = Base64.decode(base64, Base64.DEFAULT);
    List<FaceInfo> faces = manager.detectFaces(nv21, w, h);
    if (faces.isEmpty()) {
      p.resolve(null);
      return;
    }
    FaceFeature f = manager.extract(nv21, w, h, faces.get(idx));
    String out = Base64.encodeToString(f.getFeatureData(), Base64.NO_WRAP);
    WritableMap m = Arguments.createMap();
    m.putString("data", out);
    p.resolve(m);
  }

  @ReactMethod
  public void compareFeature(String f1, String f2, Promise p) {
    FaceFeature a = new FaceFeature();
    FaceFeature b = new FaceFeature();
    a.setFeatureData(Base64.decode(f1, Base64.DEFAULT));
    b.setFeatureData(Base64.decode(f2, Base64.DEFAULT));
    p.resolve(manager.compare(a, b));
  }

  @ReactMethod
  public void registerFace(String name, String f, Promise p) {
    db.put(name, f);
    p.resolve(true);
  }

  @ReactMethod
  public void removeFace(String name, Promise p) {
    db.remove(name);
    p.resolve(true);
  }

  @ReactMethod
  public void searchFace(String f, int topN, Promise p) {
    p.resolve(db.search(f, topN));
  }
}
