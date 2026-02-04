package com.arcsoft.arcfacedemo.ui.activity;

import android.Manifest;
import android.content.pm.ActivityInfo;
import android.graphics.Color;
import android.graphics.Point;
import android.hardware.Camera;
import android.media.Image;
import android.os.Bundle;
import android.util.DisplayMetrics;
import android.util.Log;
import android.util.Size;
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
import com.arcsoft.arcfacedemo.databinding.ActivityLivenessInteractiveGlareCamera2Binding;
import com.arcsoft.arcfacedemo.ui.model.PreviewConfig;
import com.arcsoft.arcfacedemo.ui.viewmodel.InteractiveGlareLivenessCamera2ViewModel;
import com.arcsoft.arcfacedemo.util.Camera2TimestampHelper;
import com.arcsoft.arcfacedemo.util.ConfigUtil;
import com.arcsoft.arcfacedemo.util.FaceRectTransformer;
import com.arcsoft.arcfacedemo.util.camera2.Camera2Helper;
import com.arcsoft.arcfacedemo.util.camera2.Camera2Listener;
import com.arcsoft.arcfacedemo.util.face.constants.LivenessType;
import com.arcsoft.arcfacedemo.util.face.model.FacePreviewInfo;
import com.arcsoft.arcfacedemo.widget.FaceRectView;

import java.util.List;

/**
 * 结合交互式 + 炫光活体逻辑处理
 * 1.先执行交互式动作检测流程，会从四个动作里选择一个；
 * 2.交互式动作检测完成后，再执行炫光活体检测流程；
 * 3.上述两种检测都成功后，才判定本次检测成功；
 */
public class LivenessInteractiveGlareCamera2Activity extends BaseActivity implements ViewTreeObserver.OnGlobalLayoutListener{

    private static final String TAG = "LivenessInteractiveGlareCamera2Activity";
    private static final String[] NEEDED_PERMISSIONS = new String[]{
            Manifest.permission.CAMERA};
    private FaceRectTransformer rgbFaceRectTransformer;
    private PreviewConfig previewConfig;
    private Camera2Helper camera2Helper;

    private ActivityLivenessInteractiveGlareCamera2Binding binding;
    private InteractiveGlareLivenessCamera2ViewModel viewModel;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = DataBindingUtil.setContentView(this, R.layout.activity_liveness_interactive_glare_camera2);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        WindowManager.LayoutParams attributes = getWindow().getAttributes();
        attributes.systemUiVisibility = View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION;
        getWindow().setAttributes(attributes);
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LOCKED);

        initView();
        initViewModel();
        initData();
    }

    private void initViewModel() {
        viewModel = new ViewModelProvider(getViewModelStore(), new ViewModelProvider.AndroidViewModelFactory(getApplication()))
                .get(InteractiveGlareLivenessCamera2ViewModel.class);
        viewModel.init();

        viewModel.getCurrentColor().observe(this, colorValue -> {
            viewModel.updateBeginCollectColorImageTime();
            binding.hollowCircle.setOverlayColor(colorValue.intValue());
            binding.llRootView.setBackgroundColor(colorValue.intValue());
        });

        viewModel.getActionTip().observe(this, tipString -> {
            binding.tvLivenessTip.setText(tipString);
        });

        viewModel.getCollectColorImageLiveData().observe(this, collect -> {
            if (collect) {
                viewModel.startColorDetect();
            }
        });

        viewModel.getEndProcessLd().observe(this, end -> {
            if (end) {
                binding.btnStartDetect.setEnabled(true);
                binding.btnStartDetect.setText("开始检测");
                binding.btnStartDetect.setTextColor(Color.WHITE);
                binding.btnStartDetect.setBackgroundColor(ActivityCompat.getColor(this, R.color.colorPrimary));
            } else {
                binding.btnStartDetect.setText("检测中");
                binding.btnStartDetect.setEnabled(false);
                binding.btnStartDetect.setTextColor(Color.GRAY);
                binding.btnStartDetect.setBackgroundColor(Color.WHITE);
            }
        });
    }

    private void initView() {
        binding.cameraTexturePreviewRgb.getViewTreeObserver().addOnGlobalLayoutListener(this);

        Window window = getWindow();
        WindowManager.LayoutParams layoutParams = window.getAttributes();
        layoutParams.screenBrightness = 1f;
        window.setAttributes(layoutParams);

        binding.btnStartDetect.setOnClickListener(v -> viewModel.startDetect());
    }

    private void initData() {
        boolean switchCamera = ConfigUtil.isSwitchCamera(this);
        previewConfig = new PreviewConfig(switchCamera ? Camera.CameraInfo.CAMERA_FACING_FRONT : Camera.CameraInfo.CAMERA_FACING_BACK,
                switchCamera ? Camera.CameraInfo.CAMERA_FACING_BACK : Camera.CameraInfo.CAMERA_FACING_FRONT,
                Integer.parseInt(ConfigUtil.getRgbCameraAdditionalRotation(this)),
                Integer.parseInt(ConfigUtil.getIrCameraAdditionalRotation(this))
        );
        initCamera2Helper();
    }

    /**
     * 使用Camera2 API开启摄像头
     */
    private void initCamera2Helper() {
        camera2Helper = new Camera2Helper();
        Point point = viewModel.loadPreviewSize();
        camera2Helper.init(this, String.valueOf(previewConfig.getRgbCameraId()), new Size(point.x, point.y), point);
        camera2Helper.setCamera2Listener(new Camera2Listener() {
            @Override
            public void onCamera2Opened(Size previewSizeRgb, int displayOrientation, String cameraId) {
                Log.i(TAG, "onCameraOpened displayOrientation:" + displayOrientation);
                /**
                 * 摄像头开启成功后，根据参数对相关UI进行修改，摄像头预览界面能够正常显示
                 */
                Camera2TimestampHelper.getInstance().init();
                ViewGroup.LayoutParams layoutParams = adjustPreviewViewSize(binding.cameraTexturePreviewRgb, binding.cameraTexturePreviewRgb,
                        binding.cameraFaceRectView, previewSizeRgb, displayOrientation, 1.0f);
                rgbFaceRectTransformer = new FaceRectTransformer(previewSizeRgb.getWidth(), previewSizeRgb.getHeight(), layoutParams.width, layoutParams.height,
                        displayOrientation, Integer.parseInt(cameraId), ConfigUtil.isDrawRgbPreviewHorizontalMirror(LivenessInteractiveGlareCamera2Activity.this),
                        ConfigUtil.isDrawRgbRectHorizontalMirror(LivenessInteractiveGlareCamera2Activity.this),
                        ConfigUtil.isDrawRgbRectVerticalMirror(LivenessInteractiveGlareCamera2Activity.this)
                );
                TextView textViewRgb = new TextView(LivenessInteractiveGlareCamera2Activity.this, null);
                textViewRgb.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT));
                textViewRgb.setText(getString(R.string.camera_rgb_preview_size, previewSizeRgb.getWidth(), previewSizeRgb.getHeight()));
                textViewRgb.setTextColor(Color.WHITE);
                textViewRgb.setBackgroundColor(getResources().getColor(R.color.color_bg_notification));
                ((RelativeLayout) binding.cameraTexturePreviewRgb.getParent()).addView(textViewRgb);

                viewModel.onRgbCameraOpened(previewSizeRgb);
                viewModel.setRgbFaceRectTransformer(rgbFaceRectTransformer);
            }

            @Override
            public void onImageAvailable(Image image) {
                /**
                 * 摄像头帧数据回调时，传给SDK算法进行检测，并根据检测结果进行绘制
                 */
                binding.cameraFaceRectView.clearFaceInfo();
                List<FacePreviewInfo> facePreviewInfoList = viewModel.onPreviewFrame(image);
                if (facePreviewInfoList != null && rgbFaceRectTransformer != null) {
                    drawPreviewInfo(facePreviewInfoList);
                }
            }

            @Override
            public void onCamera2Closed() {
                Camera2TimestampHelper.getInstance().reset();
            }
        });
    }

    @Override
    public void onGlobalLayout() {
        binding.cameraTexturePreviewRgb.getViewTreeObserver().removeOnGlobalLayoutListener(this);
        if (!checkPermissions(NEEDED_PERMISSIONS)) {
            ActivityCompat.requestPermissions(this, NEEDED_PERMISSIONS, ACTION_REQUEST_PERMISSIONS);
        } else {
            camera2Helper.resumeCamera(binding.cameraTexturePreviewRgb);
        }
    }

    private ViewGroup.LayoutParams adjustPreviewViewSize(View rgbPreview, View previewView, FaceRectView faceRectView, Size previewSize,
                                                         int displayOrientation, float scale) {
        ViewGroup.LayoutParams layoutParams = previewView.getLayoutParams();
        int measuredWidth = previewView.getMeasuredWidth();
        int measuredHeight = previewView.getMeasuredHeight();
        float ratio = ((float) previewSize.getHeight()) / (float) previewSize.getWidth();
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

        return layoutParams;
    }

    private void drawPreviewInfo(List<FacePreviewInfo> facePreviewInfoList) {
        if (rgbFaceRectTransformer != null) {
            List<FaceRectView.DrawInfo> rgbDrawInfoList = viewModel.getDrawInfo(facePreviewInfoList, LivenessType.RGB);
            binding.cameraFaceRectView.drawRealtimeFaceInfo(rgbDrawInfoList);
        }
    }

    @Override
    protected void onDestroy() {
        viewModel.destroy();
        super.onDestroy();
    }
}
