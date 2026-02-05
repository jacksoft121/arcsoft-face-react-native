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
} from 'react-native';
import {
  Camera,
  useCameraDevice,
  useCameraPermission,
  useFrameProcessor,
  type Frame,
} from 'react-native-vision-camera';
import {runAtTargetFps} from 'react-native-vision-camera';
import {useResizePlugin} from 'vision-camera-resize-plugin';
import {runOnJS} from 'react-native-reanimated';

import {
  setLogLevel,
  activateOnline,
  initEngine,
  unInitEngine,
  detectFacesNV21,
  extractFeatureNV21,
  compareFeature,
  getAgeNV21,
  getGenderNV21,
  getLivenessNV21,
  getFace3DAngleNV21,
  faceDBAdd,
  faceDBSearch,
  faceDBCount,
  type FaceInfo,
  type FaceFeature,
} from 'arcsoft-face-react-native';

type AttrState = {
  age?: number;
  gender?: number; // 0男 1女 -1未知（以SDK为准）
  liveness?: number; // 0/1/-1（以SDK为准）
  yaw?: number;
  pitch?: number;
  roll?: number;
};

function toScoreText(score: number) {
  // 有的SDK返回 0~1，有的返回 0~100
  if (!Number.isFinite(score)) return '0';
  if (score <= 1.0) return (score * 100).toFixed(2);
  return score.toFixed(2);
}

export default function TestScreen() {
  const {hasPermission, requestPermission} = useCameraPermission();
  const device = useCameraDevice('front');
  const resize = useResizePlugin();

  const [activated, setActivated] = useState(false);
  const [inited, setInited] = useState(false);

  // 你换成自己的 appId/sdkKey
  const [appId, setAppId] = useState('2x7amHG5D2zXGPPunjSyV5kmhfktrivFujNSKpq1BLmD');
  const [sdkKey, setSdkKey] = useState(Platform.OS === 'ios' ? 'FB9snd8iQpexkynHwgUpC9h8DtRcm1oLqzJ6dy3JT3HA' : '2x7amHG5D2zXGPPunjSyV5kmhfktrivFujNSKpq1BLmD');



  // 人脸库测试
  const [userId, setUserId] = useState('u_001');
  const [dbCount, setDbCount] = useState(0);

  // 识别状态
  const [lastFaceCount, setLastFaceCount] = useState(0);
  const [attrs, setAttrs] = useState<AttrState>({});
  const [log, setLog] = useState<string>('');


  // 保存一份 feature 用于对比/注册
  const lastFeatureRef = useRef<FaceFeature | null>(null);
  const lastFaceRef = useRef<FaceInfo | null>(null);

  const appendLog = useCallback((s: string) => {
    setLog(prev => {
      const next = `[${new Date().toLocaleTimeString()}] ${s}\n` + prev;
      return next.slice(0, 4000);
    });
  }, []);

  useEffect(() => {
    if (!hasPermission) requestPermission();
    // eslint-disable-next-line react-hooks/exhaustive-deps

  }, []);

  const doActivate = useCallback(async () => {
    try {
      await setLogLevel(5); // VERBOSE
      const ok = await activateOnline(appId.trim(), sdkKey.trim());
      setActivated(ok);
      appendLog(`activateOnline => ${ok}`);
      if (!ok) Alert.alert('激活失败', '请确认 appId/sdkKey 是否正确。');
    } catch (e: any) {
      appendLog(`activateOnline error: ${String(e?.message || e)}`);
      console.error(`activateOnline error: ${String(e?.message || e)}`);
      Alert.alert('激活异常', String(e?.message || e));
    }
  }, [appId, sdkKey, appendLog]);

  const doInit = useCallback(async () => {
    try {
      // combinedMask 用配置对象更直观（与你现在 index.ts 一致）
      const code = await initEngine({
        detectMode: 'image', // 用 NV21 做图片模式就行
        maxFaceNum: 10,
        scale: 16,
        enableAge: true,
        enableGender: true,
        enableLiveness: true,
        enable3DAngle: true,
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

  const onNv21Frame = useCallback(
      async (nv21: number[], width: number, height: number) => {
        if (!inited) return;

        try {
          // 1) 检测
          const faces = await detectFacesNV21(nv21, width, height);
          setLastFaceCount(faces.length);

          if (!faces.length) {
            lastFeatureRef.current = null;
            lastFaceRef.current = null;
            return;
          }

          // 取第一张脸
          const face = faces[0];
          lastFaceRef.current = face;

          // 2) 提特征
          const feature = await extractFeatureNV21(nv21, width, height, face);
          if (feature) lastFeatureRef.current = feature;

          // 3) 年龄 / 性别 / 活体 / 3D角（按你 TS API 分开取）
          // 这些函数是否需要 faces 参数，取决于你 native 的实现；你现在基线里是 (nv21,w,h,faces)
          const ageArr = await getAgeNV21(nv21, width, height, faces);
          const genderArr = await getGenderNV21(nv21, width, height, faces);
          const liveArr = await getLivenessNV21(nv21, width, height, faces);
          const angleArr = await getFace3DAngleNV21(nv21, width, height, faces);

          setAttrs({
            age: ageArr?.[0],
            gender: genderArr?.[0],
            liveness: liveArr?.[0],
            yaw: angleArr?.[0]?.yaw,
            pitch: angleArr?.[0]?.pitch,
            roll: angleArr?.[0]?.roll,
          });
        } catch (e: any) {
          appendLog(`frame error: ${String(e?.message || e)}`);
        }
      },
      [appendLog, inited],
  );

  // FrameProcessor：把 camera frame 转成 NV21
  const frameProcessor = useFrameProcessor(
      (frame: Frame) => {
        'worklet';
        if (!resize) return;

        runAtTargetFps(5, () => {
          'worklet';
          try {
            // resize-plugin 的不同版本返回结构不同：
            // 常见是 { width, height, bytes } 或直接 Uint8Array
            const out: any = resize(frame, {
              scale: {width: 480, height: 640},
              pixelFormat: 'yuv', // 期望 NV21/YUV
              dataType: 'uint8',
            });

            const w = out?.width ?? 480;
            const h = out?.height ?? 640;
            const bytes: any = out?.bytes ?? out;

            // bytes 期望是 Uint8Array
            if (!bytes || !bytes.length) return;

            // worklet 里转 JS 线程：Array.from(Uint8Array)
            // 注意：这是为了“验证插件能力”的测试写法，不建议生产一直这样跑
            const arr = Array.from(bytes as any);
            runOnJS(onNv21Frame)(arr, w, h);
          } catch (e) {
            // ignore in worklet
          }
        });
      },
      [resize, onNv21Frame],
  );

  const canUseCamera = useMemo(() => {
    return !!device && hasPermission;
  }, [device, hasPermission]);

  const doRegisterToDB = useCallback(async () => {
    try {
      const f = lastFeatureRef.current;
      if (!f) return Alert.alert('提示', '当前没有可注册的人脸特征（请先对准人脸）');

      const ok = await faceDBAdd(userId.trim(), f, userId.trim());
      appendLog(`faceDBAdd(${userId}) => ${ok}`);
      await refreshDBCount();
      if (!ok) Alert.alert('注册失败', '请看日志输出。');
    } catch (e: any) {
      appendLog(`faceDBAdd error: ${String(e?.message || e)}`);
    }
  }, [appendLog, refreshDBCount, userId]);

  const doSearchDB = useCallback(async () => {
    try {
      const f = lastFeatureRef.current;
      if (!f) return Alert.alert('提示', '当前没有可检索的人脸特征（请先对准人脸）');

      const r = await faceDBSearch(f, 1);
      appendLog(`faceDBSearch => ${JSON.stringify(r)}`);

      if (r?.length) {
        const top = r[0];
        Alert.alert('检索结果', `userId=${top.userId}\nscore=${toScoreText(top.score)}`);
      } else {
        Alert.alert('检索结果', '未命中');
      }
    } catch (e: any) {
      appendLog(`faceDBSearch error: ${String(e?.message || e)}`);
    }
  }, [appendLog]);

  const doCompare = useCallback(async () => {
    try {
      const f = lastFeatureRef.current;
      if (!f) return Alert.alert('提示', '当前没有可对比的人脸特征');

      // 简单示例：用同一个 feature 和自己对比，理论上应接近满分
      const score = await compareFeature(f, f);
      appendLog(`compareFeature(self,self) => ${score}`);
      Alert.alert('对比分数', toScoreText(score));
    } catch (e: any) {
      appendLog(`compareFeature error: ${String(e?.message || e)}`);
    }
  }, [appendLog]);

  useEffect(() => {
    refreshDBCount();
  }, [refreshDBCount]);

  return (
      <SafeAreaView style={styles.root}>
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
              <Text style={styles.badge}>{activated ? '已激活' : '未激活'}</Text>
            </View>
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
            <Text style={styles.note}>
              combinedMask 在你的 TS 层已改成对象参数：enableAge/enableGender/enableLiveness/enable3DAngle
            </Text>
          </View>

          <View style={styles.card}>
            <Text style={styles.h2}>3) Camera / Detect / Attribute</Text>
            {canUseCamera ? (
                <View style={styles.previewWrap}>
                  <Camera
                      style={styles.preview}
                      device={device!}
                      isActive={inited}
                      pixelFormat="yuv"
                      frameProcessor={frameProcessor}
                      frameProcessorFps={5}
                  />
                </View>
            ) : (
                <Text style={styles.note}>相机不可用：请确认权限 / 设备。</Text>
            )}

            <Text style={styles.kv}>检测到人脸数：{lastFaceCount}</Text>
            <Text style={styles.kv}>年龄：{attrs.age ?? '-'}</Text>
            <Text style={styles.kv}>性别：{attrs.gender ?? '-'}</Text>
            <Text style={styles.kv}>活体：{attrs.liveness ?? '-'}</Text>
            <Text style={styles.kv}>
              3D角：yaw={attrs.yaw ?? '-'} pitch={attrs.pitch ?? '-'} roll={attrs.roll ?? '-'}
            </Text>

            <View style={styles.btnRow}>
              <TouchableOpacity style={styles.btn} onPress={doCompare}>
                <Text style={styles.btnText}>自对比(Feature)</Text>
              </TouchableOpacity>
            </View>
          </View>

          <View style={styles.card}>
            <Text style={styles.h2}>4) 人脸库（内存）注册 / 检索</Text>
            <View style={styles.row}>
              <Text style={styles.label}>userId</Text>
              <TextInput value={userId} onChangeText={setUserId} style={styles.input} />
            </View>

            <Text style={styles.kv}>DB 数量：{dbCount}</Text>
            <View style={styles.btnRow}>
              <TouchableOpacity style={styles.btn} onPress={doRegisterToDB}>
                <Text style={styles.btnText}>注册到DB</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.btn} onPress={doSearchDB}>
                <Text style={styles.btnText}>检索DB</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.btnOutline} onPress={refreshDBCount}>
                <Text style={styles.btnOutlineText}>刷新数量</Text>
              </TouchableOpacity>
            </View>

            <Text style={styles.note}>
              说明：本测试页把 camera 每帧提取到的 feature 作为“当前人脸特征”。先对准人脸，再点“注册”，再点“检索”。
            </Text>
          </View>

          <View style={styles.card}>
            <Text style={styles.h2}>日志</Text>
            <Text style={styles.log}>{log || '（暂无）'}</Text>
          </View>

          <View style={{height: 30}} />
        </ScrollView>
      </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: {flex: 1},
  container: {padding: 14},
  title: {fontSize: 18, fontWeight: '700', marginBottom: 10},
  card: {
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#ccc',
    borderRadius: 10,
    padding: 12,
    marginBottom: 12,
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
    minHeight: 60,
    textAlignVertical: 'top',
  },
  btnRow: {flexDirection: 'row', alignItems: 'center', gap: 10, flexWrap: 'wrap'},
  btn: {
    backgroundColor: '#111',
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 8,
  },
  btnText: {color: '#fff', fontWeight: '700'},
  btnOutline: {
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#111',
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 8,
  },
  btnOutlineText: {color: '#111', fontWeight: '700'},
  badge: {marginLeft: 6, color: '#333'},
  note: {marginTop: 8, color: '#666', lineHeight: 18},
  kv: {color: '#333', marginTop: 4},
  previewWrap: {borderRadius: 10, overflow: 'hidden', borderWidth: 1, borderColor: '#ddd'},
  preview: {width: '100%', height: 280},
  log: {marginTop: 8, color: '#222', fontSize: 12, lineHeight: 16},
});
