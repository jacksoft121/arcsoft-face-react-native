"use strict";

import { VisionCameraProxy } from 'react-native-vision-camera';
// VisionCamera v4.7.3: 必须传 options 参数（可为空对象）
const plugin = VisionCameraProxy.initFrameProcessorPlugin('arcFace', {});
export function arcFace(frame, params) {
  'worklet';

  if (plugin == null) {
    throw new Error('Failed to load Frame Processor Plugin "arcFace"!');
  }

  // plugin.call 的返回是 ParameterType 联合，先转 unknown 再转业务类型
  const result = plugin.call(frame, params);
  return result ?? null;
}
//# sourceMappingURL=arcFacePlugin.js.map