# Flutter App Testing on Android Phone

## Step 1: Enable Developer Options on Your Android Phone

1. Go to **Settings** > **About Phone**
2. Find **Build Number** and tap it 7 times continuously
3. You'll see a message "You are now a developer!"
4. Go back to Settings and you'll find **Developer Options**

## Step 2: Enable USB Debugging

1. In **Developer Options**, enable **USB Debugging**
2. Also enable **Install via USB** (if available)
3. Enable **Stay awake** (optional, keeps screen on during development)

## Step 3: Install Android USB Drivers (Windows)

1. Download and install [Google USB Driver](https://developer.android.com/studio/run/win-usb)
2. Or use [Universal ADB Driver](https://adb.clockworkmod.com/)

## Step 4: Connect Your Phone

1. Connect your Android phone to your computer via USB cable
2. On your phone, when prompted, select **File Transfer** or **MTP** mode
3. You may see a prompt to "Allow USB debugging?" - check "Always allow" and tap OK

## Step 5: Verify Connection

Run these commands to check if your device is detected:

```bash
flutter devices
```

If your device appears, you're ready to go!

## Step 6: Run Your App on Android Phone

```bash
flutter run
```

Or specify the Android device:

```bash
flutter run -d android
```

## Troubleshooting

### If device is not detected:

1. **Check USB cable**: Use the original cable that came with your phone
2. **Try different USB ports**: Some USB 3.0 ports may have issues
3. **Restart ADB server**:
   ```bash
   adb kill-server
   adb start-server
   ```
4. **Check device manager**: Look for any unrecognized devices
5. **Update drivers**: Right-click unrecognized device > Update driver > Browse > Let me pick > Android Device > Android ADB Interface

### If you get permission errors:

1. **On Linux/Mac**: You may need to configure udev rules
2. **On Windows**: Run command prompt as Administrator

## Alternative: Create Android Emulator

If you prefer using an emulator:

```bash
flutter emulators --launch <emulator_id>
```

To list available emulators:
```bash
flutter emulators
```

## Building APK for Manual Installation

If you want to install the app manually:

```bash
flutter build apk
```

The APK will be generated at: `build/app/outputs/flutter-apk/app-release.apk`

## Additional Tips

- Keep your phone charged during development
- Use a high-quality USB cable
- Some phones may require enabling "OEM unlocking" in Developer Options
- For Huawei devices, you may need to install HiSuite
- For Xiaomi devices, enable "USB Debugging (Security Settings)"

## Testing Your Current App

Once your device is connected, simply run:

```bash
flutter run
```

Your macrobenthos_counter app will be installed and launched on your Android phone!
