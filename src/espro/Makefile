include $(THEOS)/makefiles/common.mk
export TARGET = iphone:clang:13.0

DEBUG				= 1
TWEAK_NAME 			= espro
SDKVERSION 			= 13.0
ARCHS 				= arm64 arm64e

espro_FILES 				= src/main.xm
espro_FRAMEWORKS            = Foundation UIKit
espro_CFLAGS 				= -fobjc-arc -Wno-unused -I./src/include -I/Users/rpwnage/theos/sdks/iPhoneOS$(SDKVERSION).sdk/usr/include
espro_PRIVATE_FRAMEWORKS 	= AppSupport


include $(THEOS_MAKE_PATH)/tweak.mk
after-install::
	install.exec "killall -9 SpringBoard"
