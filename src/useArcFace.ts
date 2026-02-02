import { useCallback, useEffect, useMemo, useRef } from 'react';
import { useFrameProcessor, useFrameProcessorPlugin } from 'react-native-vision-camera';
import { runOnJS } from 'react-native-reanimated';
import type { Frame } from 'react-native-vision-camera';

import type {
    ArcFacePluginResult,
    ArcFacePluginParams,
    ArcFaceProcessResult,
} from './types';
import { ArcFaceRegistry } from './ArcFaceRegistry';

type UseArcFaceOptions = {
    threshold?: number; // default 0.8
    /** 实时识别结果回调（process_result） */
    onResult?: (res: ArcFaceProcessResult) => void;
    /** 注册A完成回调（你可以用来提示 UI） */
    onRegisteredFromFrame?: (userId: string) => void;
};

export function useArcFace(options: UseArcFaceOptions = {}) {
    const threshold = options.threshold ?? 0.8;

    const plugin = useFrameProcessorPlugin('arcFace');
    const pendingRegisterUserIdRef = useRef<string | null>(null);

    // 进入识别页时：把持久化库加载到 Native 内存（离线可用）
    useEffect(() => {
        ArcFaceRegistry.loadAll().catch(() => {});
    }, []);

    const requestRegisterFromFrame = useCallback((userId: string) => {
        pendingRegisterUserIdRef.current = userId;
    }, []);

    const frameProcessor = useFrameProcessor(
        (frame: Frame) => {
            'worklet';
            if (!plugin) return;

            const pendingUserId = pendingRegisterUserIdRef.current;

            const params: ArcFacePluginParams = pendingUserId
                ? { action: 'register_from_frame', userId: pendingUserId }
                : { action: 'process', threshold };

            const res = plugin.call(frame, params as any) as ArcFacePluginResult | null;
            if (!res) return;

            if (res.type === 'process_result') {
                if (options.onResult) {
                    runOnJS(options.onResult)(res);
                }
                return;
            }

            if (res.type === 'register_result') {
                // 清空 pending
                pendingRegisterUserIdRef.current = null;

                // 把特征写入 registry（Native 内存 + debounce 落盘）
                runOnJS(ArcFaceRegistry.upsert)(res.userId, res.featureBase64, res.featureSize);

                if (options.onRegisteredFromFrame) {
                    runOnJS(options.onRegisteredFromFrame)(res.userId);
                }
            }
        },
        [plugin, threshold, options.onResult, options.onRegisteredFromFrame],
    );

    return {
        frameProcessor,
        requestRegisterFromFrame,
    };
}
