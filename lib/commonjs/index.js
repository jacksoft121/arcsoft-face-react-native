"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = exports.compareFeature = exports.clearAllFaceFeature = exports.activateOnline = void 0;
exports.detectFaces = detectFaces;
exports.unInitEngine = exports.setLogLevel = exports.searchFaceFeature = exports.removeFaceFeature = exports.registerFaceFromUrl = exports.registerFaceFeature = exports.initEngine = exports.getLivenessNV21 = exports.getLivenessImage = exports.getGenderNV21 = exports.getGenderImage = exports.getFaceCount = exports.getFace3DAngleNV21 = exports.getFace3DAngleImage = exports.getAllFaces = exports.getAgeNV21 = exports.getAgeImage = exports.getActiveFileInfo = exports.extractFeatureNV21 = exports.extractFeatureImage = exports.detectFacesNV21 = exports.detectFacesImage = void 0;
var _reactNativeVisionCamera = require("react-native-vision-camera");
var _NativeArcsoftFace = _interopRequireDefault(require("./spec/NativeArcsoftFace"));
function _interopRequireDefault(e) { return e && e.__esModule ? e : { default: e }; }
// Frame Processor Plugin
const plugin = _reactNativeVisionCamera.VisionCameraProxy.initFrameProcessorPlugin('detectFaces', {});
function detectFaces(frame, options) {
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
const setLogLevel = level => _NativeArcsoftFace.default.setLogLevel(level);

/** SDK 在线激活（返回 0 表示成功） */
exports.setLogLevel = setLogLevel;
const activateOnline = (appId, sdkKey) => _NativeArcsoftFace.default.activateOnline(appId, sdkKey);

/** 获取激活文件信息 */
exports.activateOnline = activateOnline;
const getActiveFileInfo = () => _NativeArcsoftFace.default.getActiveFileInfo();

/** 初始化引擎（返回 0 表示成功） */
exports.getActiveFileInfo = getActiveFileInfo;
const initEngine = (options = {}) => _NativeArcsoftFace.default.initEngine(JSON.stringify(options));

/** 反初始化引擎（返回 0 表示成功） */
exports.initEngine = initEngine;
const unInitEngine = () => _NativeArcsoftFace.default.unInitEngine();

/** NV21 输入（跨平台统一输入） */
exports.unInitEngine = unInitEngine;
const detectFacesNV21 = (nv21, width, height) => _NativeArcsoftFace.default.detectFacesNV21(nv21, width, height);

/** 特征提取（NV21） */
exports.detectFacesNV21 = detectFacesNV21;
const extractFeatureNV21 = (nv21, width, height, face) => _NativeArcsoftFace.default.extractFeatureNV21(nv21, width, height, face);

/** 特征比对 */
exports.extractFeatureNV21 = extractFeatureNV21;
const compareFeature = (f1, f2) => _NativeArcsoftFace.default.compareFeature(f1, f2);

/** 年龄/性别/活体/3D角度 */
exports.compareFeature = compareFeature;
const getAgeNV21 = (nv21, width, height, faces) => _NativeArcsoftFace.default.getAgeNV21(nv21, width, height, faces);
exports.getAgeNV21 = getAgeNV21;
const getGenderNV21 = (nv21, width, height, faces) => _NativeArcsoftFace.default.getGenderNV21(nv21, width, height, faces);
exports.getGenderNV21 = getGenderNV21;
const getLivenessNV21 = (nv21, width, height, faces) => _NativeArcsoftFace.default.getLivenessNV21(nv21, width, height, faces);
exports.getLivenessNV21 = getLivenessNV21;
const getFace3DAngleNV21 = (nv21, width, height, faces) => _NativeArcsoftFace.default.getFace3DAngleNV21(nv21, width, height, faces);

/** 图片输入 (Base64) */
exports.getFace3DAngleNV21 = getFace3DAngleNV21;
const detectFacesImage = base64 => _NativeArcsoftFace.default.detectFacesImage(base64);
exports.detectFacesImage = detectFacesImage;
const extractFeatureImage = (base64, face) => _NativeArcsoftFace.default.extractFeatureImage(base64, face);
exports.extractFeatureImage = extractFeatureImage;
const getAgeImage = (base64, faces) => _NativeArcsoftFace.default.getAgeImage(base64, faces);
exports.getAgeImage = getAgeImage;
const getGenderImage = (base64, faces) => _NativeArcsoftFace.default.getGenderImage(base64, faces);
exports.getGenderImage = getGenderImage;
const getLivenessImage = (base64, faces) => _NativeArcsoftFace.default.getLivenessImage(base64, faces);
exports.getLivenessImage = getLivenessImage;
const getFace3DAngleImage = (base64, faces) => _NativeArcsoftFace.default.getFace3DAngleImage(base64, faces);

/** 人脸库 */
exports.getFace3DAngleImage = getFace3DAngleImage;
const registerFaceFeature = (id, feature) => _NativeArcsoftFace.default.registerFaceFeature(id, feature);
exports.registerFaceFeature = registerFaceFeature;
const removeFaceFeature = id => _NativeArcsoftFace.default.removeFaceFeature(id);
exports.removeFaceFeature = removeFaceFeature;
const clearAllFaceFeature = () => _NativeArcsoftFace.default.clearAllFaceFeature();
exports.clearAllFaceFeature = clearAllFaceFeature;
const getFaceCount = () => _NativeArcsoftFace.default.getFaceCount();
exports.getFaceCount = getFaceCount;
const searchFaceFeature = (feature, threshold = 0) => _NativeArcsoftFace.default.searchFaceFeature(feature, threshold);

/** 获取所有人脸列表 */
exports.searchFaceFeature = searchFaceFeature;
const getAllFaces = userId => _NativeArcsoftFace.default.getAllFaces(userId);

/**
 * 注册人脸（通过图片 URL）
 * @param userId 用户ID
 * @param imageUrl 图片地址（支持 http/https 或 file://）
 * @returns 注册结果
 */
exports.getAllFaces = getAllFaces;
const registerFaceFromUrl = async (userId, imageUrl) => {
  try {
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
      // React Native fetch supports file:// on some platforms, or use a file system library.
      // For simplicity, assuming fetch works or user provides base64 directly if not http.
      // If you use react-native-fs, you can read file directly.
      // Here we try fetch for file:// as well.
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
      return {
        success: false,
        msg: '图片数据为空'
      };
    }

    // 2. 检测人脸
    const faces = await detectFacesImage(base64);
    if (!faces || faces.length === 0) {
      return {
        success: false,
        msg: '未检测到人脸'
      };
    }

    // 3. 提取特征 (取最大的人脸，通常是第一个)
    const face = faces[0];
    const feature = await extractFeatureImage(base64, face);
    if (!feature || !feature.dataBase64) {
      return {
        success: false,
        msg: '特征提取失败'
      };
    }

    // 4. 注册/更新特征
    const success = await registerFaceFeature(userId, feature);
    if (success) {
      return {
        success: true,
        msg: '注册成功',
        userId
      };
    } else {
      return {
        success: false,
        msg: '注册失败(引擎返回false)'
      };
    }
  } catch (e) {
    return {
      success: false,
      msg: `异常: ${e.message || e}`
    };
  }
};

/**
 * 默认导出：一个与原生同名的对象（方便用户 `import ArcsoftFace from 'xxx'`）
 */
exports.registerFaceFromUrl = registerFaceFromUrl;
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

  // Frame Processor Plugin
  detectFaces
};
var _default = exports.default = ArcsoftFace;
//# sourceMappingURL=index.js.map