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
    Switch,
    FlatList,
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
    getFaceCount,
    clearAllFaceFeature,
    removeFaceFeature,
    registerFaceFeature,
    searchFaceFeature,
    registerFaceFromUrl,
    getAllFaces,
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
    name?: string;
};

type FaceRecord = {
    id: string;
    userId: string;
    registerTime: number;
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
    const [imageUrl, setImageUrl] = useState('https://raw.githubusercontent.com/jackxu/arcsoft-face-react-native/main/example/assets/face_test.jpg');
    const [dbCount, setDbCount] = useState(0);
    const [lastFaceCount, setLastFaceCount] = useState(0);
    const [log, setLog] = useState<string>('');
    const [boxes, setBoxes] = useState<FaceBoxUI[]>([]);
    const [isCapturing, setIsCapturing] = useState(false);
    const [savedImagePath, setSavedImagePath] = useState<string | null>(null);

    // New states
    const [targetFps, setTargetFps] = useState(3);
    const [isDetecting, setIsDetecting] = useState(true);
    const [faceList, setFaceList] = useState<FaceRecord[]>([]);

    // Log UI state
    const [isLogMinimized, setIsLogMinimized] = useState(false);

    const lastFeatureRef = useRef<FaceFeature | null>(null);
    const lastFaceRef = useRef<FaceInfo | null>(null);

    const appendLog = useCallback((s: string) => {
        console.log(`[${new Date().toLocaleTimeString()}] ${s}\n`); // Print to console
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
            const c = await getFaceCount();
            setDbCount(c);
            appendLog(`getFaceCount => ${c}`);
            
            try {
                // 传入 userId 进行过滤，如果 userId 为空则返回所有
                const faces = await getAllFaces(userId);
                setFaceList(faces as FaceRecord[]);
                appendLog(`getAllFaces(${userId || 'all'}) => ${faces.length} records`);
            } catch (e) {
                // ignore if not implemented
            }
        } catch (e: any) {
            appendLog(`getFaceCount error: ${String(e?.message || e)}`);
        }
    }, [appendLog, userId]); // Add userId dependency

    const doClearDB = useCallback(async () => {
        try {
            await clearAllFaceFeature();
            appendLog('clearAllFaceFeature done');
            refreshDBCount();
        } catch (e: any) {
            appendLog(`clearAllFaceFeature error: ${String(e?.message || e)}`);
        }
    }, [appendLog, refreshDBCount]);

    const doRemoveFace = useCallback(async (id: string) => {
        try {
            const ok = await removeFaceFeature(id);
            appendLog(`removeFaceFeature(${id}) => ${ok}`);
            refreshDBCount();
        } catch (e: any) {
            appendLog(`removeFaceFeature error: ${String(e?.message || e)}`);
        }
    }, [appendLog, refreshDBCount]);

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

            // appendLog(`reportFacesToJS => frameW:${frameW}, frameH:${frameH},rotDegress:${rotDegress}, isFrontCamera:${isFrontCamera}`);

            // Only log if faces found or capturing to avoid spam
            if (faces.length > 0 || imagePath) {
                // appendLog(`reportFacesToJS => faces:${JSON.stringify(faces[0])}`);
            }

            setLastFaceCount(faces.length);
            if (imagePath) {
                setSavedImagePath(imagePath);
                // 自动填充到图片 URL 输入框
                setImageUrl(imagePath);
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
            
            // 如果正在截图，不执行 runAtTargetFps 限制，直接执行以尽快捕获
            if (isCapturing) {
                try {
                    const rotDegress = getFrameRotationDegrees(frame);
                    if (plugin != null) {
                        // @ts-ignore
                        const result = plugin.call(frame, {saveImage: true, extractFeature: true, score: 0.7}) as DetectFacesResult;
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
                    console.error('Frame processor error (capture):', e.message);
                }
                return;
            }

            // 如果未开启检测，直接返回
            if (!isDetecting) return;

            runAtTargetFps(targetFps, () => {
                'worklet';
                try {
                    const rotDegress = getFrameRotationDegrees(frame);
                    if (plugin != null) {
                        // @ts-ignore
                        const result = plugin.call(frame, {saveImage: false, extractFeature: true, score: 0.7}) as DetectFacesResult;
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
        [inited, reportFacesToJS, isCapturing, cameraPosition, targetFps, isDetecting],
    );

    const canUseCamera = useMemo(() => {
        return !!device && hasPermission;
    }, [device, hasPermission]);

    const doRegisterToDB = useCallback(async () => {
        if (!lastFaceRef.current) {
            Alert.alert('提示', '未检测到人脸');
            return;
        }
        try {
            const face = lastFaceRef.current;
            if (!face.featureBase64) {
                Alert.alert('提示', '未提取到特征');
                return;
            }
            const feature: FaceFeature = { dataBase64: face.featureBase64 };
            const ok = await registerFaceFeature(userId, feature);
            appendLog(`registerFaceFeature(${userId}) => ${ok}`);
            refreshDBCount();
            if (ok) Alert.alert('成功', '注册成功');
            else Alert.alert('失败', '注册失败');
        } catch (e: any) {
            appendLog(`doRegisterToDB error: ${String(e?.message || e)}`);
            Alert.alert('异常', String(e?.message || e));
        }
    }, [userId, appendLog, refreshDBCount]);

    const doRegisterFromUrl = useCallback(async () => {
        if (!imageUrl) {
            Alert.alert('提示', '请输入图片地址');
            return;
        }
        try {
            appendLog(`开始注册图片: ${imageUrl}`);
            const result = await registerFaceFromUrl(userId, imageUrl);
            appendLog(`registerFaceFromUrl => ${JSON.stringify(result)}`);
            refreshDBCount();
            if (result.success) {
                Alert.alert('成功', `注册成功: ${result.userId}`);
            } else {
                Alert.alert('失败', result.msg);
            }
        } catch (e: any) {
            appendLog(`doRegisterFromUrl error: ${String(e?.message || e)}`);
            Alert.alert('异常', String(e?.message || e));
        }
    }, [userId, imageUrl, appendLog, refreshDBCount]);

    const doSearchDB = useCallback(async () => {
        if (!lastFaceRef.current) {
            Alert.alert('提示', '未检测到人脸');
            return;
        }
        try {
            const face = lastFaceRef.current;
            if (!face.featureBase64) {
                Alert.alert('提示', '未提取到特征');
                return;
            }
            const feature: FaceFeature = { dataBase64: face.featureBase64 };
            // 阈值 0.8
            const result = await searchFaceFeature(feature, 0.8);
            appendLog(`searchFaceFeature => ${JSON.stringify(result)}`);
            if (result && result.id) {
                Alert.alert('识别成功', `ID: ${result.id}, Score: ${result.score}`);
            } else {
                Alert.alert('识别失败', '未匹配到人脸');
            }
        } catch (e: any) {
            appendLog(`doSearchDB error: ${String(e?.message || e)}`);
            Alert.alert('异常', String(e?.message || e));
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
        // Auto init on mount
        const autoInit = async () => {
            try {
                await setLogLevel(5);
                const ok = await activateOnline(appId.trim(), sdkKey.trim());
                setActivated(ok === 0 || ok === 90114);
                appendLog(`Auto activate => ${ok}`);
                
                if (ok === 0 || ok === 90114) {
                    const code = await initEngine({
                        detectMode: 'video',
                        maxFaceNum: 10,
                        scale: 16,
                        enableAge: false,
                        enableGender: false,
                        enableLiveness: false,
                        enable3DAngle: false,
                    });
                    appendLog(`Auto initEngine => ${code}`);
                    if (code === 0) {
                        setInited(true);
                        refreshDBCount();
                    }
                }
            } catch (e: any) {
                appendLog(`Auto init error: ${e.message}`);
            }
        };
        
        if (hasPermission) {
            autoInit();
        }
    }, [hasPermission, appId, sdkKey, appendLog, refreshDBCount]);

    const toggleCamera = useCallback(() => {
        setCameraPosition(p => (p === 'front' ? 'back' : 'front'));
    }, []);

    const renderFaceItem = ({item}: {item: FaceRecord}) => {
        // Format timestamp to YYYY-MM-DD HH:mm:ss
        const date = new Date(Number(item.registerTime));
        
        // Check if date is valid
        let formattedDate = "Invalid Date";
        if (!isNaN(date.getTime())) {
            formattedDate = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')} ${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}:${String(date.getSeconds()).padStart(2, '0')}`;
        }
        
        return (
            <View style={styles.faceItem}>
                <View>
                    <Text style={styles.faceId}>ID: {item.id} | User: {item.userId}</Text>
                    <Text style={styles.faceTime}>
                        {formattedDate}
                    </Text>
                </View>
                <TouchableOpacity 
                    style={styles.deleteBtn} 
                    onPress={() => doRemoveFace(item.userId)}
                >
                    <Text style={styles.deleteBtnText}>删除</Text>
                </TouchableOpacity>
            </View>
        );
    };

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
                        <View style={styles.row}>
                            <Text style={styles.label}>FPS</Text>
                            <TextInput
                                value={String(targetFps)}
                                onChangeText={(t) => setTargetFps(Number(t) || 1)}
                                keyboardType="numeric"
                                style={[styles.input, {maxWidth: 60}]}
                            />
                            <View style={{width: 20}} />
                            <Text style={styles.label}>开启检测</Text>
                            <Switch value={isDetecting} onValueChange={setIsDetecting} />
                        </View>

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
                                    frameProcessorFps={targetFps} // Use dynamic FPS if supported, or rely on runAtTargetFps
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

                    {/* Removed "4) 图片处理 (Base64)" section as requested */}

                    <View style={styles.card}>
                        <Text style={styles.h2}>5) 人脸库</Text>
                        <View style={styles.row}>
                            <Text style={styles.label}>userId</Text>
                            <TextInput value={userId} onChangeText={setUserId} style={styles.input}/>
                        </View>
                        <View style={styles.row}>
                            <Text style={styles.label}>图片URL</Text>
                            <TextInput
                                value={imageUrl}
                                onChangeText={setImageUrl}
                                placeholder="http://... or file://..."
                                style={styles.input}
                                autoCapitalize="none"
                                multiline
                            />
                        </View>

                        <Text style={styles.kv}>DB 数量：{dbCount}</Text>
                        <View style={styles.btnRow}>
                            <TouchableOpacity style={styles.btn} onPress={doRegisterToDB}>
                                <Text style={styles.btnText}>注册(当前帧)</Text>
                            </TouchableOpacity>
                            <TouchableOpacity style={styles.btn} onPress={doRegisterFromUrl}>
                                <Text style={styles.btnText}>注册(URL)</Text>
                            </TouchableOpacity>
                            <TouchableOpacity style={styles.btn} onPress={doSearchDB}>
                                <Text style={styles.btnText}>检索</Text>
                            </TouchableOpacity>
                            <TouchableOpacity style={styles.btnOutline} onPress={() => doRemoveFace(userId)}>
                                <Text style={styles.btnOutlineText}>删除(Input)</Text>
                            </TouchableOpacity>
                            <TouchableOpacity style={styles.btnOutline} onPress={doClearDB}>
                                <Text style={styles.btnOutlineText}>清空</Text>
                            </TouchableOpacity>
                            <TouchableOpacity style={styles.btnOutline} onPress={refreshDBCount}>
                                <Text style={styles.btnOutlineText}>刷新</Text>
                            </TouchableOpacity>
                        </View>

                        {/* Face List */}
                        <Text style={[styles.h2, {marginTop: 16}]}>已注册人脸列表</Text>
                        {faceList.length === 0 ? (
                            <Text style={styles.note}>暂无数据 (或原生未实现 getAllFaces)</Text>
                        ) : (
                            <View style={{marginTop: 8}}>
                                {faceList.map((item) => (
                                    <View key={item.id} style={styles.faceItem}>
                                        <View>
                                            <Text style={styles.faceId}>ID: {item.id} | User: {item.userId}</Text>
                                            <Text style={styles.faceTime}>
                                                {new Date(item.registerTime).toLocaleString()}
                                            </Text>
                                        </View>
                                        <TouchableOpacity 
                                            style={styles.deleteBtn} 
                                            onPress={() => doRemoveFace(item.userId)}
                                        >
                                            <Text style={styles.deleteBtnText}>删除</Text>
                                        </TouchableOpacity>
                                    </View>
                                ))}
                            </View>
                        )}
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

    // Face List Styles
    faceItem: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        paddingVertical: 8,
        borderBottomWidth: StyleSheet.hairlineWidth,
        borderBottomColor: '#eee',
    },
    faceId: {
        fontSize: 14,
        color: '#333',
    },
    faceTime: {
        fontSize: 12,
        color: '#999',
        marginTop: 2,
    },
    deleteBtn: {
        backgroundColor: '#ff3b30',
        paddingHorizontal: 10,
        paddingVertical: 4,
        borderRadius: 4,
    },
    deleteBtnText: {
        color: '#fff',
        fontSize: 12,
    },

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
