import { NativeModules, Platform } from 'react-native';
import type { FaceInfo, FaceFeature, FaceSearchResult } from './types';

const Native = NativeModules.ArcsoftFace;

export const ArcSoftFace = {
    /** SDK 激活 */
    activate(appId: string, sdkKey: string) {
        return Native.activate(appId, sdkKey);
    },

    /** 初始化引擎 */
    init() {
        return Native.init();
    },

    /** 释放 */
    release() {
        return Native.release();
    },

    /** 检测 + 可选属性 */
    detectNV21Base64(
        nv21Base64: string,
        width: number,
        height: number,
        options = {
            age: true,
            gender: true,
            liveness: false,
            face3d: false,
        }
    ): Promise<FaceInfo[]> {
        return Native.detect(nv21Base64, width, height, options);
    },

    /** 提取特征 */
    extractFeatureNV21Base64(
        nv21Base64: string,
        width: number,
        height: number,
        faceIndex = 0
    ): Promise<FaceFeature | null> {
        return Native.extractFeature(nv21Base64, width, height, faceIndex);
    },

    /** 特征比对 */
    compareFeature(f1: FaceFeature, f2: FaceFeature) {
        return Native.compareFeature(f1.data, f2.data);
    },

    /** 注册人脸 */
    registerFace(name: string, feature: FaceFeature) {
        return Native.registerFace(name, feature.data);
    },

    /** 删除人脸 */
    removeFace(name: string) {
        return Native.removeFace(name);
    },

    /** 搜索人脸 */
    searchFace(feature: FaceFeature, topN = 5): Promise<FaceSearchResult[]> {
        return Native.searchFace(feature.data, topN);
    },
};
