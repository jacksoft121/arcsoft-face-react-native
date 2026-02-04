package com.arcsoft.arcfacedemo.ui.activity;

import android.os.Bundle;
import android.view.View;

import androidx.annotation.Nullable;
import androidx.databinding.DataBindingUtil;

import com.arcsoft.arcfacedemo.R;
import com.arcsoft.arcfacedemo.databinding.ActivityLivenessListBinding;
import com.arcsoft.arcfacedemo.widget.NavigateItemView;

public class LivenessListActivity extends BaseActivity implements View.OnClickListener {

    private ActivityLivenessListBinding binding;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = DataBindingUtil.setContentView(this, R.layout.activity_liveness_list);
        enableBackIfActionBarExists();
        initView();
    }

    private void initView() {
        binding.llRootView.addView(new NavigateItemView(this, R.drawable.ic_liveness_check,
                getString(R.string.rgb_liveness_detect), LivenessDetectActivity.class));
        binding.llRootView.addView(new NavigateItemView(this, R.drawable.ic_liveness_check,
                getString(R.string.interactive_liveness_detect), LivenessInteractiveActivity.class));
        binding.llRootView.addView(new NavigateItemView(this, R.drawable.ic_liveness_check,
                getString(R.string.glare_liveness_detect), LivenessGlareActivity.class));
        binding.llRootView.addView(new NavigateItemView(this, R.drawable.ic_liveness_check,
                getString(R.string.interactive_glare_liveness_detect), LivenessInteractiveGlareCamera2Activity.class));

        int childCount = binding.llRootView.getChildCount();
        for (int i = 0; i < childCount; i++) {
            View itemView = binding.llRootView.getChildAt(i);
            itemView.setOnClickListener(this);
        }
    }

    @Override
    public void onClick(View v) {
        if (v instanceof NavigateItemView) {
            navigateToNewPage(((Class) ((NavigateItemView) v).getExtraData()));
        }
    }
}
