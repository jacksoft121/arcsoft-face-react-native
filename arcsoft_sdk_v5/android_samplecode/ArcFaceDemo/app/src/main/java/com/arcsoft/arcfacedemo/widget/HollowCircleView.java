package com.arcsoft.arcfacedemo.widget;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.util.AttributeSet;
import android.view.View;

public class HollowCircleView extends View {

    private Paint overlayPaint;
    private Paint clearPaint;

    private int overlayColor = 0xFFFFFFFF; // 半透明黑
    private float hollowCenterX;
    private float hollowCenterY;
    private float hollowRadius = 100;

    public HollowCircleView(Context context) {
        super(context);
        init();
    }

    public HollowCircleView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    private void init() {
        overlayPaint = new Paint();
        overlayPaint.setColor(overlayColor);

        clearPaint = new Paint();
        clearPaint.setAntiAlias(true);
        clearPaint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.CLEAR));
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);

        // 创建离屏图层
        int saveCount = canvas.saveLayer(0, 0, getWidth(), getHeight(), null);

        // 绘制半透明遮罩
        canvas.drawRect(0, 0, getWidth(), getHeight(), overlayPaint);

        // 擦除中空圆形区域
        canvas.drawCircle(hollowCenterX, hollowCenterY, hollowRadius, clearPaint);

        // 恢复图层
        canvas.restoreToCount(saveCount);
    }

    // 设置圆心位置和半径
    public void setHollowCircle(float centerX, float centerY, float radius) {
        this.hollowCenterX = centerX;
        this.hollowCenterY = centerY;
        this.hollowRadius = radius;
        invalidate();
    }

    // 可选：设置遮罩颜色
    public void setOverlayColor(int color) {
        this.overlayColor = color;
        overlayPaint.setColor(color);
        invalidate();
    }
}

