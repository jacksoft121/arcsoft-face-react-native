package com.arcsoft.rn;

import android.content.Context;
import android.graphics.Bitmap;

import com.arcsoft.face.FaceEngine;
import com.arcsoft.face.FaceFeature;
import com.arcsoft.face.FaceInfo;
import com.arcsoft.face.LivenessInfo;
import com.arcsoft.face.enums.DetectMode;
import com.arcsoft.face.enums.LivenessType;
import com.arcsoft.face.enums.RuntimeABI;
import com.arcsoft.face.toolkit.ImageInfo;

import java.util.ArrayList;
import java.util.List;

public class ArcFaceManager {

    private final FaceEngine engine;
    private final Context context;

    public ArcFaceManager(Context context) {
        this.context = context.getApplicationContext();
        this.engine = FaceEngineHolder.get(context);
    }

    // =========================
    // 1️⃣ 人脸检测
    // =========================
    public List<FaceInfo> detectFaces(Bitmap bitmap) {
        ImageInfo imageInfo = ImageInfo.fromBitmap(bitmap);
        List<FaceInfo> faceInfoList = new ArrayList<>();
        engine.detectFaces(
                imageInfo.getImageData(),
                imageInfo.getWidth(),
                imageInfo.getHeight(),
                imageInfo.getImageFormat(),
                faceInfoList
        );
        return faceInfoList;
    }

    // =========================
    // 2️⃣ 特征提取
    // =========================
    public byte[] extractFeature(Bitmap bitmap, FaceInfo faceInfo) {
        ImageInfo imageInfo = ImageInfo.fromBitmap(bitmap);
        FaceFeature feature = new FaceFeature();

        int code = engine.extractFaceFeature(
                imageInfo.getImageData(),
                imageInfo.getWidth(),
                imageInfo.getHeight(),
                imageInfo.getImageFormat(),
                faceInfo,
                feature
        );

        if (code != 0) {
            return null;
        }
        return feature.getFeatureData();
    }

    // =========================
    // 3️⃣ 特征比对
    // =========================
    public float compare(byte[] f1, byte[] f2) {
        FaceFeature ff1 = new FaceFeature(f1);
        FaceFeature ff2 = new FaceFeature(f2);
        return engine.compareFaceFeature(ff1, ff2);
    }

    // =========================
    // 4️⃣ 活体检测（RGB）
    // =========================
    public int livenessDetect(Bitmap bitmap, FaceInfo faceInfo) {
        ImageInfo imageInfo = ImageInfo.fromBitmap(bitmap);
        List<FaceInfo> faceList = new ArrayList<>();
        faceList.add(faceInfo);

        engine.process(
                imageInfo.getImageData(),
                imageInfo.getWidth(),
                imageInfo.getHeight(),
                imageInfo.getImageFormat(),
                faceList,
                FaceEngine.ASF_LIVENESS
        );

        List<LivenessInfo> livenessInfos = new ArrayList<>();
        engine.getLiveness(livenessInfos);

        if (livenessInfos.isEmpty()) return -1;
        return livenessInfos.get(0).getLiveness();
    }

    // =========================
    // 5️⃣ SDK 版本 & ABI
    // =========================
    public String getVersion() {
        return engine.getVersion();
    }

    public RuntimeABI getRuntimeABI() {
        return engine.getRuntimeABI();
    }

    // =========================
    // 6️⃣ 释放
    // =========================
    public void release() {
        FaceEngineHolder.release();
    }
}
