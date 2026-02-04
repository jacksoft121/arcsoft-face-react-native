require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = 'ArcSoftFaceReactNative'
  s.version      = package['version']
  s.summary      = package['summary']
  s.homepage     = package['homepage']
  s.license      = { :type => package['license'], :file => 'LICENSE' }
  s.author       = { package['author']['name'] => package['author']['email'] }
  s.platforms    = { :ios => "12.0" }
  s.source       = { :git => "https://example.com", :tag => s.version.to_s }
  s.source_files = "ios/**/*.{h,m,mm,cpp}"
  # RN 0.78: 推荐依赖
  s.dependency "React"
  s.dependency "React-Core"

  if ENV['RCT_NEW_ARCH_ENABLED'] == '1'
    s.dependency 'React-Codegen'
    s.dependency 'RCT-Folly'
    s.dependency 'RCTRequired'
    s.dependency 'RCTTypeSafety'
    s.dependency 'ReactCommon/turbomodule/core'
    s.compiler_flags = '-DRCT_NEW_ARCH_ENABLED=1'
  end

  # 让宿主工程链接 ArcSoftFaceEngine.framework（由你按官方 SDK 放入工程）
  s.frameworks = 'CoreVideo', 'CoreMedia', 'Accelerate'
end
