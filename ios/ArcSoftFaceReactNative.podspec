require "json"

package = JSON.parse(File.read(File.join(__dir__, "../package.json")))
new_arch_enabled = ENV['RCT_NEW_ARCH_ENABLED'] == '1'

Pod::Spec.new do |s|
  s.name         = "ArcSoftFaceReactNative"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]
  s.platforms    = { :ios => "13.0" }

  s.source = { :path => "." }
  s.source_files = "ios/**/*.{h,m,mm,swift}"

  # ✅ RN 0.78：桥接头文件来自 React-Core，不再需要 React-RCTBridge
  s.dependency "React-RCTImage"        # 如果你用到 UIImage/图片工具可留；不用可删
  s.dependency "ReactCommon/turbomodule/core" if new_arch_enabled

  # 如果你有 codegen / TurboModule：
  if new_arch_enabled
    s.dependency "React-Codegen"
    s.pod_target_xcconfig = {
      "CLANG_CXX_LANGUAGE_STANDARD" => "c++20",
      "HEADER_SEARCH_PATHS" => "\"$(PODS_ROOT)/Headers/Public/React-Codegen\" \"$(PODS_ROOT)/Headers/Public/ReactCommon\""
    }
  else
    s.pod_target_xcconfig = {
      "CLANG_CXX_LANGUAGE_STANDARD" => "c++20"
    }
  end
end
