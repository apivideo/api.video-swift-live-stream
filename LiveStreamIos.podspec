

Pod::Spec.new do |spec|


  spec.name         = "LiveStreamIos"
  spec.version      = "0.0.1"
  spec.summary      = "a native iOS library to stream on api.video"

  
  spec.description  = <<-DESC
    a native iOS library to stream on api.video
                   DESC

  spec.homepage     = "https://github.com/apivideo/LiveStreamIos"



  
  spec.license      = { :type => "MIT", :file => "FILE_LICENSE" }

  spec.author             = { "api.video" => "hello@api.video" }
  spec.social_media_url   = "https://twitter.com/api_video"

  spec.platform     = :ios, "12.0"

  
  spec.ios.deployment_target = "9.0"


  spec.source       = { :git => "https://github.com/apivideo/LiveStreamIos.git", :tag => spec.version.to_s }



  spec.source_files  = "LiveStreamIos/**/*.{h,m,swift}"
  spec.exclude_files = "LiveStreamIos/Exclude"

  spec.dependency "HaishinKit", "~> 1.1.0"

end
