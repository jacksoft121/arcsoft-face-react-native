export interface FaceRect {
  left: number;
  top: number;
  right: number;
  bottom: number;
  orient?: number;
}

export interface FaceInfo {
  rect: FaceRect;
  age?: number;
  gender?: number; // 0 female / 1 male
  liveness?: number; // 0 alive / 1 not alive
  yaw?: number;
  pitch?: number;
  roll?: number;
}

export interface FaceFeature {
  data: string; // base64
}

export interface FaceSearchResult {
  name: string;
  score: number;
}
