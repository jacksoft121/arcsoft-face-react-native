package com.rnarcface.engine

import android.content.Context
import com.arcsoft.face.FaceEngine
import com.arcsoft.face.enums.DetectMode
import com.arcsoft.face.enums.DetectOrient
import com.arcsoft.face.enums.DetectFaceMaxNum

/**
 * 对 ArcSoft FaceEngine 做最薄封装
 *
 * 说明：
 * - 不同 SDK 版本枚举命名可能略有差异（你 SDK 中 demo 里用的是 FaceEngine 常量/枚举）
 * - 如果你的 arcsoft_face.jar 枚举名不同，按 demo 的 import 替换即可
 */
class ArcSoftEngineWrapper {

    private var engine: FaceEngine? = null

    fun initDetectVideo(context: Context) {
        val e = FaceEngine()
        val res = e.init(
            context,
            DetectMode.ASF_DETECT_MODE_VIDEO,
            DetectOrient.ASF_OP_0_ONLY,
            /* scale */ 16,
            /* maxFaceNum */ DetectFaceMaxNum.ASF_DETECT_FACE_MAX_NUM_1,
            FaceEngine.ASF_FACE_DETECT or FaceEngine.ASF_FACE_RECOGNITION
        )
        if (res != 0) throw RuntimeException("DetectEngine init failed: $res")
        engine = e
    }

    fun initFeatureImage(context: Context) {
        val e = FaceEngine()
        val res = e.init(
            context,
            DetectMode.ASF_DETECT_MODE_IMAGE,
            DetectOrient.ASF_OP_0_ONLY,
            /* scale */ 30,
            /* maxFaceNum */ DetectFaceMaxNum.ASF_DETECT_FACE_MAX_NUM_1,
            FaceEngine.ASF_FACE_DETECT or FaceEngine.ASF_FACE_RECOGNITION
        )
        if (res != 0) throw RuntimeException("FeatureEngine init failed: $res")
        engine = e
    }

    fun get(): FaceEngine {
        return engine ?: throw IllegalStateException("FaceEngine not initialized")
    }

    fun uninit() {
        engine?.unInit()
        engine = null
    }
}
