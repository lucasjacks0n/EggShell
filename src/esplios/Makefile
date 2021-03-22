include $(THEOS)/makefiles/common.mk
export TARGET = iphone:clang:14.4

DEBUG				=	1
TOOL_NAME 	= esplios
SDKVERSION 	= 14.4
ARCHS 			= arm64 arm64e

esplios_FILES 							= 	src/main.mm src/espl.m
esplios_FRAMEWORKS 					= 	Foundation Security AudioToolbox CoreFoundation AVFoundation MediaPlayer UIKit
esplios_PRIVATE_FRAMEWORKS 	= 	AppSupport SpringBoardServices IOSurface
esplios_OBJ_FILES						=		lib/libssl.a lib/libcrypto.a
esplios_LDFLAGS 						+= 	-L ./lib/ -lssl -lcrypto
esplios_CODESIGN_FLAGS 			= 	-Ssign.plist

include $(THEOS_MAKE_PATH)/tool.mk

