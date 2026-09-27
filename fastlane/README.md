fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios test

```sh
[bundle exec] fastlane ios test
```

단위 테스트를 돌린다 (UI 테스트 제외)

### ios check_app

```sh
[bundle exec] fastlane ios check_app
```

앱 레코드가 App Store Connect 에 있는지 확인한다

### ios upload

```sh
[bundle exec] fastlane ios upload
```

아카이브해서 TestFlight 에 올린다

### ios release

```sh
[bundle exec] fastlane ios release
```

앱 레코드를 확인하고 업로드한다

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
