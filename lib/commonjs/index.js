"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = exports.compareFeature = exports.activateOnline = void 0;
exports.detectFaces = detectFaces;
exports.unInitEngine = exports.setLogLevel = exports.initEngine = exports.getLivenessNV21 = exports.getLivenessImage = exports.getGenderNV21 = exports.getGenderImage = exports.getFace3DAngleNV21 = exports.getFace3DAngleImage = exports.getAgeNV21 = exports.getAgeImage = exports.getActiveFileInfo = exports.faceDBSearch = exports.faceDBRemove = exports.faceDBCount = exports.faceDBClear = exports.faceDBAdd = exports.extractFeatureNV21 = exports.extractFeatureImage = exports.detectFacesNV21 = exports.detectFacesImage = void 0;
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
const faceDBAdd = (id, feature) => _NativeArcsoftFace.default.faceDBAdd(id, feature);
exports.faceDBAdd = faceDBAdd;
const faceDBRemove = id => _NativeArcsoftFace.default.faceDBRemove(id);
exports.faceDBRemove = faceDBRemove;
const faceDBClear = () => _NativeArcsoftFace.default.faceDBClear();
exports.faceDBClear = faceDBClear;
const faceDBCount = () => _NativeArcsoftFace.default.faceDBCount();
exports.faceDBCount = faceDBCount;
const faceDBSearch = (feature, threshold = 0) => _NativeArcsoftFace.default.faceDBSearch(feature, threshold);

/**
 * 默认导出：一个与原生同名的对象（方便用户 `import ArcsoftFace from 'xxx'`）
 */
exports.faceDBSearch = faceDBSearch;
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
  faceDBAdd,
  faceDBRemove,
  faceDBClear,
  faceDBCount,
  faceDBSearch,
  // Frame Processor Plugin
  detectFaces
};
var _default = exports.default = ArcsoftFace;
//# sourceMappingURL=index.js.map