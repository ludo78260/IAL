@echo off
REM ===========================================================================
REM  IA Locale - Demarrage (double-clic)
REM ===========================================================================
title IA Locale - Demarrage
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0START.ps1" %*
if errorlevel 1 pause
