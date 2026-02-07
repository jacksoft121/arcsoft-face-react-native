import type { FaceInfo } from 'arcsoft-face-react-native';

export type FaceBoxUI = {
  id: number;
  x: number;
  y: number;
  width: number;
  height: number;
  orient: number;
  color: string;
};

type Params = {
  faces: FaceInfo[];

  frameW: number;
  frameH: number;

  viewW: number;
  viewH: number;

  isFrontCamera: boolean;
  platform: 'ios' | 'android';
};

export function mapFacesToUIBoxes({
                                    faces,
                                    frameW,
                                    frameH,
                                    viewW,
                                    viewH,
                                    isFrontCamera,
                                    platform,
                                  }: Params): FaceBoxUI[] {
  if (viewW === 0 || viewH === 0) return [];

  // ===============================
  // Android 前置：你原来的逻辑
  // ===============================
  if (platform === 'android' && isFrontCamera) {
    const scaleX = viewW / frameH;
    const scaleY = viewH / frameW;
    const scale = Math.max(scaleX, scaleY);

    const scaledW = frameH * scale;
    const scaledH = frameW * scale;

    const offsetX = (viewW - scaledW) / 2;
    const offsetY = (viewH - scaledH) / 2;

    return faces.map((face, i) => {
      const { left, top, right, bottom } = face.rect;

      const mappedLeft   = frameH - bottom;
      const mappedRight  = frameH - top;
      const mappedTop    = frameW - right;
      const mappedBottom = frameW - left;

      const w = mappedRight - mappedLeft;
      const h = mappedBottom - mappedTop;

      return {
        id: face.faceId || i,
        x: mappedLeft * scale + offsetX,
        y: mappedTop * scale + offsetY,
        width: w * scale,
        height: h * scale,
        orient: face.orient,
        color: 'red',
      };
    });
  }

  // =========================================
  // iOS（前/后）+ Android 后置：你原来的逻辑
  // =========================================
  const rotatedFrameW = frameH;
  const rotatedFrameH = frameW;

  const scaleX = viewW / rotatedFrameW;
  const scaleY = viewH / rotatedFrameH;
  const scale = Math.max(scaleX, scaleY);

  const offsetX = (viewW - rotatedFrameW * scale) / 2;
  const offsetY = (viewH - rotatedFrameH * scale) / 2;

  return faces.map((face, i) => {
    let { left, top, right, bottom } = face.rect;

    let w = right - left;
    let h = bottom - top;

    // iOS / Android 后置映射（你现在用的）
    const x = frameH - bottom;
    const y = left;

    // swap w / h
    const tmp = w;
    w = h;
    h = tmp;

    return {
      id: face.faceId || i,
      x: x * scale + offsetX,
      y: y * scale + offsetY,
      width: w * scale,
      height: h * scale,
      orient: face.orient,
      color: 'red',
    };
  });
}
