import { VisionCameraProxy, type Frame } from 'react-native-vision-camera';
import ArcsoftFaceNative, {
  type FaceRect,
  type FaceInfo,
  type FaceFeature,
  type ActiveFileInfo,
} from './spec/NativeArcsoftFace';

export type { FaceRect, FaceInfo, FaceFeature, ActiveFileInfo };

// Frame Processor Plugin
const plugin = VisionCameraProxy.initFrameProcessorPlugin('detectFaces', {});

export interface DetectFacesResult {
  faces: FaceInfo[];
  imagePath?: string;
}

export interface DetectFacesOptions {
  saveImage?: boolean;
  extractFeature?: boolean;
}

export function detectFaces(frame: Frame, options?: DetectFacesOptions): DetectFacesResult {
  'worklet';
  if (plugin == null) {
      console.error("Failed to load Frame Processor Plugin 'detectFaces'!");
      return { faces: [] };
  }
  // @ts-ignore
  return plugin.call(frame, options) as DetectFacesResult;
}

export type InitEngineOptions = {
  detectMode?: 'image' | 'video';
  maxFaceNum?: number;
  scale?: number;
  enableAge?: boolean;
  enableGender?: boolean;
  enableLiveness?: boolean;
  enable3DAngle?: boolean;
};

export const setLogLevel = (level: number) => ArcsoftFaceNative.setLogLevel(level);

/** SDK 在线激活（返回 0 表示成功） */
export const activateOnline = (appId: string, sdkKey: string): Promise<number> =>
    ArcsoftFaceNative.activateOnline(appId, sdkKey);

/** 获取激活文件信息 */
export const getActiveFileInfo = (): Promise<ActiveFileInfo | null> =>
    ArcsoftFaceNative.getActiveFileInfo();

/** 初始化引擎（返回 0 表示成功） */
export const initEngine = (options: InitEngineOptions = {}): Promise<number> =>
    ArcsoftFaceNative.initEngine(JSON.stringify(options));

/** 反初始化引擎（返回 0 表示成功） */
export const unInitEngine = (): Promise<number> => ArcsoftFaceNative.unInitEngine();

/** NV21 输入（跨平台统一输入） */
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

/** 图片输入 (Base64) */
export const detectFacesImage = (base64: string): Promise<FaceInfo[]> =>
    ArcsoftFaceNative.detectFacesImage(base64);

export const extractFeatureImage = (
    base64: string,
    face: FaceInfo
): Promise<FaceFeature | null> => ArcsoftFaceNative.extractFeatureImage(base64, face);

export const getAgeImage = (base64: string, faces: FaceInfo[]): Promise<number[]> =>
    ArcsoftFaceNative.getAgeImage(base64, faces);

export const getGenderImage = (base64: string, faces: FaceInfo[]): Promise<number[]> =>
    ArcsoftFaceNative.getGenderImage(base64, faces);

export const getLivenessImage = (base64: string, faces: FaceInfo[]): Promise<number[]> =>
    ArcsoftFaceNative.getLivenessImage(base64, faces);

export const getFace3DAngleImage = (
    base64: string,
    faces: FaceInfo[]
): Promise<Array<{ roll: number; pitch: number; yaw: number }>> =>
    ArcsoftFaceNative.getFace3DAngleImage(base64, faces);

/** 人脸库 */
export const registerFaceFeature = (id: string, feature: FaceFeature): Promise<boolean> =>
    ArcsoftFaceNative.registerFaceFeature(id, feature);

export const removeFaceFeature = (id: string): Promise<boolean> => ArcsoftFaceNative.removeFaceFeature(id);

export const clearAllFaceFeature = (): Promise<void> => ArcsoftFaceNative.clearAllFaceFeature();

export const getFaceCount = (): Promise<number> => ArcsoftFaceNative.getFaceCount();

export const searchFaceFeature = (
    feature: FaceFeature,
    threshold: number = 0
): Promise<{ id: string | null; score: number }> =>
    ArcsoftFaceNative.searchFaceFeature(feature, threshold);

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
  detectFaces,
};

export default ArcsoftFace;
