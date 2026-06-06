
## Cihazda çalıştırma
```bash
xcodebuild -project EduKidGames.xcodeproj -scheme EduKidGames \
  -destination 'id=<DEVICE_UDID>' -configuration Debug \
  DEVELOPMENT_TEAM=<APPLE_TEAM_ID> CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates build
xcrun devicectl device install app --device <DEVICE_UDID> \
  ~/Library/Developer/Xcode/DerivedData/EduKidGames-*/Build/Products/Debug-iphoneos/EduKidGames.app
```
