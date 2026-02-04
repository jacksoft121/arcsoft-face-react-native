require "json"

package = JSON.parse(File.read(File.join(__dir__, "..", "package.json")))

Pod::Spec.new do |s|
  s.name         = 'ArcSoftFaceReactNative'
  s.version      = package['version']
  s.summary      = package['description']
  s.homepage     = 'https://example.invalid'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'you' => 'you@example.invalid' }
  s.source       = { :path => '.' }

  s.platforms    = { :ios => '13.0' }
  s.source_files = 'ios/**/*.{h,m,mm,cpp}'
  s.public_header_files = 'ios/**/*.h'
  s.requires_arc = true

  # RN 0.78: 只依赖 React-Core 即可提供 Bridge。新架构时额外依赖 Codegen。
  s.dependency 'React-Core'

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
