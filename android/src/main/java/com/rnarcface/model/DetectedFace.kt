package com.rnarcface.model

data class DetectedFace(
    val rectLeft: Int,
    val rectTop: Int,
    val rectRight: Int,
    val rectBottom: Int,
    val orient: Int,
    val faceId: Int = 0
) {
    fun rectMap(): Map<String, Int> = mapOf(
        "left" to rectLeft,
        "top" to rectTop,
        "right" to rectRight,
        "bottom" to rectBottom
    )
}
