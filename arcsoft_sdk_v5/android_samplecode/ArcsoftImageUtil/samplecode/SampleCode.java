public class SampleCode {
    private static final String TAG = "SampleCode";

    /**
     * write data to file
     *
     * @param data     image data
     * @param filePath image filePath
     */
    public static void writeDataToFile(@NonNull byte[] data, @NonNull String filePath) {
        File file = new File(filePath);
        if (!file.getParentFile().exists() && !file.getParentFile().mkdirs()) {
            throw new RuntimeException("parent folder not exists and create parent folder failed");
        }
        FileOutputStream fos = null;
        try {
            fos = new FileOutputStream(file);
            fos.write(data);
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            if (fos != null) {
                try {
                    fos.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    /**
     * test sdk's functions, input is a image file, like jpg
     *
     * @param imgFilePath image file's path
     */
    public void testImageUtil(String imgFilePath) {
        testImageUtil(BitmapFactory.decodeFile(imgFilePath));
    }

    /**
     * test sdk's functions, input is a Bitmap, which's format is ARGB_8888 or RGB_565
     *
     * @param bitmap a Bitmap, format is ARGB_8888 or RGB_565
     */
    public void testImageUtil(Bitmap bitmap) {
        Log.i(TAG, "testImageUtil: " + bitmap.getWidth() + "x" + bitmap.getHeight());
        ArcSoftImageFormat[] values = ArcSoftImageFormat.values();
        for (ArcSoftImageFormat value : values) {
            byte[] data = ArcSoftImageUtil.createImageData(bitmap.getWidth(), bitmap.getHeight(), value);

            testBitmapToImageData(bitmap, value, data);

            testMirrorImage(bitmap, value, data);

            testRotateImage(bitmap, value, data);

            testCropImage(bitmap, value, data);

            testTransformImage(bitmap, values, value, data);
        }
        Log.i(TAG, "testImageUtil: done!!!!");
    }

    private void testTransformImage(Bitmap bitmap, ArcSoftImageFormat[] values, ArcSoftImageFormat value, byte[] data) {
        for (ArcSoftImageFormat arcSoftImageFormat : values) {
            // create image data by size & format
            byte[] transformData = ArcSoftImageUtil.createImageData(bitmap.getWidth(), bitmap.getHeight(), arcSoftImageFormat);
            if (value != arcSoftImageFormat) {
                long start = System.currentTimeMillis();
                // transform image, fill transformData with result data
                int code = ArcSoftImageUtil.transformImage(data, transformData, bitmap.getWidth(), bitmap.getHeight(), value, arcSoftImageFormat);
                Log.i(TAG, "testImageFormatTransform: transformImage " + value + " To " + arcSoftImageFormat + " cost : " + (System.currentTimeMillis() - start) + " ms");
                writeDataToFile(transformData, "sdcard/imageUtilTest/" + bitmap.getWidth() + "x" + bitmap.getHeight() + "_" + value.name() + "To" + arcSoftImageFormat.name() + "." + arcSoftImageFormat);
                if (code != ArcSoftImageUtilError.CODE_SUCCESS) {
                    throw new RuntimeException("transformImage " + code + "  " + value + " " + arcSoftImageFormat);
                }
            }
        }
    }

    private void testCropImage(Bitmap bitmap, ArcSoftImageFormat value, byte[] data) {
        Rect cropArea = new Rect(100, 100, 300, 300);
        // create image data by size & format
        byte[] cropData = ArcSoftImageUtil.createImageData(cropArea.width(), cropArea.height(), value);
        long start = System.currentTimeMillis();
        // crop image, fill cropData with result data
        int code = ArcSoftImageUtil.cropImage(data, cropData, bitmap.getWidth(), bitmap.getHeight(), cropArea, value);
        Log.i(TAG, "testImageFormatTransform: crop" + value + "Image cost : " + (System.currentTimeMillis() - start) + " ms");

        if (code != ArcSoftImageUtilError.CODE_SUCCESS) {
            throw new RuntimeException("mirrorImage " + code + "   " + value);
        }
        writeDataToFile(cropData, "sdcard/imageUtilTest/" + cropArea.width() + "x" + cropArea.height() + "." + value);
    }

    private void testRotateImage(Bitmap bitmap, ArcSoftImageFormat value, byte[] data) {
        for (int i = 90; i < 360; i += 90) {
            // just rotate, originData's size == outputData's size
            byte[] rotateData = new byte[data.length];
            long start = System.currentTimeMillis();
            // rotate image, fill rotateData with result data
            int code = ArcSoftImageUtil.rotateImage(data, rotateData, bitmap.getWidth(), bitmap.getHeight(), ArcSoftRotateDegree.valueOf("DEGREE_" + i), value);
            Log.i(TAG, "testImageFormatTransform: rotate" + value + "Image " + i + " cost : " + (System.currentTimeMillis() - start) + " ms");

            if (code != ArcSoftImageUtilError.CODE_SUCCESS) {
                throw new RuntimeException("rotateImage" + code);
            }
            int realWidth = i % 180 == 0 ? bitmap.getWidth() : bitmap.getHeight();
            int realHeight = i % 180 != 0 ? bitmap.getWidth() : bitmap.getHeight();
            writeDataToFile(rotateData, "sdcard/imageUtilTest/" + realWidth + "x" + realHeight + "_rotate_" + i + "." + value);
        }
    }

    private void testMirrorImage(Bitmap bitmap, ArcSoftImageFormat value, byte[] data) {
        // just rotate, originData's size == outputData's size ,
        // and  outputData's size can also be calculated by size & format
        byte[] mirrorData = ArcSoftImageUtil.createImageData(bitmap.getWidth(), bitmap.getHeight(), value);
        long start = System.currentTimeMillis();
        // mirro image, fill mirrorData with result data
        int code = ArcSoftImageUtil.mirrorImage(data, mirrorData, bitmap.getWidth(), bitmap.getHeight(), ArcSoftMirrorOrient.HORIZONTAL, value);
        Log.i(TAG, "testImageFormatTransform: mirror" + value + " ImageHorizontal  cost : " + (System.currentTimeMillis() - start) + " ms");
        if (code != ArcSoftImageUtilError.CODE_SUCCESS) {
            throw new RuntimeException("mirrorImage" + code);
        }
        writeDataToFile(mirrorData, "sdcard/imageUtilTest/" + bitmap.getWidth() + "x" + bitmap.getHeight() + "_horizontalMirror" + "." + value);

        start = System.currentTimeMillis();
        // mirror vertical
        code = ArcSoftImageUtil.mirrorImage(data, mirrorData, bitmap.getWidth(), bitmap.getHeight(), ArcSoftMirrorOrient.VERTICAL, value);
        Log.i(TAG, "testImageFormatTransform: mirror" + value + "Image Verical cost : " + (System.currentTimeMillis() - start) + " ms");

        if (code != ArcSoftImageUtilError.CODE_SUCCESS) {
            throw new RuntimeException("mirrorImage" + code);
        }
        writeDataToFile(mirrorData, "sdcard/imageUtilTest/" + bitmap.getWidth() + "x" + bitmap.getHeight() + "_verticalMirror" + "." + value);
    }

    private void testBitmapToImageData(Bitmap bitmap, ArcSoftImageFormat value, byte[] data) {
        long start = System.currentTimeMillis();
        // bitmap to specific format image data
        int code = ArcSoftImageUtil.bitmapToImageData(bitmap, data, value);
        Log.i(TAG, "testImageFormatTransform: bitmapTo" + value + " cost : " + (System.currentTimeMillis() - start) + " ms");
        if (code != ArcSoftImageUtilError.CODE_SUCCESS) {
            throw new RuntimeException("transformImage" + code + "  " + value);
        }
        writeDataToFile(data, "sdcard/imageUtilTest/" + bitmap.getWidth() + "x" + bitmap.getHeight() + "_origin" + "." + value);
    }
}