package com.rnarcface

import com.mrousavy.camera.frameprocessor.Frame
import com.mrousavy.camera.frameprocessor.FrameProcessorPlugin
import com.rnarcface.engine.DetectEngine
import com.rnarcface.engine.FeatureEngine
import com.rnarcface.registry.FaceRegistry
import com.rnarcface.util.Yuv420ToNV21

/**
 * ArcSoft ArcFace - VisionCamera FrameProcessor
 *
 * 第一阶段：
 * - 单人脸（maxFaceNum = 1）
 * - detect + feature + compare
 * - register_from_frame（注册A）
 */
class ArcFaceFrameProcessorPlugin : FrameProcessorPlugin() {

    override fun callback(frame: Frame, params: Map<String, Any>?): Any? {

        val ctx = frame.context
        if (ctx != null) {
            com.rnarcface.engine.ArcFaceEnginePool.ensureInit(ctx)
        }

        val image = frame.image ?: return null
        val options = params ?: emptyMap()

        val action = options["action"] as? String ?: "process"
        val threshold = (options["threshold"] as? Number)?.toFloat() ?: 0.8f
        val userId = options["userId"] as? String

        // VisionCamera: YUV_420_888 → NV21
        val nv21 = Yuv420ToNV21.convert(image)
        val width = image.width
        val height = image.height

        // 1️⃣ detect（VIDEO engine，单人脸）
        val face = DetectEngine.detect(nv21, width, height) ?: return null

        // 2️⃣ 注册 A：从当前帧提特征
        if (action == "register_from_frame") {
            if (userId.isNullOrEmpty()) return null

            val feature = FeatureEngine.extract(
                nv21,
                width,
                height,
                face
            ) ?: return null

            // 不在 FrameProcessor 内落盘，只回传给 JS
            return mapOf(
                "type" to "register_result",
                "userId" to userId,
                "featureBase64" to feature.base64,
                "featureSize" to feature.size,
                "rect" to face.rectMap(),
                "orient" to face.orient
            )
        }

        // 3️⃣ 正常识别流程：extract + compare
        val feature = FeatureEngine.extract(
            nv21,
            width,
            height,
            face
        )

        val match = if (feature != null) {
            FaceRegistry.match(feature, threshold)
        } else null

        return mapOf(
            "type" to "process_result",
            "rect" to face.rectMap(),
            "orient" to face.orient,
            "score" to (match?.score ?: 0f),
            "matchedUserId" to (match?.userId ?: "")
        )
    }
}
