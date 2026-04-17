@echo off
title ANIGIFT Edge Fade Tool
echo.
echo ========================================
echo   ANIGIFT Edge Fade Tool
echo ========================================
echo.

REM --- [1] Edge Fade Direction ---
echo [1] Edge Fade Direction:
echo     1: Vertical (top/bottom)
echo     2: Horizontal (left/right)
echo     3: All edges
echo     4: None
set /p DIR_CHOICE="    > "
if "%DIR_CHOICE%"=="1" set DIRECTION=vertical
if "%DIR_CHOICE%"=="2" set DIRECTION=horizontal
if "%DIR_CHOICE%"=="3" set DIRECTION=all
if "%DIR_CHOICE%"=="4" set DIRECTION=none
if not defined DIRECTION set DIRECTION=vertical
echo.

REM --- [2] Edge Fade Width ---
if "%DIRECTION%"=="none" (
    set FADE_PCT=8
    echo [2] Edge Fade Width: SKIPPED (edge fade off)
) else (
    echo [2] Edge Fade Width (%%) [default: 8]:
    set /p FADE_PCT="    > "
    if not defined FADE_PCT set FADE_PCT=8
)
echo.

REM --- [3] Fade In/Out ---
echo [3] Fade In/Out:
echo     1: ON
echo     2: OFF
set /p FADE_CHOICE="    > "
echo.

REM --- [4] Fade Duration ---
if "%FADE_CHOICE%"=="1" (
    echo [4] Fade In/Out Duration (sec) [default: 1]:
    set /p FADE_DUR="    > "
    if not defined FADE_DUR set FADE_DUR=1
) else (
    set FADE_DUR=0
)
echo.

REM --- Summary ---
echo ========================================
echo   Direction : %DIRECTION%
if not "%DIRECTION%"=="none" echo   Width     : %FADE_PCT%%%
if "%FADE_CHOICE%"=="1" (
    echo   Fade In   : %FADE_DUR%s
    echo   Fade Out  : %FADE_DUR%s
) else (
    echo   Fade In   : OFF
    echo   Fade Out  : OFF
)
echo ========================================
echo.
echo Press any key to start...
pause >nul
echo.

REM --- Execute ---
powershell -ExecutionPolicy Bypass -File "%~dp0edge-fade.ps1" -Direction "%DIRECTION%" -FadePercent %FADE_PCT% -FadeInSec %FADE_DUR% -FadeOutSec %FADE_DUR%

echo.
echo ----------------------------------------
echo   DONE! Check the ZIP file.
echo   Press any key to close.
echo ----------------------------------------
pause >nul
