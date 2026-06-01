@echo off

::set "PRG=amok"
::set "MEM=none"
set "PRG=amok 8k"
set "MEM=8k"

cd .\d64
C:\Users\spwil\Documents\Commodore\Tools\GTK3VICE-3.3-win32-r35872\xvic.exe -model vic20pal -memory %MEM% "Amok.d64:%PRG%"
cd ..

::-----------------------------------------------------------------------------------
:: Run prg directly
::Note: autostartprgmode 2 is copy to D64
::cd .\prg
::C:\Users\spwil\Documents\Commodore\Tools\GTK3VICE-3.3-win32-r35872\xvic.exe -model vic20pal -memory none -autostartprgmode 2 "amok.prg"
::C:\Users\spwil\Documents\Commodore\Tools\GTK3VICE-3.3-win32-r35872\xvic.exe -model vic20pal -memory 8k -autostartprgmode 2 "amok 8k.prg"
::cd ..
