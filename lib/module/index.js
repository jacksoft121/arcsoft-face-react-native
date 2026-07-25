"use strict";

import { Platform } from 'react-native';
import { NitroModules } from 'react-native-nitro-modules';
import ArcsoftFaceNative from './spec/NativeArcsoftFace';
let frameDetector = null;
if (Platform.OS === 'android' || Platform.OS === 'ios') {
  try {
    frameDetector = NitroModules.createHybridObject('ArcsoftFrameDetector');
  } catch (error) {
    console.error('[ArcsoftFace] Failed to load ArcsoftFrameDetector', error);
  }
}
export function detectFaces(frame, options) {
  'worklet';

  if (frameDetector == null) {
    console.error("Nitro HybridObject 'ArcsoftFrameDetector' is unavailable.");
    return {
      faces: []
    };
  }
  return frameDetector.detectFaces(frame, options ?? {});
}
export const setLogLevel = level => ArcsoftFaceNative.setLogLevel(level);

/** SDK 在线激活（返回 0 表示成功） */
export const activateOnline = (appId, sdkKey) => ArcsoftFaceNative.activateOnline(appId, sdkKey);

/** 获取激活文件信息 */
export const getActiveFileInfo = async () => {
  const info = await ArcsoftFaceNative.getActiveFileInfo();
  if (!info) return null;

  // 统一 iOS 和 Android 的时间格式
  // Android: "1758270782" (秒级时间戳字符串)
  // iOS: "2025/9/16, 08:16" (格式化字符串)
  // 目标: 统一转换为秒级时间戳字符串

  const parseTime = timeStr => {
    if (!timeStr) return "0";
    // If already a numeric string, return directly
    if (/^\d+$/.test(timeStr)) return timeStr;

    // Specifically handle iOS format: "2025/9/16, 08:16"
    // Parse format: yyyy/MM/dd, HH:mm
    const iosDatePattern = /^(\d{4})\/(\d{1,2})\/(\d{1,2}),\s*(\d{1,2}):(\d{1,2})$/;
    const match = timeStr.match(iosDatePattern);
    if (match) {
      const [, year, month, day, hour, minute] = match;
      const date = new Date(parseInt(year, 10), parseInt(month, 10) - 1,
      // Months are 0-11 in JavaScript
      parseInt(day, 10), parseInt(hour, 10), parseInt(minute, 10));
      if (!isNaN(date.getTime())) {
        return Math.floor(date.getTime() / 1000).toString();
      }
    }

    // Fallback: try normalized parsing
    const normalizedTimeStr = timeStr.replace(',', '');
    const date = new Date(normalizedTimeStr);
    if (!isNaN(date.getTime())) {
      return Math.floor(date.getTime() / 1000).toString();
    }
    return "0";
  };
  let startTime = "0";
  let endTime = "0";
  if (Platform.OS === 'ios') {
    // iOS 格式: "2025/9/16, 08:16"
    startTime = parseTime(info.startTime);
    endTime = parseTime(info.endTime);
  } else {
    // Android 格式: "1758270782" (秒级时间戳)
    startTime = info.startTime || "0";
    endTime = info.endTime || "0";
  }

  // 计算是否过期
  const now = Math.floor(Date.now() / 1000);
  const isExpired = now < Number(startTime) || now > Number(endTime);
  return {
    ...info,
    startTime,
    endTime,
    // @ts-ignore: Adding extra property not in original type but useful for UI
    isExpired
  };
};

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

/** 获取所有人脸列表 */
export const getAllFaces = userId => ArcsoftFaceNative.getAllFaces(userId);

/** 清除缓存 (优化策略) */
export const clearCache = () => ArcsoftFaceNative.clearCache();

/**
 * 注册人脸（通过图片 URL），支持重试机制
 * @param userId 用户ID
 * @param imageUrl 图片地址（支持 http/https 或 file://）
 * @param maxRetries 最大重试次数（默认 2 次，总共尝试 3 次）
 * @returns 注册结果
 */
export const registerFaceFromUrl = async (userId, imageUrl, maxRetries = 2) => {
  let attempt = 0;
  let lastErrorMsg = '';
  while (attempt <= maxRetries) {
    try {
      if (attempt > 0) {
        console.log(`[ArcsoftFace] registerFaceFromUrl retry attempt ${attempt}/${maxRetries}`);
        // Optional: add a small delay before retry
        await new Promise(resolve => setTimeout(() => resolve(undefined), 500));
      }

      // 1. 下载或读取图片并转换为 Base64
      let base64 = '';
      if (imageUrl.startsWith('http')) {
        const response = await fetch(imageUrl);
        const blob = await response.blob();
        base64 = await new Promise((resolve, reject) => {
          const reader = new FileReader();
          reader.onloadend = () => {
            const res = reader.result;
            // remove prefix "data:image/jpeg;base64,"
            resolve(res.split(',')[1] || res);
          };
          reader.onerror = reject;
          reader.readAsDataURL(blob);
        });
      } else if (imageUrl.startsWith('file://')) {
        const response = await fetch(imageUrl);
        const blob = await response.blob();
        base64 = await new Promise((resolve, reject) => {
          const reader = new FileReader();
          reader.onloadend = () => {
            const res = reader.result;
            resolve(res.split(',')[1] || res);
          };
          reader.onerror = reject;
          reader.readAsDataURL(blob);
        });
      } else {
        // Assume base64 string if not url
        base64 = imageUrl;
      }
      if (!base64) {
        throw new Error('图片数据为空');
      }

      // 2. 检测人脸
      const faces = await detectFacesImage(base64);
      if (!faces || faces.length === 0) {
        throw new Error('未检测到人脸');
      }

      // 3. 提取特征 (取最大的人脸，通常是第一个)
      const face = faces[0];
      const feature = await extractFeatureImage(base64, face);
      if (!feature || !feature.dataBase64) {
        throw new Error('特征提取失败');
      }

      // 4. 注册/更新特征
      const result = await registerFaceFeature(userId, feature);
      if (result.success) {
        return {
          success: true,
          msg: '注册成功',
          userId,
          featureBase64: result.featureBase64
        };
      } else {
        throw new Error('注册失败(引擎返回false)');
      }
    } catch (e) {
      lastErrorMsg = e.message || String(e);
      console.warn(`[ArcsoftFace] registerFaceFromUrl failed (attempt ${attempt}): ${lastErrorMsg}`);
      attempt++;
    }
  }
  return {
    success: false,
    msg: `注册失败(重试${maxRetries}次后): ${lastErrorMsg}`
  };
};

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
  registerFaceFromUrl,
  // Export new function
  getAllFaces,
  // Export new function
  clearCache,
  // Export new function

  // Frame Processor Plugin
  detectFaces
};
export default ArcsoftFace;
//# sourceMappingURL=index.js.map