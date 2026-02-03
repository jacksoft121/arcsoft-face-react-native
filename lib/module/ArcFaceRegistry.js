"use strict";

import { NativeModules, Platform } from 'react-native';
const Native = NativeModules.ArcFaceModule;
function getNative() {
  if (!Native) {
    throw new Error(`[arcsoft-face-react-native] Native module "ArcFaceModule" not found. ` + `Make sure the library is linked and rebuild the app. Platform=${Platform.OS}`);
  }
  return Native;
}
function normalizeImagePath(p) {
  // iOS/Android: file://...
  if (p.startsWith('file://')) return p.slice('file://'.length);
  return p;
}
export const ArcFaceRegistry = {
  /** 启动/进入识别页：加载本地持久化库到 Native 内存（离线可用） */
  loadAll: async () => {
    try {
      await getNative().registryLoadAll();
      return true;
    } catch {
      return false;
    }
  },
  /** 写入/更新特征（Native: 内存 + debounce 持久化） */
  upsert: async (userId, featureBase64, featureSize) => {
    await getNative().registryUpsert(userId, featureBase64, featureSize);
  },
  remove: async userId => {
    await getNative().registryRemove(userId);
  },
  clear: async () => {
    await getNative().registryClear();
  },
  /**
   * 注册B：从图片路径提特征，然后写入 registry
   * 注意：Android 如果是 content:// 需要 native 端用 ContentResolver 支持（否则会失败）
   */
  registerFromImage: async (userId, imagePath) => {
    const path = normalizeImagePath(imagePath);
    const feat = await getNative().extractFeatureFromImage(path);
    await getNative().registryUpsert(userId, feat.featureBase64, feat.featureSize);
    return feat;
  }
};
//# sourceMappingURL=ArcFaceRegistry.js.map