package com.rnarcface

import com.facebook.react.bridge.*
import com.rnarcface.engine.ArcFaceEnginePool
import com.rnarcface.engine.FeatureEngine
import com.rnarcface.registry.FaceRegistry
import com.rnarcface.registry.RegistryPersister

/**
 * ArcFace Native Module
 * - 注册B（图片路径提特征）
 * - Registry 管理（内存 + 持久化）
 */
class ArcFaceModule(
    reactContext: ReactApplicationContext
) : ReactContextBaseJavaModule(reactContext) {

    override fun getName(): String = "ArcFaceModule"

    /**
     * 注册B：从图片路径提取特征（IMAGE模式）
     * 返回：{ featureBase64, featureSize }
     */
    @ReactMethod
    fun extractFeatureFromImage(path: String, promise: Promise) {
        try {
            ArcFaceEnginePool.ensureInit(reactApplicationContext)

            val feature = FeatureEngine.extractFromImage(path, reactApplicationContext)
                ?: run {
                    promise.reject("NO_FACE", "No face detected in image")
                    return
                }

            promise.resolve(
                Arguments.createMap().apply {
                    putString("featureBase64", feature.base64)
                    putInt("featureSize", feature.size)
                }
            )
        } catch (e: Exception) {
            promise.reject("EXTRACT_FAILED", e)
        }
    }

    /**
     * 启动/进入识别页：加载持久化 registry 到内存
     */
    @ReactMethod
    fun registryLoadAll(promise: Promise) {
        try {
            ArcFaceEnginePool.ensureInit(reactApplicationContext)
            FaceRegistry.load(reactApplicationContext)
            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("LOAD_FAILED", e)
        }
    }

    /**
     * 写入/更新一个注册特征
     * 注意：不在这里做 compare（实时 compare 由 FrameProcessor 在 native 内存中做）
     */
    @ReactMethod
    fun registryUpsert(
        userId: String,
        featureBase64: String,
        featureSize: Int,
        promise: Promise
    ) {
        try {
            FaceRegistry.upsert(userId, featureBase64, featureSize)
            RegistryPersister.schedulePersist(reactApplicationContext)
            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("UPSERT_FAILED", e)
        }
    }

    @ReactMethod
    fun registryRemove(userId: String, promise: Promise) {
        try {
            FaceRegistry.remove(userId)
            RegistryPersister.schedulePersist(reactApplicationContext)
            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("REMOVE_FAILED", e)
        }
    }

    @ReactMethod
    fun registryClear(promise: Promise) {
        try {
            FaceRegistry.clear()
            RegistryPersister.flush(reactApplicationContext)
            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("CLEAR_FAILED", e)
        }
    }
}
