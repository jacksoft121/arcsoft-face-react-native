require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = 'ArcSoftFaceReactNative'
  s.version      = package['version']
  s.summary      = package['summary']
  s.homepage     = package['homepage']
  # npm portal 包没有附带 LICENSE 文件；ArcSoft SDK 使用商业授权，Pod 校验时
  # 只声明许可证类型，避免 CocoaPods 因不存在的本地文件中止 iOS 构建。
  s.license      = { :type => package['license'] }
  s.author       = { package['author']['name'] => package['author']['email'] }
  s.platforms    = { :ios => "13.0" }
  s.source       = { :git => "https://example.com", :tag => s.version.to_s }

  s.source_files = [
    "ios/**/*.{h,m,mm,swift}",
  ]
  s.public_header_files = "ios/ArcsoftFrameDetectorRuntime.h"

  s.vendored_frameworks = "ios/ArcSoftFaceEngine.framework"
  s.frameworks = 'AVFoundation', 'CoreVideo', 'CoreMedia', 'CoreImage', 'UIKit', 'Accelerate'

  load 'nitrogen/generated/ios/ArcSoftFaceReactNative+autolinking.rb'
  add_nitrogen_files(s)

  s.dependency 'VisionCamera'
  install_modules_dependencies(s)
end
