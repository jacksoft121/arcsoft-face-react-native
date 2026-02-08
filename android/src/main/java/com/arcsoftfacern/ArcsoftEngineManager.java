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
import com.arcsoftfacern.facedb.FaceDatabase;
import com.arcsoftfacern.facedb.entity.FaceEntity;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * ArcSoft FaceEngine 生命周期管理与核心功能封装
 * 负责与 ArcSoft SDK 进行直接交互，包括引擎初始化、人脸检测、特征提取、属性检测等。
 * 支持 NV21 (预览流) 和 BGR24 (静态图片) 格式。
 */
public class ArcsoftEngineManager {

  // =========================
  // Logging (日志工具)
  // =========================
  private static final String TAG = "ArcsoftFaceRN";

  // 0=OFF, 1=ERROR, 2=WARN, 3=INFO, 4=DEBUG, 5=VERBOSE
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

  // 属性检测结果封装类
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
  private FaceDatabase faceDatabase;

  // 人脸库映射: JS tag(String id) -> engine searchId (int)
  private final Map<String, Integer> tagToSearchId = new ConcurrentHashMap<>();
  private final AtomicInteger nextSearchId = new AtomicInteger(1);

  private ArcsoftEngineManager(Context appContext) {
    this.appContext = appContext;
    this.faceDatabase = FaceDatabase.getInstance(appContext);
    i("EngineManager created");
  }

  public Context getContext() {
      return appContext;
  }

  /**
   * 在线激活 SDK
   * @param appId 应用ID
   * @param sdkKey SDK密钥
   * @return 错误码 (MOK=0 为成功)
   */
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

  /**
   * 获取激活文件信息
   * @return ActiveFileInfo 对象，失败返回 null
   */
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

  /**
   * 初始化引擎
   * @param detectMode 检测模式 (VIDEO/IMAGE)
   * @param orientPriority 人脸角度优先级
   * @param maxFaceNum 最大检测人脸数
   * @param combinedMask 功能组合掩码
   * @return 错误码
   */
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
      // Load faces from DB
      loadFacesFromDB();
    }
    return code;
  }

  private void loadFacesFromDB() {
      if (!inited || engine == null) return;
      List<FaceEntity> faces = faceDatabase.faceDao().getAllFaces();
      tagToSearchId.clear();
      // Reset nextSearchId based on DB? Or just increment.
      // Better to keep searchId consistent if possible, but SDK uses int.
      // We will re-register everything.
      nextSearchId.set(1);

      for (FaceEntity face : faces) {
          int searchId = nextSearchId.getAndIncrement();
          FaceFeatureInfo info = new FaceFeatureInfo(searchId, face.featureData, face.userId);
          int code = engine.registerFaceFeature(info);
          if (code == ErrorInfo.MOK) {
              tagToSearchId.put(face.userId, searchId);
          } else {
              w("Failed to register face from DB: " + face.userId + ", code=" + code);
          }
      }
      i("Loaded " + tagToSearchId.size() + " faces from DB");
  }

  /**
   * 销毁引擎
   * @return 错误码
   */
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
  // NV21 Methods (视频流处理)
  // =========================

  /**
   * NV21 人脸检测
   * @param nv21 图像数据
   * @param width 宽
   * @param height 高
   * @return 检测到的人脸列表
   */
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

  /**
   * NV21 特征提取
   * @param nv21 图像数据
   * @param width 宽
   * @param height 高
   * @param faceInfo 人脸信息
   * @return 提取到的特征，失败返回 null
   */
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

  /**
   * NV21 属性检测（年龄、性别、活体等）
   */
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
  // Image (BGR24) Methods (图片处理)
  // =========================

  // 将 Base64 图片解码并转换为 BGR24 格式
  private Object[] decodeImage(String base64) {
    try {
      byte[] decoded = Base64.decode(base64, Base64.DEFAULT);
      Bitmap bitmap = BitmapFactory.decodeByteArray(decoded, 0, decoded.length);
      if (bitmap == null) return null;

      // Align (对齐)
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

  /**
   * 图片人脸检测
   */
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

  /**
   * 图片特征提取
   */
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

  /**
   * 图片属性检测
   */
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
  // Common (通用方法)
  // =========================

  // 获取属性检测结果
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

  /**
   * 特征比对
   * @param f1 特征1
   * @param f2 特征2
   * @return 相似度 (0.0 - 1.0)
   */
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

  /**
   * Base64 特征比对
   */
  public synchronized float compareBase64(String base64A, String base64B) {
    v("compareBase64(lenA=" + (base64A == null ? 0 : base64A.length()) + ", lenB=" + (base64B == null ? 0 : base64B.length()) + ")");
    byte[] a = Base64.decode(base64A, Base64.DEFAULT);
    byte[] b = Base64.decode(base64B, Base64.DEFAULT);
    return compare(new FaceFeature(a), new FaceFeature(b));
  }

  // =========================
  // Face DB (人脸库管理 - 持久化)
  // =========================

  /**
   * 注册/更新人脸特征
   * @param tag 用户ID (String)
   * @param featureBase64 特征数据 (Base64)
   * @return 是否成功
   */
  public synchronized boolean faceDBAddOrUpdate(String tag, String featureBase64) {
    ensureInited();
    long t0 = System.currentTimeMillis();
    d("faceDBAddOrUpdate(tag=" + tag + ", featureB64.len=" + (featureBase64 == null ? 0 : featureBase64.length()) + ")");

    byte[] bytes = Base64.decode(featureBase64, Base64.DEFAULT);

    // 1. Save to DB
    FaceEntity entity = new FaceEntity(tag, bytes);
    // 更新注册时间
    entity.registerTime = System.currentTimeMillis();
    faceDatabase.faceDao().insertFace(entity);

    // 2. Update Engine
    Integer existingId = tagToSearchId.get(tag);
    if (existingId != null) {
      // Update in engine
      // Note: ArcSoft SDK updateFaceFeature requires FaceFeatureInfo with ID.
      // But if we just re-register, it might fail or duplicate if not handled.
      // Actually, registerFaceFeature returns error if ID exists? No, ID is unique.
      // Let's try update.
      int code = engine.updateFaceFeature(new FaceFeatureInfo(existingId, bytes, tag));
      boolean ok = (code == ErrorInfo.MOK);
      d("faceDB update => ok=" + ok + ", code=" + code + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      return ok;
    }

    // New face in engine
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

  /**
   * 移除人脸特征
   * @param tag 用户ID
   * @return 是否成功
   */
  public synchronized boolean faceDBRemove(String tag) {
    ensureInited();
    d("faceDBRemove(tag=" + tag + ")");

    // 1. Remove from DB
    faceDatabase.faceDao().deleteFaceByUserId(tag);

    // 2. Remove from Engine
    Integer id = tagToSearchId.remove(tag);
    if (id == null) return false;
    int code = engine.removeFaceFeature(id);
    boolean ok = (code == ErrorInfo.MOK);
    d("faceDBRemove => ok=" + ok + ", code=" + code);
    return ok;
  }

  /**
   * 清空人脸库
   */
  public synchronized void faceDBClear() {
    ensureInited();
    d("faceDBClear(count=" + tagToSearchId.size() + ")");

    // 1. Clear DB
    faceDatabase.faceDao().deleteAll();

    // 2. Clear Engine
    for (Integer id : tagToSearchId.values()) {
      try { engine.removeFaceFeature(id); } catch (Throwable ignore) {}
    }
    tagToSearchId.clear();
  }

  /**
   * 获取人脸库数量
   */
  public synchronized int faceDBCount() {
//    ensureInited();
    // Return count from DB to be accurate
    int c = faceDatabase.faceDao().getCount();
    d("faceDBCount => " + c);
    return c;
  }

  /**
   * 获取所有人脸列表
   * @param userId 可选的用户ID，如果提供则只返回该用户的数据
   * @return 包含 { "id": userId } 的列表
   */
  public synchronized List<Map<String, String>> faceDBGetAllFaces(String userId) {
      List<FaceEntity> faces;
      if (userId != null && !userId.isEmpty()) {
          faces = faceDatabase.faceDao().getFacesByUserId(userId);
      } else {
          faces = faceDatabase.faceDao().getAllFaces();
      }

      List<Map<String, String>> result = new ArrayList<>();
      for (FaceEntity face : faces) {
          Map<String, String> map = new java.util.HashMap<>();
          map.put("id", String.valueOf(face.id)); // DB ID
          map.put("userId", face.userId); // User ID
          map.put("registerTime", String.valueOf(face.registerTime));
          result.add(map);
      }
      return result;
  }

  /**
   * 搜索人脸 (1:N)
   * @param featureBase64 待搜索特征 (Base64)
   * @return 搜索结果 (SearchResult)，未找到返回 null
   */
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
