import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export type FaceRect = {
  left: number;
  top: number;
  right: number;
  bottom: number;
};

export type FaceInfo = {
  rect: FaceRect;
  orient: number;
};

export type FaceFeature = {
  /** raw feature bytes, base64 encoded */
  dataBase64: string;
};

export interface Spec extends TurboModule {
  /**
   * SDK 激活/注册
   * Android: FaceEngine.activeOnline
   * iOS: 按官方 Demo（Online Activation）
   */
  activateOnline(appId: string, sdkKey: string): Promise<number>;

  /**
   * 初始化引擎（检测/识别/年龄/性别/活体/3D角度等能力开关）
   * 返回 0 表示成功
   */
  initEngine(options?: {
    detectMode?: 'image' | 'video';
    maxFaceNum?: number;
    scale?: number;
    enableAge?: boolean;
    enableGender?: boolean;
    enableLiveness?: boolean;
    enable3DAngle?: boolean;
  }): Promise<number>;

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

  /** 人脸库（JS 侧 id -> 原生侧特征映射） */
  faceDBAdd(id: string, feature: FaceFeature): Promise<boolean>;
  faceDBRemove(id: string): Promise<boolean>;
  faceDBClear(): Promise<void>;
  faceDBCount(): Promise<number>;
  faceDBSearch(
    feature: FaceFeature,
    threshold?: number
  ): Promise<{ id: string | null; score: number }>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('ArcsoftFace');
