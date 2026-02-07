"use strict";

import { VisionCameraProxy } from 'react-native-vision-camera';
import ArcsoftFaceNative from './spec/NativeArcsoftFace';
// Frame Processor Plugin
const plugin = VisionCameraProxy.initFrameProcessorPlugin('detectFaces', {});
export function detectFaces(frame, options) {
  'worklet';

  if (plugin == null) {
    console.error("Failed to load Frame Processor Plugin 'detectFaces'!");
    return {
      faces: []
    };
  }
  // @ts-ignore
  return plugin.call(frame, options);
}
export const setLogLevel = level => ArcsoftFaceNative.setLogLevel(level);

/** SDK 在线激活（返回 0 表示成功） */
export const activateOnline = (appId, sdkKey) => ArcsoftFaceNative.activateOnline(appId, sdkKey);

/** 获取激活文件信息 */
export const getActiveFileInfo = () => ArcsoftFaceNative.getActiveFileInfo();

/** 初始化引擎（返回 0 表示成功） */
export const initEngine = (options = {}) => ArcsoftFaceNative.initEngine(JSON.stringify(options));

/** 反初始化引擎（返回 0 表示成功） */
export const unInitEngine = () => ArcsoftFaceNative.unInitEngine();

/** NV21 输入（跨平台统一输入） */
export const detectFacesNV21 = (nv21, width, height) => ArcsoftFaceNative.detectFacesNV21(nv21, width, height);

/** 特征提取（NV21） */
export const extractFeatureNV21 = (nv21, width, height, face) => ArcsoftFaceNative.extractFeatureNV21(nv21, width, height, face);

/** 特征比对 */
export const compareFeature = (f1, f2) => ArcsoftFaceNative.compareFeature(f1, f2);

/** 年龄/性别/活体/3D角度 */
export const getAgeNV21 = (nv21, width, height, faces) => ArcsoftFaceNative.getAgeNV21(nv21, width, height, faces);
export const getGenderNV21 = (nv21, width, height, faces) => ArcsoftFaceNative.getGenderNV21(nv21, width, height, faces);
export const getLivenessNV21 = (nv21, width, height, faces) => ArcsoftFaceNative.getLivenessNV21(nv21, width, height, faces);
export const getFace3DAngleNV21 = (nv21, width, height, faces) => ArcsoftFaceNative.getFace3DAngleNV21(nv21, width, height, faces);

/** 图片输入 (Base64) */
export const detectFacesImage = base64 => ArcsoftFaceNative.detectFacesImage(base64);
export const extractFeatureImage = (base64, face) => ArcsoftFaceNative.extractFeatureImage(base64, face);
export const getAgeImage = (base64, faces) => ArcsoftFaceNative.getAgeImage(base64, faces);
export const getGenderImage = (base64, faces) => ArcsoftFaceNative.getGenderImage(base64, faces);
export const getLivenessImage = (base64, faces) => ArcsoftFaceNative.getLivenessImage(base64, faces);
export const getFace3DAngleImage = (base64, faces) => ArcsoftFaceNative.getFace3DAngleImage(base64, faces);

/** 人脸库 */
export const registerFaceFeature = (id, feature) => ArcsoftFaceNative.registerFaceFeature(id, feature);
export const removeFaceFeature = id => ArcsoftFaceNative.removeFaceFeature(id);
export const clearAllFaceFeature = () => ArcsoftFaceNative.clearAllFaceFeature();
export const getFaceCount = () => ArcsoftFaceNative.getFaceCount();
export const searchFaceFeature = (feature, threshold = 0) => ArcsoftFaceNative.searchFaceFeature(feature, threshold);

/**
 * 默认导出：一个与原生同名的对象（方便用户 `import ArcsoftFace from 'xxx'`）
 */
const ArcsoftFace = {
  setLogLevel,
  activateOnline,
  getActiveFileInfo,
  initEngine,
  unInitEngine,
  detectFacesNV21,
  extractFeatureNV21,
  compareFeature,
  getAgeNV21,
  getGenderNV21,
  getLivenessNV21,
  getFace3DAngleNV21,
  detectFacesImage,
  extractFeatureImage,
  getAgeImage,
  getGenderImage,
  getLivenessImage,
  getFace3DAngleImage,
  registerFaceFeature,
  removeFaceFeature,
  clearAllFaceFeature,
  getFaceCount,
  searchFaceFeature,
  // Frame Processor Plugin
  detectFaces
};
export default ArcsoftFace;
//# sourceMappingURL=index.js.map