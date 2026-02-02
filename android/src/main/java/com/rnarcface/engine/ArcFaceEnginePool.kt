package com.rnarcface.engine

import android.content.Context
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.atomic.AtomicBoolean

/**
 * ArcSoft Engine Pool
 *
 * - DetectEngine: VIDEO 模式
 * - FeatureEngine: IMAGE 模式
 *
 * 关键约束：
 * - 同一个引擎实例不允许并发调用同一算法接口
 *   => 每个引擎使用单线程队列串行化所有调用
 */
object ArcFaceEnginePool {

    private val detectExecutor = Executors.newSingleThreadExecutor { r ->
        Thread(r, "ArcFace-DetectEngine").apply { isDaemon = true }
    }

    private val featureExecutor = Executors.newSingleThreadExecutor { r ->
        Thread(r, "ArcFace-FeatureEngine").apply { isDaemon = true }
    }

    private val inited = AtomicBoolean(false)

    // 这里不直接暴露 ArcSoft 原始 engine，避免被外部并发调用
    private var detectEngine: ArcSoftEngineWrapper? = null
    private var featureEngine: ArcSoftEngineWrapper? = null

    /**
     * 初始化两个引擎：
     * - detect: VIDEO (tracking 更稳更快)
     * - feature: IMAGE (静态图精度更高，适合注册/提特征)
     */
    fun ensureInit(context: Context) {
        if (!inited.get()) init(context)
    }
    fun init(context: Context) {
        if (inited.get()) return

        // 你可以在这里加激活检查/主动激活（activeOnline）
        // 第一阶段先假设已激活成功（由 App 侧在启动页/设置页做一次激活）

        val detect = ArcSoftEngineWrapper()
        val feature = ArcSoftEngineWrapper()

        detect.initDetectVideo(context)
        feature.initFeatureImage(context)

        detectEngine = detect
        featureEngine = feature
        inited.set(true)
    }

    fun uninit() {
        if (!inited.get()) return

        // 按队列顺序销毁，避免销毁时还有任务在跑
        try {
            detectExecutor.submit { detectEngine?.uninit() }.get()
            featureExecutor.submit { featureEngine?.uninit() }.get()
        } catch (_: Throwable) {
        } finally {
            detectEngine = null
            featureEngine = null
            inited.set(false)
        }
    }

    fun <T> withDetect(block: (ArcSoftEngineWrapper) -> T): T? {
        val engine = detectEngine ?: return null
        val future: Future<T> = detectExecutor.submit<T> { block(engine) }
        return future.get()
    }

    fun <T> withFeature(block: (ArcSoftEngineWrapper) -> T): T? {
        val engine = featureEngine ?: return null
        val future: Future<T> = featureExecutor.submit<T> { block(engine) }
        return future.get()
    }
}
