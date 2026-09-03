Pod::Spec.new do |s|
  s.name = "NexconnChatUI"
  s.version = "26.4.2"
  s.summary = "Source-based Nexconn ChatUI components for local integration."

  s.homepage = "https://www.nexconn.ai"
  s.license = {
    :type => "Apache-2.0",
    :text => "Nexconn-owned ChatUI source is licensed under the Apache License, Version 2.0."
  }
  s.author = { "Nexconn Support Team" => "support@nexconn.ai" }

  s.platform = :ios, "13.0"
  s.source = {
    :git => "https://github.com/NexconnAI-Dev/nexconn-chatui-ios.git",
    :tag => "v26.4.2"
  }

  s.source_files = "**/*.{h,m,mm,c}"
  s.resources = [
    "Resource/*",
    "Supporting Files/PrivacyInfo.xcprivacy"
  ]
  s.frameworks = %w[
    AVFoundation AudioToolbox CoreFoundation CoreGraphics CoreImage
    CoreMedia CoreMotion CoreTelephony CoreText CoreVideo ImageIO
    MobileCoreServices Photos QuartzCore SafariServices
    SystemConfiguration UIKit UserNotifications WebKit
  ]
  s.libraries = "sqlite3"
  s.pod_target_xcconfig = {
    "OTHER_LDFLAGS" => "$(inherited) -ObjC",
    "DEFINES_MODULE" => "YES"
  }
  s.dependency "NexconnChat/Chat", "= 26.4.2"
end
