#!/bin/bash
# Build APK con JAVA_HOME impostato al JDK di Android Studio (evita errori di lock Gradle).
# Esegui da terminale: ./build_apk.sh   oppure   bash build_apk.sh

export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
cd "$(dirname "$0")"

if ! command -v flutter &>/dev/null; then
  echo "Flutter non è nel PATH. Aggiungi Flutter al PATH (es. in ~/.zshrc) e riprova."
  exit 1
fi

echo "JAVA_HOME=$JAVA_HOME"
# Ferma eventuali daemon Gradle per evitare lock su executionHistory
(cd android && ./gradlew --stop 2>/dev/null) || true
flutter build apk
