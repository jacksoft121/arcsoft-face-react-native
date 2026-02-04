import { Platform } from 'react-native';
import NativeArcsoftFace, { type FaceFeature, type FaceInfo } from './spec/NativeArcsoftFace';

export type ImageFormat = 'NV21' | 'NV12' | 'BGR24' | 'RGB24' | 'RGBA' | 'BGRA';

export type DetectResult = {
  faces: FaceInfo[];
};

export type AttrResult = {
  /** 年龄(如启用) */
  ages?: number[];
  /** 性别: 0未知 1男 2女 */
  genders?: number[];
  /** 3D角度: yaw/pitch/roll */
  angles?: { yaw: number; pitch: number; roll: number }[];
  /** 活体: 0未知 1真人 2假体 */
  liveness?: number[];
};

function u8ToNumberArray(u8: Uint8Array): number[] {
  // RN Bridge 只能稳定传 number[] (0-255). TurboModule 未来可优化为 ArrayBuffer.
  const out = new Array(u8.length);
  for (let i = 0; i < u8.length; i++) out[i] = u8[i];
  return out;
}

export const ArcsoftFace = {
  /** SDK 在线激活（Android: activeOnline / iOS: ASFOnlineActivation/ASFActivation） */
  async activateOnline(appId: string, sdkKey: string): Promise<boolean> {
    return NativeArcsoftFace.activateOnline(appId, sdkKey);
  },

  /** 引擎初始化（detect + recognize + attrs） */
  async initEngine(options?: {
    detectMode?: 'image' | 'video';
    orientPriority?: number;
    scale?: number;
    maxFaceNum?: number;
    enableAge?: boolean;
    enableGender?: boolean;
    enableLiveness?: boolean;
    enable3DAngle?: boolean;
  }): Promise<boolean> {
    return NativeArcsoftFace.initEngine(options ?? {});
  },

  async releaseEngine(): Promise<void> {
    return NativeArcsoftFace.releaseEngine();
  },

  /**
   * 人脸检测
   * - Android: NV21 必须
   * - iOS: 推荐传 NV12/NV21（从 CVPixelBuffer 转）
   */
  async detect(input: {
    data: Uint8Array;
    width: number;
    height: number;
    format: ImageFormat;
  }): Promise<DetectResult> {
    const faces = await NativeArcsoftFace.detect(u8ToNumberArray(input.data), input.width, input.height, input.format);
    return { faces };
  },

  /** 提取特征（默认第 faceIndex 张脸） */
  async extractFeature(input: {
    data: Uint8Array;
    width: number;
    height: number;
    format: ImageFormat;
    faceIndex?: number;
  }): Promise<FaceFeature | null> {
    return NativeArcsoftFace.extractFeature(
      u8ToNumberArray(input.data),
      input.width,
      input.height,
      input.format,
      input.faceIndex ?? 0,
    );
  },

  /** 特征比对 */
  async compareFeature(f1: FaceFeature, f2: FaceFeature): Promise<number> {
    return NativeArcsoftFace.compareFeature(f1, f2);
  },

  /** 年龄/性别/活体/3D角度（按 detect 返回的人脸顺序输出） */
  async getAttributes(input: {
    data: Uint8Array;
    width: number;
    height: number;
    format: ImageFormat;
  }): Promise<AttrResult> {
    return NativeArcsoftFace.getAttributes(u8ToNumberArray(input.data), input.width, input.height, input.format);
  },

  /** 人脸库 */
  async faceDBAdd(id: string, feature: FaceFeature): Promise<boolean> {
    return NativeArcsoftFace.faceDBAdd(id, feature);
  },
  async faceDBRemove(id: string): Promise<boolean> {
    return NativeArcsoftFace.faceDBRemove(id, feature);
  },
  async faceDBClear(): Promise<void> {
    return NativeArcsoftFace.faceDBClear();
  },
  async faceDBCount(): Promise<number> {
    return NativeArcsoftFace.faceDBCount();
  },
  async faceDBSearch(feature: FaceFeature, threshold = 0.6): Promise<{ id: string | null; score: number }> {
    return NativeArcsoftFace.faceDBSearch(feature, threshold);
  },
};

export type { FaceFeature, FaceInfo };
export default ArcsoftFace;
