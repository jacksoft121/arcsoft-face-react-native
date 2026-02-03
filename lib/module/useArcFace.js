"use strict";

import { useEffect, useRef } from 'react';
import { useFrameProcessor } from 'react-native-vision-camera';
import { useRunOnJS } from 'react-native-worklets-core';
import { arcFace } from "./arcFacePlugin.js";
import { ArcFaceRegistry } from "./ArcFaceRegistry.js";
export function useArcFace(options = {}) {
  const threshold = options.threshold ?? 0.8;
  const pendingRegisterUserIdRef = useRef(null);

  // 从 worklet 回 JS
  const onResultJS = useRunOnJS(res => {
    options.onResult?.(res);
  }, [options.onResult]);
  const onRegisteredJS = useRunOnJS(async (userId, featureBase64, featureSize) => {
    await ArcFaceRegistry.upsert(userId, featureBase64, featureSize);
    options.onRegisteredFromFrame?.(userId);
  }, [options.onRegisteredFromFrame]);

  // 进入识别页：加载 registry 到 native 内存（离线）
  useEffect(() => {
    ArcFaceRegistry.loadAll().catch(() => {});
  }, []);
  const requestRegisterFromFrame = userId => {
    pendingRegisterUserIdRef.current = userId;
  };
  const frameProcessor = useFrameProcessor(frame => {
    'worklet';

    const pending = pendingRegisterUserIdRef.current;
    const params = pending ? {
      action: 'register_from_frame',
      userId: pending
    } : {
      action: 'process',
      threshold
    };
    const res = arcFace(frame, params);
    if (!res) return;
    if (res.type === 'process_result') {
      onResultJS(res);
      return;
    }
    if (res.type === 'register_result') {
      pendingRegisterUserIdRef.current = null;
      // 写入 registry（native 内存 + 持久化）
      onRegisteredJS(res.userId, res.featureBase64, res.featureSize);
    }
  }, [threshold, onResultJS, onRegisteredJS]);
  return {
    frameProcessor,
    requestRegisterFromFrame
  };
}
//# sourceMappingURL=useArcFace.js.map