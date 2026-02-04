import ArcsoftFaceNative from './spec/NativeArcsoftFace';
/** SDK 在线激活（返回 0 表示成功） */
export const activateOnline = (appId, sdkKey) => ArcsoftFaceNative.activateOnline(appId, sdkKey);

/** 初始化引擎（返回 0 表示成功） */
export const initEngine = (options = {}) => ArcsoftFaceNative.initEngine(options);

/** 反初始化引擎（返回 0 表示成功） */
export const unInitEngine = () => ArcsoftFaceNative.unInitEngine();

/** 人脸检测（NV21） */
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

/** 人脸库 */
export const faceDBAdd = (id, feature) => ArcsoftFaceNative.faceDBAdd(id, feature);
export const faceDBRemove = id => ArcsoftFaceNative.faceDBRemove(id);
export const faceDBClear = () => ArcsoftFaceNative.faceDBClear();
export const faceDBCount = () => ArcsoftFaceNative.faceDBCount();
export const faceDBSearch = (feature, threshold = 0) => ArcsoftFaceNative.faceDBSearch(feature, threshold);

/**
 * 默认导出：一个与原生同名的对象（方便用户 `import ArcsoftFace from 'xxx'`）
 */
const ArcsoftFace = {
  activateOnline,
  initEngine,
  unInitEngine,
  detectFacesNV21,
  extractFeatureNV21,
  compareFeature,
  getAgeNV21,
  getGenderNV21,
  getLivenessNV21,
  getFace3DAngleNV21,
  faceDBAdd,
  faceDBRemove,
  faceDBClear,
  faceDBCount,
  faceDBSearch
};
export default ArcsoftFace;
//# sourceMappingURL=index.js.map