import React, {useCallback, useEffect, useMemo, useRef, useState} from 'react';
import {
  Alert,
  Platform,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
  useWindowDimensions,
  Image,
  Modal,
} from 'react-native';
import {
  Camera,
  useCameraDevice,
  useCameraPermission,
  useFrameProcessor,
  VisionCameraProxy,
  type Frame,
  type CameraPosition,
} from 'react-native-vision-camera';
import {runAtTargetFps} from 'react-native-vision-camera';
import {Worklets} from 'react-native-worklets-core';
import {
  Canvas,
  Rect,
  useFont,
} from '@shopify/react-native-skia';

import {
  setLogLevel,
  activateOnline,
  getActiveFileInfo,
  initEngine,
  unInitEngine,
  detectFacesImage,
  extractFeatureImage,
  getAgeImage,
  getGenderImage,
  getLivenessImage,
  getFace3DAngleImage,
  faceDBCount,
  faceDBClear,
  faceDBRemove,
  type FaceInfo,
  type FaceFeature,
  type ActiveFileInfo,
  type DetectFacesResult,
  type DetectFacesOptions,
} from 'arcsoft-face-react-native';

import { mapFacesToUIBoxes } from './recognition/mapFaceRectToView';

// Define plugin locally
const plugin = VisionCameraProxy.initFrameProcessorPlugin('detectFaces', {});

type FaceBoxUI = {
  id: number;
  x: number;
  y: number;
  width: number;
  height: number;
  orient: number;
  color: string;
};

export default function TestScreen() {
  const {hasPermission, requestPermission} = useCameraPermission();
  const [cameraPosition, setCameraPosition] = useState<CameraPosition>('front');
  const device = useCameraDevice(cameraPosition);
  const {width: screenW, height: screenH} = useWindowDimensions();

  const [cameraLayout, setCameraLayout] = useState({width: 0, height: 0});

  const [activated, setActivated] = useState(false);
  const [activeInfo, setActiveInfo] = useState<ActiveFileInfo | null>(null);
  const [inited, setInited] = useState(false);

  const [appId, setAppId] = useState('2x7amHG5D2zXGPPunjSyV5kmhfktrivFujNSKpq1BLmD');
  const [sdkKey, setSdkKey] = useState(Platform.OS === 'ios' ? 'FB9snd8iQpexkynHwgUpC9h8DtRcm1oLqzJ6dy3JT3HA' : 'FB9snd8iQpexkynHwgUpC9h8CGJwRsg4ZJdd84yBdy9d');

  const [imageBase64, setImageBase64] = useState('');
  const [userId, setUserId] = useState('u_001');
  const [dbCount, setDbCount] = useState(0);
  const [lastFaceCount, setLastFaceCount] = useState(0);
  const [log, setLog] = useState<string>('');
  const [boxes, setBoxes] = useState<FaceBoxUI[]>([]);
  const [isCapturing, setIsCapturing] = useState(false);
  const [savedImagePath, setSavedImagePath] = useState<string | null>(null);

  // Log UI state
  const [isLogMinimized, setIsLogMinimized] = useState(false);

  const lastFeatureRef = useRef<FaceFeature | null>(null);
  const lastFaceRef = useRef<FaceInfo | null>(null);

  const appendLog = useCallback((s: string) => {
    setLog(prev => {
      const next = `[${new Date().toLocaleTimeString()}] ${s}\n` + prev;
      return next.slice(0, 10000); // Keep more logs
    });
  }, []);

  const clearLog = useCallback(() => {
    setLog('');
  }, []);

  useEffect(() => {
    if (!hasPermission) requestPermission();
  }, []);

  const doActivate = useCallback(async () => {
    try {
      await setLogLevel(5);
      const ok = await activateOnline(appId.trim(), sdkKey.trim());
      setActivated(ok === 0 || ok === 90114);
      appendLog(`activateOnline => ${ok}`);
      if (ok !== 0 && ok !== 90114) Alert.alert('激活失败', `code=${ok}`);
    } catch (e: any) {
      appendLog(`activateOnline error: ${String(e?.message || e)}`);
      Alert.alert('激活异常', String(e?.message || e));
    }
  }, [appId, sdkKey, appendLog]);

  const doGetActiveInfo = useCallback(async () => {
    try {
      const info = await getActiveFileInfo();
      setActiveInfo(info);
      appendLog(`getActiveFileInfo => ${JSON.stringify(info)}`);
    } catch (e: any) {
      appendLog(`getActiveFileInfo error: ${String(e?.message || e)}`);
    }
  }, [appendLog]);

  const doInit = useCallback(async () => {
    try {
      const code = await initEngine({
        detectMode: 'video',
        maxFaceNum: 10,
        scale: 16,
        enableAge: false,
        enableGender: false,
        enableLiveness: false,
        enable3DAngle: false,
      });
      appendLog(`initEngine code => ${code}`);
      if (code === 0) setInited(true);
      else Alert.alert('initEngine 失败', `code=${code}`);
    } catch (e: any) {
      appendLog(`initEngine error: ${String(e?.message || e)}`);
      Alert.alert('initEngine 异常', String(e?.message || e));
    }
  }, [appendLog]);

  const doUnInit = useCallback(async () => {
    try {
      const code = await unInitEngine();
      appendLog(`unInitEngine code => ${code}`);
      setInited(false);
      lastFeatureRef.current = null;
      lastFaceRef.current = null;
      setBoxes([]);
    } catch (e: any) {
      appendLog(`unInitEngine error: ${String(e?.message || e)}`);
    }
  }, [appendLog]);

  const refreshDBCount = useCallback(async () => {
    try {
      const c = await faceDBCount();
      setDbCount(c);
      appendLog(`faceDBCount => ${c}`);
    } catch (e: any) {
      appendLog(`faceDBCount error: ${String(e?.message || e)}`);
    }
  }, [appendLog]);

  const doClearDB = useCallback(async () => {
    try {
      await faceDBClear();
      appendLog('faceDBClear done');
      refreshDBCount();
    } catch (e: any) {
      appendLog(`faceDBClear error: ${String(e?.message || e)}`);
    }
  }, [appendLog, refreshDBCount]);

  const doRemoveFace = useCallback(async () => {
    try {
      const ok = await faceDBRemove(userId);
      appendLog(`faceDBRemove(${userId}) => ${ok}`);
      refreshDBCount();
    } catch (e: any) {
      appendLog(`faceDBRemove error: ${String(e?.message || e)}`);
    }
  }, [appendLog, refreshDBCount, userId]);

  const reportFacesToJS = useMemo(() => {
    return Worklets.createRunOnJS((payload: {
      faces: FaceInfo[],
      frameW: number,
      frameH: number,
      imagePath?: string,
      isFrontCamera?: boolean,
      rotDegress?: number,
    }) => {
      const {faces, frameW, frameH, imagePath,isFrontCamera,rotDegress } = payload;

      appendLog(`reportFacesToJS => frameW:${frameW}, frameH:${frameH},rotDegress:${rotDegress}, isFrontCamera:${isFrontCamera}`);

      // Only log if faces found or capturing to avoid spam
      if (faces.length > 0 || imagePath) {
        appendLog(`reportFacesToJS => faces:${JSON.stringify(faces[0])}`);

      }

      setLastFaceCount(faces.length);
      if (imagePath) {
        setSavedImagePath(imagePath);
        setIsCapturing(false);
        appendLog(`Captured image: ${imagePath}`);
      }

      if (faces.length > 0) {
        lastFaceRef.current = faces[0];
      } else {
        lastFaceRef.current = null;
      }

      const viewW = cameraLayout.width;
      const viewH = cameraLayout.height;

      if (viewW === 0 || viewH === 0) return;

      const uiBoxes = mapFacesToUIBoxes({
        faces,
        frameW,
        frameH,
        viewW,
        viewH,
        isFrontCamera: isFrontCamera,
        platform: Platform.OS,
      });

      setBoxes(uiBoxes);
    });
  }, [cameraLayout, appendLog]);

  function getFrameRotationDegrees(frame: Frame) {
    'worklet';
    switch (frame.orientation) {
      case 'portrait': return 0;
      case 'portrait-upside-down': return 180;
      case 'landscape-left': return 90;
      case 'landscape-right': return 270;
      default: return 0;
    }
  }

  const frameProcessor = useFrameProcessor(
      (frame: Frame) => {
        'worklet';
        if (!inited) return;

        runAtTargetFps(15, () => {
          'worklet';
          try {
            const rotDegress = getFrameRotationDegrees(frame);
            if (plugin != null) {
              // @ts-ignore
              const result = plugin.call(frame, {saveImage: isCapturing}) as DetectFacesResult;
              reportFacesToJS({
                faces: result.faces,
                frameW: frame.width,
                frameH: frame.height,
                imagePath: result.imagePath,
                isFrontCamera: cameraPosition === 'front',
                rotDegress: rotDegress,
              });
            }
          } catch (e: any) {
            console.error('Frame processor error:', e.message);
          }
        });
      },
      [inited, reportFacesToJS, isCapturing, cameraPosition],
  );

  const canUseCamera = useMemo(() => {
    return !!device && hasPermission;
  }, [device, hasPermission]);

  const doRegisterToDB = useCallback(async () => {
    Alert.alert('提示', '此功能在 Frame Processor 流程中尚未实现');
  }, []);

  const doSearchDB = useCallback(async () => {
    Alert.alert('提示', '此功能在 Frame Processor 流程中尚未实现');
  }, []);

  const doProcessImage = useCallback(async () => {
    if (!imageBase64) {
      Alert.alert('提示', '请先输入 Base64 图片数据');
      return;
    }
    try {
      const faces = await detectFacesImage(imageBase64);
      appendLog(`detectFacesImage => ${faces.length} faces`);
      if (faces.length > 0) {
        const face = faces[0];
        const feature = await extractFeatureImage(imageBase64, face);
        appendLog(`extractFeatureImage => ${feature ? 'success' : 'failed'}`);

        const ages = await getAgeImage(imageBase64, faces);
        const genders = await getGenderImage(imageBase64, faces);
        const liveness = await getLivenessImage(imageBase64, faces);
        const angles = await getFace3DAngleImage(imageBase64, faces);

        appendLog(`Image Attrs: Age=${ages[0]}, Gender=${genders[0]}, Live=${liveness[0]}, Angle=${JSON.stringify(angles[0])}`);
      }
    } catch (e: any) {
      appendLog(`doProcessImage error: ${String(e?.message || e)}`);
    }
  }, [imageBase64, appendLog]);

  useEffect(() => {
    refreshDBCount();
  }, [refreshDBCount]);

  const toggleCamera = useCallback(() => {
    setCameraPosition(p => (p === 'front' ? 'back' : 'front'));
  }, []);

  return (
      <SafeAreaView style={styles.root}>
        <View style={styles.mainContent}>
          <ScrollView contentContainerStyle={styles.container}>
            <Text style={styles.title}>ArcSoft Face RN 插件验证页</Text>

            <View style={styles.card}>
              <Text style={styles.h2}>1) SDK 激活（online）</Text>
              <View style={styles.row}>
                <Text style={styles.label}>appId</Text>
                <TextInput
                    value={appId}
                    onChangeText={setAppId}
                    placeholder="你的 appId"
                    style={styles.input}
                    autoCapitalize="none"
                    multiline
                />
              </View>
              <View style={styles.row}>
                <Text style={styles.label}>sdkKey</Text>
                <TextInput
                    value={sdkKey}
                    onChangeText={setSdkKey}
                    placeholder="你的 sdkKey"
                    style={styles.input}
                    autoCapitalize="none"
                    multiline
                />
              </View>

              <View style={styles.btnRow}>
                <TouchableOpacity style={styles.btn} onPress={doActivate}>
                  <Text style={styles.btnText}>激活</Text>
                </TouchableOpacity>
                <TouchableOpacity style={styles.btnOutline} onPress={doGetActiveInfo}>
                  <Text style={styles.btnOutlineText}>获取激活信息</Text>
                </TouchableOpacity>
                <Text style={styles.badge}>{activated ? '已激活' : '未激活'}</Text>
              </View>
              {activeInfo && (
                  <Text style={styles.note}>
                    有效期: {activeInfo.expireTime}
                  </Text>
              )}
            </View>

            <View style={styles.card}>
              <Text style={styles.h2}>2) Engine init / uninit</Text>
              <View style={styles.btnRow}>
                <TouchableOpacity style={styles.btn} onPress={doInit}>
                  <Text style={styles.btnText}>initEngine</Text>
                </TouchableOpacity>
                <TouchableOpacity style={styles.btnOutline} onPress={doUnInit}>
                  <Text style={styles.btnOutlineText}>unInitEngine</Text>
                </TouchableOpacity>
                <Text style={styles.badge}>{inited ? '已初始化' : '未初始化'}</Text>
              </View>
            </View>

            <View style={styles.card}>
              <Text style={styles.h2}>3) Camera / Detect</Text>
              {canUseCamera ? (
                  <View
                      style={styles.previewWrap}
                      onLayout={(event) => {
                        const {width, height} = event.nativeEvent.layout;
                        setCameraLayout({width, height});
                      }}
                  >
                    <Camera
                        style={styles.preview}
                        device={device!}
                        isActive={inited}
                        pixelFormat="yuv"
                        frameProcessor={frameProcessor}
                        frameProcessorFps={15}
                    />
                    <Canvas style={StyleSheet.absoluteFill} pointerEvents="none">
                      {boxes.map((box, i) => (
                          <Rect
                              key={i}
                              x={box.x}
                              y={box.y}
                              width={box.width}
                              height={box.height}
                              color={box.color}
                              style="stroke"
                              strokeWidth={2}
                          />
                      ))}
                    </Canvas>
                  </View>
              ) : (
                  <Text style={styles.note}>相机不可用</Text>
              )}

              <View style={styles.row}>
                <Text style={styles.kv}>检测到人脸数：{lastFaceCount}</Text>
                <View style={{flex: 1}}/>
                <TouchableOpacity
                    style={[styles.btn, {backgroundColor: isCapturing ? '#999' : '#007AFF'}]}
                    onPress={() => setIsCapturing(true)}
                    disabled={isCapturing}
                >
                  <Text style={styles.btnText}>{isCapturing ? '...' : '截图'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={[styles.btn, {backgroundColor: '#333', marginLeft: 10}]}
                    onPress={toggleCamera}
                >
                  <Text style={styles.btnText}>切换</Text>
                </TouchableOpacity>
              </View>

              {savedImagePath && (
                  <View style={{marginTop: 10, alignItems: 'center'}}>
                    <Image
                        source={{uri: savedImagePath}}
                        style={{width: 100, height: 100, resizeMode: 'contain', borderWidth: 1, borderColor: '#ccc'}}
                    />
                    <Text style={{fontSize: 10, color: '#666'}}>{savedImagePath.split('/').pop()}</Text>
                  </View>
              )}
            </View>

            <View style={styles.card}>
              <Text style={styles.h2}>4) 图片处理 (Base64)</Text>
              <TextInput
                  value={imageBase64}
                  onChangeText={setImageBase64}
                  placeholder="输入 Base64..."
                  style={[styles.input, {height: 40}]}
                  multiline
              />
              <View style={styles.btnRow}>
                <TouchableOpacity style={styles.btn} onPress={doProcessImage}>
                  <Text style={styles.btnText}>处理图片</Text>
                </TouchableOpacity>
              </View>
            </View>

            <View style={styles.card}>
              <Text style={styles.h2}>5) 人脸库</Text>
              <View style={styles.row}>
                <Text style={styles.label}>userId</Text>
                <TextInput value={userId} onChangeText={setUserId} style={styles.input}/>
              </View>

              <Text style={styles.kv}>DB 数量：{dbCount}</Text>
              <View style={styles.btnRow}>
                <TouchableOpacity style={styles.btn} onPress={doRegisterToDB}>
                  <Text style={styles.btnText}>注册</Text>
                </TouchableOpacity>
                <TouchableOpacity style={styles.btn} onPress={doSearchDB}>
                  <Text style={styles.btnText}>检索</Text>
                </TouchableOpacity>
                <TouchableOpacity style={styles.btnOutline} onPress={doRemoveFace}>
                  <Text style={styles.btnOutlineText}>删除</Text>
                </TouchableOpacity>
                <TouchableOpacity style={styles.btnOutline} onPress={doClearDB}>
                  <Text style={styles.btnOutlineText}>清空</Text>
                </TouchableOpacity>
                <TouchableOpacity style={styles.btnOutline} onPress={refreshDBCount}>
                  <Text style={styles.btnOutlineText}>刷新</Text>
                </TouchableOpacity>
              </View>
            </View>

            {/* Spacer for log window */}
            <View style={{height: screenH / 3 + 20}} />
          </ScrollView>
        </View>

        {/* Floating Log Window */}
        <View style={[styles.logContainer, {height: isLogMinimized ? 40 : screenH / 3}]}>
          <View style={styles.logHeader}>
            <Text style={styles.logTitle}>日志</Text>
            <View style={{flexDirection: 'row'}}>
              <TouchableOpacity onPress={clearLog} style={styles.logBtn}>
                <Text style={styles.logBtnText}>清除</Text>
              </TouchableOpacity>
              <TouchableOpacity onPress={() => setIsLogMinimized(!isLogMinimized)} style={styles.logBtn}>
                <Text style={styles.logBtnText}>{isLogMinimized ? '展开' : '最小化'}</Text>
              </TouchableOpacity>
            </View>
          </View>
          {!isLogMinimized && (
              <ScrollView style={styles.logScroll} nestedScrollEnabled>
                <Text style={styles.logText}>{log || '（暂无日志）'}</Text>
              </ScrollView>
          )}
        </View>
      </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: {flex: 1, backgroundColor: '#f2f2f2'},
  mainContent: {flex: 1},
  container: {padding: 14},
  title: {fontSize: 18, fontWeight: '700', marginBottom: 10},
  card: {
    backgroundColor: 'white',
    borderRadius: 10,
    padding: 12,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 1},
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  h2: {fontSize: 15, fontWeight: '700', marginBottom: 8},
  row: {flexDirection: 'row', alignItems: 'center', marginBottom: 8},
  label: {width: 60, color: '#333'},
  input: {
    flex: 1,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#bbb',
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: Platform.select({ios: 10, android: 8}),
    minHeight: 40,
    textAlignVertical: 'top',
    backgroundColor: '#fff',
  },
  btnRow: {flexDirection: 'row', alignItems: 'center', gap: 10, flexWrap: 'wrap', marginTop: 8},
  btn: {
    backgroundColor: '#111',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 6,
  },
  btnText: {color: '#fff', fontWeight: '600', fontSize: 13},
  btnOutline: {
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#111',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 6,
  },
  btnOutlineText: {color: '#111', fontWeight: '600', fontSize: 13},
  badge: {marginLeft: 6, color: '#333', fontSize: 12},
  note: {marginTop: 8, color: '#666', fontSize: 12, lineHeight: 16},
  kv: {color: '#333', marginTop: 4, fontSize: 13},
  previewWrap: {
    borderRadius: 10,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: '#ddd',
    backgroundColor: '#000',
    height: 300, // Fixed height for preview
  },
  preview: {width: '100%', height: '100%'},

  // Log Window Styles
  logContainer: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: 'rgba(0,0,0,0.85)',
    borderTopLeftRadius: 12,
    borderTopRightRadius: 12,
    padding: 10,
    elevation: 10,
    zIndex: 100,
  },
  logHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  logTitle: {
    color: '#fff',
    fontWeight: 'bold',
    fontSize: 14,
  },
  logBtn: {
    marginLeft: 12,
    paddingHorizontal: 8,
    paddingVertical: 4,
    backgroundColor: '#444',
    borderRadius: 4,
  },
  logBtnText: {
    color: '#fff',
    fontSize: 12,
  },
  logScroll: {
    flex: 1,
  },
  logText: {
    color: '#0f0',
    fontSize: 11,
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
  },
});
