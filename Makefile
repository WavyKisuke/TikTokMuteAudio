TARGET := iphone:clang:16.5:14.0
ARCHS = arm64 arm64e
SYSROOT = $(THEOS)/sdks/iPhoneOS16.5.sdk
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TikTokMuteAudio
TikTokMuteAudio_FILES = Tweak.x
TikTokMuteAudio_FRAMEWORKS = UIKit AVFoundation
TikTokMuteAudio_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
