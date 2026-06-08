
## Cihazda çalıştırma

Uygulama **canlı** web’e bağlanır: `https://edukidgames.com/Account/Login?shell=webview`

```bash
xcodebuild -project EduKidGames.xcodeproj -scheme EduKidGames \
  -destination 'id=<DEVICE_UDID>' -configuration Debug \
  DEVELOPMENT_TEAM=ZDR75MUR47 CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates build
xcrun devicectl device install app --device <DEVICE_UDID> \
  ~/Library/Developer/Xcode/DerivedData/EduKidGames-*/Build/Products/Debug-iphoneos/EduKidGames.app
xcrun devicectl device process launch --device <DEVICE_UDID> com.edukidgames.app
```

Oturum çıkış yapılana kadar kalıcıdır; yalnızca `/Account/Logout` sonrası native cookie deposu temizlenir.
