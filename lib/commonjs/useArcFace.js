"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.useArcFace = useArcFace;
var _react = require("react");
var _reactNativeVisionCamera = require("react-native-vision-camera");
var _reactNativeWorkletsCore = require("react-native-worklets-core");
var _arcFacePlugin = require("./arcFacePlugin");
var _ArcFaceRegistry = require("./ArcFaceRegistry");
function useArcFace(options = {}) {
  const threshold = options.threshold ?? 0.8;
  const pendingRegisterUserIdRef = (0, _react.useRef)(null);

  // 从 worklet 回 JS
  const onResultJS = (0, _reactNativeWorkletsCore.useRunOnJS)(res => {
    options.onResult?.(res);
  }, [options.onResult]);
  const onRegisteredJS = (0, _reactNativeWorkletsCore.useRunOnJS)(async (userId, featureBase64, featureSize) => {
    await _ArcFaceRegistry.ArcFaceRegistry.upsert(userId, featureBase64, featureSize);
    options.onRegisteredFromFrame?.(userId);
  }, [options.onRegisteredFromFrame]);

  // 进入识别页：加载 registry 到 native 内存（离线）
  (0, _react.useEffect)(() => {
    _ArcFaceRegistry.ArcFaceRegistry.loadAll().catch(() => {});
  }, []);
  const requestRegisterFromFrame = userId => {
    pendingRegisterUserIdRef.current = userId;
  };
  const frameProcessor = (0, _reactNativeVisionCamera.useFrameProcessor)(frame => {
    'worklet';

    const pending = pendingRegisterUserIdRef.current;
    const params = pending ? {
      action: 'register_from_frame',
      userId: pending
    } : {
      action: 'process',
      threshold
    };
    const res = (0, _arcFacePlugin.arcFace)(frame, params);
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