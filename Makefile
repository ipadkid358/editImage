DEBUG = 0
ARCHS = armv7 arm64

include $(THEOS)/makefiles/common.mk

TOOL_NAME = editImage
$(TOOL_NAME)_FILES = main.m
$(TOOL_NAME)_FRAMEWORKS = UIKit
$(TOOL_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tool.mk
