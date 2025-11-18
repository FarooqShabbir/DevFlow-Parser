@echo off
REM Windows Build Script for DevFlow DSL Parser
REM Requires: bison, flex, gcc (can be installed via MSYS2, MinGW, or WSL)

echo Building DevFlow DSL Parser...
echo.

REM Check if bison is available
where bison >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: bison is not installed or not in PATH
    echo.
    echo Please install bison, flex, and gcc using one of these methods:
    echo.
    echo Option 1 - MSYS2 (Recommended for Windows):
    echo   Download from: https://www.msys2.org/
    echo   Then run: pacman -S bison flex gcc make
    echo.
    echo Option 2 - MinGW-w64:
    echo   Download from: https://www.mingw-w64.org/
    echo.
    echo Option 3 - WSL (Windows Subsystem for Linux):
    echo   Install WSL, then: sudo apt-get install bison flex gcc make
    echo.
    pause
    exit /b 1
)

REM Generate parser
echo Generating parser from Bison grammar...
bison -d devflow.y
if %errorlevel% neq 0 (
    echo ERROR: Failed to generate parser
    pause
    exit /b 1
)

REM Check if flex is available
where flex >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: flex is not installed or not in PATH
    pause
    exit /b 1
)

REM Generate lexer
echo Generating lexer from Flex file...
flex devflow.l
if %errorlevel% neq 0 (
    echo ERROR: Failed to generate lexer
    pause
    exit /b 1
)

REM Check if gcc is available
where gcc >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: gcc is not installed or not in PATH
    pause
    exit /b 1
)

REM Compile
echo Compiling parser...
gcc -Wall -g -c devflow.tab.c -o devflow.tab.o
if %errorlevel% neq 0 (
    echo ERROR: Failed to compile parser
    pause
    exit /b 1
)

gcc -Wall -g -c lex.yy.c -o lex.yy.o
if %errorlevel% neq 0 (
    echo ERROR: Failed to compile lexer
    pause
    exit /b 1
)

REM Link
echo Linking executable...
gcc -Wall -g -o devflow_parser.exe devflow.tab.o lex.yy.o -lfl
if %errorlevel% neq 0 (
    echo WARNING: Linking with -lfl failed, trying without...
    gcc -Wall -g -o devflow_parser.exe devflow.tab.o lex.yy.o
    if %errorlevel% neq 0 (
        echo ERROR: Failed to link executable
        pause
        exit /b 1
    )
)

echo.
echo Build completed successfully!
echo Executable: devflow_parser.exe
echo.
echo Usage: devflow_parser.exe test_pipeline.devflow
echo.

