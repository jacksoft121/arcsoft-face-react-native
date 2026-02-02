Pod::Spec.new do |s|
  s.name         = "RnArcFace"
  s.version      = "0.1.0"
  s.summary      = "ArcSoft ArcFace VisionCamera plugin"
  s.platforms    = { :ios => "13.0" }
  s.source_files = "ios/**/*.{h,m,mm}"
  s.vendored_frameworks = "ios/ArcSoftFaceEngine.framework"
  s.dependency "react-native-vision-camera"
  s.dependency "React-Core"
end
