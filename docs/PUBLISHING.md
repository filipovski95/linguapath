# Publishing LinguaPath on Google Play

Everything in the app is ready for Play except the parts only you can do: the developer account, your signing key, and the forms in Play Console. This is the order to do them in.

## 1. Create a Google Play developer account (you)

- Go to https://play.google.com/console/signup and sign in with the Google account that should own the app.
- Choose **Personal** (just you) or **Organization** (needs a company and a D-U-N-S number). Personal is the quick path.
- Pay the one-time **US$25** registration fee.
- Complete **identity verification** (government ID, and a phone number/address check). This can take a few days.

**Important for new personal accounts:** before the app can go public, Google requires a **closed test with at least 12 testers who stay opted in for 14 days in a row**. Line up 12+ friends or family with Android phones early (they just need a Gmail address). After the 14 days you click "Apply for production" in Play Console.

## 2. Install the tools to build the app (you, once)

1. Install **Android Studio** (https://developer.android.com/studio). It installs the Android SDK.
2. Install **Flutter** (https://docs.flutter.dev/get-started/install/windows/mobile) and run `flutter doctor` until the Android items are green (`flutter doctor --android-licenses` accepts the licenses).
3. Copy the `language-app` folder to your computer, open a terminal in it and run:
   ```
   flutter pub get
   flutter test
   flutter run
   ```
   with your phone plugged in (USB debugging on) to try it.

*No-install alternative:* put the folder in a GitHub repository. The included workflow (`.github/workflows/build.yml`) tests and builds the app on every push; download `app-release.aab` from the run's artifacts.

## 3. Create your upload key (you, once — keep it safe!)

This key proves future updates come from you. If you lose it you need Google support to reset it, so back it up (password manager + a second drive).

```
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

(`keytool` ships with Android Studio: `"C:\Program Files\Android\Android Studio\jbr\bin\keytool"` on Windows.)

Move `upload-keystore.jks` into `android/app/`, then create `android/key.properties`:

```
storePassword=<the password you chose>
keyPassword=<the password you chose>
keyAlias=upload
storeFile=upload-keystore.jks
```

Both files are in `.gitignore`; never commit or share them. The build already reads `key.properties` (see `android/app/build.gradle.kts`).

If you use the GitHub build instead, add repository secrets `KEYSTORE_BASE64` (output of `base64 upload-keystore.jks`), `KEYSTORE_PASSWORD`, `KEY_ALIAS` and `KEY_PASSWORD`.

## 4. Build the release bundle

```
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`. Google Play only accepts `.aab` bundles for new apps. Before each new upload, raise the version in `pubspec.yaml` (`version: 0.1.0+1` → `0.1.1+2`; the number after `+` must always go up).

Already set in the project:
- App id `com.ruflo.linguapath` (**permanent once uploaded** — change it in `android/app/build.gradle.kts` now if you want a different one).
- Target Android 16 (API 36), minimum Android 7 (API 24), which meets Play's current target-API rule.
- App name "LinguaPath", launcher icon, no internet or other sensitive permissions.

## 5. Create the app in Play Console

**Create app** → name *LinguaPath*, default language English (US), **App**, **Free**, accept the declarations.

Then finish every item under **Dashboard → Set up your app**:

| Item | What to enter |
|---|---|
| Privacy policy | https://filipovski95.github.io/linguapath/privacy.html (published from `web/privacy.html` with the web build). |
| App access | All functionality is available without special access. |
| Ads | No, the app does not contain ads. |
| Content rating | Fill in the questionnaire: category *Reference, News, or Educational*; answer No to violence, sexual content, gambling, user interaction, etc. Expect *Everyone / PEGI 3*. |
| Target audience | Recommended: **13 and older** for the first release. Selecting under-13 brings in the Families policy and extra review; can be added later. |
| News app | No. |
| Data safety | **No data collected, no data shared.** Progress stays on the device; the app has no network access. |
| Government app / Financial features / Health | No / None / None. |
| App category | Education. Contact email: your email. |

**Store listing** (Grow → Store presence → Main store listing): copy the English texts from `store/listings/en-US.md`, then add translations (Store presence → Translations → Add your own) from the other files in `store/listings/`, and upload from `store/`:
- App icon: `play-icon-512.png` (512×512)
- Feature graphic: `feature-graphic-1024x500.png`
- Phone screenshots: the files in `store/screenshots/` (1080×1920, need 2–8)

## 6. Testing tracks → production

1. **Internal testing** (optional, instant): Testing → Internal testing → create release → upload the `.aab`. Add your own email to try it from the Play Store.
2. **Closed testing** (required for new personal accounts): create a track, add the 12+ testers' emails (or a Google Group), upload the same `.aab`, send them the opt-in link. Keep them opted in **14 days**.
3. **Apply for production** on the Dashboard, answer the short questions about your test. Once approved: Production → create release → upload → choose countries → **Send for review**. First reviews usually take a few days.

Play App Signing is turned on automatically: Google holds the final app-signing key, you keep only the upload key.

## Checklist of what's needed from you

- [ ] Play developer account + $25 + ID verification
- [ ] 12 testers with Android phones for the 14-day closed test
- [ ] Upload key created and backed up
- [ ] Final decision on app name and app id (`com.ruflo.linguapath`)
- [x] A public URL for the privacy policy (https://filipovski95.github.io/linguapath/privacy.html)
- [ ] Contact email for the store listing
