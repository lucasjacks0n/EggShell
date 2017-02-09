include $(THEOS)/makefiles/common.mk

TWEAK_NAME = eggshellPro
eggshellPro_FILES = Tweak.xm
eggshellPro_PRIVATE_FRAMEWORKS = AppSupport
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
