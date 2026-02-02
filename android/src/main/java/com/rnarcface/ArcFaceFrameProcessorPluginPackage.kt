package com.rnarcface

import com.mrousavy.camera.frameprocessor.FrameProcessorPlugin
import com.mrousavy.camera.frameprocessor.FrameProcessorPluginPackage

/**
 * VisionCamera FrameProcessor 插件注册入口
 * JS 中通过 useFrameProcessorPlugin("arcFace") 调用
 */
class ArcFaceFrameProcessorPluginPackage :
    FrameProcessorPluginPackage("arcFace") {

    override fun createPlugin(): FrameProcessorPlugin {
        return ArcFaceFrameProcessorPlugin()
    }
}
