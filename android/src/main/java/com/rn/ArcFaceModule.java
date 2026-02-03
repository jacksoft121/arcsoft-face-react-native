package com.arcsoft.rn;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Base64;

import com.arcsoft.face.FaceInfo;
import com.facebook.react.bridge.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ArcFaceModule extends ReactContextBaseJavaModule {

    private final ArcFaceManager manager;

    public ArcFaceModule(ReactApplicationContext reactContext) {
        super(reactContext);
        manager = new ArcFaceManager(reactContext);
    }

    @Override
    public String getName() {
        return "ArcFace";
    }

    // =========================
    // detectFaces
    // =========================
    @ReactMethod
    public void detectFaces(String base64, Promise promise) {
        try {
            byte[] bytes = Base64.decode(base64, Base64.DEFAULT);
            Bitmap bmp = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);

            List<FaceInfo> faces = manager.detectFaces(bmp);
            WritableArray arr = Arguments.createArray();

            for (FaceInfo f : faces) {
                WritableMap m = Arguments.createMap();
                m.putInt("orient", f.getOrient());
                m.putInt("left", f.getRect().left);
                m.putInt("top", f.getRect().top);
                m.putInt("right", f.getRect().right);
                m.putInt("bottom", f.getRect().bottom);
                arr.pushMap(m);
            }
            promise.resolve(arr);
        } catch (Exception e) {
            promise.reject("detect_error", e);
        }
    }

    // =========================
    // extractFeature
    // =========================
    @ReactMethod
    public void extractFeature(String base64, ReadableMap face, Promise promise) {
        try {
            byte[] bytes = Base64.decode(base64, Base64.DEFAULT);
            Bitmap bmp = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);

            FaceInfo fi = new FaceInfo();
            fi.setOrient(face.getInt("orient"));
            fi.getRect().left = face.getInt("left");
            fi.getRect().top = face.getInt("top");
            fi.getRect().right = face.getInt("right");
            fi.getRect().bottom = face.getInt("bottom");

            byte[] feature = manager.extractFeature(bmp, fi);
            promise.resolve(Base64.encodeToString(feature, Base64.NO_WRAP));
        } catch (Exception e) {
            promise.reject("feature_error", e);
        }
    }

    // =========================
    // compare
    // =========================
    @ReactMethod
    public void compare(String f1, String f2, Promise promise) {
        byte[] b1 = Base64.decode(f1, Base64.DEFAULT);
        byte[] b2 = Base64.decode(f2, Base64.DEFAULT);
        promise.resolve(manager.compare(b1, b2));
    }

    // =========================
    // liveness
    // =========================
    @ReactMethod
    public void liveness(String base64, ReadableMap face, Promise promise) {
        try {
            byte[] bytes = Base64.decode(base64, Base64.DEFAULT);
            Bitmap bmp = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);

            FaceInfo fi = new FaceInfo();
            fi.setOrient(face.getInt("orient"));
            fi.getRect().left = face.getInt("left");
            fi.getRect().top = face.getInt("top");
            fi.getRect().right = face.getInt("right");
            fi.getRect().bottom = face.getInt("bottom");

            int result = manager.livenessDetect(bmp, fi);
            promise.resolve(result);
        } catch (Exception e) {
            promise.reject("liveness_error", e);
        }
    }
}
