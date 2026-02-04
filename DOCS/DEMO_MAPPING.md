# Demo mapping (逐文件对照)

> 说明：此仓库不含 ArcSoft SDK 二进制文件。你需要把官方 Demo 中的 Framework/Jar/So 拷进对应目录后再编译。
> 下文以 ArcSoft 官方 iOS/Android Demo 的常见类/方法为参照（如 ASF... / ASL... / AFD... 等）。

## iOS

- `ios/ArcSoftFaceReactNative.podspec`
    - 对照官方 iOS Demo 的 Pod/Framework 引入：这里定义 **SDK Framework/StaticLib 的链接位置**（你拷贝后生效）
- `ios/ArcSoftFace/ArcSoftFace.h/.mm`
    - 对照官方 iOS Demo 中的 **Engine 封装层**（通常是把 ASFInitEngine / ASFDetectFaces / ASFProcess 等串起来）
    - 这里提供 RN 可调用的 C++/ObjC++ glue：把 PixelBuffer / UIImage / 文件路径转换为 ArcSoft 需要的数据结构

## Android

- `android/src/main/java/com/arcsoftfacern/ArcsoftEngineManager.java`
    - 对照官方 Android Demo 的 `FaceEngine` 初始化/释放、`detectFaces`、`extractFaceFeature`、`compareFaceFeature`、`liveness` 流程
- `android/src/main/java/com/arcsoftfacern/ArcsoftFaceModule.java`
    - RN Bridge：把 JS 参数转成 EngineManager 调用，并把结果转回 JS

## JS/TS

- `src/ArcSoftFace.ts`
    - 统一 API：init / detectFaces / detectLiveness / extractFeature / compareFeatures / release
    - 这些方法名与官方 Demo 的调用链一一对应：初始化 -> 检测 -> 活体/特征 -> 比对 -> 释放
- `src/NativeArcFace.(ios|android).ts`
    - 平台差异封装：只负责找到正确的 NativeModule 名称并导出同一套接口

