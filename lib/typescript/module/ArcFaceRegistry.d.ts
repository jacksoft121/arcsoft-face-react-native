import type { ArcFaceExtractFeatureResult } from './types';
export declare const ArcFaceRegistry: {
    /** 启动/进入识别页：加载本地持久化库到 Native 内存（离线可用） */
    loadAll: () => Promise<boolean>;
    /** 写入/更新特征（Native: 内存 + debounce 持久化） */
    upsert: (userId: string, featureBase64: string, featureSize: number) => Promise<void>;
    remove: (userId: string) => Promise<void>;
    clear: () => Promise<void>;
    /**
     * 注册B：从图片路径提特征，然后写入 registry
     * 注意：Android 如果是 content:// 需要 native 端用 ContentResolver 支持（否则会失败）
     */
    registerFromImage: (userId: string, imagePath: string) => Promise<ArcFaceExtractFeatureResult>;
};
//# sourceMappingURL=ArcFaceRegistry.d.ts.map