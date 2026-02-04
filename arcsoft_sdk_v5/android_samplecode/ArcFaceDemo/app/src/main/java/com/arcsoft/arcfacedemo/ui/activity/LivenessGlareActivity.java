package com.arcsoft.arcfacedemo.ui.activity;

import android.Manifest;
import android.content.pm.ActivityInfo;
import android.graphics.Color;
import android.graphics.Point;
import android.hardware.Camera;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;
import android.view.Window;
import android.view.WindowManager;
import android.widget.RelativeLayout;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.databinding.DataBindingUtil;
import androidx.lifecycle.ViewModelProvider;

import com.arcsoft.arcfacedemo.R;
import com.arcsoft.arcfacedemo.databinding.ActivityLivenessGlareBinding;
import com.arcsoft.arcfacedemo.ui.model.PreviewConfig;
import com.arcsoft.arcfacedemo.ui.viewmodel.GlareLivenessViewModel;
import com.arcsoft.arcfacedemo.ui.viewmodel.InteractiveLivenessViewModel;
import com.arcsoft.arcfacedemo.util.ConfigUtil;
import com.arcsoft.arcfacedemo.util.FaceRectTransformer;
import com.arcsoft.arcfacedemo.util.camera.CameraListener;
import com.arcsoft.arcfacedemo.util.camera.DualCameraHelper;
import com.arcsoft.arcfacedemo.util.face.constants.LivenessType;
import com.arcsoft.arcfacedemo.util.face.model.FacePreviewInfo;
import com.arcsoft.arcfacedemo.widget.FaceRectView;
import com.arcsoft.arcfacedemo.widget.HollowCircleView;

import java.util.List;

public class LivenessGlareActivity extends BaseActivity implements ViewTreeObserver.OnGlobalLayoutListener{

    private static final String TAG = "LivenessGlareActivity";
    private static final String[] NEEDED_PERMISSIONS = new String[]{
            Manifest.permission.CAMERA};
    private DualCameraHelper rgbCameraHelper;
    private FaceRectTransformer rgbFaceRectTransformer;
    private PreviewConfig previewConfig;

    private ActivityLivenessGlareBinding binding;
    private GlareLivenessViewModel viewModel;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = DataBindingUtil.setContentView(this, R.layout.activity_liveness_glare);
        //保持亮屏
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        WindowManager.LayoutParams attributes = getWindow().getAttributes();
        attributes.systemUiVisibility = View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION;
        getWindow().setAttributes(attributes);
        // Activity启动后就锁定为启动时的方向
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LOCKED);

        initViewModel();
        initData();
        initView();
    }

    private void initViewModel() {
        viewModel = new ViewModelProvider(getViewModelStore(), new ViewModelProvider.AndroidViewModelFactory(getApplication()))
                .get(GlareLivenessViewModel.class);
        viewModel.init();

        viewModel.getCurrentColor().observe(this, colorValue -> {
            binding.hollowCircle.setOverlayColor(colorValue.intValue());
            binding.llRootView.setBackgroundColor(colorValue.intValue());
            Log.i(TAG, "setBackgroundColor time" + System.currentTimeMillis());
            new Handler().postDelayed(new Runnable() {
                @Override
                public void run() {
                    viewModel.setEnableCollectColorImage();
                }
            }, 100);
        });
    }

    private void initView() {
        binding.cameraTexturePreviewRgb.getViewTreeObserver().addOnGlobalLayoutListener(this);

        Window window = getWindow();
        WindowManager.LayoutParams layoutParams = window.getAttributes();
        layoutParams.screenBrightness = 1f;
        window.setAttributes(layoutParams);

        binding.btnStartDetect.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                viewModel.startDetect();
            }
        });
    }

    private void initData() {
        boolean switchCamera = ConfigUtil.isSwitchCamera(this);
        previewConfig = new PreviewConfig(
                switchCamera ? Camera.CameraInfo.CAMERA_FACING_FRONT : Camera.CameraInfo.CAMERA_FACING_BACK,
                switchCamera ? Camera.CameraInfo.CAMERA_FACING_BACK : Camera.CameraInfo.CAMERA_FACING_FRONT,
                Integer.parseInt(ConfigUtil.getRgbCameraAdditionalRotation(this)),
                Integer.parseInt(ConfigUtil.getIrCameraAdditionalRotation(this))
        );
    }

    @Override
    public void onGlobalLayout() {
        binding.cameraTexturePreviewRgb.getViewTreeObserver().removeOnGlobalLayoutListener(this);
        if (!checkPermissions(NEEDED_PERMISSIONS)) {
            ActivityCompat.requestPermissions(this, NEEDED_PERMISSIONS, ACTION_REQUEST_PERMISSIONS);
        } else {
            initRgbCamera();
        }
    }

    private void initRgbCamera() {
        CameraListener cameraListener = new CameraListener() {
            @Override
            public void onCameraOpened(Camera camera, int cameraId, int displayOrientation, boolean isMirror) {
                Log.i(TAG, "onCameraOpened");
                Camera.Size previewSizeRgb = camera.getParameters().getPreviewSize();
                ViewGroup.LayoutParams layoutParams = adjustPreviewViewSize(binding.cameraTexturePreviewRgb, binding.cameraTexturePreviewRgb,
                        binding.cameraFaceRectView,
                        previewSizeRgb, displayOrientation, 1.0f);
                rgbFaceRectTransformer = new FaceRectTransformer(
                        previewSizeRgb.width, previewSizeRgb.height,
                        layoutParams.width, layoutParams.height,
                        displayOrientation, cameraId, isMirror,
                        ConfigUtil.isDrawRgbRectHorizontalMirror(LivenessGlareActivity.this),
                        ConfigUtil.isDrawRgbRectVerticalMirror(LivenessGlareActivity.this)
                );
                TextView textViewRgb = new TextView(LivenessGlareActivity.this, null);
                textViewRgb.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT));
                textViewRgb.setText(getString(R.string.camera_rgb_preview_size, previewSizeRgb.width, previewSizeRgb.height));
                textViewRgb.setTextColor(Color.WHITE);
                textViewRgb.setBackgroundColor(getResources().getColor(R.color.color_bg_notification));
                ((RelativeLayout) binding.cameraTexturePreviewRgb.getParent()).addView(textViewRgb);

                viewModel.onRgbCameraOpened(camera);
                viewModel.setRgbFaceRectTransformer(rgbFaceRectTransformer);
            }


            @Override
            public void onPreview(final byte[] nv21, Camera camera) {
                binding.cameraFaceRectView.clearFaceInfo();
                List<FacePreviewInfo> facePreviewInfoList = viewModel.onPreviewFrame(nv21);
                if (facePreviewInfoList != null && rgbFaceRectTransformer != null) {
                    drawPreviewInfo(facePreviewInfoList);
                }
            }

            @Override
            public void onCameraClosed() {
                Log.i(TAG, "onCameraClosed: ");
            }

            @Override
            public void onCameraError(Exception e) {
                Log.e(TAG, "onCameraError: " + e.getMessage());
            }

            @Override
            public void onCameraConfigurationChanged(int cameraID, int displayOrientation) {
                if (rgbFaceRectTransformer != null) {
                    rgbFaceRectTransformer.setCameraDisplayOrientation(displayOrientation);
                }
                Log.i(TAG, "onCameraConfigurationChanged: " + cameraID + "  " + displayOrientation);
            }
        };

        rgbCameraHelper = new DualCameraHelper.Builder()
                .previewViewSize(new Point(binding.cameraTexturePreviewRgb.getMeasuredWidth(), binding.cameraTexturePreviewRgb.getMeasuredHeight()))
                .rotation(getWindowManager().getDefaultDisplay().getRotation())
                .specificCameraId(previewConfig.getRgbCameraId())
                .isMirror(ConfigUtil.isDrawRgbPreviewHorizontalMirror(this))
                .additionalRotation(Integer.parseInt(ConfigUtil.getRgbCameraAdditionalRotation(this)))
                .previewSize(viewModel.loadPreviewSize())
                .previewOn(binding.cameraTexturePreviewRgb)
                .cameraListener(cameraListener)
                .build();
        rgbCameraHelper.init();
        rgbCameraHelper.start();
    }

    private ViewGroup.LayoutParams adjustPreviewViewSize(View rgbPreview, View previewView, FaceRectView faceRectView, Camera.Size previewSize,
                                                         int displayOrientation, float scale) {
        ViewGroup.LayoutParams layoutParams = previewView.getLayoutParams();
        int measuredWidth = previewView.getMeasuredWidth();
        int measuredHeight = previewView.getMeasuredHeight();
        float ratio = ((float) previewSize.height) / (float) previewSize.width;
        if (ratio > 1) {
            ratio = 1 / ratio;
        }
        if (displayOrientation % 180 == 0) {
            layoutParams.width = measuredWidth;
            layoutParams.height = (int) (measuredWidth * ratio);
        } else {
            layoutParams.height = measuredHeight;
            layoutParams.width = (int) (measuredHeight * ratio);
        }
        if (scale < 1f) {
            ViewGroup.LayoutParams rgbParam = rgbPreview.getLayoutParams();
            layoutParams.width = (int) (rgbParam.width * scale);
            layoutParams.height = (int) (rgbParam.height * scale);
        } else {
            layoutParams.width *= scale;
            layoutParams.height *= scale;
        }


        DisplayMetrics metrics = new DisplayMetrics();
        getWindowManager().getDefaultDisplay().getMetrics(metrics);

        if (layoutParams.width >= metrics.widthPixels) {
            float viewRatio = layoutParams.width / ((float) metrics.widthPixels);
            layoutParams.width /= viewRatio;
            layoutParams.height /= viewRatio;
        }
        if (layoutParams.height >= metrics.heightPixels) {
            float viewRatio = layoutParams.height / ((float) metrics.heightPixels);
            layoutParams.width /= viewRatio;
            layoutParams.height /= viewRatio;
        }

        previewView.setLayoutParams(layoutParams);
        faceRectView.setLayoutParams(layoutParams);
        binding.hollowCircle.setLayoutParams(layoutParams);
        int centerX = layoutParams.width / 2;
        int centerY = layoutParams.height / 2 - layoutParams.height / 6;
        binding.hollowCircle.setHollowCircle(centerX, centerY,  400);

        binding.hollowCircle.postDelayed(() -> {

        }, 3000);

        return layoutParams;
    }

    private void drawPreviewInfo(List<FacePreviewInfo> facePreviewInfoList) {
        if (rgbFaceRectTransformer != null) {
            List<FaceRectView.DrawInfo> rgbDrawInfoList = viewModel.getDrawInfo(facePreviewInfoList, LivenessType.RGB);
            binding.cameraFaceRectView.drawRealtimeFaceInfo(rgbDrawInfoList);
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        resumeCamera();
    }

    private void resumeCamera() {
        if (rgbCameraHelper != null) {
            rgbCameraHelper.start();
        }
    }

    @Override
    protected void onPause() {
        pauseCamera();
        super.onPause();
    }

    private void pauseCamera() {
        if (rgbCameraHelper != null) {
            rgbCameraHelper.stop();
        }
    }

    @Override
    protected void onDestroy() {
        if (rgbCameraHelper != null) {
            rgbCameraHelper.release();
            rgbCameraHelper = null;
        }
        viewModel.destroy();
        super.onDestroy();
    }
}
