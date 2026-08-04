#!/usr/bin/env bash

set -e

echo "Creating Flutter platform files..."
flutter create . --org com.example --project-name sonic_wave --platforms=android,web

echo "Installing dependencies..."
flutter pub get

echo "Generating code..."
flutter pub run build_runner build --delete-conflicting-outputs

echo "Done."
