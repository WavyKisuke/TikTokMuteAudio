TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
SYSROOT = $(THEOS)/sdks/iPhoneOS14.5.sdk
include $(THEOS)/makefiles/common.mk
TWEAK_NAME = TikTokMuteAudio
TikTokMuteAudio_FILES = Tweak.x
TikTokMuteAudio_FRAMEWORKS = AVFoundation
include $(THEOS_MAKE_PATH)/tweak.mk
