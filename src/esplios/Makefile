include $(THEOS)/makefiles/common.mk
export SYSROOT = ~/theos/sdks/iPhoneOS14.4.sdk
export TARGET_CODESIGN_FLAGS="-Ssign.plist"

TOOL_NAME = esplios
esplios_OBJ_FILES = libcrypto.a libssl.a
esplios_FILES = src/main.mm src/espl.m
esplios_FRAMEWORKS = Foundation Security AudioToolbox CoreFoundation AVFoundation MediaPlayer UIKit
esplios_PRIVATE_FRAMEWORKS = AppSupport SpringBoardServices IOSurface
esplios_ARCHS = arm64 arm64e

include $(THEOS_MAKE_PATH)/tool.mk

CFLAGS = -Wall -g 
