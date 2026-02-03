import { NativeArcFace } from './NativeArcFace';
import type {
  ArcFaceInitOptions,
  ArcFaceVersion,
  DetectFaceResult,
  LivenessResult,
  FeatureExtractResult,
  CompareResult,
} from './types';

/**
 * JS Facade: platform-neutral API surface.
 * This mirrors ArcSoft demo flows:
 * - init/active (engine init & activation)
 * - detect / liveness / extractFeature / compare
 * - release
 */
export const ArcSoftFace = {
  /** Engine init */
  init(options: ArcFaceInitOptions): Promise<boolean> {
    return NativeArcFace.init(options);
  },

  /** Optional: query SDK version */
  getVersion(): Promise<ArcFaceVersion> {
    return NativeArcFace.getVersion();
  },

  /** Face detect on a pixel buffer / image path */
  detectFaces(input: { imagePath?: string; pixelBufferId?: string }): Promise<DetectFaceResult> {
    return NativeArcFace.detectFaces(input);
  },

  /** Liveness */
  detectLiveness(input: { imagePath?: string; pixelBufferId?: string }): Promise<LivenessResult> {
    return NativeArcFace.detectLiveness(input);
  },

  /** Extract feature */
  extractFeature(input: { imagePath?: string; pixelBufferId?: string; faceIndex?: number }): Promise<FeatureExtractResult> {
    return NativeArcFace.extractFeature(input);
  },

  /** Compare features */
  compareFeatures(a: string, b: string): Promise<CompareResult> {
    return NativeArcFace.compareFeatures(a, b);
  },

  /** Release native resources */
  release(): Promise<boolean> {
    return NativeArcFace.release();
  },
};
