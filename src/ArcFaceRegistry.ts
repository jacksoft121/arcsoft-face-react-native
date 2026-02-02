import { NativeModules } from 'react-native';
import type { ArcFaceExtractFeatureResult } from './types';

const Native = NativeModules.ArcFaceModule as {
    extractFeatureFromImage(path: string): Promise<ArcFaceExtractFeatureResult>;
    registryLoadAll(): Promise<void>;
    registryUpsert(userId: string, featureBase64: string, featureSize: number): Promise<void>;
    registryRemove(userId: string): Promise<void>;
    registryClear(): Promise<void>;
};

export const ArcFaceRegistry = {
    /** 启动/进入识别页：加载本地持久化库到 Native 内存 */
    loadAll: async () => {
        await Native.registryLoadAll();
    },

    /** 写入/更新特征（会触发 Native debounce 持久化） */
    upsert: async (userId: string, featureBase64: string, featureSize: number) => {
        await Native.registryUpsert(userId, featureBase64, featureSize);
    },

    remove: async (userId: string) => {
        await Native.registryRemove(userId);
    },

    clear: async () => {
        await Native.registryClear();
    },

    /**
     * 注册B：从图片路径提特征，然后写入 registry
     */
    registerFromImage: async (userId: string, imagePath: string) => {
        const feat = await Native.extractFeatureFromImage(imagePath);
        await Native.registryUpsert(userId, feat.featureBase64, feat.featureSize);
        return feat;
    },
};
