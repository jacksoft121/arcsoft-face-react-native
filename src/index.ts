import { VisionCameraProxy, type Frame } from 'react-native-vision-camera';
import ArcsoftFaceNative, {
  type FaceRect,
  type FaceInfo,
  type FaceFeature,
  type ActiveFileInfo,
} from './spec/NativeArcsoftFace';

export type { FaceRect, FaceInfo, FaceFeature, ActiveFileInfo };

// Frame Processor Plugin
const plugin = VisionCameraProxy.initFrameProcessorPlugin('detectFaces', {});

export interface DetectFacesResult {
  faces: FaceInfo[];
  imagePath?: string;
}

export interface DetectFacesOptions {
  saveImage?: boolean;
  extractFeature?: boolean;
  score?: number;
}

export function detectFaces(frame: Frame, options?: DetectFacesOptions): DetectFacesResult {
  'worklet';
  if (plugin == null) {
      console.error("Failed to load Frame Processor Plugin 'detectFaces'!");
      return { faces: [] };
  }
  // @ts-ignore
  return plugin.call(frame, options) as DetectFacesResult;
}

export type InitEngineOptions = {
  detectMode?: 'image' | 'video';
  maxFaceNum?: number;
  scale?: number;
  enableAge?: boolean;
  enableGender?: boolean;
  enableLiveness?: boolean;
  enable3DAngle?: boolean;
};

export const setLogLevel = (level: number) => ArcsoftFaceNative.setLogLevel(level);

/** SDK 在线激活（返回 0 表示成功） */
export const activateOnline = (appId: string, sdkKey: string): Promise<number> =>
    ArcsoftFaceNative.activateOnline(appId, sdkKey);

/** 获取激活文件信息 */
export const getActiveFileInfo = (): Promise<ActiveFileInfo | null> =>
    ArcsoftFaceNative.getActiveFileInfo();

/** 初始化引擎（返回 0 表示成功） */
export const initEngine = (options: InitEngineOptions = {}): Promise<number> =>
    ArcsoftFaceNative.initEngine(JSON.stringify(options));

/** 反初始化引擎（返回 0 表示成功） */
export const unInitEngine = (): Promise<number> => ArcsoftFaceNative.unInitEngine();

/** NV21 输入（跨平台统一输入） */
export const detectFacesNV21 = (
    nv21: number[],
    width: number,
    height: number
): Promise<FaceInfo[]> => ArcsoftFaceNative.detectFacesNV21(nv21, width, height);

/** 特征提取（NV21） */
export const extractFeatureNV21 = (
    nv21: number[],
    width: number,
    height: number,
    face: FaceInfo
): Promise<FaceFeature | null> => ArcsoftFaceNative.extractFeatureNV21(nv21, width, height, face);

/** 特征比对 */
export const compareFeature = (f1: FaceFeature, f2: FaceFeature): Promise<number> =>
    ArcsoftFaceNative.compareFeature(f1, f2);

/** 年龄/性别/活体/3D角度 */
export const getAgeNV21 = (
    nv21: number[],
    width: number,
    height: number,
    faces: FaceInfo[]
): Promise<number[]> => ArcsoftFaceNative.getAgeNV21(nv21, width, height, faces);

export const getGenderNV21 = (
    nv21: number[],
    width: number,
    height: number,
    faces: FaceInfo[]
): Promise<number[]> => ArcsoftFaceNative.getGenderNV21(nv21, width, height, faces);

export const getLivenessNV21 = (
    nv21: number[],
    width: number,
    height: number,
    faces: FaceInfo[]
): Promise<number[]> => ArcsoftFaceNative.getLivenessNV21(nv21, width, height, faces);

export const getFace3DAngleNV21 = (
    nv21: number[],
    width: number,
    height: number,
    faces: FaceInfo[]
): Promise<Array<{ roll: number; pitch: number; yaw: number }>> =>
    ArcsoftFaceNative.getFace3DAngleNV21(nv21, width, height, faces);

/** 图片输入 (Base64) */
export const detectFacesImage = (base64: string): Promise<FaceInfo[]> =>
    ArcsoftFaceNative.detectFacesImage(base64);

export const extractFeatureImage = (
    base64: string,
    face: FaceInfo
): Promise<FaceFeature | null> => ArcsoftFaceNative.extractFeatureImage(base64, face);

export const getAgeImage = (base64: string, faces: FaceInfo[]): Promise<number[]> =>
    ArcsoftFaceNative.getAgeImage(base64, faces);

export const getGenderImage = (base64: string, faces: FaceInfo[]): Promise<number[]> =>
    ArcsoftFaceNative.getGenderImage(base64, faces);

export const getLivenessImage = (base64: string, faces: FaceInfo[]): Promise<number[]> =>
    ArcsoftFaceNative.getLivenessImage(base64, faces);

export const getFace3DAngleImage = (
    base64: string,
    faces: FaceInfo[]
): Promise<Array<{ roll: number; pitch: number; yaw: number }>> =>
    ArcsoftFaceNative.getFace3DAngleImage(base64, faces);

/** 人脸库 */
export const registerFaceFeature = (id: string, feature: FaceFeature): Promise<boolean> =>
    ArcsoftFaceNative.registerFaceFeature(id, feature);

export const removeFaceFeature = (id: string): Promise<boolean> => ArcsoftFaceNative.removeFaceFeature(id);

export const clearAllFaceFeature = (): Promise<void> => ArcsoftFaceNative.clearAllFaceFeature();

export const getFaceCount = (): Promise<number> => ArcsoftFaceNative.getFaceCount();

export const searchFaceFeature = (
    feature: FaceFeature,
    threshold: number = 0
): Promise<{ id: string | null; score: number }> =>
    ArcsoftFaceNative.searchFaceFeature(feature, threshold);

/** 获取所有人脸列表 */
export const getAllFaces = (): Promise<Array<{ id: string; userId: string; registerTime: number }>> =>
    ArcsoftFaceNative.getAllFaces();

/**
 * 注册人脸（通过图片 URL）
 * @param userId 用户ID
 * @param imageUrl 图片地址（支持 http/https 或 file://）
 * @returns 注册结果
 */
export const registerFaceFromUrl = async (userId: string, imageUrl: string): Promise<{ success: boolean; msg: string; userId?: string }> => {
    try {
        // 1. 下载或读取图片并转换为 Base64
        let base64 = '';
        if (imageUrl.startsWith('http')) {
            const response = await fetch(imageUrl);
            const blob = await response.blob();
            base64 = await new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.onloadend = () => {
                    const res = reader.result as string;
                    // remove prefix "data:image/jpeg;base64,"
                    resolve(res.split(',')[1] || res);
                };
                reader.onerror = reject;
                reader.readAsDataURL(blob);
            });
        } else if (imageUrl.startsWith('file://')) {
            // React Native fetch supports file:// on some platforms, or use a file system library.
            // For simplicity, assuming fetch works or user provides base64 directly if not http.
            // If you use react-native-fs, you can read file directly.
            // Here we try fetch for file:// as well.
            const response = await fetch(imageUrl);
            const blob = await response.blob();
            base64 = await new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.onloadend = () => {
                    const res = reader.result as string;
                    resolve(res.split(',')[1] || res);
                };
                reader.onerror = reject;
                reader.readAsDataURL(blob);
            });
        } else {
            // Assume base64 string if not url
            base64 = imageUrl;
        }

        if (!base64) {
            return { success: false, msg: '图片数据为空' };
        }

        // 2. 检测人脸
        const faces = await detectFacesImage(base64);
        if (!faces || faces.length === 0) {
            return { success: false, msg: '未检测到人脸' };
        }

        // 3. 提取特征 (取最大的人脸，通常是第一个)
        const face = faces[0];
        const feature = await extractFeatureImage(base64, face);
        if (!feature || !feature.dataBase64) {
            return { success: false, msg: '特征提取失败' };
        }

        // 4. 注册/更新特征
        const success = await registerFaceFeature(userId, feature);
        if (success) {
            return { success: true, msg: '注册成功', userId };
        } else {
            return { success: false, msg: '注册失败(引擎返回false)' };
        }

    } catch (e: any) {
        return { success: false, msg: `异常: ${e.message || e}` };
    }
};

/**
 * 默认导出：一个与原生同名的对象（方便用户 `import ArcsoftFace from 'xxx'`）
 */
const ArcsoftFace = {
  setLogLevel,
  activateOnline,
  getActiveFileInfo,
  initEngine,
  unInitEngine,

  detectFacesNV21,
  extractFeatureNV21,
  compareFeature,

  getAgeNV21,
  getGenderNV21,
  getLivenessNV21,
  getFace3DAngleNV21,

  detectFacesImage,
  extractFeatureImage,
  getAgeImage,
  getGenderImage,
  getLivenessImage,
  getFace3DAngleImage,

  registerFaceFeature,
  removeFaceFeature,
  clearAllFaceFeature,
  getFaceCount,
  searchFaceFeature,
  
  registerFaceFromUrl, // Export new function
  getAllFaces, // Export new function
  
  // Frame Processor Plugin
  detectFaces,
};

export default ArcsoftFace;
