import { NativeModules, Platform } from 'react-native';

export type ActivateOptions = {
  appId: string;
  sdkKey: string;
};

export type InitEngineOptions = {
  /** Android 使用固定 DetectMode/Orient；iOS 可选，默认与官方 Demo 一致 */
  detectMode?: number; // iOS: ASF_DETECT_MODE_IMAGE
  orientPriority?: number; // iOS: ASF_OP_0_ONLY
  scale?: number; // iOS: 16
  maxFaceNum?: number; // Android/iOS: 10
  combinedMask?: number; // iOS: 功能组合掩码（可选）
};

type NativeArcSoftFace = {
  activate: (appId: string, sdkKey: string) => Promise<boolean>;
  init: () => Promise<boolean>;
  initEngine?: (opt: InitEngineOptions) => Promise<boolean>; // iOS
  release: () => void;
  getVersion?: () => Promise<any>;

  detectBase64: (nv21Base64: string, width: number, height: number) => Promise<number>;
  extractFeatureBase64: (nv21Base64: string, width: number, height: number) => Promise<string | null>;
  compareFeatureBase64: (feature1Base64: string, feature2Base64: string) => Promise<number>;
  compareBase64: (imgA: string, imgB: string, width: number, height: number) => Promise<number>;
};

const Native: NativeArcSoftFace = (NativeModules as any).ArcsoftFace;

if (!Native) {
  throw new Error(
    '[arcsoft-face-react-native] NativeModules.ArcsoftFace not found. ' +
      'Did you run pod install / rebuild the app?',
  );
}

/**
 * ✅ 跨平台统一入口
 *
 * - Android：FaceEngine.activeOnline + FaceEngine.init(5参)
 * - iOS：ArcSoftFaceEngine activeWithAppId/SDKKey + initWithDetectMode
 */
export const ArcsoftFace = {
  /** SDK 注册/激活（必须先调用一次） */
  async activate(opt: ActivateOptions) {
    return Native.activate(opt.appId, opt.sdkKey);
  },

  /** 初始化引擎（Android 固定参数；iOS 支持可选 initEngine） */
  async init(opt?: InitEngineOptions) {
    if (Platform.OS === 'ios' && Native.initEngine && opt) {
      return Native.initEngine(opt);
    }
    return Native.init();
  },

  release() {
    Native.release();
  },

  async detectNV21Base64(nv21Base64: string, width: number, height: number) {
    return Native.detectBase64(nv21Base64, width, height);
  },

  async extractFeatureNV21Base64(nv21Base64: string, width: number, height: number) {
    return Native.extractFeatureBase64(nv21Base64, width, height);
  },

  async compareFeatures(feature1Base64: string, feature2Base64: string) {
    return Native.compareFeatureBase64(feature1Base64, feature2Base64);
  },

  /** 便捷：两张 NV21 图直接比对（取第一张脸） */
  async compareNV21Base64(imgA: string, imgB: string, width: number, height: number) {
    return Native.compareBase64(imgA, imgB, width, height);
  },

  async getVersion() {
    if (Native.getVersion) return Native.getVersion();
    return null;
  },
};

export default ArcsoftFace;
