import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export type ImageFormat =
  | 'ASF_IMAGE_FORMAT_BGR24'
  | 'ASF_IMAGE_FORMAT_BGRA32'
  | 'ASF_IMAGE_FORMAT_GRAY'
  | 'ASF_IMAGE_FORMAT_NV21';

export type DetectMode = 'ASF_DETECT_MODE_IMAGE' | 'ASF_DETECT_MODE_VIDEO';

export type OrientationPriority =
  | 'ASF_OP_0_ONLY'
  | 'ASF_OP_90_ONLY'
  | 'ASF_OP_270_ONLY'
  | 'ASF_OP_180_ONLY'
  | 'ASF_OP_0_HIGHER_EXT'
  | 'ASF_OP_90_HIGHER_EXT'
  | 'ASF_OP_270_HIGHER_EXT'
  | 'ASF_OP_180_HIGHER_EXT';

export type InitConfig = {
  appId: string;
  sdkKey: string;
  detectMode?: DetectMode;
  orientationPriority?: OrientationPriority;
  scale?: number; // 2~32
  maxFaceNum?: number; // 1~50
  combinedMask?: number; // ASF_FACE_DETECT | ASF_FACERECOGNITION | ASF_AGE | ASF_GENDER | ASF_FACE3DANGLE | ASF_LIVENESS
};

export type ImageData = {
  width: number;
  height: number;
  format: ImageFormat;
  base64: string; // RAW bytes in base64 (NOT JPEG)
};

export type FaceRect = { left: number; top: number; right: number; bottom: number };

export type FaceInfo = {
  rect: FaceRect;
  orient: number;
};

export type DetectResult = {
  faces: FaceInfo[];
};

export type ProcessMask = {
  age?: boolean;
  gender?: boolean;
  face3dAngle?: boolean;
  liveness?: boolean;
};

export type ProcessResult = {
  ages?: number[];
  genders?: number[]; // 0=male,1=female
  livenessScores?: number[]; // 0~1
  face3dAngles?: { pitch: number; roll: number; yaw: number; status: number }[];
};

export type Feature = {
  base64: string;
  size: number;
};

export type LivenessInteractiveResult = {
  result: number;
  action: number;
  status: number;
};

export interface Spec extends TurboModule {
  init(config: InitConfig): Promise<number>;
  unInit(): Promise<number>;
  getVersion(): Promise<string>;

  detectFaces(image: ImageData): Promise<DetectResult>;

  process(image: ImageData, faces: FaceInfo[], mask: ProcessMask): Promise<ProcessResult>;

  setLivenessThreshold(threshold: number): Promise<number>;
  getLivenessThreshold(): Promise<number>;

  extractFeature(image: ImageData, face: FaceInfo): Promise<Feature>;
  compareFeature(feature1: Feature, feature2: Feature, compareModel?: number): Promise<number>;

  detectLivenessInteractive(
    image: ImageData,
    face: FaceInfo,
    action: number,
    reset: number,
  ): Promise<LivenessInteractiveResult>;

  detectLivenessGlare(
    image: ImageData,
    face: FaceInfo,
    flashSequenceMode: number,
    flashColor: number,
    reset: number,
  ): Promise<LivenessInteractiveResult>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('ArcSoftFace');
