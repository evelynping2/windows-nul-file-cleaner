@echo off
title Windows NUL File Cleaner - Remove Undeletable Reserved Device Name Files
color 0A

echo ============================================================
echo    Windows NUL File Cleaner
echo    Remove undeletable NUL, CON, PRN, AUX files
echo ============================================================
echo.
echo  WHY DO THESE FILES EXIST?
echo  --------------------------
echo  NUL, CON, PRN, AUX, COM1-9, LPT1-9 are reserved device
echo  names in Windows inherited from MS-DOS.
echo.
echo  These files are typically created when:
echo  - Linux/Unix scripts run on Windows (e.g., redirecting to /dev/null)
echo  - AI tools like Claude Code, GitHub Copilot, or other LLM-based
echo    assistants generate code with Unix-style null redirections
echo  - Cross-platform build tools or package managers execute incorrectly
echo  - WSL or Git Bash scripts output to "nul" instead of "NUL" device
echo.
echo  These files CANNOT be deleted normally because Windows interprets
echo  them as device names, not filenames.
echo.
echo  SOLUTION: Use the \\?\ prefix to bypass the device name check.
echo ============================================================
echo.

set /p userpath="Enter path to scan (default: %USERPROFILE%): "
if "%userpath%"=="" set userpath=%USERPROFILE%

echo.
echo Scanning: %userpath%
echo This may take a while depending on the number of files...
echo.

set count=0

echo Searching for NUL files...
for /r "%userpath%" %%i in (nul) do (
    if exist "\\?\%%i" (
        echo [FOUND] %%i
        del "\\?\%%i" 2>nul
        if not exist "\\?\%%i" (
            echo [DELETED] %%i
            set /a count+=1
        ) else (
            echo [FAILED] %%i - May require administrator privileges
        )
    )
)

echo.
echo Searching for CON files...
for /r "%userpath%" %%i in (con) do (
    if exist "\\?\%%i" (
        echo [FOUND] %%i
        del "\\?\%%i" 2>nul
        if not exist "\\?\%%i" (
            echo [DELETED] %%i
            set /a count+=1
        )
    )
)

echo.
echo Searching for PRN files...
for /r "%userpath%" %%i in (prn) do (
    if exist "\\?\%%i" (
        echo [FOUND] %%i
        del "\\?\%%i" 2>nul
        if not exist "\\?\%%i" (
            echo [DELETED] %%i
            set /a count+=1
        )
    )
)

echo.
echo Searching for AUX files...
for /r "%userpath%" %%i in (aux) do (
    if exist "\\?\%%i" (
        echo [FOUND] %%i
        del "\\?\%%i" 2>nul
        if not exist "\\?\%%i" (
            echo [DELETED] %%i
            set /a count+=1
        )
    )
)

echo.
echo ============================================================
echo  COMPLETED!
echo  Total files cleaned: %count%
echo ============================================================
echo.
echo If some files failed to delete, try running as Administrator.
echo Right-click the batch file and select "Run as administrator"
echo.
pause
