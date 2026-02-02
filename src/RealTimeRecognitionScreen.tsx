import React, { useMemo, useState } from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import { Camera, useCameraDevice } from 'react-native-vision-camera';
import { useArcFace } from 'rn-arcface'; // 你插件包名
import type { ArcFaceProcessResult } from 'rn-arcface';

export default function RealTimeRecognitionScreen() {
    const device = useCameraDevice('front');
    const [last, setLast] = useState<string>('');

    const { frameProcessor, requestRegisterFromFrame } = useArcFace({
        threshold: 0.8,
        onResult: (res: ArcFaceProcessResult) => {
            if (res.matchedUserId && res.score && res.score > 0) {
                setLast(`✅ ${res.matchedUserId}  score=${res.score.toFixed(3)}`);
            } else {
                setLast('未命中');
            }
        },
        onRegisteredFromFrame: (userId) => {
            setLast(`📌 已从当前画面注册：${userId}`);
        },
    });

    if (!device) return <Text>无相机设备</Text>;

    return (
        <View style={{ flex: 1 }}>
            <Camera
                style={{ flex: 1 }}
                device={device}
                isActive={true}
                frameProcessor={frameProcessor}
                frameProcessorFps={5} // 建议 5~10
                pixelFormat="yuv"
            />

            <View style={{ padding: 12 }}>
                <Text>{last}</Text>

                <TouchableOpacity
                    style={{ marginTop: 10, padding: 12, backgroundColor: '#333' }}
                    onPress={() => requestRegisterFromFrame('stu_001')}
                >
                    <Text style={{ color: '#fff' }}>用当前画面注册 stu_001（注册A）</Text>
                </TouchableOpacity>
            </View>
        </View>
    );
}
