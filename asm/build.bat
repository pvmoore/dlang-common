@echo off

rem objconv -fmasm file.obj here.asm

rem /Cp - preserve case of identifiers
rem /WX - treat warnings as errors
rem /Zd - add line number debug info
rem /Zi - add symbolic debug info

set ML64="ml64.exe" /nologo /WX /Cp /I.
set LIBEXE="lib.exe" /nologo

cd asm

echo Compiling...
%ML64% /Fo obj\common.obj /c common.asm
%ML64% /Fo obj\strings.obj /c strings.asm
%ML64% /Fo obj\dump.obj /c dump.asm


rem echo Creating common-asm.lib
rem %LIBEXE% /out:..\common-asm.lib *.obj

rem del *.obj
