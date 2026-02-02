package com.rnarcface.engine

import android.content.Context
import android.graphics.BitmapFactory
import android.util.Base64
import com.arcsoft.face.FaceEngine
import com.arcsoft.face.FaceFeature
import com.arcsoft.face.FaceInfo
import com.arcsoft.face.enums.ImageFormat
import com.rnarcface.model.DetectedFace
import com.rnarcface.model.ExtractedFeature
import com.rnarcface.util.ImageToNV21

object FeatureEngine {

    /**
     * 从 NV21 + face 信息提取特征
     * 使用 IMAGE 引擎更准
     */
    fun extract(nv21: ByteArray, width: Int, height: Int, face: DetectedFace): ExtractedFeature? {
        return ArcFaceEnginePool.withFeature { wrapper ->
            val engine = wrapper.get()

            val faceInfo = FaceInfo().apply {
                rect.left = face.rectLeft
                rect.top = face.rectTop
                rect.right = face.rectRight
                rect.bottom = face.rectBottom
                orient = face.orient
                faceId = face.faceId
            }

            val faceFeature = FaceFeature()
            val code = engine.extractFaceFeature(nv21, width, height, ImageFormat.CP_PAF_NV21, faceInfo, faceFeature)
            if (code != 0) return@withFeature null

            val bytes = faceFeature.featureData ?: return@withFeature null
            val b64 = Base64.encodeToString(bytes, Base64.NO_WRAP)
            ExtractedFeature(base64 = b64, size = bytes.size)
        }
    }

    /**
     * 注册B：从图片路径提取特征（内部：decode -> NV21 -> detect(IMAGE) -> extract）
     */
    fun extractFromImage(path: String, context: Context): ExtractedFeature? {
        ArcFaceEnginePool.init(context)

        val bitmap = BitmapFactory.decodeFile(path) ?: return null
        val (nv21, width, height) = ImageToNV21.bitmapToNV21Aligned(bitmap)

        // 用 IMAGE 引擎做 detect
        val face = ArcFaceEnginePool.withFeature { wrapper ->
            val engine = wrapper.get()
            val faces = ArrayList<FaceInfo>(1)
            val code = engine.detectFaces(nv21, width, height, ImageFormat.CP_PAF_NV21, faces)
            if (code != 0 || faces.isEmpty()) return@withFeature null
            val f = faces[0]
            DetectedFace(
                rectLeft = f.rect.left,
                rectTop = f.rect.top,
                rectRight = f.rect.right,
                rectBottom = f.rect.bottom,
                orient = f.orient,
                faceId = f.faceId
            )
        } ?: return null

        return extract(nv21, width, height, face)
    }
}
