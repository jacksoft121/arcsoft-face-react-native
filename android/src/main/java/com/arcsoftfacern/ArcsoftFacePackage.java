package com.arcsoftfacern;

import androidx.annotation.NonNull;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;
import com.mrousavy.camera.frameprocessor.FrameProcessorPluginRegistry;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class ArcsoftFacePackage implements ReactPackage {
  static {
    FrameProcessorPluginRegistry.addFrameProcessorPlugin("detectFaces", (proxy, options) -> new ArcsoftFaceProcessorPlugin(proxy, options));
  }

  @NonNull
  @Override
  public List<NativeModule> createNativeModules(@NonNull ReactApplicationContext reactContext) {
    List<NativeModule> modules = new ArrayList<>();
    modules.add(new ArcsoftFaceModule(reactContext));
    return modules;
  }

  @NonNull
  @Override
  public List<ViewManager> createViewManagers(@NonNull ReactApplicationContext reactContext) {
    return Collections.emptyList();
  }
}
