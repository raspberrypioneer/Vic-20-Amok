:: Amok - perform a full build of program
:: USE_8k_MEMORY_LAYOUT = 0 for unexpanded memory layout or, = 1 for 8K+ expanded memory layout
@echo off

::-----------------------------------------------------------------------------------
set USE_8k_MEMORY_LAYOUT=0
set "PRG=amok.prg"
set "PRGHDR=prgheader.bin"
call :create_prg_file_for_version

:: Binary file comparison for unexpanded version
fc.exe /b ".\prg\%PRG%" ".\prg\Amok original.prg"
echo --- Unexpanded version built ---

::-----------------------------------------------------------------------------------
set USE_8k_MEMORY_LAYOUT=1
set "PRG=amok 8k.prg"
set "PRGHDR=prgheader8k.bin"
call :create_prg_file_for_version

:: Binary file comparison for tested 8k version
fc.exe /b ".\prg\%PRG%" ".\prg\amok 8k tested.prg"
echo --- 8k version built ---

goto :build_d64

::-----------------------------------------------------------------------------------
:: Subroutine to compile and copy renamed file into the prg folder
:create_prg_file_for_version

:: Compile main programs
.\bin\acme.exe -l .\build\symbols -o .\build\main -DUSE_8k_MEMORY_LAYOUT=%USE_8k_MEMORY_LAYOUT% .\main.asm

:: Add the 2 load address bytes for the PRG header (PRG header created using Notepad++ with hex editor plugin)
copy /b .\build\%PRGHDR%+.\build\main ".\prg\%PRG%" >nul

exit /B

::-----------------------------------------------------------------------------------
:: Subroutine to build the d64 file with both the unexpanded and 8k versions included
:build_d64
del ".\d64\Amok.d64"
%PYPATH%\python .\utilities\create_d64.py
echo Done!
