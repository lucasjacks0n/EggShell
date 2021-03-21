include $(THEOS)/makefiles/common.mk
export TARGET_CODESIGN_FLAGS="-Ssign.plist"
export TARGET = iphone:clang:14.4

TOOL_NAME 	= esplios
SDKVERSION 	= 14.4
ARCHS 			= arm64 arm64e

esplios_FILES 							= 	src/main.mm src/espl.m
esplios_FRAMEWORKS 					= 	Foundation Security AudioToolbox CoreFoundation AVFoundation MediaPlayer UIKit
esplios_PRIVATE_FRAMEWORKS 	= 	AppSupport SpringBoardServices IOSurface
esplios_LDFLAGS 						+= 	-L ./lib/ -lssl -lcrypto

include $(THEOS_MAKE_PATH)/tool.mk

