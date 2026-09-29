@echo off
REM ===========================================================================
REM  IA Locale - Verification complete (double-clic)
REM ===========================================================================
title IA Locale - Verification
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0TEST.ps1" %*
pause
