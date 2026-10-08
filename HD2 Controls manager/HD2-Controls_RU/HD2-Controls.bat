@echo off
chcp 65001 >nul
title HD2 Controls Manager
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0HD2-Controls.ps1"
pause
