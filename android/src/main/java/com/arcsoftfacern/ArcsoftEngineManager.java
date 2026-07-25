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
import java.util.concurrent.atomic.AtomicLong;

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
  /**
   * VIDEO 引擎负责连续帧/静态图检测与属性；识别引擎只负责特征提取和 1:N 搜索。
   * ArcSoft 明确禁止同一引擎句柄并发调用同一算法，拆分后相机跟踪不会再被
   * 特征提取和全库搜索阻塞。
   */
  private FaceEngine trackingEngine;
  private FaceEngine recognitionEngine;
  private boolean inited = false;
  private FaceDatabase faceDatabase;
  private final Object lifecycleLock = new Object();
  private final Object trackingLock = new Object();
  private final Object faceStateLock = new Object();

  // 人脸库映射: JS tag(String id) -> engine searchId (int)
  private final Map<String, Integer> tagToSearchId = new ConcurrentHashMap<>();
  private final AtomicInteger nextSearchId = new AtomicInteger(1);

  // 优化策略缓存
  private final Map<Integer, String> processedFaceIds = new ConcurrentHashMap<>(); // faceId -> userId (if recognized)
  private final Map<Integer, Integer> faceRetryCounts = new ConcurrentHashMap<>(); // faceId -> retry count
  private final Map<Integer, Double> faceScores = new ConcurrentHashMap<>(); // faceId -> score
  private final Map<Integer, String> faceFeatures = new ConcurrentHashMap<>(); // faceId -> featureBase64
  private final Map<Integer, Long> faceLastSeenAt = new ConcurrentHashMap<>();
  private final Map<Integer, Long> faceLastAttemptAt = new ConcurrentHashMap<>();
  private final Map<Integer, Long> faceRecognitionGenerations = new ConcurrentHashMap<>();
  private final AtomicLong faceStateGeneration = new AtomicLong(1);
  private static final int DEFAULT_MAX_RETRY_COUNT = 5;
  private static final long FACE_STATE_STALE_MS = 1500L;
  // 官方 Demo 在特征失败后允许后续预览帧立即重试。保留一个很短的间隔，
  // 既接近 Demo 的响应速度，也避免低质量人脸在 30 FPS 下连续占满识别线程。
  private static final long FACE_RETRY_INTERVAL_MS = 120L;
  // Demo 的 extractRetryCount 只限制单轮失败，之后会重新进入 TO_RETRY。
  // 每轮之间留 500ms 冷却，保证远处人脸靠近后能恢复，又不持续跑满 1:N。
  private static final long FACE_RETRY_BURST_COOLDOWN_MS = 500L;

  /** 原生异步识别结果，避免 FrameProcessor 在 Kotlin 层来回编解码 Base64。 */
  public static final class RecognitionResult {
    public final String userId;
    public final double score;
    public final String featureBase64;

    public RecognitionResult(String userId, double score, String featureBase64) {
      this.userId = userId;
      this.score = score;
      this.featureBase64 = featureBase64;
    }
  }

  private ArcsoftEngineManager(Context appContext) {
    this.appContext = appContext;
    this.faceDatabase = FaceDatabase.getInstance(appContext);
    i("EngineManager created");
  }

  public Context getContext() {
      return appContext;
  }

  /**
   * 清空所有缓存
   */
  public void clearCache() {
    synchronized (faceStateLock) {
      faceStateGeneration.incrementAndGet();
      processedFaceIds.clear();
      faceRetryCounts.clear();
      faceScores.clear();
      faceFeatures.clear();
      faceLastSeenAt.clear();
      faceLastAttemptAt.clear();
      faceRecognitionGenerations.clear();
    }
      d("Cache cleared");
  }

  /**
   * 判断是否需要处理该人脸
   */
  public boolean shouldProcessFace(int faceId, int maxRetryCount) {
      synchronized (faceStateLock) {
        if (processedFaceIds.containsKey(faceId)) {
            return false; // 已识别，无需处理
        }
        int retryCount = faceRetryCounts.containsKey(faceId) ? faceRetryCounts.get(faceId) : 0;
        return retryCount < maxRetryCount;
      }
  }

  /**
   * 获取缓存的人脸信息
   */
  public Map<String, Object> getCachedFaceInfo(int faceId) {
    synchronized (faceStateLock) {
      Map<String, Object> info = new java.util.HashMap<>();
      String userId = processedFaceIds.get(faceId);
      if (userId != null) {
          info.put("userId", userId);
          Double score = faceScores.get(faceId);
          info.put("score", score != null ? score : 1.0);
      }
      String feature = faceFeatures.get(faceId);
      if (feature != null) {
          info.put("featureBase64", feature);
      }
      return info;
    }
  }

  /**
   * 更新缓存
   */
  public void updateFaceCache(int faceId, String userId, double score, String featureBase64) {
    synchronized (faceStateLock) {
      if (userId != null) {
          processedFaceIds.put(faceId, userId);
          faceScores.put(faceId, score);
          faceRetryCounts.remove(faceId);
      }
      if (featureBase64 != null) {
          faceFeatures.put(faceId, featureBase64);
      }
    }
  }

  /**
   * 增加重试计数
   */
  public void updateRetryCount(int faceId) {
      synchronized (faceStateLock) {
        int count = faceRetryCounts.containsKey(faceId) ? faceRetryCounts.get(faceId) : 0;
        faceRetryCounts.put(faceId, count + 1);
      }
  }

  /**
   * 标记当前帧 traceID 并延迟清理离开画面的人脸状态。
   *
   * 单帧空检测不能立即删除已命中的姓名，否则 ArcSoft 仍在追踪同一人时会在
   * 绿框和红框之间闪烁；超过窗口后再次出现的同值 faceId 才按新目标处理。
   */
  public void cleanUpFaceStates(List<FaceInfo> currentFaces) {
      long now = System.currentTimeMillis();
      synchronized (faceStateLock) {
        for (FaceInfo face : currentFaces) {
          int faceId = face.getFaceId();
          Long previousSeenAt = faceLastSeenAt.get(faceId);
          if (previousSeenAt != null && now - previousSeenAt > FACE_STATE_STALE_MS) {
            clearFaceStateLocked(faceId);
          }
          faceLastSeenAt.put(faceId, now);
        }

        List<Integer> staleIds = new ArrayList<>();
        for (Map.Entry<Integer, Long> entry : faceLastSeenAt.entrySet()) {
          if (now - entry.getValue() > FACE_STATE_STALE_MS) {
            staleIds.add(entry.getKey());
          }
        }
        for (Integer faceId : staleIds) {
          clearFaceStateLocked(faceId);
        }
      }
  }

  /**
   * 原子申请一次后台识别。返回负数表示已命中、正在处理或仍在重试冷却期。
   * 返回值是缓存代次，异步任务完成时用它阻止旧任务污染新页面/新人脸状态。
   */
  public long tryBeginFaceRecognition(int faceId, int maxRetryCount) {
    long now = System.currentTimeMillis();
    synchronized (faceStateLock) {
      if (processedFaceIds.containsKey(faceId)) return -1L;
      int retryCount = faceRetryCounts.getOrDefault(faceId, 0);
      if (faceRecognitionGenerations.containsKey(faceId)) return -1L;
      long lastAttemptAt = faceLastAttemptAt.getOrDefault(faceId, 0L);
      if (retryCount >= Math.max(1, maxRetryCount)) {
        if (now - lastAttemptAt < FACE_RETRY_BURST_COOLDOWN_MS) return -1L;
        // 对齐 Demo：一轮提取/搜索失败不是永久失败，清零后允许下一轮。
        faceRetryCounts.put(faceId, 0);
      }
      if (now - lastAttemptAt < FACE_RETRY_INTERVAL_MS) return -1L;

      long generation = faceStateGeneration.get();
      faceLastAttemptAt.put(faceId, now);
      faceRecognitionGenerations.put(faceId, generation);
      return generation;
    }
  }

  /** 完成后台识别并仅在 traceID/缓存代次仍有效时发布姓名。 */
  public void completeFaceRecognition(
      int faceId,
      long generation,
      RecognitionResult result
  ) {
    synchronized (faceStateLock) {
      Long activeGeneration = faceRecognitionGenerations.remove(faceId);
      if (
          activeGeneration == null ||
          activeGeneration != generation ||
          generation != faceStateGeneration.get()
      ) {
        return;
      }
      Long lastSeenAt = faceLastSeenAt.get(faceId);
      if (
          lastSeenAt == null ||
          System.currentTimeMillis() - lastSeenAt > FACE_STATE_STALE_MS
      ) {
        clearFaceStateLocked(faceId);
        return;
      }
      if (result != null && result.userId != null) {
        processedFaceIds.put(faceId, result.userId);
        faceScores.put(faceId, result.score);
        faceRetryCounts.remove(faceId);
        if (result.featureBase64 != null) {
          faceFeatures.put(faceId, result.featureBase64);
        }
        return;
      }
      faceRetryCounts.put(faceId, faceRetryCounts.getOrDefault(faceId, 0) + 1);
    }
  }

  /** 有界后台队列拒绝任务时撤销占位，允许后续有效帧重试。 */
  public void cancelFaceRecognition(int faceId, long generation) {
    synchronized (faceStateLock) {
      Long activeGeneration = faceRecognitionGenerations.get(faceId);
      if (activeGeneration != null && activeGeneration == generation) {
        faceRecognitionGenerations.remove(faceId);
      }
    }
  }

  private void clearFaceStateLocked(int faceId) {
    processedFaceIds.remove(faceId);
    faceRetryCounts.remove(faceId);
    faceScores.remove(faceId);
    faceFeatures.remove(faceId);
    faceLastSeenAt.remove(faceId);
    faceLastAttemptAt.remove(faceId);
    faceRecognitionGenerations.remove(faceId);
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
  public int initEngine(
          DetectMode detectMode,
          DetectFaceOrientPriority orientPriority,
          int maxFaceNum,
          int combinedMask
  ) {
    synchronized (lifecycleLock) {
      long t0 = System.currentTimeMillis();
      d("initEngine(mode=" + detectMode + ", orient=" + orientPriority + ", maxFaceNum=" + maxFaceNum + ", mask=" + combinedMask + ")");
      if (inited && trackingEngine != null && recognitionEngine != null) {
        i("initEngine => already inited, return 0");
        return 0;
      }

      // VIDEO 引擎只保留跟踪及明确启用的属性；特征能力移到独立 IMAGE 引擎。
      int trackingMask = (combinedMask | FaceEngine.ASF_FACE_DETECT)
          & ~FaceEngine.ASF_FACE_RECOGNITION;
      // 官方门禁方案的附加引擎只初始化识别能力，避免为第二个句柄重复加载
      // 检测/属性模型；静态图检测和属性仍由 trackingEngine 串行执行。
      int recognitionMask = FaceEngine.ASF_FACE_RECOGNITION;

      trackingEngine = new FaceEngine();
      int trackingCode = trackingEngine.init(
          appContext,
          DetectMode.ASF_DETECT_MODE_VIDEO,
          orientPriority,
          maxFaceNum,
          trackingMask
      );
      if (trackingCode != ErrorInfo.MOK) {
        w("trackingEngine init failed => code=" + trackingCode);
        trackingEngine = null;
        return trackingCode;
      }

      recognitionEngine = new FaceEngine();
      int recognitionCode = recognitionEngine.init(
          appContext,
          DetectMode.ASF_DETECT_MODE_IMAGE,
          orientPriority,
          maxFaceNum,
          recognitionMask
      );
      if (recognitionCode != ErrorInfo.MOK) {
        w("recognitionEngine init failed => code=" + recognitionCode);
        trackingEngine.unInit();
        trackingEngine = null;
        recognitionEngine = null;
        return recognitionCode;
      }

      inited = true;
      i("split engines initialized => cost=" + (System.currentTimeMillis() - t0) + "ms");
      // 人脸库只注册到识别引擎，跟踪引擎不持有无用的 1:N 索引。
      loadFacesFromDB();
      return ErrorInfo.MOK;
    }
  }

  private void loadFacesFromDB() {
    synchronized (this) {
      if (!inited || recognitionEngine == null) return;
      List<FaceEntity> faces = faceDatabase.faceDao().getAllFaces();
      tagToSearchId.clear();
      // Reset nextSearchId based on DB? Or just increment.
      // Better to keep searchId consistent if possible, but SDK uses int.
      // We will re-register everything.
      nextSearchId.set(1);

      for (FaceEntity face : faces) {
          int searchId = nextSearchId.getAndIncrement();
          FaceFeatureInfo info = new FaceFeatureInfo(searchId, face.featureData, face.userId);
          int code = recognitionEngine.registerFaceFeature(info);
          if (code == ErrorInfo.MOK) {
              tagToSearchId.put(face.userId, searchId);
          } else {
              w("Failed to register face from DB: " + face.userId + ", code=" + code);
          }
      }
      i("Loaded " + tagToSearchId.size() + " faces from DB");
    }
  }

  /**
   * 销毁引擎
   * @return 错误码
   */
  public int unInitEngine() {
    synchronized (lifecycleLock) {
      long t0 = System.currentTimeMillis();
      d("unInitEngine()");
      if (!inited || trackingEngine == null || recognitionEngine == null) {
        i("unInitEngine => not inited, return 0");
        return 0;
      }

      // 固定先锁跟踪、再锁识别，避免释放时与后台识别交叉销毁句柄。
      synchronized (trackingLock) {
        synchronized (this) {
          int trackingCode = trackingEngine.unInit();
          int recognitionCode = recognitionEngine.unInit();
          inited = false;
          trackingEngine = null;
          recognitionEngine = null;
          tagToSearchId.clear();
          clearCache();
          int code = trackingCode != ErrorInfo.MOK ? trackingCode : recognitionCode;
          i("unInitEngine => code=" + code + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
          return code;
        }
      }
    }
  }

  private void ensureInited() {
    if (!inited || trackingEngine == null || recognitionEngine == null) {
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
  public List<FaceInfo> detectFacesNV21(byte[] nv21, int width, int height) {
    synchronized (trackingLock) {
      ensureInited();
      long t0 = System.currentTimeMillis();
      v("detectFacesNV21(w=" + width + ", h=" + height + ", len=" + (nv21 == null ? 0 : nv21.length) + ")");
      List<FaceInfo> faces = new ArrayList<>();
      int code = trackingEngine.detectFaces(nv21, width, height, FaceEngine.CP_PAF_NV21, faces);
      if (code != ErrorInfo.MOK) {
        // ArcSoft 在画面无人或人脸置信度不足时会返回这两个业务状态，
        // 它们等价于空结果，不应按异常逐帧写日志拖慢相机线程。
        if (
            code != ErrorInfo.MERR_FSDK_FACEFEATURE_MISSFACE &&
            code != ErrorInfo.MERR_FSDK_FACEFEATURE_NO_FACE
        ) {
          w("detectFacesNV21 failed => code=" + code);
        }
        faces.clear();
      }
      d("detectFacesNV21 => faces=" + faces.size() + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      return faces;
    }
  }

  /**
   * NV21 特征提取
   * @param nv21 图像数据
   * @param width 宽
   * @param height 高
   * @param faceInfo 人脸信息
   * @return 提取到的特征，失败返回 null
   */
  public FaceFeature extractFeatureNV21(byte[] nv21, int width, int height, FaceInfo faceInfo) {
    synchronized (this) {
      ensureInited();
      long t0 = System.currentTimeMillis();
      v("extractFeatureNV21(w=" + width + ", h=" + height + ")");
      FaceFeature feature = new FaceFeature();
      int code = recognitionEngine.extractFaceFeature(
          nv21,
          width,
          height,
          FaceEngine.CP_PAF_NV21,
          faceInfo,
          feature
      );
      if (code != ErrorInfo.MOK) {
        w("extractFeatureNV21 failed => code=" + code);
        return null;
      }
      d("extractFeatureNV21 => ok, cost=" + (System.currentTimeMillis() - t0) + "ms");
      return feature;
    }
  }

  /**
   * 在独立 IMAGE+识别引擎上完成一次“提特征 + SDK 内建 1:N Top1”。
   *
   * 调用方应放在有界后台队列；整个方法持有识别引擎锁，保证注册/删除人脸库
   * 不会与搜索并发。除非 JS 明确需要，否则不生成 Base64 中间字符串。
   */
  public synchronized RecognitionResult recognizeFaceNV21(
      byte[] nv21,
      int width,
      int height,
      FaceInfo faceInfo,
      double scoreThreshold,
      boolean returnFeatureBase64
  ) {
    ensureInited();
    long t0 = System.currentTimeMillis();
    FaceFeature feature = new FaceFeature();
    int extractCode = recognitionEngine.extractFaceFeature(
        nv21,
        width,
        height,
        FaceEngine.CP_PAF_NV21,
        faceInfo,
        feature
    );
    byte[] featureData = feature.getFeatureData();
    if (extractCode != ErrorInfo.MOK || featureData == null) {
      w("recognizeFaceNV21 extract failed => code=" + extractCode);
      return null;
    }

    String featureBase64 = returnFeatureBase64
        ? Base64.encodeToString(featureData, Base64.NO_WRAP)
        : null;
    try {
      SearchResult result = recognitionEngine.searchFaceFeature(
          feature,
          CompareModel.LIFE_PHOTO
      );
      if (
          result != null &&
          result.getFaceFeatureInfo() != null &&
          result.getFaceFeatureInfo().getFaceTag() != null &&
          result.getMaxSimilar() >= scoreThreshold
      ) {
        d("recognizeFaceNV21 => matched, cost=" + (System.currentTimeMillis() - t0) + "ms");
        return new RecognitionResult(
            result.getFaceFeatureInfo().getFaceTag(),
            result.getMaxSimilar(),
            featureBase64
        );
      }
      d("recognizeFaceNV21 => unmatched, cost=" + (System.currentTimeMillis() - t0) + "ms");
      return new RecognitionResult(null, 0.0, featureBase64);
    } catch (Throwable t) {
      e("recognizeFaceNV21 search exception", t);
      return null;
    }
  }

  /**
   * NV21 属性检测（年龄、性别、活体等）
   */
  public AttrResult processAttributes(byte[] nv21, int width, int height, List<FaceInfo> faces, int combinedMask) {
    synchronized (trackingLock) {
      ensureInited();
      long t0 = System.currentTimeMillis();
      v("processAttributes(mask=" + combinedMask + ", faces=" + (faces == null ? 0 : faces.size()) + ")");

      int code = trackingEngine.process(nv21, width, height, FaceEngine.CP_PAF_NV21, faces, combinedMask);
      if (code != ErrorInfo.MOK) {
        w("processAttributes.process failed => code=" + code);
        return new AttrResult(new int[0], new int[0], new int[0], new float[0], new float[0], new float[0]);
      }
      return getAttrResult(faces, trackingEngine);
    }
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
  public List<FaceInfo> detectFacesImage(String base64) {
    synchronized (trackingLock) {
      ensureInited();
      long t0 = System.currentTimeMillis();
      Object[] img = decodeImage(base64);
      if (img == null) return new ArrayList<>();

      byte[] bgr24 = (byte[]) img[0];
      int width = (int) img[1];
      int height = (int) img[2];

      v("detectFacesImage(w=" + width + ", h=" + height + ")");
      List<FaceInfo> faces = new ArrayList<>();
      int code = trackingEngine.detectFaces(bgr24, width, height, FaceEngine.CP_PAF_BGR24, faces);
      if (code != ErrorInfo.MOK) {
        w("detectFacesImage failed => code=" + code);
        faces.clear();
      }
      d("detectFacesImage => faces=" + faces.size() + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      return faces;
    }
  }

  /**
   * 图片特征提取
   */
  public FaceFeature extractFeatureImage(String base64, FaceInfo faceInfo) {
    synchronized (this) {
      ensureInited();
      long t0 = System.currentTimeMillis();
      Object[] img = decodeImage(base64);
      if (img == null) return null;

      byte[] bgr24 = (byte[]) img[0];
      int width = (int) img[1];
      int height = (int) img[2];

      v("extractFeatureImage(w=" + width + ", h=" + height + ")");
      FaceFeature feature = new FaceFeature();
      int code = recognitionEngine.extractFaceFeature(bgr24, width, height, FaceEngine.CP_PAF_BGR24, faceInfo, feature);
      if (code != ErrorInfo.MOK) {
        w("extractFeatureImage failed => code=" + code);
        return null;
      }
      d("extractFeatureImage => ok, cost=" + (System.currentTimeMillis() - t0) + "ms");
      return feature;
    }
  }

  /**
   * 图片属性检测
   */
  public AttrResult processAttributesImage(String base64, List<FaceInfo> faces, int combinedMask) {
    synchronized (trackingLock) {
      ensureInited();
      long t0 = System.currentTimeMillis();
      Object[] img = decodeImage(base64);
      if (img == null) return new AttrResult(new int[0], new int[0], new int[0], new float[0], new float[0], new float[0]);

      byte[] bgr24 = (byte[]) img[0];
      int width = (int) img[1];
      int height = (int) img[2];

      v("processAttributesImage(mask=" + combinedMask + ", faces=" + (faces == null ? 0 : faces.size()) + ")");

      int code = trackingEngine.process(bgr24, width, height, FaceEngine.CP_PAF_BGR24, faces, combinedMask);
      if (code != ErrorInfo.MOK) {
        w("processAttributesImage.process failed => code=" + code);
        return new AttrResult(new int[0], new int[0], new int[0], new float[0], new float[0], new float[0]);
      }
      return getAttrResult(faces, trackingEngine);
    }
  }

  // =========================
  // Common (通用方法)
  // =========================

  // 获取属性检测结果
  private AttrResult getAttrResult(List<FaceInfo> faces, FaceEngine targetEngine) {
    // Age
    List<AgeInfo> ageInfos = new ArrayList<>();
    int codeAge = targetEngine.getAge(ageInfos);
    if (codeAge != ErrorInfo.MOK) w("getAge failed => code=" + codeAge);
    int[] ages = new int[ageInfos.size()];
    for (int i = 0; i < ageInfos.size(); i++) {
      ages[i] = ageInfos.get(i).getAge();
    }

    // Gender
    List<GenderInfo> genderInfos = new ArrayList<>();
    int codeGender = targetEngine.getGender(genderInfos);
    if (codeGender != ErrorInfo.MOK) w("getGender failed => code=" + codeGender);
    int[] genders = new int[genderInfos.size()];
    for (int i = 0; i < genderInfos.size(); i++) {
      genders[i] = genderInfos.get(i).getGender();
    }

    // Liveness
    List<LivenessInfo> livenessInfos = new ArrayList<>();
    int codeLive = targetEngine.getLiveness(livenessInfos);
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
    int code = recognitionEngine.compareFaceFeature(f1, f2, CompareModel.LIFE_PHOTO, similar);
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

    // 1. Check if exists in DB
    FaceEntity existingFace = faceDatabase.faceDao().getFaceByUserId(tag);
    if (existingFace != null) {
        // Remove old face first
        faceDatabase.faceDao().deleteFaceByUserId(tag);
        Integer oldSearchId = tagToSearchId.remove(tag);
        if (oldSearchId != null) {
            recognitionEngine.removeFaceFeature(oldSearchId);
        }
    }

    // 2. Save to DB
    FaceEntity entity = new FaceEntity(tag, bytes);
    // 更新注册时间
    entity.registerTime = System.currentTimeMillis();
    faceDatabase.faceDao().insertFace(entity);

    // 3. Add to Engine
    int searchId = nextSearchId.getAndIncrement();
    int code = recognitionEngine.registerFaceFeature(new FaceFeatureInfo(searchId, bytes, tag));
    if (code == ErrorInfo.MOK) {
      tagToSearchId.put(tag, searchId);
      // 4. Clear cache
      clearCache();
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
    int code = recognitionEngine.removeFaceFeature(id);
    boolean ok = (code == ErrorInfo.MOK);

    // 3. Clear cache
    clearCache();

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
      try { recognitionEngine.removeFaceFeature(id); } catch (Throwable ignore) {}
    }
    tagToSearchId.clear();

    // 3. Clear cache
    clearCache();
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
      SearchResult r = recognitionEngine.searchFaceFeature(f, CompareModel.LIFE_PHOTO);
      d("faceDBSearchTop1 => got=" + (r != null) + ", cost=" + (System.currentTimeMillis() - t0) + "ms");
      return r;
    } catch (Throwable t) {
      e("faceDBSearchTop1 exception", t);
      return null;
    }
  }
}
