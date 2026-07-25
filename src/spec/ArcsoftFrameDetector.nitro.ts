import type { HybridObject } from "react-native-nitro-modules";
import type { Frame } from "react-native-vision-camera";

export interface ArcsoftFrameRect {
  left: number;
  top: number;
  right: number;
  bottom: number;
}

/** ArcSoft VIDEO 检测随人脸返回的真实三维姿态角，单位为度。 */
export interface ArcsoftFrameAngle {
  yaw: number;
  pitch: number;
  roll: number;
  valid: boolean;
}

export interface ArcsoftDetectedFace {
  rect: ArcsoftFrameRect;
  orient: number;
  faceId: number;
  angle?: ArcsoftFrameAngle;
  featureBase64?: string;
  userId?: string;
  score?: number;
}

export interface ArcsoftDetectFacesOptions {
  saveImage?: boolean;
  captureUserIds?: string;
  extractFeature?: boolean;
  retExtractFeatureBase64?: boolean;
  score?: number;
  maxRetryCount?: number;
}

export interface ArcsoftDetectFacesResult {
  faces: ArcsoftDetectedFace[];
  imagePath?: string;
}

export interface ArcsoftFrameDetector extends HybridObject<{
  android: "kotlin";
  ios: "swift";
}> {
  detectFaces(
    frame: Frame,
    options: ArcsoftDetectFacesOptions,
  ): ArcsoftDetectFacesResult;
}
