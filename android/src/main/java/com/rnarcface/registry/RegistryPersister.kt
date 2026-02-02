package com.rnarcface.registry

import android.content.Context
import android.os.Handler
import android.os.Looper

/**
 * 防抖持久化工具：频繁 upsert/remove 时不要每次都写文件
 * 默认：最后一次变更后 400ms 写一次
 */
object RegistryPersister {

    private const val DEBOUNCE_MS = 400L

    private val handler = Handler(Looper.getMainLooper())
    private var pending: Runnable? = null

    fun schedulePersist(context: Context) {
        pending?.let { handler.removeCallbacks(it) }
        val r = Runnable {
            try {
                FaceRegistry.persist(context)
            } catch (_: Throwable) {
                // 持久化失败不影响识别主流程
            }
        }
        pending = r
        handler.postDelayed(r, DEBOUNCE_MS)
    }

    fun flush(context: Context) {
        pending?.let { handler.removeCallbacks(it) }
        pending = null
        try {
            FaceRegistry.persist(context)
        } catch (_: Throwable) {
        }
    }
}
