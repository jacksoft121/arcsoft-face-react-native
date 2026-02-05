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
  s.private_header_files = "ios/**/*.h"
  s.exclude_files = "ios/generated/**/*"
  # ✅ 把 ArcSoftFaceEngine.framework 作为 vendored frameworks 引入
  s.vendored_frameworks = "ios/ArcSoftFaceEngine.framework"
  s.frameworks = 'CoreVideo', 'CoreMedia', 'Accelerate'
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

  install_modules_dependencies(s)
end
