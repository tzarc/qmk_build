SRC += \
	tzarc_common.c \
	tzarc_eeprom.c \
	tzarc_rawhid.c \
	tzarc_wow.c \
	tzarc_diablo3.c

BOOTMAGIC_ENABLE = lite
EXTRAKEY_ENABLE = yes
MOUSEKEY_ENABLE = yes
UNICODE_ENABLE = yes
CONSOLE_ENABLE = yes
RAW_ENABLE = yes

ifeq ($(strip $(PLATFORM_KEY)),chibios)
	# Uses defaults above
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
