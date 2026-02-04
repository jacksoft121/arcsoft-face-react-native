import React, {useCallback, useEffect, useMemo, useRef, useState} from 'react';
import {Alert, Platform, SafeAreaView, Text, TouchableOpacity, View} from 'react-native';
import {Camera, useCameraDevice, useCameraPermission, useFrameProcessor} from 'react-native-vision-camera';
import {runAtTargetFps} from 'react-native-vision-camera';
import {useResizePlugin} from 'vision-camera-resize-plugin';

import ArcsoftFace from 'arcsoft-face-react-native'; // ✅ 你的插件包名（按你实际 node_modules 名称）

type FaceInfo = {
    rect: {left: number; top: number; right: number; bottom: number};
    orient: number;
    faceData?: number[]; // 有的 SDK 会带；你 TS 里写的是可选
};

function u8ToNumberArray(u8: Uint8Array): number[] {
    // TurboModule 端用 number[]，这里做一次转换
    return Array.from(u8, (v) => v);
}

export default function ArcsoftFaceTestScreen() {
    const device = useCameraDevice('back');
    const {hasPermission, requestPermission} = useCameraPermission();
    const {resize} = useResizePlugin();

    const [inited, setInited] = useState(false);
    const [activeCode, setActiveCode] = useState<number | null>(null);
    const [engineCode, setEngineCode] = useState<number | null>(null);

    const [faceCount, setFaceCount] = useState(0);
    const [lastScore, setLastScore] = useState<number | null>(null);

    // “已注册的一张脸”的特征（演示用）
    const registeredFeatureRef = useRef<number[] | null>(null);

    const requestCam = useCallback(async () => {
        const ok = await requestPermission();
        if (!ok) Alert.alert('需要摄像头权限');
    }, [requestPermission]);

    // 1) SDK 激活（在线激活）
    const onActivate = useCallback(async () => {
        try {
            // TODO: 换成你的 appId / sdkKey
            const appId = 'YOUR_APP_ID';
            const sdkKey = Platform.OS === 'android' ? 'YOUR_ANDROID_SDK_KEY' : 'YOUR_IOS_SDK_KEY';

            const code = await ArcsoftFace.activateOnline(appId, sdkKey);
            setActiveCode(code);

            if (code === 0) {
                const info = await ArcsoftFace.getActiveFileInfo();
                Alert.alert('激活成功', JSON.stringify(info, null, 2));
            } else {
                Alert.alert('激活失败', `code=${code}`);
            }
        } catch (e: any) {
            Alert.alert('激活异常', String(e?.message || e));
        }
    }, []);

    // 2) 引擎初始化
    const onInitEngine = useCallback(async () => {
        try {
            const code = await ArcsoftFace.initEngine();
            setEngineCode(code);
            if (code === 0) {
                setInited(true);
                Alert.alert('引擎初始化成功');
            } else {
                Alert.alert('引擎初始化失败', `code=${code}`);
            }
        } catch (e: any) {
            Alert.alert('初始化异常', String(e?.message || e));
        }
    }, []);

    // 3) 释放引擎
    const onRelease = useCallback(async () => {
        try {
            const code = await ArcsoftFace.releaseEngine();
            setInited(false);
            setFaceCount(0);
            registeredFeatureRef.current = null;
            setLastScore(null);
            Alert.alert('release', `code=${code}`);
        } catch (e: any) {
            Alert.alert('释放异常', String(e?.message || e));
        }
    }, []);

    // 4) 在当前帧上做 detect +（可选）抽特征/对比
    const frameProcessor = useFrameProcessor(
        (frame) => {
            if (!inited) return;

            runAtTargetFps(6, () => {
                'worklet';
                try {
                    // ✅ 关键：把 Camera frame resize 到 NV21
                    // 注：不同版本 resize 插件入参略有差异，你工程里能跑哪个就按哪个；
                    // 这里是常见写法：format: 'nv21'
                    const out = resize(frame, {
                        width: 640,
                        height: 480,
                        format: 'nv21',
                    });

                    // out 通常是 Uint8Array / ArrayBuffer
                    // @ts-ignore
                    const bytes: Uint8Array = out instanceof Uint8Array ? out : new Uint8Array(out);

                    // worklet 里不能直接 await TurboModule；所以把数据抛到 JS 线程处理
                    // 这里用 globalThis + setImmediate 方式，简单可靠
                    // @ts-ignore
                    globalThis.__arcsoft_last_nv21 = bytes;
                    // @ts-ignore
                    globalThis.__arcsoft_last_wh = {w: 640, h: 480};
                } catch (e) {
                    // ignore
                }
            });
        },
        [inited, resize],
    );

    // JS 侧轮询取 frameProcessor 产出的 NV21，再调用 TurboModule
    useEffect(() => {
        if (!inited) return;

        let alive = true;
        const timer = setInterval(async () => {
            if (!alive) return;

            // @ts-ignore
            const bytes: Uint8Array | undefined = globalThis.__arcsoft_last_nv21;
            // @ts-ignore
            const wh: {w: number; h: number} | undefined = globalThis.__arcsoft_last_wh;
            if (!bytes || !wh) return;

            try {
                const data = u8ToNumberArray(bytes);
                const faces: FaceInfo[] = await ArcsoftFace.detectFacesNV21(data, wh.w, wh.h);
                setFaceCount(faces?.length || 0);

                // 演示：若检测到人脸，可抽第一张的特征
                if (faces && faces.length > 0) {
                    // 仅在“已注册特征”为空时，允许你手动点击按钮注册；这里不自动注册
                }
            } catch (e) {
                // ignore
            }
        }, 250);

        return () => {
            alive = false;
            clearInterval(timer);
        };
    }, [inited]);

    // 5) “注册当前画面第一张脸” -> 保存 feature
    const onRegisterCurrentFace = useCallback(async () => {
        try {
            // @ts-ignore
            const bytes: Uint8Array | undefined = globalThis.__arcsoft_last_nv21;
            // @ts-ignore
            const wh: {w: number; h: number} | undefined = globalThis.__arcsoft_last_wh;
            if (!bytes || !wh) {
                Alert.alert('还没拿到相机帧');
                return;
            }

            const data = u8ToNumberArray(bytes);
            const faces: FaceInfo[] = await ArcsoftFace.detectFacesNV21(data, wh.w, wh.h);
            if (!faces || faces.length === 0) {
                Alert.alert('未检测到人脸');
                return;
            }

            const feature = await ArcsoftFace.extractFeatureNV21(data, wh.w, wh.h, faces[0]);
            registeredFeatureRef.current = feature;
            Alert.alert('注册成功', `feature length=${feature?.length || 0}`);
        } catch (e: any) {
            Alert.alert('注册异常', String(e?.message || e));
        }
    }, []);

    // 6) “用当前画面第一张脸与已注册特征对比”
    const onCompareWithRegistered = useCallback(async () => {
        try {
            const reg = registeredFeatureRef.current;
            if (!reg) {
                Alert.alert('请先注册一张脸特征');
                return;
            }

            // @ts-ignore
            const bytes: Uint8Array | undefined = globalThis.__arcsoft_last_nv21;
            // @ts-ignore
            const wh: {w: number; h: number} | undefined = globalThis.__arcsoft_last_wh;
            if (!bytes || !wh) {
                Alert.alert('还没拿到相机帧');
                return;
            }

            const data = u8ToNumberArray(bytes);
            const faces: FaceInfo[] = await ArcsoftFace.detectFacesNV21(data, wh.w, wh.h);
            if (!faces || faces.length === 0) {
                Alert.alert('未检测到人脸');
                return;
            }

            const cur = await ArcsoftFace.extractFeatureNV21(data, wh.w, wh.h, faces[0]);
            const score = await ArcsoftFace.compareFeature(reg, cur);
            setLastScore(score);
            Alert.alert('比对完成', `score=${score}`);
        } catch (e: any) {
            Alert.alert('比对异常', String(e?.message || e));
        }
    }, []);

    useEffect(() => {
        if (!hasPermission) requestCam();
    }, [hasPermission, requestCam]);

    return (
        <SafeAreaView style={{flex: 1, backgroundColor: '#111'}}>
            <View style={{padding: 12}}>
                <Text style={{color: '#fff', fontSize: 18, fontWeight: '600'}}>ArcSoft RN 插件验证页</Text>
                <Text style={{color: '#aaa', marginTop: 6}}>activeCode: {String(activeCode)}</Text>
                <Text style={{color: '#aaa'}}>engineCode: {String(engineCode)}</Text>
                <Text style={{color: '#aaa'}}>faceCount: {faceCount}</Text>
                <Text style={{color: '#aaa'}}>lastScore: {lastScore == null ? '-' : String(lastScore)}</Text>

                <View style={{flexDirection: 'row', flexWrap: 'wrap', marginTop: 10, gap: 8}}>
                    <Btn title="1) 在线激活" onPress={onActivate} />
                    <Btn title="2) 初始化引擎" onPress={onInitEngine} />
                    <Btn title="3) 注册当前人脸" onPress={onRegisterCurrentFace} />
                    <Btn title="4) 与注册脸比对" onPress={onCompareWithRegistered} />
                    <Btn title="5) release" onPress={onRelease} />
                </View>
            </View>

            <View style={{flex: 1}}>
                {device && hasPermission ? (
                    <Camera
                        style={{flex: 1}}
                        device={device}
                        isActive={true}
                        pixelFormat="yuv"
                        frameProcessor={frameProcessor}
                    />
                ) : (
                    <View style={{flex: 1, alignItems: 'center', justifyContent: 'center'}}>
                        <Text style={{color: '#fff'}}>等待相机权限/设备…</Text>
                    </View>
                )}
            </View>
        </SafeAreaView>
    );
}

function Btn({title, onPress}: {title: string; onPress: () => void}) {
    return (
        <TouchableOpacity
            onPress={onPress}
            style={{
                paddingHorizontal: 12,
                paddingVertical: 10,
                backgroundColor: '#2a2a2a',
                borderRadius: 10,
            }}>
            <Text style={{color: '#fff'}}>{title}</Text>
        </TouchableOpacity>
    );
}
