package com.rnarcface.engine

import com.arcsoft.face.FaceInfo
import com.arcsoft.face.FaceEngine
import com.arcsoft.face.enums.ImageFormat
import com.rnarcface.model.DetectedFace

object DetectEngine {

    /**
     * NV21 输入，单人脸检测（maxFaceNum=1）
     */
    fun detect(nv21: ByteArray, width: Int, height: Int): DetectedFace? {
        ArcFaceEnginePool.initIfNeeded()

        val res = ArcFaceEnginePool.withDetect { wrapper ->
            val engine = wrapper.get()
            val faces = ArrayList<FaceInfo>(1)
            val code = engine.detectFaces(nv21, width, height, ImageFormat.CP_PAF_NV21, faces)
            if (code != 0 || faces.isEmpty()) return@withDetect null

            val f = faces[0]
            DetectedFace(
                rectLeft = f.rect.left,
                rectTop = f.rect.top,
                rectRight = f.rect.right,
                rectBottom = f.rect.bottom,
                orient = f.orient,
                faceId = f.faceId // VIDEO模式有效；IMAGE模式可能为0或无意义
            )
        }

        return res
    }
}

/**
 * 给 Pool 加一个 lazy init 入口（避免你忘记 init）
 */
private fun ArcFaceEnginePool.initIfNeeded() {
    // DetectEngine 只在 FrameProcessor 调用，context 由 FeatureEngine/Module init 时传入
    // 这里不做 context init，保持严格：必须先 init(context)
    // 你如果希望自动 init，可在 Plugin callback 第一次拿到 context 时调用 init
}
