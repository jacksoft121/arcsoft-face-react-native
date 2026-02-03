export type ArcFaceRect = {
    left: number;
    top: number;
    right: number;
    bottom: number;
};
export type ArcFaceProcessResult = {
    type: 'process_result';
    rect: ArcFaceRect;
    orient: number;
    score?: number;
    matchedUserId?: string;
};
export type ArcFaceRegisterResult = {
    type: 'register_result';
    userId: string;
    rect: ArcFaceRect;
    orient: number;
    featureBase64: string;
    featureSize: number;
};
export type ArcFacePluginResult = ArcFaceProcessResult | ArcFaceRegisterResult;
export type ArcFaceProcessParams = {
    action: 'process';
    threshold?: number;
};
export type ArcFaceRegisterFromFrameParams = {
    action: 'register_from_frame';
    userId: string;
};
export type ArcFacePluginParams = ArcFaceProcessParams | ArcFaceRegisterFromFrameParams;
export type ArcFaceExtractFeatureResult = {
    featureBase64: string;
    featureSize: number;
};
//# sourceMappingURL=types.d.ts.map