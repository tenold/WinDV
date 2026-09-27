@echo off
setlocal

set VCVARS=C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars32.bat
set ATLMFC=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.44.35207\atlmfc
set BASECLASSES=C:\Users\rober\Downloads\WinDV-src-1.2.3\baseclasses
set SRC=C:\Users\rober\Downloads\WinDV-src-1.2.3\WinDV
set OUT=%SRC%\Release

call "%VCVARS%"
if errorlevel 1 ( echo ERROR: vcvars32.bat failed & goto :error )

:: Add MFC from VS 2022 Build Tools (only atlmfc was installed there)
set INCLUDE=%ATLMFC%\include;%INCLUDE%
set LIB=%ATLMFC%\lib\x86;%LIB%

:: /Zc:wchar_t- makes wchar_t a typedef for unsigned short, matching strmbase.lib's ABI
set CFLAGS=/nologo /MD /W3 /EHsc /O2 /Zc:wchar_t- /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_AFXDLL" /D "_MBCS" /D "_WIN32_DCOM" /D "_CRT_SECURE_NO_WARNINGS" /D "WINVER=0x0601" /D "_WIN32_WINNT=0x0601" /I"%BASECLASSES%"
:: legacy_stdio_definitions.lib resolves __vsnwprintf_s used internally by strmbase.lib
set LIBS=strmbase.lib legacy_stdio_definitions.lib quartz.lib winmm.lib kernel32.lib user32.lib gdi32.lib advapi32.lib version.lib comctl32.lib ole32.lib oleaut32.lib uuid.lib shell32.lib

mkdir "%OUT%" 2>nul

echo === Compiling precompiled header ===
cl %CFLAGS% /Yc"stdafx.h" /Fp"%OUT%\WinDV.pch" /Fo"%OUT%\StdAfx.obj" /c "%SRC%\StdAfx.cpp"
if errorlevel 1 goto :error

echo === Compiling sources ===
for %%f in (CaptureCfg DropFilesEdit DShow DV DVToolsDlg RecordCfg ToolTab VideoDeviceSel WinDV) do (
    echo   %%f.cpp
    cl %CFLAGS% /Yu"stdafx.h" /Fp"%OUT%\WinDV.pch" /Fo"%OUT%\%%f.obj" /c "%SRC%\%%f.cpp"
    if errorlevel 1 goto :error
)

echo === Compiling resources ===
rc /nologo /D "NDEBUG" /D "_AFXDLL" /fo"%OUT%\WinDV.res" "%SRC%\WinDV.rc"
if errorlevel 1 goto :error

echo === Linking ===
link /nologo /SUBSYSTEM:WINDOWS /MACHINE:X86 ^
    "%OUT%\StdAfx.obj" "%OUT%\CaptureCfg.obj" "%OUT%\DropFilesEdit.obj" ^
    "%OUT%\DShow.obj" "%OUT%\DV.obj" "%OUT%\DVToolsDlg.obj" ^
    "%OUT%\RecordCfg.obj" "%OUT%\ToolTab.obj" "%OUT%\VideoDeviceSel.obj" ^
    "%OUT%\WinDV.obj" "%OUT%\WinDV.res" ^
    %LIBS% /OUT:"%OUT%\WinDV.exe"
if errorlevel 1 goto :error

echo === Embedding manifest ===
mt -nologo -manifest "%SRC%\WinDV.exe.manifest" -outputresource:"%OUT%\WinDV.exe;1"

echo.
echo === BUILD SUCCESSFUL ===
echo Output: %OUT%\WinDV.exe
goto :end

:error
echo.
echo === BUILD FAILED ===
exit /b 1

:end
endlocal
