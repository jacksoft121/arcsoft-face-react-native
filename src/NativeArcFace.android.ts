import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export type DetectMode = 'video' | 'image';

export type InitOptions = {
  detectMode?: DetectMode;
  orientPriority?: number; // 0/90/180/270 priority
  scale?: number;
  maxFaceNum?: number;
};

export type FaceRect = { left: number; top: number; right: number; bottom: number };

export type FaceInfo = {
  rect: FaceRect;
  orient: number;
};

export type ImageFormat = 'NV21' | 'BGR24' | 'RGB24' | 'RGBA';

export interface Spec extends TurboModule {
  /** Online activation. Returns ArcSoft error code (0 means success). */
  activateOnline(appId: string, sdkKey: string): Promise<number>;

  /** Init engines (detect/recognize). Returns true if success. */
  init(options?: InitOptions): Promise<boolean>;

  /** Uninit engines. */
  unInit(): Promise<void>;

  /** Get SDK version string. */
  getVersion(): Promise<string>;

  /** Detect faces from a base64 image buffer (NV21 recommended). */
  detectFacesBase64(
    imageBase64: string,
    width: number,
    height: number,
    format: ImageFormat,
    cameraOrient: number
  ): Promise<FaceInfo[]>;

  /** Extract feature as base64 from last-detected faces. */
  extractFeatureFromLastDetect(faceIndex: number): Promise<string>;

  /** Compare two features (both base64). Returns similarity (0~1). */
  compareFeaturesBase64(feature1: string, feature2: string): Promise<number>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('ArcsoftFace');
