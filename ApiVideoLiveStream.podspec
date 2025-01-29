

Pod::Spec.new do |spec|
  spec.name         = "ApiVideoLiveStream"
  spec.version      = "1.4.6"
  spec.summary      = "The api.video live stream framework allow easy integration of a live stream broadcast into your application."
  
  spec.description  = <<-DESC
    Quickly add the ability to broadcast a live stream from your application with this module. Within minutes, your app will be streaming RTMP live video to api.video where it can be broadcasted to anyone around the world.
                   DESC

  spec.homepage     = "https://docs.api.video"  
  spec.license      = { :type => 'MIT' }

  spec.author             = { "Ecosystem Team" => "ecosystem@api.video" }
  spec.social_media_url   = "https://x.com/api_video"

  spec.swift_versions    = ["5.6"]
  spec.ios.deployment_target = "13.0"

  spec.source       = { :git => "https://github.com/apivideo/api.video-swift-live-stream.git", :tag => "v" + spec.version.to_s }

  spec.source_files  = "Sources/**/*.{h,m,swift}"
  spec.exclude_files = "Sources/Exclude"

  spec.dependency "HaishinKit", "1.9.3"

end
