@echo off
setlocal EnableExtensions
REM CNN Accelerator Simulation Script for Windows
REM Usage: sim.bat [test_name]
REM Available tests: cnn, cnn_csv, uart, multiplier, mac, divider, div9, all

set "ROOT_DIR=%~dp0"
set "SRC_DIR=%ROOT_DIR%src"
set "TB_DIR=%ROOT_DIR%tb"
set "OUT_DIR=%ROOT_DIR%sim_output"
set "VCD_DIR=%OUT_DIR%\waveforms"
set "IVERILOG=iverilog"
set "VVP=vvp"

call :resolve_tool IVERILOG iverilog "C:\iverilog\bin\iverilog.exe"
if errorlevel 1 exit /b 1

call :resolve_tool VVP vvp "C:\iverilog\bin\vvp.exe"
if errorlevel 1 exit /b 1

REM Create output directories
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
if not exist "%VCD_DIR%" mkdir "%VCD_DIR%"

REM Parse command line argument
set "TEST=%~1"
if "%TEST%"=="" set "TEST=cnn"

echo ========================================
echo CNN Accelerator Simulation
echo ========================================

if /I "%TEST%"=="cnn" (
    call :run_cnn
    exit /b %ERRORLEVEL%
)
if /I "%TEST%"=="cnn_csv" (
    call :run_cnn_csv
    exit /b %ERRORLEVEL%
)
if /I "%TEST%"=="uart" (
    call :run_uart
    exit /b %ERRORLEVEL%
)
if /I "%TEST%"=="multiplier" (
    call :run_multiplier
    exit /b %ERRORLEVEL%
)
if /I "%TEST%"=="mac" (
    call :run_mac
    exit /b %ERRORLEVEL%
)
if /I "%TEST%"=="divider" (
    call :run_divider
    exit /b %ERRORLEVEL%
)
if /I "%TEST%"=="div9" (
    call :run_div9
    exit /b %ERRORLEVEL%
)
if /I "%TEST%"=="all" (
    call :run_all
    exit /b %ERRORLEVEL%
)
if /I "%TEST%"=="clean" (
    call :clean
    exit /b %ERRORLEVEL%
)
if /I "%TEST%"=="help" (
    call :help
    exit /b %ERRORLEVEL%
)

echo Unknown test: %TEST%
call :help
exit /b 1

:run_cnn
echo.
echo === Compiling CNN Accelerator ===
"%IVERILOG%" -g2012 -o "%OUT_DIR%\cnn_accelerator.vvp" ^
    "%SRC_DIR%\multiplier.v" ^
    "%SRC_DIR%\MAC.v" ^
    "%SRC_DIR%\divider_Version2.v" ^
    "%SRC_DIR%\divide_by_9_Version2.v" ^
    "%SRC_DIR%\controller_Version2.v" ^
    "%SRC_DIR%\cnn_accelerator_Version2.v" ^
    "%TB_DIR%\cnn_accelerator_tb_Version2.v"

if errorlevel 1 (
    echo Compilation failed!
    exit /b 1
)

echo === Running CNN Accelerator Simulation ===
pushd "%OUT_DIR%" >nul
"%VVP%" "cnn_accelerator.vvp"
set "STATUS=%ERRORLEVEL%"
popd >nul

if not "%STATUS%"=="0" (
    echo Simulation failed!
    exit /b %STATUS%
)

if exist "%ROOT_DIR%cnn_accelerator_tb.vcd" move /Y "%ROOT_DIR%cnn_accelerator_tb.vcd" "%VCD_DIR%\" >nul
if exist "%OUT_DIR%\cnn_accelerator_tb.vcd" move /Y "%OUT_DIR%\cnn_accelerator_tb.vcd" "%VCD_DIR%\" >nul

echo === Simulation Complete ===
echo Waveform saved to %VCD_DIR%\cnn_accelerator_tb.vcd
exit /b 0

:run_cnn_csv
echo.
echo === Compiling CNN Accelerator CSV Testbench ===
"%IVERILOG%" -g2012 -DUSE_CSV_TEST_DATA -o "%OUT_DIR%\cnn_csv.vvp" ^
    "%SRC_DIR%\multiplier.v" ^
    "%SRC_DIR%\MAC.v" ^
    "%SRC_DIR%\divider_Version2.v" ^
    "%SRC_DIR%\divide_by_9_Version2.v" ^
    "%SRC_DIR%\controller_Version2.v" ^
    "%SRC_DIR%\cnn_accelerator_Version2.v" ^
    "%TB_DIR%\cnn_accelerator_tb_Version2.v"

if errorlevel 1 (
    echo Compilation failed!
    exit /b 1
)

echo === Running CNN Accelerator CSV Simulation ===
pushd "%ROOT_DIR%" >nul
"%VVP%" "%OUT_DIR%\cnn_csv.vvp"
set "STATUS=%ERRORLEVEL%"
popd >nul

if not "%STATUS%"=="0" (
    echo Simulation failed!
    exit /b %STATUS%
)

if exist "%ROOT_DIR%cnn_accelerator_tb.vcd" move /Y "%ROOT_DIR%cnn_accelerator_tb.vcd" "%VCD_DIR%\cnn_accelerator_csv_tb.vcd" >nul
if exist "%OUT_DIR%\cnn_accelerator_tb.vcd" move /Y "%OUT_DIR%\cnn_accelerator_tb.vcd" "%VCD_DIR%\cnn_accelerator_csv_tb.vcd" >nul

echo === Simulation Complete ===
echo Waveform saved to %VCD_DIR%\cnn_accelerator_csv_tb.vcd
exit /b 0

:run_uart
echo.
echo === Compiling UART Result Streamer ===
"%IVERILOG%" -g2012 -o "%OUT_DIR%\uart_result_streamer.vvp" ^
    "%SRC_DIR%\uart_tx.v" ^
    "%SRC_DIR%\uart_result_streamer.v" ^
    "%TB_DIR%\uart_result_streamer_tb.v"

if errorlevel 1 (
    echo Compilation failed!
    exit /b 1
)

echo === Running UART Result Streamer Simulation ===
pushd "%OUT_DIR%" >nul
"%VVP%" "uart_result_streamer.vvp"
set "STATUS=%ERRORLEVEL%"
popd >nul

if not "%STATUS%"=="0" (
    echo Simulation failed!
    exit /b %STATUS%
)

if exist "%ROOT_DIR%uart_result_streamer_tb.vcd" move /Y "%ROOT_DIR%uart_result_streamer_tb.vcd" "%VCD_DIR%\" >nul
if exist "%OUT_DIR%\uart_result_streamer_tb.vcd" move /Y "%OUT_DIR%\uart_result_streamer_tb.vcd" "%VCD_DIR%\" >nul

echo === Simulation Complete ===
exit /b 0

:run_multiplier
echo.
echo === Compiling Multiplier ===
"%IVERILOG%" -g2012 -o "%OUT_DIR%\multiplier.vvp" ^
    "%SRC_DIR%\multiplier.v" ^
    "%TB_DIR%\multiplier_tb_Version2.v"

if errorlevel 1 (
    echo Compilation failed!
    exit /b 1
)

echo === Running Multiplier Simulation ===
pushd "%OUT_DIR%" >nul
"%VVP%" "multiplier.vvp"
set "STATUS=%ERRORLEVEL%"
popd >nul

if not "%STATUS%"=="0" (
    echo Simulation failed!
    exit /b %STATUS%
)

if exist "%ROOT_DIR%multiplier_tb.vcd" move /Y "%ROOT_DIR%multiplier_tb.vcd" "%VCD_DIR%\" >nul
if exist "%OUT_DIR%\multiplier_tb.vcd" move /Y "%OUT_DIR%\multiplier_tb.vcd" "%VCD_DIR%\" >nul

echo === Simulation Complete ===
exit /b 0

:run_mac
echo.
echo === Compiling MAC ===
"%IVERILOG%" -g2012 -o "%OUT_DIR%\mac.vvp" ^
    "%SRC_DIR%\multiplier.v" ^
    "%SRC_DIR%\MAC.v" ^
    "%TB_DIR%\mac_tb_Version2.v"

if errorlevel 1 (
    echo Compilation failed!
    exit /b 1
)

echo === Running MAC Simulation ===
pushd "%OUT_DIR%" >nul
"%VVP%" "mac.vvp"
set "STATUS=%ERRORLEVEL%"
popd >nul

if not "%STATUS%"=="0" (
    echo Simulation failed!
    exit /b %STATUS%
)

if exist "%ROOT_DIR%mac_tb.vcd" move /Y "%ROOT_DIR%mac_tb.vcd" "%VCD_DIR%\" >nul
if exist "%OUT_DIR%\mac_tb.vcd" move /Y "%OUT_DIR%\mac_tb.vcd" "%VCD_DIR%\" >nul

echo === Simulation Complete ===
exit /b 0

:run_divider
echo.
echo === Compiling Divider ===
"%IVERILOG%" -g2012 -o "%OUT_DIR%\divider.vvp" ^
    "%SRC_DIR%\divider_Version2.v" ^
    "%TB_DIR%\divider_tb_Version2.v"

if errorlevel 1 (
    echo Compilation failed!
    exit /b 1
)

echo === Running Divider Simulation ===
pushd "%OUT_DIR%" >nul
"%VVP%" "divider.vvp"
set "STATUS=%ERRORLEVEL%"
popd >nul

if not "%STATUS%"=="0" (
    echo Simulation failed!
    exit /b %STATUS%
)

if exist "%ROOT_DIR%divider_tb.vcd" move /Y "%ROOT_DIR%divider_tb.vcd" "%VCD_DIR%\" >nul
if exist "%OUT_DIR%\divider_tb.vcd" move /Y "%OUT_DIR%\divider_tb.vcd" "%VCD_DIR%\" >nul

echo === Simulation Complete ===
exit /b 0

:run_div9
echo.
echo === Compiling Divide-by-9 ===
"%IVERILOG%" -g2012 -o "%OUT_DIR%\div9.vvp" ^
    "%SRC_DIR%\divide_by_9_Version2.v" ^
    "%TB_DIR%\divide_by_9_Version2.v"

if errorlevel 1 (
    echo Compilation failed!
    exit /b 1
)

echo === Running Divide-by-9 Simulation ===
pushd "%OUT_DIR%" >nul
"%VVP%" "div9.vvp"
set "STATUS=%ERRORLEVEL%"
popd >nul

if not "%STATUS%"=="0" (
    echo Simulation failed!
    exit /b %STATUS%
)

if exist "%ROOT_DIR%divide_by_9_tb.vcd" move /Y "%ROOT_DIR%divide_by_9_tb.vcd" "%VCD_DIR%\" >nul
if exist "%OUT_DIR%\divide_by_9_tb.vcd" move /Y "%OUT_DIR%\divide_by_9_tb.vcd" "%VCD_DIR%\" >nul

echo === Simulation Complete ===
exit /b 0

:run_all
call :run_multiplier
if errorlevel 1 exit /b 1
call :run_mac
if errorlevel 1 exit /b 1
call :run_divider
if errorlevel 1 exit /b 1
call :run_div9
if errorlevel 1 exit /b 1
call :run_uart
if errorlevel 1 exit /b 1
call :run_cnn
if errorlevel 1 exit /b 1
call :run_cnn_csv
if errorlevel 1 exit /b 1
echo.
echo === All Tests Complete ===
exit /b 0

:clean
echo Cleaning simulation outputs...
if exist "%OUT_DIR%" rd /s /q "%OUT_DIR%"
del /q "%ROOT_DIR%*.vcd" 2>nul
del /q "%ROOT_DIR%*.vvp" 2>nul
echo === Cleaned ===
exit /b 0

:help
echo.
echo CNN Accelerator Simulation Script
echo ==================================
echo Usage: sim.bat [test_name]
echo.
echo Available tests:
echo   cnn         - Run CNN accelerator simulation (default)
echo   cnn_csv     - Run CSV-driven CNN accelerator simulation with accuracy summary
echo   uart        - Run UART result streamer testbench
echo   multiplier  - Run multiplier testbench
echo   mac         - Run MAC testbench
echo   divider     - Run divider testbench
echo   div9        - Run divide-by-9 testbench
echo   all         - Run all testbenches
echo   clean       - Remove all simulation outputs
echo   help        - Show this help message
echo.
echo Examples:
echo   sim.bat              (runs CNN accelerator)
echo   sim.bat cnn_csv      (runs the CSV-driven CNN testbench)
echo   sim.bat multiplier   (runs multiplier test)
echo   sim.bat all          (runs all tests)
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
