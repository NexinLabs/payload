flutter build apk --release --target-platform android-arm64; 
cd build/app/outputs/flutter-apk; 
adb install app-release.apk; 
cd -;