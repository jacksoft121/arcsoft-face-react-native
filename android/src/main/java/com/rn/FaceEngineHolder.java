package com.arcsoft.rn;

import android.content.Context;
import android.util.Log;

import com.arcsoft.face.EngineConfiguration;
import com.arcsoft.face.FaceEngine;
import com.arcsoft.face.enums.DetectFaceOrientPriority;
import com.arcsoft.face.enums.DetectMode;

public class FaceEngineHolder {

    private static final String TAG = "ArcFaceEngine";
    private static FaceEngine faceEngine;
    private static boolean inited = false;

    public static synchronized FaceEngine get(Context context) {
        if (faceEngine == null) {
            faceEngine = new FaceEngine();
        }
        if (!inited) {
            init(context);
        }
        return faceEngine;
    }

    private static void init(Context context) {
        EngineConfiguration config = new EngineConfiguration();
        config.setDetectMode(DetectMode.ASF_DETECT_MODE_VIDEO);
        config.setDetectFaceOrientPriority(DetectFaceOrientPriority.ASF_OP_0_HIGHER_EXT);
        config.setDetectFaceMaxNum(10);
        config.setDetectFaceScaleVal(16);

        int code = faceEngine.init(context, config);
        if (code != 0) {
            throw new RuntimeException("FaceEngine init failed: " + code);
        }
        inited = true;
        Log.i(TAG, "FaceEngine init success");
    }

    public static synchronized void release() {
        if (faceEngine != null && inited) {
            faceEngine.unInit();
            inited = false;
            faceEngine = null;
        }
    }
}
