@echo off

set "INSTALL_DIR=%LOCALAPPDATA%\Phronova"

echo.
echo Installing Phronova to:
echo %INSTALL_DIR%
echo.

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
xcopy "%~dp0.." "%INSTALL_DIR%" /E /I /Y /Q >nul

pause