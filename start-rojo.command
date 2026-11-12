#!/bin/bash
cd "$(dirname "$0")" || exit 1
if ! command -v rojo >/dev/null 2>&1; then
  echo "Rojo bulunamadi. Once Rojo'yu kur: https://rojo.space"
  read -n 1 -s -r -p "Kapatmak icin bir tusa bas"
  exit 1
fi
echo "Rojo baslatiliyor... Bu pencereyi kapatma. Studio'da Rojo eklentisinden Connect'e bas."
rojo serve roblox/default.project.json
