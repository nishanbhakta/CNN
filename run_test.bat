@echo off
REM Quick test script - just compile and run the CNN accelerator testbench

echo Compiling CNN Accelerator...
iverilog -g2012 -o cnn_test.vvp src\multiplier.v src\MAC.v src\divider_Version2.v src\divide_by_9_Version2.v src\controller_Version2.v src\cnn_accelerator_Version2.v tb\cnn_accelerator_tb_Version2.v

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Compilation failed!
    echo Check if all source files exist and iverilog is properly installed.
    pause
    exit /b 1
)

echo.
echo Compilation successful!
echo.
echo Running simulation...
echo.
vvp cnn_test.vvp

echo.
echo Simulation complete!
echo.
pause
