package com.arcsoft.arcfacedemo.ui.viewmodel;

import android.content.Context;
import android.os.Environment;

import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

import com.arcsoft.arcfacedemo.common.Constants;
import com.arcsoft.face.FaceEngine;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;

public class ActiveViewModel extends ViewModel {
    private MutableLiveData<Integer> activeResult = new MutableLiveData<>();

    public void activeOnline(Context context, String appId, String sdkKey) {
        activeResult.postValue(FaceEngine.activeOnline(context, appId, sdkKey));
    }

    public MutableLiveData<Integer> getActiveResult() {
        return activeResult;
    }


    public Properties loadProperties() {
        Properties properties = new Properties();
        FileInputStream fis = null;
        try {
            File configFile = new File(Environment.getExternalStorageDirectory().getAbsolutePath() + File.separator + Constants.ACTIVE_CONFIG_FILE_NAME);
            fis = new FileInputStream(configFile);
            properties.load(fis);
            return properties;
        } catch (IOException e) {
            e.printStackTrace();
            return null;
        } finally {
            if (fis != null) {
                try {
                    fis.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
    }
}
