[![badge](https://img.shields.io/twitter/follow/api_video?style=social)](https://twitter.com/intent/follow?screen_name=api_video) &nbsp; [![badge](https://img.shields.io/github/stars/apivideo/api.video-ios-live-stream?style=social)](https://github.com/apivideo/api.video-ios-live-stream) &nbsp; [![badge](https://img.shields.io/discourse/topics?server=https%3A%2F%2Fcommunity.api.video)](https://community.api.video)
![](https://github.com/apivideo/API_OAS_file/blob/master/apivideo_banner.png)
<h1 align="center">api.video IOS live stream library</h1>

[api.video](https://api.video) is the video infrastructure for product builders. Lightning fast video APIs for integrating, scaling, and managing on-demand & low latency live streaming features in your app.

# Table of contents

- [Table of contents](#table-of-contents)
- [Project description](#project-description)
- [Getting started](#getting-started)
  - [Installation](#installation)
    - [With Cocoapods](#with-cocoapods)
  - [Permissions](#permissions)
  - [Code sample](#code-sample)
- [Plugins](#plugins)
- [FAQ](#faq)

# Project description

This module is an easy way to broadcast livestream on api.video platform

# Getting started

## Installation

### With Cocoapods

1. Add the following entry to your Podfile:
```swift
pod 'ApiVideoLiveStream', '0.1.0' 
```
3. Then run `pod install`
4. Don’t forget to import LiveStreamIos in every file you’d like to use api.video livestream library

### With Carthage
```
github "apivideo/ApiVideoLiveStream.swift" ~> 0.1.0
```

## Permissions
To be able to broadcast, you must update Info.plist with a usage description for camera and microphone

```xml
...
<key>NSCameraUsageDescription</key>
<string>Your own description of the purpose</string>
<key>NSMicrophoneUsageDescription</key>
<string>Your own description of the purpose</string>
...
```

## Code sample
1. In your ViewController.swift file import the library
2. Add a viariable apiVideo 
3. Intenciate your variable with an AudioConfig and VideoConfig and add a view (or not if you dont want a preview of your stream)
4. to start your stream use startStreaming(streamKey: String) function
 - if you're broadcasting on api.video you only have to add your stream key to streamKey)
 - if not use 'startStreaming(streamKey: String, url: String)', url is your rtmp server url.

```swift
class ViewController: UIViewController {
    var liveStream:  ApiVideoLiveStream?
    @IBOutlet var viewCamera: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        let audioConfig = AudioConfig(bitrate: 32 * 1000)
        let videoConfig = VideoConfig(bitrate: 2 * 1024 * 1024, resolution: Resolutions.RESOLUTION_720, fps: 30)
        do {
            liveStream = try ApiVideoLiveStream(initialAudioConfig: audioConfig, initialVideoConfig: videoConfig, preview: preview)
        } catch {
            print (error)
        }
    }
}
```

# Plugins

API.Video sdk is using external library

| Plugin | README |
| ------ | ------ |
| HaishinKit | [https://github.com/shogo4405/HaishinKit.swift][HaishinKit] |

# FAQ
If you have any questions, ask us here:  https://community.api.video .
Or use [Issues].

Also feel free to test our [Sample app].

[//]: # (These are reference links used in the body of this note and get stripped out when the markdown processor does its job. There is no need to format nicely because it shouldn't be seen. Thanks SO - http://stackoverflow.com/questions/4823468/store-comments-in-markdown-syntax)

[Issues]: <https://github.com/apivideo/api.video-ios-live-stream/issues>
[HaishinKit]: <https://github.com/shogo4405/HaishinKit.swift>
[Sample app]: <https://github.com/apivideo/api.video-ios-live-stream/Example>


