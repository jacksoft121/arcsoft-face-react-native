package com.rnarcface.util

import android.media.Image
import java.nio.ByteBuffer

/**
 * Image (YUV_420_888) -> NV21
 * 重点：减少拷贝；第一版先稳，后续再做 pool 优化
 */
object Yuv420ToNV21 {

    fun convert(image: Image): ByteArray {
        val width = image.width
        val height = image.height
        val ySize = width * height
        val uvSize = width * height / 2
        val out = ByteArray(ySize + uvSize)

        val yBuf = image.planes[0].buffer
        val uBuf = image.planes[1].buffer
        val vBuf = image.planes[2].buffer

        val yRowStride = image.planes[0].rowStride
        val uvRowStride = image.planes[1].rowStride
        val uvPixelStride = image.planes[1].pixelStride

        // Copy Y
        var pos = 0
        for (row in 0 until height) {
            val rowStart = row * yRowStride
            yBuf.position(rowStart)
            yBuf.get(out, pos, width)
            pos += width
        }

        // Copy VU (NV21)
        // For each 2x2 block, take one V and one U
        var uvPos = ySize
        val chromaHeight = height / 2
        val chromaWidth = width / 2

        for (row in 0 until chromaHeight) {
            val rowStart = row * uvRowStride
            for (col in 0 until chromaWidth) {
                val offset = rowStart + col * uvPixelStride
                vBuf.position(offset)
                out[uvPos++] = vBuf.get()
                uBuf.position(offset)
                out[uvPos++] = uBuf.get()
            }
        }

        return out
    }
}
