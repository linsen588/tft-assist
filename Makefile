TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TFTAssist
TFTAssist_FILES = Tweak.xm
TFTAssist_FRAMEWORKS = UIKit Foundation ReplayKit Vision CoreVideo CoreMedia
TFTAssist_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

# 越狱机才启用触摸注入
# TFTAssist_CFLAGS += -DTFT_JAILBREAK=1

include $(THEOS_MAKE_PATH)/tweak.mk