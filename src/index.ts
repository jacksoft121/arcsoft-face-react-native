import ArcsoftFaceNative, {
  type FaceFeature,
  type FaceInfo,
  type ActiveFileInfo,
} from './spec/NativeArcsoftFace';

/**
 * ✅ JS/TS 统一入口（iOS/Android 同一套 API）
 * - 直接对齐 TurboModule Spec（./spec/NativeArcsoftFace.ts）
 * - 不做平台分支：native 侧保证同名方法均实现
 */

export type { FaceFeature, FaceInfo, ActiveFileInfo };

/** ---------- SDK 激活/信息 ---------- */
export const activateOnline = (appId: string, sdkKey: string): Promise<number> =>
  ArcsoftFaceNative.activateOnline(appId, sdkKey);

export const getActiveFileInfo = (): Promise<ActiveFileInfo> =>
  ArcsoftFaceNative.getActiveFileInfo();

/** ---------- 引擎生命周期 ---------- */
/**
 * combinedMask 建议：
 *  - FaceEngine.ASF_FACE_DETECT (1)
 *  - FaceEngine.ASF_FACE_RECOGNITION (4)
 *  - FaceEngine.ASF_AGE (8)
 *  - FaceEngine.ASF_GENDER (16)
 *  - FaceEngine.ASF_LIVENESS (128)
 * 按需 OR 起来传入即可
 */
export const initEngine = (combinedMask: number): Promise<number> =>
  ArcsoftFaceNative.initEngine(combinedMask);

export const unInitEngine = (): Promise<number> => ArcsoftFaceNative.unInitEngine();

/** ---------- 基础能力（NV21） ---------- */
export const detectFacesNV21 = (
  nv21: number[],
  width: number,
  height: number
): Promise<FaceInfo[]> => ArcsoftFaceNative.detectFacesNV21(nv21, width, height);

export const extractFaceFeatureNV21 = (
  nv21: number[],
  width: number,
  height: number,
  face: FaceInfo
): Promise<FaceFeature> => ArcsoftFaceNative.extractFaceFeatureNV21(nv21, width, height, face);

export const compareFaceFeature = (
  featureA: FaceFeature,
  featureB: FaceFeature
): Promise<number> => ArcsoftFaceNative.compareFaceFeature(featureA, featureB);

/**
 * 对已检测的人脸做 process，返回错误码（0=OK）
 * 注意：必须先 initEngine 时包含相应 combinedMask（AGE/GENDER/LIVENESS 等），否则后续 getX 会失败/无结果
 */
export const processNV21 = (
  nv21: number[],
  width: number,
  height: number,
  faces: FaceInfo[],
  combinedMask: number
): Promise<number> => ArcsoftFaceNative.processNV21(nv21, width, height, faces, combinedMask);

/** ---------- 属性（需先 processNV21） ---------- */
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

/** ---------- 人脸库（纯 JS API，native 内存库实现） ---------- */
export const faceDBAdd = (id: string, feature: FaceFeature): Promise<boolean> =>
  ArcsoftFaceNative.faceDBAdd(id, feature);

export const faceDBRemove = (id: string): Promise<boolean> =>
  ArcsoftFaceNative.faceDBRemove(id);

export const faceDBClear = (): Promise<void> => ArcsoftFaceNative.faceDBClear();

export const faceDBCount = (): Promise<number> => ArcsoftFaceNative.faceDBCount();

export const faceDBSearch = (
  feature: FaceFeature,
  threshold: number = 0.6
): Promise<{ id: string | null; score: number }> => ArcsoftFaceNative.faceDBSearch(feature, threshold);

/** ---------- 组合便捷方法（可选） ---------- */
/**
 * 检测 + 提取首张人脸特征（没检测到返回 null）
 */
export const detectAndExtractFirstFeatureNV21 = async (
  nv21: number[],
  width: number,
  height: number
): Promise<FaceFeature | null> => {
  const faces = await detectFacesNV21(nv21, width, height);
  if (!faces || faces.length === 0) return null;
  return extractFaceFeatureNV21(nv21, width, height, faces[0]);
};
