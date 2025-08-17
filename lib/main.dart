name: Build Android APK (LITE, debug)

on:
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Java 17
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: Create Flutter structure
        run: |
          flutter --version
          flutter create .

      - name: Install deps
        run: flutter pub get

      - name: Build APK (debug)
        run: flutter build apk --debug

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: apk-debug
          path: build/app/outputs/flutter-apk/app-debug.apk
