# ArcSoft ArcFace Android SDK 开发指南

> **版本**: 5.0
> **版权**: ©2025 ArcSoft Corporation Limited. All rights reserved.

---

## 1. 简介 (Introduction)

### 1.1 产品概述
ArcFace 离线 SDK 包含人脸检测、性别检测、年龄检测、人脸识别等能力。初次使用时需联网激活，激活后即可在本地无网络环境下工作，可根据具体的业务需求结合人脸识别 SDK 灵活地进行应用层开发。

**基础算法库包含**：
* 人脸检测、人脸追踪、特征提取、人脸比对
* 年龄检测、性别检测、3D 角度检测
* RGB 活体检测、交互式动作检测、炫光活体检测

### 1.2 功能简介

* **人脸检测 (Face Detection)**: 对传入的图像数据进行人脸检测，返回人脸的边框以及朝向信息。支持 IMAGE 模式（高精度）和 VIDEO 模式（追踪）。
* **人脸追踪 (Face Tracking)**: 对来自于视频流中的图像数据进行持续跟踪。
* **特征提取 (Feature Extraction)**: 提取人脸特征信息，用于后续的比对。
* **特征比对 (Feature Comparison)**: 对两个人脸特征数据进行比对，返回相似度。
* **属性检测 (Attributes)**: 支持检测年龄、性别、活体以及 3D 角度（俯仰角 pitch, 横滚角 roll, 偏航角 yaw）。

### 1.3 授权说明
SDK 授权按设备进行授权，每台硬件设备需要一个独立的授权。
* **在线激活**: 确保设备可以访问公网，调用激活接口激活 SDK。激活成功后可离线运行。
* **注意事项**: 若设备授权信息被删除（如重装系统/应用卸载）或硬件信息变更，需重新联网激活。

### 1.4 环境要求
* **运行环境**: Android 5.0 (API Level 21) 及以上。
* **架构支持**: armeabi-v7a, arm64-v8a。
* **权限申明**: 允许应用联网（用于激活），相机权限，存储权限（可选）。

---

## 2. 接入须知 (Getting Started)

### 2.1 SDK 包结构
* `doc`: 开发说明文档
* `libs`: 包含 `arcsoft_face.jar` 和 `libarcsoft_face.so` 等
* `sample`: 示例工程

### 2.2 阈值推荐
人脸比对分值区间为 [0, 1]，推荐阈值如下：
* **生活照 vs 生活照**: 0.80
* **证件照 vs 生活照**: 0.80

### 2.3 图像要求
* 人脸角度上、下、左、右转向小于 30 度。
* 图像中人脸尺寸不小于 50x50 像素。
* 图像大小小于 10MB，且清晰。

---

## 3. SDK 详细接口说明 (API Reference)

### 3.1 激活 SDK (active)
在使用 SDK 前需进行在线激活，激活成功后即可离线使用。

**接口方法**:
```java
public int activeOnline(Context context, String appId, String sdkKey);
```

---

## 4. 核心功能覆盖情况 (Core Features Implementation)

下表列出了 ArcSoft Android SDK 的核心接口与本项目 (`arcsoft-face-react-native`) Android 原生实现 (`ArcsoftEngineManager.java`) 的对应关系及覆盖状态。

| 功能模块 | SDK 接口 (Java) | 当前实现 (`ArcsoftEngineManager.java`) | 状态 |
| :--- | :--- | :--- | :--- |
| **激活** | `FaceEngine.activeOnline` | `activateOnline` | ✅ 已实现 |
| **获取激活信息** | `FaceEngine.getActiveFileInfo` | `getActiveFileInfo` | ✅ 已实现 |
| **初始化引擎** | `FaceEngine.init` | `initEngine` | ✅ 已实现 |
| **反初始化** | `FaceEngine.unInit` | `unInitEngine` | ✅ 已实现 |
| **人脸检测** | `FaceEngine.detectFaces` | `detectFacesNV21` / `detectFacesImage` | ✅ 已实现 |
| **特征提取** | `FaceEngine.extractFaceFeature` | `extractFeatureNV21` / `extractFeatureImage` | ✅ 已实现 |
| **特征比对** | `FaceEngine.compareFaceFeature` | `compare` / `compareBase64` | ✅ 已实现 |
| **属性检测** | `FaceEngine.process` | `processAttributes` / `processAttributesImage` | ✅ 已实现 |
| **获取年龄** | `FaceEngine.getAge` | `getAttrResult` (内部调用) | ✅ 已实现 |
| **获取性别** | `FaceEngine.getGender` | `getAttrResult` (内部调用) | ✅ 已实现 |
| **获取活体** | `FaceEngine.getLiveness` | `getAttrResult` (内部调用) | ✅ 已实现 |
| **获取3D角度** | `FaceEngine.getFace3DAngle` | `getAttrResult` (内部调用) | ✅ 已实现 |
| **人脸库注册** | `FaceEngine.registerFaceFeature` | `faceDBAddOrUpdate` | ✅ 已实现 |
| **人脸库更新** | `FaceEngine.updateFaceFeature` | `faceDBAddOrUpdate` | ✅ 已实现 |
| **人脸库删除** | `FaceEngine.removeFaceFeature` | `faceDBRemove` | ✅ 已实现 |
| **人脸库清空** | (循环调用 remove) | `faceDBClear` | ✅ 已实现 |
| **人脸库数量** | `FaceEngine.getFaceCount` | `faceDBCount` | ✅ 已实现 |
| **人脸库搜索** | `FaceEngine.searchFaceFeature` | `faceDBSearchTop1` | ✅ 已实现 |
