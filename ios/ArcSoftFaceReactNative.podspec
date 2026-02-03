require 'json'

package = JSON.parse(File.read(File.join(__dir__, '..', 'package.json')))

Pod::Spec.new do |s|
  s.name         = 'ArcSoftFaceReactNative'
  s.version      = package['version']
  s.summary      = 'ArcSoft ArcFace iOS bridge for React Native (0.78+)'
  s.license      = { :type => 'MIT' }
  s.homepage     = 'https://example.invalid'
  s.author       = { 'you' => 'you@example.invalid' }
  s.platforms    = { :ios => '13.0' }
  s.source       = { :path => '.' }

  s.source_files = 'ArcSoftFace/**/*.{h,m,mm,cpp}'
  s.vendored_frameworks = 'ArcSoftFaceEngine.framework'

  s.dependency 'React-Core'
  s.dependency 'React-RCTBridge'
  s.dependency 'React-Codegen'
  s.dependency 'RCT-Folly'
  s.dependency 'glog'
  s.dependency 'DoubleConversion'

  s.pod_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++20',
    'DEFINES_MODULE' => 'YES'
  }

  s.user_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++20'
  }
end
