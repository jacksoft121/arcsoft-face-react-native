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
    score?: number; // 0~1
    matchedUserId?: string; // 命中注册库 userId
};

export type ArcFaceRegisterResult = {
    type: 'register_result';
    userId: string;
    rect: ArcFaceRect;
    orient: number;
    featureBase64: string;
    featureSize: number; // 1032 / 2056
};

export type ArcFacePluginResult = ArcFaceProcessResult | ArcFaceRegisterResult;

export type ArcFaceProcessParams = {
    action: 'process';
    threshold?: number; // compare threshold, default 0.8
};

export type ArcFaceRegisterFromFrameParams = {
    action: 'register_from_frame';
    userId: string;
};

export type ArcFacePluginParams = ArcFaceProcessParams | ArcFaceRegisterFromFrameParams;

// NativeModule (register B + registry)
export type ArcFaceExtractFeatureResult = {
    featureBase64: string;
    featureSize: number;
};
