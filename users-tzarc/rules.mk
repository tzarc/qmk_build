SRC += \
	tzarc_common.c \
	tzarc_eeprom.c \
	tzarc_rawhid.c \
	tzarc_wow.c \
	tzarc_diablo3.c

DEBUG_MATRIX_SCAN_RATE_ENABLE ?= yes
BOOTMAGIC_ENABLE ?= lite
EXTRAKEY_ENABLE ?= yes
MOUSEKEY_ENABLE ?= no
RAW_ENABLE ?= yes
UNICODE_ENABLE ?= yes

VPATH += $(USER_PATH)/graphics/src

ifeq ($(strip $(PLATFORM_KEY)),chibios)
	# We can actually fit this debounce algorithm on an ARM chip, with the rest of the stuff
	DEBOUNCE_TYPE ?= asym_eager_defer_pk
else ifeq ($(strip $(PLATFORM_KEY)),arm_atsam)
	# This shit's broken, surprise surprise.
	RAW_ENABLE = no
else ifeq ($(strip $(PLATFORM_KEY)),avr)
	ifeq ($(strip $(PROTOCOL)),LUFA)
		# Uses defaults above
	else ifeq ($(strip $(PROTOCOL)),VUSB)
		CONSOLE_ENABLE = no
		RAW_ENABLE = no
	endif
endif