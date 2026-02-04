package com.arcsoft.arcfacedemo.util;

import android.media.Image;

public class Camera2TimestampHelper {

    private static final String TAG = "Camera2TimestampHelper";

    private long baseSystemTimeMs = 0;
    private long baseNanoTimeNs = 0;
    private long timestampOffsetNs = Long.MIN_VALUE;

    private Camera2TimestampHelper() {
    }

    private static class Holder {
        private static final Camera2TimestampHelper INSTANCE = new Camera2TimestampHelper();
    }

    public static Camera2TimestampHelper getInstance() {
        return Holder.INSTANCE;
    }

    /**
     * 初始化基准点
     */
    public void init() {
        baseSystemTimeMs = System.currentTimeMillis();
        baseNanoTimeNs = System.nanoTime();
    }

    /**
     * 计算 HAL 时钟和系统时钟的偏移（首次调用时自动）
     */
    private void calculateOffset(long imageTimestampNs) {
        if (timestampOffsetNs == Long.MIN_VALUE) {
            long currentNanoTime = System.nanoTime();
            timestampOffsetNs = currentNanoTime - imageTimestampNs;
        }
    }

    /**
     * 将 Image.getTimestamp() 转换为系统时间（毫秒）
     */
    public long getSystemTimeMs(Image image) {
        long imageTimestampNs = image.getTimestamp();
        calculateOffset(imageTimestampNs);
        // Image时间戳+偏移 = 系统nanoTime
        long estimatedNanoTime = imageTimestampNs + timestampOffsetNs;
        // 系统时间 = 基准SystemTime + (estimatedNanoTime - baseNanoTime) / 1_000_000
        long estimatedSystemTimeMs = baseSystemTimeMs + (estimatedNanoTime - baseNanoTimeNs) / 1_000_000L;
        return estimatedSystemTimeMs;
    }

    /**
     * 重置偏移（如果摄像头重启）
     */
    public void reset() {
        timestampOffsetNs = Long.MIN_VALUE;
    }
}

