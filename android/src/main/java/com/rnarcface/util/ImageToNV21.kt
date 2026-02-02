package com.rnarcface.util

import android.graphics.Bitmap
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import java.io.ByteArrayOutputStream

/**
 * bitmap -> NV21（并做宽4对齐、高2对齐的处理）
 */
object ImageToNV21 {

    data class NV21Image(val nv21: ByteArray, val width: Int, val height: Int)

    fun bitmapToNV21Aligned(bitmap: Bitmap): NV21Image {
        // 先转 ARGB -> NV21（简单但会有压缩损耗；第一阶段先跑通）
        // 后续你要“精度极致”，可以改成纯像素转换（不经 JPEG）
        val w0 = bitmap.width
        val h0 = bitmap.height

        val width = align4(w0)
        val height = align2(h0)

        val resized = if (width != w0 || height != h0) {
            Bitmap.createScaledBitmap(bitmap, width, height, true)
        } else bitmap

        val out = ByteArrayOutputStream()
        resized.compress(Bitmap.CompressFormat.JPEG, 100, out)
        val jpegBytes = out.toByteArray()

        val yuv = YuvImage(jpegBytes, ImageFormat.NV21, width, height, null)
        val nvOut = ByteArrayOutputStream()
        yuv.compressToJpeg(Rect(0, 0, width, height), 100, nvOut)
        val nv21 = nvOut.toByteArray()

        return NV21Image(nv21, width, height)
    }

    private fun align4(v: Int): Int = (v + 3) / 4 * 4
    private fun align2(v: Int): Int = (v + 1) / 2 * 2
}
