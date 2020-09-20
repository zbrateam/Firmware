# Firmware
Firmware is a tool to generate virtual debian packages for the capablilites found on the device. It is intended to be run on iOS devices.

## Compiling

1. Clone this repository using `git clone https://github.com/zbrateam/Firmware.git`
2. `cd` into the `Firmware` folder
3. (One time only)
    - Install `fakeroot` if you haven't already via `brew install fakeroot`
4. Run `make` to build
5. Run `make install` to install to the `out` folder

## Customizing the build

### Firmware Options

| Variable Name | Description | Default Value |
| --- | --- | --- |
| `FIRMWARE_MAINTAINER` | maintainer to use for the generated packages | `Zebra Team` |

### Custom Tools

| Variable Name | Default Value |
| --- | --- |
| `CC` | `cc` |
| `STRIP` | `strip` |
| `FAKEROOT` | `fakeroot` |
| `LDID` | `ldid` |


### Compiler Options

| Variable Name | Description | Default Value |
| --- | --- | --- |
| `TARGET_PLATFORM` | target device platform | `iphoneos` |
| `TARGET_VERSION` | minimum operating system version | `11.0` |
| `TARGET_ARCH` | target architecture | `arm64` |
| `TARGET_SYSROOT` | sdk to use | xcode's sdk for `TARGET_PLATFORM` |
| `CFLAGS` | additional compiler arguments | _no default_ |


### Install Options

| Variable Name | Description | Default Value |
| --- | --- | --- |
| `DESTDIR` | where to install the binary | `out` |

## Pull Requests

Pull requests to fix bugs, add new features, and fix awful code (I'm sure there is a lot) are also very welcome, and we're happy to work with you in order to get your PR into Firmware.
