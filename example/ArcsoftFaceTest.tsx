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
} from 'react-native';
import {
    Camera,
    useCameraDevice,
    useCameraPermission,
    useFrameProcessor,
    VisionCameraProxy, // Import Proxy directly
    type Frame,
} from 'react-native-vision-camera';
import {runAtTargetFps} from 'react-native-vision-camera';
import {Worklets} from 'react-native-worklets-core'; // Import Worklets
import {
    Canvas,
    Rect,
    Skia,
    ColorType,
    AlphaType,
    ImageFormat,
    useFont,
    Text as SkiaText,
} from '@shopify/react-native-skia';

import {
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
    faceDBAdd,
    faceDBSearch,
    faceDBCount,
    faceDBClear,
    faceDBRemove,
    // detectFaces, // Comment out library import
    type FaceInfo,
    type FaceFeature,
    type ActiveFileInfo,
    type FaceRect,
    type DetectFacesResult,
    type DetectFacesOptions,
} from 'arcsoft-face-react-native';
import {NativeModules} from 'react-native';

console.log('NativeModules keys:', Object.keys(NativeModules));

// Define plugin locally
const plugin = VisionCameraProxy.initFrameProcessorPlugin('detectFaces', {});

function detectFaces(frame: Frame, options?: DetectFacesOptions): DetectFacesResult {
    'worklet';
    if (plugin == null) {
        console.error("Failed to load Frame Processor Plugin 'detectFaces'!");
        return {faces: []};
    }
    // @ts-ignore
    return plugin.call(frame, options) as DetectFacesResult;
}

type AttrState = {
    age?: number;
    gender?: number; // 0男 1女 -1未知（以SDK为准）
    liveness?: number; // 0/1/-1（以SDK为准）
    yaw?: number;
    pitch?: number;
    roll?: number;
};

// UI Box type
type FaceBoxUI = {
    id: number;
    x: number;
    y: number;
    width: number;
    height: number;
    orient: number;
    color: string; // Debug color
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
    const {width: screenW, height: screenH} = useWindowDimensions();

    // Dynamic camera dimensions
    const [cameraLayout, setCameraLayout] = useState({width: 0, height: 0});

    const [activated, setActivated] = useState(false);
    const [activeInfo, setActiveInfo] = useState<ActiveFileInfo | null>(null);
    const [inited, setInited] = useState(false);

    // 你换成自己的 appId/sdkKey
    const [appId, setAppId] = useState('2x7amHG5D2zXGPPunjSyV5kmhfktrivFujNSKpq1BLmD');
    const [sdkKey, setSdkKey] = useState(Platform.OS === 'ios' ? 'FB9snd8iQpexkynHwgUpC9h8DtRcm1oLqzJ6dy3JT3HA' : 'FB9snd8iQpexkynHwgUpC9h8CGJwRsg4ZJdd84yBdy9d');

    // 图片测试
    const [imageBase64, setImageBase64] = useState('');

    // 人脸库测试
    const [userId, setUserId] = useState('u_001');
    const [dbCount, setDbCount] = useState(0);

    // 识别状态
    const [lastFaceCount, setLastFaceCount] = useState(0);
    const [attrs, setAttrs] = useState<AttrState>({});
    const [log, setLog] = useState<string>('');
    const [boxes, setBoxes] = useState<FaceBoxUI[]>([]);

    // 截图状态
    const [isCapturing, setIsCapturing] = useState(false);
    const [savedImagePath, setSavedImagePath] = useState<string | null>(null);

    // Skia font
    const font = useFont(require('./assets/fonts/PingFangSC-Regular.ttf'), 18); // Ensure you have this font or use system font

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
            setActivated(ok === 0 || ok === 90114); // 0=MOK, 90114=ALREADY_ACTIVATED
            appendLog(`activateOnline => ${ok}`);
            if (ok !== 0 && ok !== 90114) Alert.alert('激活失败', `code=${ok}`);
        } catch (e: any) {
            appendLog(`activateOnline error: ${String(e?.message || e)}`);
            console.error(`activateOnline error: ${String(e?.message || e)}`);
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

    // Use useMemo + Worklets.createRunOnJS for better performance and stability
    const reportFacesToJS = useMemo(() => {
        return Worklets.createRunOnJS((payload: {
            faces: FaceInfo[],
            frameW: number,
            frameH: number,
            imagePath?: string
        }) => {
            const {faces, frameW, frameH, imagePath} = payload;
            setLastFaceCount(faces.length);

            if (imagePath) {
                console.log('Image saved at:', imagePath);
                setSavedImagePath(imagePath);
                setIsCapturing(false); // Stop capturing after one frame
            }

            if (faces.length > 0) {
                lastFaceRef.current = faces[0];
            } else {
                lastFaceRef.current = null;
            }

            const viewW = cameraLayout.width;
            const viewH = cameraLayout.height;

            if (viewW === 0 || viewH === 0) return;


            if (Platform.OS === 'android') {
                // Scale logic (Cover)
                // Mapped dimensions: frameH x frameW (480 x 640)
                const scaleX = viewW / frameH;
                const scaleY = viewH / frameW;
                const scale = Math.max(scaleX, scaleY);

                const scaledW = frameH * scale;
                const scaledH = frameW * scale;

                const offsetX = (viewW - scaledW) / 2;
                const offsetY = (viewH - scaledH) / 2;

                const uiBoxes = faces.map((face, i) => {
                    let {left, top, right, bottom} = face.rect;

                    // User provided algorithm:
                    // left: frameHeight - rect.bottom,
                    // right: frameHeight - rect.top,
                    // top: frameWidth - rect.right,
                    // bottom: frameWidth - rect.left,

                    const mappedLeft = frameH - bottom;
                    const mappedRight = frameH - top;
                    const mappedTop = frameW - right;
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
                        color: 'red'
                    };
                });

                setBoxes(uiBoxes);
            } else {
                // iOS Front: 90 deg rotation (Swap W/H)
                // Coordinate mapping logic
                let rotatedFrameW = frameH;
                let rotatedFrameH = frameW;


                const scaleX = viewW / rotatedFrameW;
                const scaleY = viewH / rotatedFrameH;
                const scale = Math.max(scaleX, scaleY);

                const offsetX = (viewW - rotatedFrameW * scale) / 2;
                const offsetY = (viewH - rotatedFrameH * scale) / 2;

                const uiBoxes = faces.map((face, i) => {
                    let {left, top, right, bottom} = face.rect;
                    let w = right - left;
                    let h = bottom - top;

                    const x = frameH - bottom;
                    const y = left;

                    // Swap w/h
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
                        color: 'red'
                    };
                });
                setBoxes(uiBoxes);
            }

        });
    }, [cameraLayout]);

    // FrameProcessor using Plugin (Inline logic)
    const frameProcessor = useFrameProcessor(
        (frame: Frame) => {
            'worklet';
            if (!inited) return;

            runAtTargetFps(15, () => {
                'worklet';
                try {
                    if (plugin != null) {
                        // @ts-ignore
                        const result = plugin.call(frame, {saveImage: isCapturing}) as DetectFacesResult;
                        // Call the JS function created by Worklets.createRunOnJS
                        reportFacesToJS({
                            faces: result.faces,
                            frameW: frame.width,
                            frameH: frame.height,
                            imagePath: result.imagePath
                        });
                    }
                } catch (e: any) {
                    console.error('Frame processor error:', e.message);
                }
            });
        },
        [inited, reportFacesToJS, isCapturing],
    );

    const canUseCamera = useMemo(() => {
        return !!device && hasPermission;
    }, [device, hasPermission]);

    const doRegisterToDB = useCallback(async () => {
        try {
            const f = lastFeatureRef.current;
            if (!f) return Alert.alert('提示', '当前没有可注册的人脸特征（请先对准人脸）');

            // Note: Feature extraction is not yet implemented in Frame Processor Plugin flow.
            // You would need to add extractFeature to the plugin or use the image based method.
            Alert.alert('提示', '此功能在 Frame Processor 流程中尚未实现');

        } catch (e: any) {
            appendLog(`faceDBAdd error: ${String(e?.message || e)}`);
        }
    }, [appendLog]);

    const doSearchDB = useCallback(async () => {
        try {
            const f = lastFeatureRef.current;
            if (!f) return Alert.alert('提示', '当前没有可检索的人脸特征（请先对准人脸）');

            Alert.alert('提示', '此功能在 Frame Processor 流程中尚未实现');

        } catch (e: any) {
            appendLog(`faceDBSearch error: ${String(e?.message || e)}`);
        }
    }, [appendLog]);

    const doCompare = useCallback(async () => {
        try {
            const f = lastFeatureRef.current;
            if (!f) return Alert.alert('提示', '当前没有可对比的人脸特征');

            Alert.alert('提示', '此功能在 Frame Processor 流程中尚未实现');

        } catch (e: any) {
            appendLog(`compareFeature error: ${String(e?.message || e)}`);
        }
    }, [appendLog]);

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
                    <Text style={styles.note}>
                        combinedMask 在你的 TS 层已改成对象参数：enableAge/enableGender/enableLiveness/enable3DAngle
                    </Text>
                </View>

                <View style={styles.card}>
                    <Text style={styles.h2}>3) Camera / Detect (Frame Processor)</Text>
                    {canUseCamera ? (
                        <View
                            style={styles.previewWrap}
                            onLayout={(event) => {
                                const {width, height} = event.nativeEvent.layout;
                                console.log('Camera Layout:', width, height);
                                setCameraLayout({width, height});
                            }}
                        >
                            <Camera
                                style={styles.preview}
                                device={device!}
                                isActive={inited}
                                pixelFormat="yuv"
                                frameProcessor={frameProcessor}
                                frameProcessorFps={15} // Higher FPS for smooth boxes
                            />
                            {/* Skia Canvas for drawing boxes */}
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
                        <Text style={styles.note}>相机不可用：请确认权限 / 设备。</Text>
                    )}

                    <View style={styles.row}>
                        <Text style={styles.kv}>检测到人脸数：{lastFaceCount}</Text>
                        <View style={{flex: 1}}/>
                        <TouchableOpacity
                            style={[styles.btn, {backgroundColor: isCapturing ? '#999' : '#007AFF'}]}
                            onPress={() => setIsCapturing(true)}
                            disabled={isCapturing}
                        >
                            <Text style={styles.btnText}>{isCapturing ? '正在截图...' : '截图当前帧'}</Text>
                        </TouchableOpacity>
                    </View>

                    {savedImagePath && (
                        <View style={{marginTop: 10, alignItems: 'center'}}>
                            <Text style={[styles.h2, {alignSelf: 'flex-start'}]}>最近截图：</Text>
                            <Image
                                source={{uri: savedImagePath}}
                                style={{
                                    width: 200,
                                    height: 200,
                                    resizeMode: 'contain',
                                    backgroundColor: '#eee',
                                    borderWidth: 1,
                                    borderColor: '#ccc'
                                }}
                            />
                            <Text style={{fontSize: 10, color: '#666', marginTop: 4}}>{savedImagePath}</Text>
                        </View>
                    )}

                    <Text style={styles.note}>
                        Frame Processor 流程仅测试人脸检测。
                    </Text>
                </View>

                <View style={styles.card}>
                    <Text style={styles.h2}>4) 图片处理 (Base64)</Text>
                    <TextInput
                        value={imageBase64}
                        onChangeText={setImageBase64}
                        placeholder="输入 Base64 图片数据..."
                        style={[styles.input, {height: 60}]}
                        multiline
                    />
                    <View style={styles.btnRow}>
                        <TouchableOpacity style={styles.btn} onPress={doProcessImage}>
                            <Text style={styles.btnText}>处理图片</Text>
                        </TouchableOpacity>
                    </View>
                </View>

                <View style={styles.card}>
                    <Text style={styles.h2}>5) 人脸库（内存）注册 / 检索</Text>
                    <View style={styles.row}>
                        <Text style={styles.label}>userId</Text>
                        <TextInput value={userId} onChangeText={setUserId} style={styles.input}/>
                    </View>

                    <Text style={styles.kv}>DB 数量：{dbCount}</Text>
                    <View style={styles.btnRow}>
                        <TouchableOpacity style={styles.btn} onPress={doRegisterToDB}>
                            <Text style={styles.btnText}>注册到DB</Text>
                        </TouchableOpacity>
                        <TouchableOpacity style={styles.btn} onPress={doSearchDB}>
                            <Text style={styles.btnText}>检索DB</Text>
                        </TouchableOpacity>
                        <TouchableOpacity style={styles.btnOutline} onPress={doRemoveFace}>
                            <Text style={styles.btnOutlineText}>删除</Text>
                        </TouchableOpacity>
                        <TouchableOpacity style={styles.btnOutline} onPress={doClearDB}>
                            <Text style={styles.btnOutlineText}>清空</Text>
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

                <View style={{height: 30}}/>
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
        minHeight: 40,
        textAlignVertical: 'top',
    },
    btnRow: {flexDirection: 'row', alignItems: 'center', gap: 10, flexWrap: 'wrap', marginTop: 8},
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
