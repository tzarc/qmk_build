MCU = STM32G474

SRC += \
	menu.c

BOOTMAGIC_ENABLE = lite     # Virtual DIP switch configuration
MOUSEKEY_ENABLE = no        # Mouse keys
EXTRAKEY_ENABLE = no        # Audio control and System control
CONSOLE_ENABLE = yes        # Console for debug
COMMAND_ENABLE = no         # Commands for debug and configuration
SLEEP_LED_ENABLE = no       # Breathing sleep LED during USB suspend
NKRO_ENABLE = no            # USB Nkey Rollover
UNICODE_ENABLE = no         # Unicode

SPLIT_KEYBOARD = yes
SERIAL_DRIVER = usart

ENCODER_ENABLE = yes

USBPD_ENABLE = yes

BACKLIGHT_ENABLE = yes
BACKLIGHT_DRIVER = pwm

WS2812_DRIVER = pwm
CIE1931_CURVE = yes

RGBLIGHT_ENABLE = no
RGBLIGHT_DRIVER = WS2812

RGB_MATRIX_ENABLE = yes
RGB_MATRIX_DRIVER = WS2812

EEPROM_DRIVER = spi

AUDIO_ENABLE = no
AUDIO_DRIVER = pwm_software
AUDIO_PIN = A5
AUDIO_PIN_ALT = A4

QUANTUM_PAINTER_ENABLE = yes
QUANTUM_PAINTER_DRIVERS = ili9341

LTO_ENABLE = yes
OPT = 2

#LTO_ENABLE = no
#OPT = 0
#OPT_DEFS += -g

FIRMWARE_FORMAT = uf2