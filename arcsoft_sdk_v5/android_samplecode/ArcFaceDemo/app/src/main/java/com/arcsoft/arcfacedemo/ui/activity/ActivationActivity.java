package com.arcsoft.arcfacedemo.ui.activity;

import androidx.core.app.ActivityCompat;
import androidx.databinding.DataBindingUtil;
import androidx.lifecycle.ViewModelProvider;

import android.Manifest;
import android.os.Bundle;
import android.os.Environment;
import android.view.View;

import com.arcsoft.arcfacedemo.R;
import com.arcsoft.arcfacedemo.databinding.ActivityActivationBinding;
import com.arcsoft.arcfacedemo.ui.viewmodel.ActiveViewModel;
import com.arcsoft.arcfacedemo.util.ConfigUtil;
import com.arcsoft.arcfacedemo.util.ErrorCodeUtil;
import com.arcsoft.face.ErrorInfo;
import com.google.android.material.snackbar.Snackbar;

import java.io.File;
import java.util.Properties;

/**
 * 激活界面
 */
public class ActivationActivity extends BaseActivity {

    /**
     * 读取本地配置文件激活的所有权限信息
     */
    private static final String[] NEEDED_PERMISSIONS_ACTIVE_FROM_CONFIG_FILE = new String[]{
            Manifest.permission.READ_EXTERNAL_STORAGE
    };
    /**
     * 获取设备信息的所需的权限信息
     */
    private static final String[] NEEDED_PERMISSIONS_GET_DEVICE_INFO = new String[]{
            Manifest.permission.READ_EXTERNAL_STORAGE
    };

    private static final int ACTION_REQUEST_ACTIVE_ONLINE = 2;
    private static final int ACTION_REQUEST_ACTIVE_FROM_CONFIG_FILE = 4;

    private ActivityActivationBinding binding;
    private ActiveViewModel activeViewModel;
    private Snackbar snackbar;
    private static String DEFAULT_AUTH_FILE_PATH;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = DataBindingUtil.setContentView(this, R.layout.activity_activation);

        initData();
        initViewModel();
        initView();
    }

    private void initView() {
        enableBackIfActionBarExists();
    }

    private void initViewModel() {
        activeViewModel = new ViewModelProvider(
                getViewModelStore(),
                new ViewModelProvider.AndroidViewModelFactory(getApplication())
        )
                .get(ActiveViewModel.class);
        activeViewModel.getActiveResult().observe(this, result -> {
            if (snackbar != null) {
                snackbar.dismiss();
                snackbar = null;
            }
            String notice;
            switch (result) {
                case ErrorInfo.MOK:
                    notice = getString(R.string.active_success);
                    break;
                case ErrorInfo.MERR_ASF_ALREADY_ACTIVATED:
                    notice = getString(R.string.already_activated);
                    break;
                case ErrorInfo.MERR_ASF_ACTIVEKEY_ACTIVEKEY_ACTIVATED:
                    notice = getString(R.string.active_key_activated);
                    break;
                default:
                    notice = getString(R.string.active_failed, result, ErrorCodeUtil.arcFaceErrorCodeToFieldName(result));
                    break;
            }
            showLongSnackBar(binding.getRoot(), notice);
            ConfigUtil.commitAppId(getApplicationContext(), binding.getAppId());
            ConfigUtil.commitSdkKey(getApplicationContext(), binding.getSdkKey());
        });
    }

    private void initData() {
        DEFAULT_AUTH_FILE_PATH = Environment.getExternalStorageDirectory().getAbsolutePath() + File.separator + getString(R.string.active_file_name);
        binding.setAppId(ConfigUtil.getAppId(this));
        binding.setSdkKey(ConfigUtil.getSdkKey(this));
    }

    public void activeOnline(View view) {
        if (checkPermissions(NEEDED_PERMISSIONS_GET_DEVICE_INFO)) {
            snackbar = showIndefiniteSnackBar(binding.getRoot(), getString(R.string.please_wait), null, null);
            runOnSubThread(() -> activeViewModel.activeOnline(getApplicationContext(), binding.getAppId(), binding.getSdkKey()));
        } else {
            ActivityCompat.requestPermissions(this, NEEDED_PERMISSIONS_GET_DEVICE_INFO, ACTION_REQUEST_ACTIVE_ONLINE);
        }
    }

    @Override
    protected void afterRequestPermission(int requestCode, boolean isAllGranted) {
        if (!isAllGranted) {
            showToast(getString(R.string.permission_denied));
            return;
        }
        switch (requestCode) {
            case ACTION_REQUEST_ACTIVE_ONLINE:
                activeOnline(null);
                break;
            case ACTION_REQUEST_ACTIVE_FROM_CONFIG_FILE:
                readLocalConfigAndActive(null);
                break;
            default:
                break;
        }
    }

    public void readLocalConfigAndActive(View view) {
        if (checkPermissions(NEEDED_PERMISSIONS_ACTIVE_FROM_CONFIG_FILE)) {
            Properties properties = activeViewModel.loadProperties();
            if (properties == null) {
                return;
            }
            String appId = properties.getProperty("APP_ID");
            String sdkKey = properties.getProperty("SDK_KEY");
            if (appId != null && sdkKey != null) {
                binding.setAppId(appId);
                binding.setSdkKey(sdkKey);
                activeOnline(null);
            } else {
                showToast(getString(R.string.read_config_failed));
            }
        } else {
            ActivityCompat.requestPermissions(this, NEEDED_PERMISSIONS_ACTIVE_FROM_CONFIG_FILE, ACTION_REQUEST_ACTIVE_FROM_CONFIG_FILE);
        }
    }

}
