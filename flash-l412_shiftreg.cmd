@echo off
setlocal
set PATH=%PATH%;E:\QMK_MSYS\mingw64\bin
dfu-util.exe -a 0 -d 0483:df11 -s 0x08000000:leave -D l412_shiftreg_default.bin
endlocal
