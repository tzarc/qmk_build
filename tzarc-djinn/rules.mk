MCU = cortex-m4
ARMV = 7
MCU_FAMILY = STM32
MCU_SERIES = STM32G4xx
MCU_LDSCRIPT = STM32G474xE
MCU_STARTUP = stm32g4xx
BOARD = ST_NUCLEO64_G474RE
USE_FPU = YES
DFU_ARGS = -d 0483:df11 -a 0 -s 0x08000000:leave
DFU_SUFFIX_ARGS = -v 0483 -p df11
#STM32_BOOTLOADER_ADDRESS = 0x1FFF0000

#-------------------------------------------------

# Build Options
#   change yes to no to disable
#
BOOTMAGIC_ENABLE = lite       # Virtual DIP switch configuration
MOUSEKEY_ENABLE = no        # Mouse keys
EXTRAKEY_ENABLE = yes       # Audio control and System control
CONSOLE_ENABLE = yes        # Console for debug
COMMAND_ENABLE = no         # Commands for debug and configuration
SLEEP_LED_ENABLE = no       # Breathing sleep LED during USB suspend
NKRO_ENABLE = no            # USB Nkey Rollover
BACKLIGHT_ENABLE = yes      # Enable keyboard backlight functionality on B7 by default
RGBLIGHT_ENABLE = yes       # Enable keyboard RGB underglow
UNICODE_ENABLE = no         # Unicode
AUDIO_ENABLE = yes          # Audio output

ENCODER_ENABLE = yes

SPLIT_KEYBOARD = yes
SERIAL_DRIVER = usart_dataxfer

BACKLIGHT_DRIVER = pwm

WS2812_DRIVER = pwm
CIE1931_CURVE = yes

#RGB_MATRIX_ENABLE = WS2812

EEPROM_DRIVER = spi

AUDIO_DRIVER = pwm_software
AUDIO_PIN = A5
AUDIO_PIN_ALT = A4

QUANTUM_PAINTER_DRIVERS = ili9341 ili9488

LTO_ENABLE = yes
OPT = 2

LTO_ENABLE = no
#OPT = 0
#OPT_DEFS += -g