@echo off
::Note: autostartprgmode 2 is copy to D64
cd .\prg
C:\Users\spwil\Documents\Commodore\Tools\GTK3VICE-3.3-win32-r35872\xvic.exe -model vic20pal -memory none -autostartprgmode 2 "Amok.prg"
::C:\Users\spwil\Documents\Commodore\Tools\GTK3VICE-3.3-win32-r35872\xvic.exe -model vic20pal -memory 8k -autostartprgmode 2 "Amok.prg"
cd ..