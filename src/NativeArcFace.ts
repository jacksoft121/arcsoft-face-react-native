import { NativeModules } from 'react-native';

type NativeArcFaceModule = {
  init(options: any): Promise<boolean>;
  getVersion(): Promise<any>;
  detectFaces(input: any): Promise<any>;
  detectLiveness(input: any): Promise<any>;
  extractFeature(input: any): Promise<any>;
  compareFeatures(a: string, b: string): Promise<any>;
  release(): Promise<boolean>;
};

export const NativeArcFace: NativeArcFaceModule =
  NativeModules.ArcsoftFaceModule ?? NativeModules.ArcSoftFace ?? NativeModules.ArcsoftFace ?? ({} as any);

if (!NativeArcFace || typeof (NativeArcFace as any).init !== 'function') {
  // eslint-disable-next-line no-console
  console.warn(
    '[arcsoft-face-react-native] Native module not found. Did you run pod install / gradle sync and rebuild the app?',
  );
}
