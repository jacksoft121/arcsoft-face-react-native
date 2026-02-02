package com.rnarcface.registry

import android.content.Context
import android.util.Base64
import com.arcsoft.face.FaceEngine
import com.arcsoft.face.FaceFeature
import com.arcsoft.face.enums.CompareModel
import com.rnarcface.engine.ArcFaceEnginePool
import com.rnarcface.model.ExtractedFeature
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.max

object FaceRegistry {

    private const val FILE_NAME = "ArcFaceRegistryV1.json"
    private val map = ConcurrentHashMap<String, StoredFeature>()

    data class StoredFeature(val bytes: ByteArray, val size: Int)

    data class MatchResult(val userId: String, val score: Float)

    fun upsert(userId: String, featureBase64: String, featureSize: Int) {
        val bytes = Base64.decode(featureBase64, Base64.DEFAULT)
        map[userId] = StoredFeature(bytes = bytes, size = featureSize)
    }

    fun remove(userId: String) {
        map.remove(userId)
    }

    fun clear() {
        map.clear()
    }

    fun load(context: Context) {
        val file = File(context.filesDir, FILE_NAME)
        if (!file.exists()) return

        val text = file.readText()
        val json = JSONObject(text)
        val items = json.optJSONArray("items") ?: JSONArray()
        map.clear()
        for (i in 0 until items.length()) {
            val it = items.getJSONObject(i)
            val userId = it.getString("userId")
            val featureSize = it.getInt("featureSize")
            val featureBase64 = it.getString("featureBase64")
            upsert(userId, featureBase64, featureSize)
        }
    }

    fun persist(context: Context) {
        val file = File(context.filesDir, FILE_NAME)

        val items = JSONArray()
        for ((userId, feat) in map.entries) {
            val b64 = Base64.encodeToString(feat.value.bytes, Base64.NO_WRAP)
            items.put(
                JSONObject().apply {
                    put("userId", userId)
                    put("featureSize", feat.value.size)
                    put("featureBase64", b64)
                }
            )
        }

        val root = JSONObject().apply {
            put("version", 1)
            put("items", items)
        }

        file.writeText(root.toString())
    }

    /**
     * 当前帧特征与注册库逐个 compare，取最大 score
     * 第一阶段：只做 1:1 compare（不做 1:N search API）
     */
    fun match(feature: ExtractedFeature, threshold: Float): MatchResult? {
        if (map.isEmpty()) return null

        val inputBytes = Base64.decode(feature.base64, Base64.DEFAULT)
        val input = FaceFeature().apply { featureData = inputBytes }

        var bestId: String? = null
        var bestScore = 0f

        ArcFaceEnginePool.withFeature { wrapper ->
            val engine = wrapper.get()

            for ((userId, stored) in map.entries) {
                // 特征长度不一致：先跳过（或你也可以做兼容策略）
                if (stored.size != inputBytes.size) continue

                val target = FaceFeature().apply { featureData = stored.bytes }
                val score = engine.compareFaceFeature(input, target, CompareModel.LIFE_PHOTO)
                if (score > bestScore) {
                    bestScore = score
                    bestId = userId
                }
            }
        }

        return if (bestId != null && bestScore >= threshold) {
            MatchResult(bestId!!, bestScore)
        } else null
    }
}
