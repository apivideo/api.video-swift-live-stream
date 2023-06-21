# Changelog
All changes to this project will be documented in this file.

## [1.3.5] - 2023-06-21
- Fix detach camera
- Upgrade HaishinKit to 1.5.2

## [1.3.4] - 2023-03-02
- Fix front camera mirroring
- Upgrade HaishinKit to 1.4.3

## [1.3.3] - 2023-01-19
- Fix streaming orientation when application is opened in portrait and device is turned to landscape
- Upgrade HaishinKit to 1.4.2

## [1.3.2] - 2023-01-11
- Fix `lastCamera` when camera is set with `cameraPosition`
- Improve `startStreaming` errors

## [1.3.1] - 2023-01-09
- Reduce startup time by fixing synchronization issues
- Fix `isMuted` value. The property was inverted

## [1.3.0] - 2023-01-06
- Add a camera parameter in the ApiVideoLiveStream constructors
- Add an API to set the duration between two key frames
- Introducing the new `camera` API. Previous `camera` has been renamed to `cameraPosition`
- Add swift PM support
- Upgrade HaishinKit to 1.4.1
- Example: refactor and clean the UIKit example

## [1.2.2] - 2022-09-29
- Only register event listener in constructor to avoid multiple callback called

## [1.2.1] - 2022-09-29
- fix(lib): use RtmpStream lock instead of a custom lock

## [1.2.0] - 2022-09-29
- Add startPreview/stopPreview API
- Try to synchronize `startStreaming` abd video configuration
- Force HaishinKit default resolution to 720p
- Add constructor for HaishinKit NetStreamDrawable
- Upgrade to HaishinKit 1.3.0
- Release workflow is triggered on release published (instead of created)

## [1.1.0] - 2022-08-18
- Adds API to set zoom ratio

## [1.0.0] - 2022-08-15
- Allows nil initialVideoConfig and initialAudioConfig
- Fix landscape orientation
- Return onDisconnect when user call `stopStreaming`

## [0.2.1] - 2022-04-22
- Stop streaming on didEnterBackgroundNotification

## [0.2.0] - 2022-04-13
- Add default parameters for audio and video config
- Fix continous auto focus
- Call `onDisconnect` when connection is closed
- Rename `Resolution` to `Size`
- Few fixes on example

## [0.1.0] - 2022-01-27
- Large refactor and clean
- Add a sample application
