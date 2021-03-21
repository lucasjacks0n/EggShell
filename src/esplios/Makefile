include $(THEOS)/makefiles/common.mk
export SYSROOT = /Users/rpwnage/theos/sdks/iPhoneOS14.4.sdk
export TARGET_CODESIGN_FLAGS="-Ssign.plist"

TOOL_NAME = esplios
export TARGET = iphone:latest:14.4
esplios_OBJ_FILES = ../../resources/lib/iOS/libcrypto.a ../../resources/lib/iOS/libssl.a
esplios_FILES = src/main.mm src/espl.m
esplios_FRAMEWORKS = Foundation Security AudioToolbox CoreFoundation AVFoundation MediaPlayer UIKit
esplios_PRIVATE_FRAMEWORKS = AppSupport SpringBoardServices IOSurface
esplios_ARCHS = arm64 arm64e
esplios_LDFLAGS = -L../../resources/lib/iOS/ -lssl -lcrypto
esplios_CFLAGS = -Wall -g

include $(THEOS_MAKE_PATH)/tool.mk

