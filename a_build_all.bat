:: Amok - perform a full build of program
@echo off

:: Memory layout required to build
:: 0 = unexpanded memory layout or 1 = 8K+ expanded memory layout
set USE_8k_MEMORY_LAYOUT=1

if "%USE_8k_MEMORY_LAYOUT%"=="1" (

:: Build main program
.\bin\acme.exe -l .\build\symbols -o .\build\amok -DUSE_8k_MEMORY_LAYOUT=1 .\main.asm

:: Add the 2 load adddress bytes for the PRG header (PRG header created using Notepad++ with hex editor plugin)
copy /b .\build\prgheader8k.bin+.\build\amok ".\prg\Amok.prg" >nul

echo 8k version done!
) else (

:: Build main program
.\bin\acme.exe -l .\build\symbols -o .\build\amok -DUSE_8k_MEMORY_LAYOUT=0 .\main.asm

:: Add the 2 load adddress bytes for the PRG header (PRG header created using Notepad++ with hex editor plugin)
copy /b .\build\prgheader.bin+.\build\amok ".\prg\Amok.prg" >nul

:: Binary file comparison for unexpanded version
fc.exe /b ".\prg\Amok.prg" ".\prg\Amok_original.prg"

echo Unexpanded version done!
)
