# MCU name
MCU = STM32F303
CONSOLE_ENABLE = yes

RGBLIGHT_ENABLE = no
WS2812_DRIVER = pwm

BACKLIGHT_ENABLE = no
#BACKLIGHT_DRIVER = pwm

AUDIO_ENABLE = yes
AUDIO_DRIVER = pwm_software
AUDIO_PIN = A5
AUDIO_PIN_ALT = A4

SRC += proton_c.c
