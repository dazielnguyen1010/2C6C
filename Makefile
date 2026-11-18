export THEOS_PACKAGE_SCHEME = rootless
TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = 2C6C

2C6C_FILES = Tweak.x DZLJBGlassShader.m DZLJBControlsGallery.m
2C6C_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-parameter -Wno-undeclared-selector
2C6C_FRAMEWORKS = UIKit QuartzCore CoreGraphics CoreMotion MediaPlayer Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += 2C6CPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk
