
Pod::Spec.new do |spec|


  spec.name         = "JCAVURLPlayer"
  spec.version      = "1.0.2"
  spec.summary      = "A short description of JCAVURLPlayer."
  spec.description  = "网络播放器"
  spec.homepage     = "https://github.com/baby-007/JCAVURLPlayer"
  spec.license      = "MIT"
  spec.author             = { "liaojianhua" => "1371243950@qq.com" }
  spec.platform     = :ios, "10.0"
  spec.source       = { :git => "https://github.com/baby-007/JCAVURLPlayer.git", :tag => "1.0.2" }
  spec.source_files  = "AVURLPlayer/**/*.{h,m}"
  spec.frameworks = "UIKit","AVFoundation","Foundation","CoreServices"
  spec.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/CommonCrypto" }

end
