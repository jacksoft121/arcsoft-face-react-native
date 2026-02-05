require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = 'ArcSoftFaceReactNative'
  s.version      = package['version']
  s.summary      = package['summary']
  s.homepage     = package['homepage']
  s.license      = { :type => package['license'], :file => 'LICENSE' }
  s.author       = { package['author']['name'] => package['author']['email'] }
  s.platforms    = { :ios => "13.0" }
  s.source       = { :git => "https://example.com", :tag => s.version.to_s }

  s.source_files = "ios/**/*.{h,m,mm}"

  s.vendored_frameworks = "ios/ArcSoftFaceEngine.framework"
  s.frameworks = 'CoreVideo', 'CoreMedia', 'Accelerate'

  install_modules_dependencies(s)
end
