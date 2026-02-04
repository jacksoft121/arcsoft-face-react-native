# arcsoft-face-react-native (RN 0.78)

> 说明：本仓库 **不包含** ArcSoft/虹软 SDK 二进制文件（Android 的 jar/so、iOS 的 framework）。
> 你需要把官方 SDK 按下方步骤放到宿主工程里（或用私有仓库 / 内部制品管理）。

## ✅ 提供的跨平台 API（Android/iOS 对齐）

```ts
import { ArcSoftFace } from 'arcsoft-face-react-native';

await ArcSoftFace.activate({ appId, sdkKey }); // 注册/激活（建议启动时调用一次）
await ArcSoftFace.init(); // 初始化引擎

const count = await ArcSoftFace.detectNV21Base64(nv21Base64, w, h);
const feature = await ArcSoftFace.extractFirstFeatureNV21Base64(nv21Base64, w, h); // base64
const score = await ArcSoftFace.compareImagesNV21Base64(nv21A, nv21B, w, h);

await ArcSoftFace.release();
```

> NV21 Base64：把 NV21 的 `Uint8Array` 编码成 Base64（不含 data: 前缀）。

---

## Android 集成（按你当前 SDK：FaceEngine.init 5 参数）

1) 把官方 SDK 放到宿主工程：

- `android/app/libs/arcsoft_face.jar`
- `android/app/libs/arcsoft_image_util.jar`（如用到）
- `android/app/src/main/jniLibs/` 下放官方 `.so`（按 CPU 架构）

2) `android/app/build.gradle` 添加：

```gradle
dependencies {
  implementation fileTree(dir: "libs", include: ["*.jar"])
}
```

3) 确保 `minSdkVersion` / `ndk` / `abiFilters` 与官方 SDK 匹配。

---

## iOS 集成（ArcSoftFaceEngine.framework）

1) 把官方 iOS SDK 放到宿主工程（推荐用 Xcode 引入）：

- `ArcSoftFaceEngine.framework`
- 以及官方要求的依赖库/系统库

2) 在宿主工程的 `Podfile` 里，确保你的工程能找到该 framework（例如通过 `FRAMEWORK_SEARCH_PATHS` 或手工拖入）。

---

## 说明：逐文件对照官方 Demo

- Android：核心逻辑对照官方 Demo 的 `FaceEngine.init / activeOnline / detectFaces / extractFaceFeature / compareFaceFeature`。
  - 见 `android/src/main/java/com/arcsoftfacern/ArcsoftEngineManager.java`
  - 以及 RN Bridge：`android/src/main/java/com/arcsoftfacern/ArcsoftFaceModule.java`

- iOS：核心逻辑对照官方 Demo 的 `ArcSoftFaceEngine activeWithAppId:SDKKey: / initEngineWithDetectMode:... / detectFacesWithWidth:height:format:data:` 等。
  - 见 `ios/ArcSoftFace/ArcSoftFace.mm`

