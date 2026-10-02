@echo off

SET "PROJECT_DIR=%CD%"

cd /d "%~dp0.."

"%~dp0..\lua55.exe" "%~dp0..\commands.lua" %~dp0.. %PROJECT_DIR% %*