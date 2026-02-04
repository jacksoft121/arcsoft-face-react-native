package com.arcsoft.arcfacedemo.util.camera2;

import android.media.Image;
import android.util.Size;

public interface Camera2Listener {

    void onCamera2Opened(Size previewSize, int displayOrientation, String cameraId);

    void onImageAvailable(Image image);

    void onCamera2Closed();
}
