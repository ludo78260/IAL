@echo off
REM ===========================================================================
REM  IA Locale - Installation (double-clic)
REM ===========================================================================
title IA Locale - Installation
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALL.ps1" %*
pause
