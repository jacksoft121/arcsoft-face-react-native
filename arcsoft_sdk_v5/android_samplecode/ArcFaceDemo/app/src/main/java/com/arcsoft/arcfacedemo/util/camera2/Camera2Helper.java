package com.arcsoft.arcfacedemo.util.camera2;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.ImageFormat;
import android.graphics.Point;
import android.graphics.SurfaceTexture;
import android.hardware.Camera;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.CaptureResult;
import android.hardware.camera2.TotalCaptureResult;
import android.hardware.camera2.params.StreamConfigurationMap;
import android.media.Image;
import android.media.ImageReader;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Looper;
import android.util.Log;
import android.util.Size;
import android.view.Surface;
import android.view.TextureView;
import android.view.WindowManager;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

public class Camera2Helper {

    private static final String TAG = Camera2Helper.class.getSimpleName();

    private final TextureView.SurfaceTextureListener surfaceTextureListener = new TextureView.SurfaceTextureListener() {

        @Override
        public void onSurfaceTextureAvailable(@NonNull SurfaceTexture surface, int width, int height) {
            openCamera(surface);
        }

        @Override
        public void onSurfaceTextureSizeChanged(@NonNull SurfaceTexture surface, int width, int height) {
        }

        @Override
        public boolean onSurfaceTextureDestroyed(@NonNull SurfaceTexture surface) {
            closeCamera();
            return false;
        }

        @Override
        public void onSurfaceTextureUpdated(@NonNull SurfaceTexture surface) {
        }
    };

    private final CameraDevice.StateCallback stateCallback = new CameraDevice.StateCallback() {

        @Override
        public void onOpened(@NonNull CameraDevice camera) {
            Log.i(TAG, "camera2 onOpened:" + camera.getId());
            cameraLock.release();
            cameraDevice = camera;
            createCameraPreviewSession();
            if (camera2Listener != null) {
                camera2Listener.onCamera2Opened(previewSize, getCameraOri(), cameraId);
            }
        }

        @Override
        public void onDisconnected(@NonNull CameraDevice camera) {
            cameraLock.release();
            camera.close();
            if (camera2Listener != null) {
                camera2Listener.onCamera2Closed();
            }
        }

        @Override
        public void onError(@NonNull CameraDevice camera, int error) {
            Log.i(TAG, "camera2 onError:" + error);
            onDisconnected(camera);
        }
    };

    private final ImageReader.OnImageAvailableListener onImageAvailableListener = new ImageReader.OnImageAvailableListener() {
        @Override
        public void onImageAvailable(ImageReader reader) {
            final Image image = reader.acquireLatestImage();
            if (image == null) {
                return;
            }
            if (camera2Listener != null) {
                camera2Listener.onImageAvailable(image);
            }
            image.close();
        }
    };

    private final CameraCaptureSession.CaptureCallback captureCallback = new CameraCaptureSession.CaptureCallback() {

        @Override
        public void onCaptureProgressed(@NonNull CameraCaptureSession session, @NonNull CaptureRequest request, @NonNull CaptureResult partialResult) {
            super.onCaptureProgressed(session, request, partialResult);
        }

        @Override
        public void onCaptureCompleted(@NonNull CameraCaptureSession session, @NonNull CaptureRequest request, @NonNull TotalCaptureResult result) {
            super.onCaptureCompleted(session, request, result);
        }
    };

    private static final int IMAGE_READER_FORMAT = ImageFormat.YUV_420_888;
    private final Semaphore cameraLock = new Semaphore(1);
    private boolean flashSupported = false;
    @NonNull
    private String specifiedCameraId = String.valueOf(Camera.CameraInfo.CAMERA_FACING_BACK);
    private Size specifiedPreviewSize;
    private String cameraId = String.valueOf(Camera.CameraInfo.CAMERA_FACING_FRONT);
    private CaptureRequest.Builder previewRequestBuilder;
    private CameraCaptureSession cameraCaptureSession;
    private CaptureRequest previewRequest;
    private CameraDevice cameraDevice;
    private CameraManager cameraManager;
    private Size previewSize;
    private SurfaceTexture surfaceTexture;
    private HandlerThread handlerThread;
    private Handler cameraHandler;
    private ImageReader imageReader;
    private WeakReference<Context> weakReferenceContext;
    private Point displaySize;
    private Camera2Listener camera2Listener;

    public void init(Context context, String specifiedCameraId, Size specifiedPreviewSize, Point displaySize) {
        this.displaySize = displaySize;
        this.specifiedCameraId = specifiedCameraId;
        this.specifiedPreviewSize = specifiedPreviewSize;
        if (weakReferenceContext == null) {
            weakReferenceContext = new WeakReference<>(context);
        }
        cameraManager = (CameraManager) weakReferenceContext.get().getSystemService(Context.CAMERA_SERVICE);
    }

    public void setCamera2Listener(Camera2Listener camera2Listener) {
        this.camera2Listener = camera2Listener;
    }

    public void resumeCamera(TextureView textureView) {
        startHandlerThread();
        if (textureView.isAvailable()) {
            openCamera(textureView.getSurfaceTexture());
        } else {
            textureView.setSurfaceTextureListener(surfaceTextureListener);
        }
    }

    public void resumeCamera() {
        startHandlerThread();
        openCamera(null);
    }

    public void pauseCamera() {
        closeCamera();
        stopHandlerThread();
    }

    private void startHandlerThread() {
        if (handlerThread == null) {
            handlerThread = new HandlerThread("Camera2HandlerThread");
        }
        handlerThread.start();
        if (cameraHandler == null) {
            cameraHandler = new Handler(Looper.getMainLooper());
        }
    }

    private void stopHandlerThread() {
        if (handlerThread != null) {
            handlerThread.quitSafely();
            try {
                handlerThread.join();
                handlerThread = null;
                cameraHandler = null;
            } catch (Exception e) {
                Log.e(TAG, e.toString());
            }
        }
    }

    private void openCamera(SurfaceTexture surfaceTexture) {
        this.surfaceTexture = surfaceTexture;
        int permission = ContextCompat.checkSelfPermission(weakReferenceContext.get(), Manifest.permission.CAMERA);
        if (permission != PackageManager.PERMISSION_GRANTED) {
            Log.e(TAG, "Camera is not granted");
            return;
        }
        setUpCameraOutputs();
        configTransform();
        try {
            if (!cameraLock.tryAcquire(2500, TimeUnit.MILLISECONDS)) {
                throw new RuntimeException("Time out waiting to lock camera opening.");
            }
            if (cameraManager != null) {
                Log.i(TAG, "openCamera:" + cameraId);
                cameraManager.openCamera(cameraId, stateCallback, cameraHandler);
            }
        } catch (CameraAccessException e) {
            Log.e(TAG, e.getMessage());
        } catch (InterruptedException e) {
            throw new RuntimeException("Interrupted while trying to lock camera opening.", e);
        }
    }

    private void setUpCameraOutputs() {
        try {
            String[] cameraIdList = cameraManager.getCameraIdList();
            StringBuilder cameraIdBuilder = new StringBuilder();
            for (String cameraId : cameraIdList) {
                cameraIdBuilder.append(",").append(cameraId);
            }
            String cameraIdString = cameraIdBuilder.toString();
            Log.i(TAG, "cameraIdString:" + cameraIdString);
            boolean cameraIdValid = false;
            for (String cameraId : cameraIdList) {
                CameraCharacteristics characteristics = cameraManager.getCameraCharacteristics(cameraId);
                Integer cameraDir = characteristics.get(CameraCharacteristics.LENS_FACING);
                if (!cameraId.equals(specifiedCameraId)) {
                    continue;
                }
                this.cameraId = cameraId;
                cameraIdValid = true;
                StreamConfigurationMap map = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP);
                if (map == null) {
                    continue;
                }
                int sensorOrientation = characteristics.get(CameraCharacteristics.SENSOR_ORIENTATION);
                Log.i(TAG, "sensorOrientation:" + sensorOrientation);

                if (imageReader != null) {
                    imageReader.close();
                }
                previewSize = getBestPreviewSize(map.getOutputSizes(SurfaceTexture.class));
                imageReader = ImageReader.newInstance(previewSize.getWidth(), previewSize.getHeight(), IMAGE_READER_FORMAT, 5);
                imageReader.setOnImageAvailableListener(onImageAvailableListener, cameraHandler);
                flashSupported = characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE);
            }

//            boolean cameraIdValid;
//            CameraCharacteristics characteristics = cameraManager.getCameraCharacteristics("1");
//            Integer cameraDir = characteristics.get(CameraCharacteristics.LENS_FACING);
//            cameraIdValid = true;
//            StreamConfigurationMap map = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP);
//            if (imageReader != null) {
//                imageReader.close();
//            }
//            previewSize = getBestPreviewSize(map.getOutputSizes(SurfaceTexture.class));
//            imageReader = ImageReader.newInstance(previewSize.getWidth(), previewSize.getHeight(), IMAGE_READER_FORMAT, 5);
//            imageReader.setOnImageAvailableListener(onImageAvailableListener, cameraHandler);
//            flashSupported = characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE);

            if (!cameraIdValid) {
                Log.e(TAG, "specifiedCameraId is invalid");
            }
        } catch (CameraAccessException | NullPointerException e) {
            Log.e(TAG, e.toString());
        }
    }

    private void configTransform() {
//        textureView.setRotation(90);
    }

    private void createCameraPreviewSession() {
        try {
            List<Surface> outPuts;
            previewRequestBuilder = cameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW);
            Surface imageReaderSurface = imageReader.getSurface();
            previewRequestBuilder.addTarget(imageReaderSurface);
            if (surfaceTexture != null) {
                surfaceTexture.setDefaultBufferSize(previewSize.getWidth(), previewSize.getHeight());
                Surface surface = new Surface(surfaceTexture);
                previewRequestBuilder.addTarget(surface);
                outPuts = Arrays.asList(surface, imageReaderSurface);
            } else {
                outPuts = Collections.singletonList(imageReaderSurface);
            }
            cameraDevice.createCaptureSession(outPuts, new CameraCaptureSession.StateCallback() {

                @Override
                public void onConfigured(@NonNull CameraCaptureSession session) {
                    if (cameraDevice == null) {
                        return;
                    }
                    cameraCaptureSession = session;
                    try {
                        previewRequestBuilder.set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE);
                        setAutoFlash(previewRequestBuilder);
                        previewRequest = previewRequestBuilder.build();
                        cameraCaptureSession.setRepeatingRequest(previewRequest, captureCallback, cameraHandler);
                    } catch (Exception e) {
                        Log.e(TAG, e.toString());
                    }
                }

                @Override
                public void onConfigureFailed(@NonNull CameraCaptureSession session) {
                    Log.e(TAG, "onConfigureFailed deviceId:" + session.getDevice().getId());
                }
            }, cameraHandler);
        } catch (CameraAccessException e) {
            Log.e(TAG, e.toString());
        }
    }

    private void setAutoFlash(CaptureRequest.Builder requestBuilder) {
        if (flashSupported) {
            requestBuilder.set(CaptureRequest.CONTROL_AE_MODE, CaptureRequest.CONTROL_AE_MODE_ON_AUTO_FLASH);
        }
    }

    private void closeCamera() {
        try {
            cameraLock.acquire();
            if (cameraCaptureSession != null) {
                cameraCaptureSession.close();
                cameraCaptureSession = null;
            }
            if (cameraDevice != null) {
                cameraDevice.close();
                cameraDevice = null;
            }
            if (imageReader != null) {
                imageReader.close();
                imageReader = null;
            }
        } catch (Exception e) {
            Log.e(TAG, "" + e.getMessage());
        } finally {
            cameraLock.release();
        }
    }

    private Size getBestPreviewSize(@NonNull Size[] sizeArray) {
        if (specifiedPreviewSize != null) {
            return specifiedPreviewSize;
        }
        if (sizeArray.length == 0) {
            throw new IllegalStateException("camera size is invalid...");
        }
        float displayRatio = displaySize.x * 1.0F / displaySize.y;
        if (displayRatio > 1) {
            displayRatio = 1 / displayRatio;
        }
        Size bestSize = sizeArray[0];
        List<Size> bestSizeList = new ArrayList<>(sizeArray.length);
        for (Size size : sizeArray) {
            float sizeRatio = size.getWidth() * 1.0f / size.getHeight();
            if (sizeRatio > 1) {
                sizeRatio = 1 / sizeRatio;
            }
            if (Math.abs(sizeRatio - displayRatio) <= 0.1) {
                bestSizeList.add(size);
            }
        }
        if (bestSizeList.isEmpty()) {
            return bestSize;
        }
        return Collections.min(bestSizeList, new CompareSizes());
    }

    public boolean hasDualCamera() {
        try {
            return cameraManager != null && cameraManager.getCameraIdList().length > 1;
        } catch (Exception e) {
            Log.e(TAG, e.toString());
        }
        return false;
    }

    private static class CompareSizes implements Comparator<Size> {

        @Override
        public int compare(Size lhs, Size rhs) {
            return Long.signum((long) lhs.getWidth() * lhs.getHeight() - (long) rhs.getWidth() * rhs.getHeight());
        }
    }

    private int getCameraOri() {
        try {
            Context context = weakReferenceContext.get();
            CameraManager manager = (CameraManager) context.getSystemService(Context.CAMERA_SERVICE);
            CameraCharacteristics characteristics = manager.getCameraCharacteristics(cameraId);

            // 设备方向（0/90/180/270）
            int deviceRotation = ((WindowManager) context.getSystemService(Context.WINDOW_SERVICE))
                    .getDefaultDisplay().getRotation();
            int deviceDegrees = 0;
            switch (deviceRotation) {
                case Surface.ROTATION_0:
                    deviceDegrees = 0;
                    break;
                case Surface.ROTATION_90:
                    deviceDegrees = 90;
                    break;
                case Surface.ROTATION_180:
                    deviceDegrees = 180;
                    break;
                case Surface.ROTATION_270:
                    deviceDegrees = 270;
                    break;
            }

            // 摄像头方向
            int sensorOrientation = characteristics.get(CameraCharacteristics.SENSOR_ORIENTATION);

            // 是否前置
            int facing = characteristics.get(CameraCharacteristics.LENS_FACING);

            // 计算预览旋转角度
            int rotation;
            if (facing == CameraCharacteristics.LENS_FACING_FRONT) {
                rotation = (sensorOrientation + deviceDegrees) % 360;
                rotation = (360 - rotation) % 360; // 前置镜像
            } else { // 后置
                rotation = (sensorOrientation - deviceDegrees + 360) % 360;
            }
            return rotation;
        } catch (Exception e) {
        }
        return -1;
    }
}
