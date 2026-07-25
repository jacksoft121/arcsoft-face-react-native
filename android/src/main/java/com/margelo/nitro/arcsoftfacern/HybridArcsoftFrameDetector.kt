package com.margelo.nitro.arcsoftfacern

import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import android.util.Log
import com.arcsoft.face.FaceInfo
import com.arcsoftfacern.ArcsoftEngineManager
import com.margelo.nitro.NitroModules
import com.margelo.nitro.camera.HybridFrameSpec
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.SynchronousQueue
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.max
import kotlin.math.roundToInt

class HybridArcsoftFrameDetector : HybridArcsoftFrameDetectorSpec() {
  private val engineManager: ArcsoftEngineManager
  private val isProcessing = AtomicBoolean(false)
  private val bufferLock = Any()

  private var nv21Buffer: ByteArray? = null
  private var uBufferArray: ByteArray? = null
  private var vBufferArray: ByteArray? = null
  // 每个 detector 只记录一次实际 YUV 路径，便于真机确认是否命中 Demo 风格快路径。
  private val hasLoggedYuvPath = AtomicBoolean(false)

  init {
    val context = NitroModules.applicationContext
      ?: throw Error("Application context is unavailable")
    engineManager = ArcsoftEngineManager.getInstance(context)
  }

  override fun detectFaces(
    frame: HybridFrameSpec,
    options: ArcsoftDetectFacesOptions
  ): ArcsoftDetectFacesResult {
    if (!isProcessing.compareAndSet(false, true)) {
      Log.w(TAG, "Skip frame: previous frame still processing")
      return emptyResult()
    }

    try {
      val width = frame.width.toInt()
      val height = frame.height.toInt()
      val saveImage = options.saveImage ?: false
      val captureUserIds = options.captureUserIds ?: ""
      val extractFeature = options.extractFeature ?: false
      val retExtractFeatureBase64 = options.retExtractFeatureBase64 ?: false
      val scoreThreshold = options.score ?: 0.8
      val maxRetryCount = options.maxRetryCount?.toInt() ?: DEFAULT_MAX_RETRY_COUNT

      val nv21 = yuv420ToNv21(frame, width, height)
      if (nv21 == null) {
        Log.e(TAG, "Failed to convert Frame planes to NV21")
        return emptyResult()
      }

      val faces = engineManager.detectFacesNV21(nv21, width, height)
      engineManager.cleanUpFaceStates(faces)
      if (extractFeature && faces.isNotEmpty()) {
        // 只复制真正需要识别的帧；VIDEO 跟踪立即返回，特征提取和 1:N 搜索
        // 在独立引擎/后台线程完成，下一帧通过 faceId 读取结果。
        scheduleRecognition(
          faces,
          nv21,
          width,
          height,
          retExtractFeatureBase64,
          scoreThreshold,
          maxRetryCount
        )
      }

      var shouldSaveFrame = saveImage && captureUserIds.isBlank()
      val out = ArrayList<ArcsoftDetectedFace>(faces.size)
      for (face in faces) {
        val r = face.rect
        val rect = ArcsoftFrameRect(
          r.left.toDouble(),
          r.top.toDouble(),
          r.right.toDouble(),
          r.bottom.toDouble()
        )
        // ArcSoft v5 在 VIDEO detectFaces 的 FaceInfo 中直接携带 3D 姿态，
        // 无需再跑年龄/性别/活体的 process，避免注册页每帧重复计算属性模型。
        val nativeAngle = face.face3DAngle
        val angle = nativeAngle?.let {
          val yaw = it.yaw.toDouble()
          val pitch = it.pitch.toDouble()
          val roll = it.roll.toDouble()
          ArcsoftFrameAngle(
            yaw,
            pitch,
            roll,
            yaw.isFinite() && pitch.isFinite() && roll.isFinite()
          )
        }

        // 无论本帧是否触发特征提取，都返回同一 faceId 已确认的身份。
        // 成功后该 trace 在离开画面前不会重复搜索，也不会退回红框。
        val cachedInfo = engineManager.getCachedFaceInfo(face.faceId)
        val cachedUserId = cachedInfo["userId"] as? String
        val cachedScore = (cachedInfo["score"] as? Number)?.toDouble()
        val cachedFeature = if (retExtractFeatureBase64) {
          cachedInfo["featureBase64"] as? String
        } else {
          null
        }

        if (
          saveImage &&
          captureUserIds.isNotBlank() &&
          cachedUserId != null &&
          captureUserIds.contains(",$cachedUserId,")
        ) {
          shouldSaveFrame = true
        }

        out.add(
          ArcsoftDetectedFace(
            rect,
            face.orient.toDouble(),
            face.faceId.toDouble(),
            angle,
            cachedFeature,
            cachedUserId,
            cachedScore
          )
        )
      }

      val imagePath = if (shouldSaveFrame) saveFrame(width, height, nv21) else null
      return ArcsoftDetectFacesResult(out.toTypedArray(), imagePath)
    } catch (t: Throwable) {
      Log.e(TAG, "Error processing frame", t)
      return emptyResult()
    } finally {
      isProcessing.set(false)
    }
  }

  private data class PendingRecognition(
    val face: FaceInfo,
    val faceId: Int,
    val generation: Long
  )

  /**
   * 把一次帧中的待识别人脸作为单个任务提交，所有人脸共享同一份 NV21
   * 快照。识别线程忙时直接丢弃请求，避免旧帧排队造成姓名延迟和内存滞留。
   */
  private fun scheduleRecognition(
    faces: List<FaceInfo>,
    nv21: ByteArray,
    width: Int,
    height: Int,
    retExtractFeatureBase64: Boolean,
    scoreThreshold: Double,
    maxRetryCount: Int
  ) {
    val pending = ArrayList<PendingRecognition>(faces.size)
    for (face in faces) {
      val generation = engineManager.tryBeginFaceRecognition(
        face.faceId,
        maxRetryCount
      )
      if (generation >= 0) {
        // FaceInfo 内含特征提取所需 faceData，必须随当前帧一起复制。
        pending.add(
          PendingRecognition(
            FaceInfo(face),
            face.faceId,
            generation
          )
        )
      }
    }
    if (pending.isEmpty()) return

    val frameCopy = nv21.copyOf(width * height * 3 / 2)
    try {
      recognitionExecutor.execute {
        for (item in pending) {
          try {
            val result = engineManager.recognizeFaceNV21(
              frameCopy,
              width,
              height,
              item.face,
              scoreThreshold,
              retExtractFeatureBase64
            )
            engineManager.completeFaceRecognition(
              item.faceId,
              item.generation,
              result
            )
          } catch (t: Throwable) {
            Log.e(TAG, "Async recognition failed, faceId=${item.faceId}", t)
            engineManager.completeFaceRecognition(
              item.faceId,
              item.generation,
              null
            )
          }
        }
      }
    } catch (_: RejectedExecutionException) {
      // 不允许识别队列积压；撤销占位后由下一次有效特征帧重新申请。
      for (item in pending) {
        engineManager.cancelFaceRecognition(item.faceId, item.generation)
      }
    }
  }

  private fun saveFrame(width: Int, height: Int, nv21: ByteArray): String? {
    try {
      val cacheDir = engineManager.context?.externalCacheDir ?: return null
      val file = File(cacheDir, "frame_${System.currentTimeMillis()}.jpg")
      val yuvImage = YuvImage(nv21, ImageFormat.NV21, width, height, null)

      FileOutputStream(file).use { output ->
        val ok = yuvImage.compressToJpeg(Rect(0, 0, width, height), 92, output)
        if (!ok) {
          Log.e(TAG, "compressToJpeg failed")
          return null
        }
      }

      Log.i(TAG, "Saved frame to ${file.absolutePath}")
      return "file://${file.absolutePath}"
    } catch (t: Throwable) {
      Log.e(TAG, "Failed to save frame", t)
      return null
    }
  }

  private fun yuv420ToNv21(frame: HybridFrameSpec, width: Int, height: Int): ByteArray? {
    try {
      val planes = frame.getPlanes()
      if (planes.size < 3) {
        Log.e(TAG, "Invalid frame planes: ${planes.size}")
        return null
      }

      val yPlane = planes[0]
      val uPlane = planes[1]
      val vPlane = planes[2]
      val yBuffer = yPlane.getPixelBuffer().getBuffer(false)
      val uBuffer = uPlane.getPixelBuffer().getBuffer(false)
      val vBuffer = vPlane.getPixelBuffer().getBuffer(false)

      val yRowStride = yPlane.bytesPerRow.toInt()
      val uvRowStride = uPlane.bytesPerRow.toInt()
      val uvPixelStride = max(
        1,
        (uPlane.bytesPerRow / max(1.0, uPlane.width)).roundToInt()
      )

      val frameSize = width * height
      val totalSize = frameSize * 3 / 2
      val chromaSize = totalSize - frameSize

      synchronized(bufferLock) {
        ensureCapacity(totalSize, uBuffer.remaining(), vBuffer.remaining())
        val nv21 = nv21Buffer ?: return null
        val uArray = uBufferArray ?: return null
        val vArray = vBufferArray ?: return null

        var pos = 0
        yBuffer.rewind()

        if (yRowStride == width) {
          yBuffer.get(nv21, 0, frameSize)
          pos = frameSize
        } else {
          for (row in 0 until height) {
            yBuffer.position(row * yRowStride)
            yBuffer.get(nv21, pos, width)
            pos += width
          }
        }

        // CameraX 常见的 YUV_420_888 实际是两个相差 1 字节的 NV21 视图。
        // ArcSoft Demo 直接收到 NV21；优先整块复制 VU 平面，避免 Kotlin 在
        // 每个像素上交错 U/V。布局不满足时再走下面的通用安全路径。
        if (
          copyInterleavedNv21Chroma(
            uBuffer,
            vBuffer,
            uvRowStride,
            uvPixelStride,
            width,
            chromaSize,
            nv21,
            frameSize
          )
        ) {
          if (hasLoggedYuvPath.compareAndSet(false, true)) {
            Log.i(TAG, "YUV path: interleaved NV21 bulk copy")
          }
          return nv21
        }

        if (hasLoggedYuvPath.compareAndSet(false, true)) {
          Log.i(TAG, "YUV path: generic planar conversion")
        }
        uBuffer.rewind()
        vBuffer.rewind()
        val uRemaining = uBuffer.remaining()
        val vRemaining = vBuffer.remaining()
        uBuffer.get(uArray, 0, uRemaining)
        vBuffer.get(vArray, 0, vRemaining)

        val uvHeight = height / 2
        val uvWidth = width / 2
        for (row in 0 until uvHeight) {
          val rowStart = row * uvRowStride
          for (col in 0 until uvWidth) {
            val index = rowStart + col * uvPixelStride
            nv21[pos++] = if (index < vRemaining) vArray[index] else 0
            nv21[pos++] = if (index < uRemaining) uArray[index] else 0
          }
        }

        return nv21
      }
    } catch (t: Throwable) {
      Log.e(TAG, "YUV conversion failed", t)
      return null
    }
  }

  /**
   * 尝试把 CameraX 的半平面 YUV_420_888 作为 NV21 整块复制。
   *
   * U/V 两个 ByteBuffer 通常共享同一块 VU 内存，V 视图比 U 视图早一个
   * 字节。先抽样验证重叠关系，避免在厂商返回真正三平面数据时误判。
   */
  private fun copyInterleavedNv21Chroma(
    uBuffer: ByteBuffer,
    vBuffer: ByteBuffer,
    uvRowStride: Int,
    uvPixelStride: Int,
    width: Int,
    chromaSize: Int,
    output: ByteArray,
    outputOffset: Int
  ): Boolean {
    if (
      uvPixelStride != 2 ||
      uvRowStride != width ||
      chromaSize < 2
    ) {
      return false
    }

    val uView = uBuffer.duplicate().apply { rewind() }
    val vView = vBuffer.duplicate().apply { rewind() }
    if (
      uView.remaining() < chromaSize - 1 ||
      vView.remaining() < chromaSize - 1
    ) {
      return false
    }

    val sampleBytes = minOf(32, chromaSize - 1)
    var offset = 0
    while (offset + 1 < sampleBytes) {
      if (vView.get(offset + 1) != uView.get(offset)) {
        return false
      }
      offset += 2
    }

    if (vView.remaining() >= chromaSize) {
      vView.get(output, outputOffset, chromaSize)
    } else {
      vView.get(output, outputOffset, chromaSize - 1)
      output[outputOffset + chromaSize - 1] = uView.get(chromaSize - 2)
    }
    return true
  }

  private fun ensureCapacity(nv21Size: Int, uSize: Int, vSize: Int) {
    if (nv21Buffer == null || nv21Buffer!!.size < nv21Size) {
      nv21Buffer = ByteArray(nv21Size)
    }
    if (uBufferArray == null || uBufferArray!!.size < uSize) {
      uBufferArray = ByteArray(uSize)
    }
    if (vBufferArray == null || vBufferArray!!.size < vSize) {
      vBufferArray = ByteArray(vSize)
    }
  }

  private fun emptyResult(): ArcsoftDetectFacesResult {
    return ArcsoftDetectFacesResult(emptyArray<ArcsoftDetectedFace>(), null)
  }

  companion object {
    private const val TAG = "ArcsoftFaceDetector"
    private const val DEFAULT_MAX_RETRY_COUNT = 3
    /**
     * ArcSoft 同一识别引擎只允许串行调用。全进程共用一个可超时线程且不保留
     * 等待任务，避免每次创建 HybridObject 都残留线程或慢设备积压旧帧。
     */
    private val recognitionExecutor = ThreadPoolExecutor(
      1,
      1,
      15,
      TimeUnit.SECONDS,
      SynchronousQueue(),
      { runnable ->
        Thread(runnable, "ArcSoftRecognition").apply { isDaemon = true }
      },
      ThreadPoolExecutor.AbortPolicy()
    ).apply {
      allowCoreThreadTimeOut(true)
    }
  }
}
