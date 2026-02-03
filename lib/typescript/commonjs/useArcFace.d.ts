import type { ArcFaceProcessResult } from './types';
type UseArcFaceOptions = {
    threshold?: number;
    onResult?: (res: ArcFaceProcessResult) => void;
    onRegisteredFromFrame?: (userId: string) => void;
};
export declare function useArcFace(options?: UseArcFaceOptions): {
    frameProcessor: import("react-native-vision-camera").ReadonlyFrameProcessor;
    requestRegisterFromFrame: (userId: string) => void;
};
export {};
//# sourceMappingURL=useArcFace.d.ts.map