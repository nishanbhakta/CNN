@echo off
setlocal EnableExtensions
REM Quick test script - just compile and run the CNN accelerator testbench

set "ROOT_DIR=%~dp0"
set "IVERILOG=iverilog"
set "VVP=vvp"

call :resolve_tool IVERILOG iverilog "C:\iverilog\bin\iverilog.exe"
if errorlevel 1 (
    if not defined NO_PAUSE pause
    exit /b 1
)

call :resolve_tool VVP vvp "C:\iverilog\bin\vvp.exe"
if errorlevel 1 (
    if not defined NO_PAUSE pause
    exit /b 1
)

echo Compiling CNN Accelerator...
"%IVERILOG%" -g2012 -o "%ROOT_DIR%cnn_test.vvp" ^
    "%ROOT_DIR%src\multiplier.v" ^
    "%ROOT_DIR%src\MAC.v" ^
    "%ROOT_DIR%src\divider_Version2.v" ^
    "%ROOT_DIR%src\divide_by_9_Version2.v" ^
    "%ROOT_DIR%src\controller_Version2.v" ^
    "%ROOT_DIR%src\cnn_accelerator_Version2.v" ^
    "%ROOT_DIR%tb\cnn_accelerator_tb_Version2.v"

if errorlevel 1 (
    echo.
    echo ERROR: Compilation failed!
    echo Check that the repository files are present and Icarus Verilog is installed.
    if not defined NO_PAUSE pause
    exit /b 1
)

echo.
echo Compilation successful!
echo.
echo Running simulation...
echo.
pushd "%ROOT_DIR%" >nul
"%VVP%" "cnn_test.vvp"
set "STATUS=%ERRORLEVEL%"
popd >nul

if not "%STATUS%"=="0" (
    echo.
    echo ERROR: Simulation failed!
    if not defined NO_PAUSE pause
    exit /b %STATUS%
)

echo.
echo Simulation complete!
echo.
if not defined NO_PAUSE pause
exit /b 0

:resolve_tool
where "%~2" >nul 2>nul
if not errorlevel 1 (
    set "%~1=%~2"
    exit /b 0
)

if exist "%~3" (
    set "%~1=%~3"
    exit /b 0
)

echo ERROR: Could not find %~2.
echo Install Icarus Verilog and make sure both iverilog and vvp are in PATH.
echo As a fallback, these scripts also accept the default install path C:\iverilog\bin.
exit /b 1
