CC					?= cc
STRIP				?= strip
FAKEROOT			?= fakeroot
LDID				?= ldid

DESTDIR				?= out

FIRMWARE_MAINTAINER	?= Zebra Team
PREFIX                  ?= /
EXECPREFIX              ?= usr/

TARGET_PLATFORM		?= iphoneos
TARGET_VERSION		?= 11.0
TARGET_ARCH			?= arm64
TARGET_SYSROOT		?= $(shell xcrun --sdk $(TARGET_PLATFORM) --show-sdk-path)

ifeq (,$(findstring -arch ,$(CFLAGS)))
CFLAGS += -arch $(TARGET_ARCH)
endif

ifeq (,$(findstring -isysroot ,$(CFLAGS)))
CFLAGS += -isysroot $(TARGET_SYSROOT)
endif

CFLAGS += -m$(TARGET_PLATFORM)-version-min=$(TARGET_VERSION)

ifeq ($(DEBUG),1)
CFLAGS += -DDEBUG
endif

all:: src/*.m
	mkdir -p build
	$(CC) $(CFLAGS) -fobjc-arc -DMAINTAINER='@"$(FIRMWARE_MAINTAINER)"' -DPREFIX='@"$(PREFIX)"' -DEXECPREFIX='@"$(EXECPREFIX)"' src/*.m -o build/firmware -Ibuild -framework Foundation -O3
	$(STRIP) build/firmware
	$(LDID) -Sentitlements.plist build/firmware
	$(FAKEROOT) chmod 755 build/firmware

install::
	mkdir -p $(DESTDIR)
	cp -a build/firmware $(DESTDIR)

clean::
	rm -rf firmware build out


# theos subproject compatibilty
internal-stage:: install
	@:

internal-after-install::
	@:
