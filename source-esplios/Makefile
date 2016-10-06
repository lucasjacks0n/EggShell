include $(THEOS)/makefiles/common.mk

export TARGET_CODESIGN_FLAGS="-Ssign.plist"

TOOL_NAME = esplios

esplios_FILES = main.mm FBEncryptorAES.m NSData+AESCrypt.m espl.m

esplios_FRAMEWORKS = Security AudioToolbox CoreFoundation AVFoundation MediaPlayer UIKit
esplios_PRIVATE_FRAMEWORKS = AppSupport SpringBoardServices

include $(THEOS_MAKE_PATH)/tool.mk

export ARCHS = armv7

CFLAGS = -Wall -g