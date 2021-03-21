include $(THEOS)/makefiles/common.mk
export TARGET_CODESIGN_FLAGS="-Ssign.plist"

TOOL_NAME = esplios
esplios_OBJ_FILES = /Users/rpwnage/Downloads/OpenSSLStaticLibs/libssl.a 
esplios_FILES = src/main.mm src/espl.m
esplios_FRAMEWORKS = Foundation Security AudioToolbox CoreFoundation AVFoundation MediaPlayer UIKit
#esplios_PRIVATE_FRAMEWORKS = AppSupport SpringBoardServices IOSurface

include $(THEOS_MAKE_PATH)/tool.mk
ARCHS = arm64 arm64e

CFLAGS = -Wall -g -lssl -lcrypto
