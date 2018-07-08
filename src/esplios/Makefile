include $(THEOS)/makefiles/common.mk
export SYSROOT = /opt/theos/sdks/iPhoneOS9.3.sdk
export TARGET_CODESIGN_FLAGS="-Ssign.plist"
TOOL_NAME = esplios

esplios_FILES = main.mm espl.m
esplios_OBJ_FILES = libcrypto.a libssl.a
esplios_FRAMEWORKS = Foundation Security AudioToolbox CoreFoundation AVFoundation MediaPlayer UIKit
esplios_PRIVATE_FRAMEWORKS = AppSupport SpringBoardServices IOSurface

include $(THEOS_MAKE_PATH)/tool.mk

export ARCHS = armv7 arm64

CFLAGS = -Wall -g
