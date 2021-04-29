# Logboard
[![Platform](https://img.shields.io/cocoapods/p/Logboard.svg?style=flat)](http://cocoapods.org/pods/Logboard)
![Language](https://img.shields.io/badge/language-Swift%205.3-orange.svg)
[![CocoaPods](https://img.shields.io/cocoapods/v/Logboard.svg?style=flat)](http://cocoapods.org/pods/Logboard)
[![GitHub license](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://github.com/shogo4405/Logboard/blob/master/LICENSE.md)

Simple logging framework for your framework project.

## Usage
```swift
let logger = Logboard.with("identifier")

logger.level = .trace
logger.trace("trace")
logger.debug("debug")
logger.info("hoge")
logger.warn("sample")
logger.error("error")
```

## Requirements
|-|iOS|OSX|tvOS|watchOS|XCode|Swift|CocoaPods|Carthage|
|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|
|2.2.0+|9.0+|10.9+|9.0+|2.0|12.0+|5.3|1.3.0|0.31.0+|
|2.1.0+|8.0+|10.9+|9.0+|2.0|11.0+|5.0|1.3.0|0.31.0+|

## Installation
*Please set up your project Swift 5.0

### CocoaPods
```rb
source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!

def import_pods
pod 'Logboard', '~> 2.2.2'
end

target 'Your Target'  do
platform :ios, '9.0'
import_pods
end
```
### Carthage
```
github "shogo4405/Logboard" ~> 2.2.2
```

## Appenders
### ConsoleAppender
Use print function. You can see XCode's console.
```swift
let logger = Logboard.with("identifier")
let console = ConsoleAppender()
logger.appender = console
```

### MultiAppender
```swift
let logger = Logboard.with("identifier")
let multi = MultiAppender()
multi.appenders.append(ConsoleAppender())
multi.appenders.append(SocketAppender())
logger.appender = multi
```

### SocketAppender
```swift
let logger = Logboard.with("identifier")
let socket = SocketAppender()
socket.connect("toHost", 22222)
logger.appender = socket
```

## License
BSD-3-Clause
