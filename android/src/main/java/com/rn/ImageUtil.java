package com.arcsoft.rn;

import android.graphics.Bitmap;
import android.graphics.ImageFormat;
import android.graphics.Rect;
import android.graphics.YuvImage;

import java.io.ByteArrayOutputStream;

public class ImageUtil {

    public static byte[] bitmapToNv21(Bitmap bitmap) {
        int width = bitmap.getWidth();
        int height = bitmap.getHeight();
        int[] argb = new int[width * height];
        bitmap.getPixels(argb, 0, width, 0, 0, width, height);

        byte[] yuv = new byte[width * height * 3 / 2];
        encodeYUV420SP(yuv, argb, width, height);
        return yuv;
    }

    private static void encodeYUV420SP(byte[] yuv420sp, int[] argb, int width, int height) {
        int frameSize = width * height;
        int yIndex = 0;
        int uvIndex = frameSize;

        int R, G, B, Y, U, V;
        int index = 0;

        for (int j = 0; j < height; j++) {
            for (int i = 0; i < width; i++) {
                R = (argb[index] & 0xff0000) >> 16;
                G = (argb[index] & 0xff00) >> 8;
                B = (argb[index] & 0xff);

                Y = ((66 * R + 129 * G + 25 * B + 128) >> 8) + 16;
                U = ((-38 * R - 74 * G + 112 * B + 128) >> 8) + 128;
                V = ((112 * R - 94 * G - 18 * B + 128) >> 8) + 128;

                yuv420sp[yIndex++] = (byte) (Math.max(0, Math.min(Y, 255)));

                if (j % 2 == 0 && i % 2 == 0) {
                    yuv420sp[uvIndex++] = (byte) (Math.max(0, Math.min(V, 255)));
                    yuv420sp[uvIndex++] = (byte) (Math.max(0, Math.min(U, 255)));
                }
                index++;
            }
        }
    }
}
