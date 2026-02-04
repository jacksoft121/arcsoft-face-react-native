import ArcsoftFaceNative, {
  type FaceRect,
  type FaceInfo,
  type FaceFeature,
} from './spec/NativeArcsoftFace';

export type { FaceRect, FaceInfo, FaceFeature };

export type InitEngineOptions = {
  detectMode?: 'image' | 'video';
  maxFaceNum?: number;
  scale?: number;
  enableAge?: boolean;
  enableGender?: boolean;
  enableLiveness?: boolean;
  enable3DAngle?: boolean;
};

/** SDK 在线激活（返回 0 表示成功） */
export const activateOnline = (appId: string, sdkKey: string): Promise<number> =>
    ArcsoftFaceNative.activateOnline(appId, sdkKey);

/** 初始化引擎（返回 0 表示成功） */
export const initEngine = (options: InitEngineOptions = {}): Promise<number> =>
    ArcsoftFaceNative.initEngine(options);

/** 反初始化引擎（返回 0 表示成功） */
export const unInitEngine = (): Promise<number> => ArcsoftFaceNative.unInitEngine();

/** 人脸检测（NV21） */
export const detectFacesNV21 = (
    nv21: number[],
    width: number,
    height: number
): Promise<FaceInfo[]> => ArcsoftFaceNative.detectFacesNV21(nv21, width, height);

/** 特征提取（NV21） */
export const extractFeatureNV21 = (
    nv21: number[],
    width: number,
    height: number,
    face: FaceInfo
): Promise<FaceFeature | null> => ArcsoftFaceNative.extractFeatureNV21(nv21, width, height, face);

/** 特征比对 */
export const compareFeature = (f1: FaceFeature, f2: FaceFeature): Promise<number> =>
    ArcsoftFaceNative.compareFeature(f1, f2);

/** 年龄/性别/活体/3D角度 */
export const getAgeNV21 = (
    nv21: number[],
    width: number,
    height: number,
    faces: FaceInfo[]
): Promise<number[]> => ArcsoftFaceNative.getAgeNV21(nv21, width, height, faces);

export const getGenderNV21 = (
    nv21: number[],
    width: number,
    height: number,
    faces: FaceInfo[]
): Promise<number[]> => ArcsoftFaceNative.getGenderNV21(nv21, width, height, faces);

export const getLivenessNV21 = (
    nv21: number[],
    width: number,
    height: number,
    faces: FaceInfo[]
): Promise<number[]> => ArcsoftFaceNative.getLivenessNV21(nv21, width, height, faces);

export const getFace3DAngleNV21 = (
    nv21: number[],
    width: number,
    height: number,
    faces: FaceInfo[]
): Promise<Array<{ roll: number; pitch: number; yaw: number }>> =>
    ArcsoftFaceNative.getFace3DAngleNV21(nv21, width, height, faces);

/** 人脸库 */
export const faceDBAdd = (id: string, feature: FaceFeature): Promise<boolean> =>
    ArcsoftFaceNative.faceDBAdd(id, feature);

export const faceDBRemove = (id: string): Promise<boolean> => ArcsoftFaceNative.faceDBRemove(id);

export const faceDBClear = (): Promise<void> => ArcsoftFaceNative.faceDBClear();

export const faceDBCount = (): Promise<number> => ArcsoftFaceNative.faceDBCount();

export const faceDBSearch = (
    feature: FaceFeature,
    threshold: number = 0
): Promise<{ id: string | null; score: number }> =>
    ArcsoftFaceNative.faceDBSearch(feature, threshold);

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
  faceDBSearch,
};

export default ArcsoftFace;
