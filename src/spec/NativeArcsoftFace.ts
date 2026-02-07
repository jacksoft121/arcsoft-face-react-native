import { NativeModules } from 'react-native';

export type FaceRect = {
  left: number;
  top: number;
  right: number;
  bottom: number;
};

export type FaceInfo = {
  rect: FaceRect;
  orient: number;
  /** Internal face data (Base64), required for feature extraction */
  faceDataBase64?: string;
  /** Face ID (if available) */
  faceId?: number;
  /** Extracted Feature (Base64), if extractFeature is enabled in FrameProcessor */
  featureBase64?: string;
  /** Matched User ID from FaceDB (if extractFeature is enabled and match found) */
  userId?: string;
  /** Match Score (if extractFeature is enabled and match found) */
  score?: number;
};

export type FaceFeature = {
  /** raw feature bytes, base64 encoded */
  dataBase64: string;
};

export type ActiveFileInfo = {
  appId: string;
  sdkKey: string;
  platform: string;
  sdkVersion: string;
  fileVersion: string;
  expireTime: string;
  deviceFingerprint: string;
};

export interface Spec {
  /**
   * SDK 激活/注册
   * Android: FaceEngine.activeOnline
   * iOS: 按官方 Demo（Online Activation）
   */
  activateOnline(appId: string, sdkKey: string): Promise<number>;

  /**
   * 获取激活文件信息
   */
  getActiveFileInfo(): Promise<ActiveFileInfo | null>;

  /**
   * 初始化引擎
   * optionsJson: JSON string of { detectMode, maxFaceNum, ... }
   */
  initEngine(optionsJson: string): Promise<number>;

  /** 反初始化引擎，返回 0 表示成功 */
  unInitEngine(): Promise<number>;

  /** NV21 输入（跨平台统一输入） */
  detectFacesNV21(nv21: number[], width: number, height: number): Promise<FaceInfo[]>;

  extractFeatureNV21(
    nv21: number[],
    width: number,
    height: number,
    face: FaceInfo
  ): Promise<FaceFeature | null>;

  /** 特征比对，返回相似度分数（0~1 或 0~100，取决于原生实现） */
  compareFeature(f1: FaceFeature, f2: FaceFeature): Promise<number>;

  /** 年龄/性别/活体/3D角度（若未开启相关能力，返回空数组） */
  getAgeNV21(nv21: number[], width: number, height: number, faces: FaceInfo[]): Promise<number[]>;
  getGenderNV21(nv21: number[], width: number, height: number, faces: FaceInfo[]): Promise<number[]>;
  getLivenessNV21(nv21: number[], width: number, height: number, faces: FaceInfo[]): Promise<number[]>;
  getFace3DAngleNV21(
    nv21: number[],
    width: number,
    height: number,
    faces: FaceInfo[]
  ): Promise<Array<{ roll: number; pitch: number; yaw: number }>>;

  /** 图片输入 (Base64) */
  detectFacesImage(base64: string): Promise<FaceInfo[]>;
  extractFeatureImage(base64: string, face: FaceInfo): Promise<FaceFeature | null>;
  getAgeImage(base64: string, faces: FaceInfo[]): Promise<number[]>;
  getGenderImage(base64: string, faces: FaceInfo[]): Promise<number[]>;
  getLivenessImage(base64: string, faces: FaceInfo[]): Promise<number[]>;
  getFace3DAngleImage(
    base64: string,
    faces: FaceInfo[]
  ): Promise<Array<{ roll: number; pitch: number; yaw: number }>>;

  /** 人脸库（JS 侧 id -> 原生侧特征映射） */
  registerFaceFeature(id: string, feature: FaceFeature): Promise<boolean>;
  removeFaceFeature(id: string): Promise<boolean>;
  clearAllFaceFeature(): Promise<void>;
  getFaceCount(): Promise<number>;
  searchFaceFeature(
    feature: FaceFeature,
    threshold?: number
  ): Promise<{ id: string | null; score: number }>;
  setLogLevel(level: number): Promise<boolean>;
}

const { ArcsoftFace } = NativeModules;
export default ArcsoftFace as Spec;
