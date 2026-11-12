@echo off
cd /d "%~dp0"
where rojo >nul 2>nul
if errorlevel 1 (
  echo Rojo bulunamadi. Once Rojo'yu kur: https://rojo.space
  pause
  exit /b 1
)
echo Rojo baslatiliyor... Bu pencereyi kapatma. Studio'da Rojo eklentisinden Connect'e bas.
rojo serve roblox/default.project.json
pause
