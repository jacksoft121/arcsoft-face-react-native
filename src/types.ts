export type ArcFaceInitOptions = {
  /** iOS/Android AppId from ArcSoft console */
  appId: string;
  /** iOS/Android SDK Key */
  sdkKey: string;
  /** detect mode, etc. Keep minimal for now; extend to match demo options */
  detectMode?: number;
  /** max faces */
  maxFaceNum?: number;
};

export type ArcFaceVersion = {
  version: string;
  build?: string;
};

export type FaceRect = { left: number; top: number; right: number; bottom: number };
export type DetectFaceResult = { faces: Array<{ rect: FaceRect; orient?: number; confidence?: number }> };

export type LivenessResult = { isLive: boolean; score?: number };
export type FeatureExtractResult = { featureBase64: string; length: number };
export type CompareResult = { score: number };
