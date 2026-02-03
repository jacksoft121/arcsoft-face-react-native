# arcsoft-face-react-native (iOS)

> 适配 React Native 0.78（支持 New Architecture / TurboModule）。

## 说明
- iOS 侧集成了 `ArcSoftFaceEngine.framework`（来自你提供的 iOS demo）。
- JS 侧为了通用/易用，Bridge 输入的是 **RAW bytes 的 base64**（不是 JPEG/PNG base64）。

## 安装（建议作为本地 package）
1. 把本目录放到你的仓库里（例如 `packages/arcsoft-face-react-native`）
2. App 的 `package.json` 里添加依赖（workspace/path）
3. iOS 执行：
   - `cd ios && pod install`

## 使用
```ts
import { ArcSoftFace } from 'arcsoft-face-react-native';

await ArcSoftFace.init({
  appId: 'YOUR_APP_ID',
  sdkKey: 'YOUR_SDK_KEY',
  detectMode: 'ASF_DETECT_MODE_VIDEO',
  orientationPriority: 'ASF_OP_0_HIGHER_EXT',
  scale: 16,
  maxFaceNum: 5,
});

const image = {
  width,
  height,
  format: 'ASF_IMAGE_FORMAT_BGRA32',
  base64: rawBytesBase64,
};

const { faces } = await ArcSoftFace.detectFaces(image);
if (faces.length) {
  const feat = await ArcSoftFace.extractFeature(image, faces[0]);
  // compare / save...
}
```
