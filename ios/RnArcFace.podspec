Pod::Spec.new do |s|
  s.name         = "RnArcFace"
  s.version      = "0.1.0"
  s.summary      = "ArcSoft ArcFace VisionCamera FrameProcessor Plugin"
  s.license      = { :type => "MIT" }
  s.author       = { "you" => "you@example.invalid" }
  s.homepage     = "https://example.invalid"

  # ✅ 必须要有 source，否则 podspec 校验会失败
  s.source       = { :path => "." }

  s.platforms    = { :ios => "13.0" }

  # ✅ 只包含我们自己的源码文件（不扫 libs/）
  s.source_files = [
    "ArcFace*.{h,m,mm}",
    "engine/**/*.{h,m,mm}",
    "registry/**/*.{h,m,mm}",
    "util/**/*.{h,m,mm}"
  ]

  # ✅ framework 在 ios/libs/
  s.vendored_frameworks = "libs/ArcSoftFaceEngine.framework"

  s.dependency "React-Core"
  s.dependency "VisionCamera"

  s.frameworks = ["Foundation", "AVFoundation", "CoreVideo"]
end
