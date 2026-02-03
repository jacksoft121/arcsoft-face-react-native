import NativeArcFace, {
  type InitConfig,
  type ImageData,
  type FaceInfo,
  type ProcessMask,
  type Feature,
} from './NativeArcFace';

export const ArcSoftFace = {
  init: (config: InitConfig) => NativeArcFace.init(config),
  unInit: () => NativeArcFace.unInit(),
  getVersion: () => NativeArcFace.getVersion(),

  detectFaces: (image: ImageData) => NativeArcFace.detectFaces(image),

  process: (image: ImageData, faces: FaceInfo[], mask: ProcessMask) =>
    NativeArcFace.process(image, faces, mask),

  setLivenessThreshold: (threshold: number) => NativeArcFace.setLivenessThreshold(threshold),
  getLivenessThreshold: () => NativeArcFace.getLivenessThreshold(),

  extractFeature: (image: ImageData, face: FaceInfo) => NativeArcFace.extractFeature(image, face),

  compareFeature: (feature1: Feature, feature2: Feature, compareModel?: number) =>
    NativeArcFace.compareFeature(feature1, feature2, compareModel),

  detectLivenessInteractive: (image: ImageData, face: FaceInfo, action: number, reset: number) =>
    NativeArcFace.detectLivenessInteractive(image, face, action, reset),

  detectLivenessGlare: (
    image: ImageData,
    face: FaceInfo,
    flashSequenceMode: number,
    flashColor: number,
    reset: number,
  ) => NativeArcFace.detectLivenessGlare(image, face, flashSequenceMode, flashColor, reset),
};

export * from './NativeArcFace';
export default ArcSoftFace;
