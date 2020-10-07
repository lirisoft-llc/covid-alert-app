[La version française suit.](#application-mobile-alerte-covid)

# COVID Alert Mobile App

This repository modifes the Canada COVID app to work with the APHL (give full form) server that is being rolled out in the US. It implements a React Native client application for Apple/Google's Exposure Notification framework.

![Lint + Typscript](https://github.com/cds-snc/covid-alert-app/workflows/CI/badge.svg)

*Available for iOS and Android:*

<a href="https://apps.apple.com/ca/app/id1520284227"><img src="https://www.canada.ca/content/dam/phac-aspc/images/services/diseases-maladies/coronavirus-disease-covid-19/covid-alert/app-store-eng.png" alt="Download on the App Store"></a>
<a href="https://play.google.com/store/apps/details?id=ca.gc.hcsc.canada.stopcovid"><img src="https://www.canada.ca/content/dam/phac-aspc/images/services/diseases-maladies/coronavirus-disease-covid-19/covid-alert/google-play-eng.png" alt="Get it on Google Play"></a>

*Pour iOS et Android:*

<a href="https://apps.apple.com/ca/app/id1520284227?l=fr"><img src="https://www.canada.ca/content/dam/phac-aspc/images/services/diseases-maladies/coronavirus-disease-covid-19/covid-alert/app-store-fra.png" alt="Télécharger dans l'App Store"></a>
<a href="https://play.google.com/store/apps/details?id=ca.gc.hcsc.canada.stopcovid&hl=fr"><img src="https://www.canada.ca/content/dam/phac-aspc/images/services/diseases-maladies/coronavirus-disease-covid-19/covid-alert/google-play-fra.png" alt="Disponible sur Google Play"></a>

- [Overview](#overview)
- [Local development](#local-development)
- [Customization](#customization)
- [Localization](#localization)

## Overview

This app is built using React Native and designed to work well with patterns on both Android and iOS devices.

## Customization

This app is modified to connect to the google [Exposure Notifications API](https://github.com/google/exposure-notifications-server). The primitive changes are done to connect to the exposure notification server, still exception, edges cases are yet to be done. It is compatible to work with [APHL Key server](https://static.googleusercontent.com/media/www.google.com/en//covid19/exposurenotifications/pdfs/Exposure-Notification-FAQ-v1.2.pdf). APHL will be granted only to public health authorities.

## Local development

### Prerequisites

Follow the steps outlined in [React Native Development Environment Setup](https://reactnative.dev/docs/environment-setup) to make sure you have the proper tools installed.

#### Node

- [Node 12 LTS](https://nodejs.org/en/download/)

#### iOS

- Xcode 11.5 or greater
- iOS device or simulator with iOS 13.5 or greater
- [Bundler](https://bundler.io/) to install the right version of CocoaPods locally
- You also need a provisioning profile with the Exposure Notification entitlement. For more information, visit https://developer.apple.com/documentation/exposurenotification.

#### Android

- Android device with the ability to run the latest version of Google Play Services or Google Play Services Beta. Sign up for beta program here https://developers.google.com/android/guides/beta-program.
- You also need a safelisted APPLICATION_ID that will be used to publish to Google Play. You could use APPLICATION_ID from [Google Sample App](https://github.com/google/exposure-notifications-android) for testing purposes `"com.google.android.apps.exposurenotification"`. Go to [Environment config](https://github.com/CovidShield/mobile#3-environment-config) to see how to change APPLICATION_ID.

#### 1. Check out the repository

```bash
git clone git@github.com:cds-snc/covid-shield-mobile.git
```

#### 2. Install dependencies

```bash
yarn install
```

##### 2.1 Additional step for iOS

###### 2.1.1 Install Cocoapods

```bash
sudo gem install cocoapods
```

###### 2.1.2 Install pods

```bash
bundle install && yarn pod-install
```

#### 3. Environment config

Check `.env` and adjust configuration if necessary. See [react-native-config](https://www.npmjs.com/package/react-native-config#different-environments) for more information.

Ex:

```bash
ENVFILE=.env.production yarn run-ios
ENVFILE=.env.production yarn run-android
```

#### 4. Start app in development mode

You can now launch the app using the following commands for both iOS and Android.

```bash
yarn run-ios
yarn run-android
```

You can also build the app with native development tool:

- For iOS, using Xcode by opening the `CovidShield.xcworkspace` file in the `ios` folder.
- For Android, using Android Studio by opening `android` folder.

### Development mode

When the app is running in development mode, you can tap on the COVID Alert logo at the top of the app to open the Test menu. This menu enables you to:

- Put the app into test mode to bypass the Exposure Notification API check
- Change the system status
- Change the exposure status
- Send a sample notification
- Reset the app to onboarding state

Note that: Test menu is enabled if the environment config file (`.env*`) has `TEST_MODE=true`. To disable test mode UI on production build, simply set it to false in the environment config file `TEST_MODE=false`.

#### iOS Local Development

Please add the following keys to the `info.plist` file. These keys should not be commited to the repo, and used only for local development.

```
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsLocalNetworking</key>
		<true/>
		<key>NSAllowsArbitraryLoads</key>
		<false/>
	</dict>
```

## Customization

You can customize the look and feel of the app largely by editing values found in the [Theme File](https://github.com/CovidShield/mobile/blob/master/src/shared/theme.ts). 

## Localization

The COVID Alert app is available in French and English. Fully localized content can be modified by editing translations files found in the [translations directory](https://github.com/cds-snc/covid-alert-app/tree/master/src/locale/translations). More translations can be added by using the same mechanism as French and English.

After modifying the content you must run the `generate-translations` command in order for the app to reflect your changes.

```bash
yarn generate-translations
```

### Add new translation

1. Create a new i18n file in [src/locale/translations/](./src/locale/translations/).
2. Add the new option `pt` in [translations.js](./translations.js).
3. Regenerate the translations `yarn generate-translations`.
4. Add the new option in [src/components/LanguageToggle.tsx](./src/components/LanguageToggle.tsx).
5. Add the new option in [src/screens/language/Language.tsx](./src/screens/language/Language.tsx).
6. Add the new option in Xcode `Localizations` settings (Project -> CovidShield -> Info tab -> Localizations) and make sure `Launch Screen.storyboard` is checked.

## Testing

- [Manual Testing Plan](./TEST_PLAN.md)
- [End to end testing with Detox](./e2e/DETOX_DOC.md)

## Who built COVID Alert?

COVID Alert was originally developed by [volunteers at Shopify](https://www.covidshield.app/). It was [released free of charge under a flexible open-source license](https://github.com/CovidShield/mobile).

This repository is being developed by the [Canadian Digital Service](https://digital.canada.ca/). We can be reached at <cds-snc@tbs-sct.gc.ca>.

## Troubleshooting

### [Android] Problem with debug.keystore during run Android version

Logs

```bash
FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':app:packageDebug'.
> A failure occurred while executing com.android.build.gradle.internal.tasks.Workers$ActionFacade
   > com.android.ide.common.signing.KeytoolException: Failed to read key AndroidDebugKey from store "/Users/YOUR_USER/.android/debug.keystore": keystore password was incorrect
```

Generate a new `debug.keystore`:

```bash
cd android/app
keytool -genkey -v -keystore debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000
```

Copy your debug.keystore to `~/.android/debug.keystore`:

```bash
cd android/app
cp debug.keystore ~/.android/debug.keystore
```

Now you can run `yarn run-android` in your root folder.

### [MacOS] Problem installing Cocoapods

When following step _2.1.1 Install Cocoapods_ if you receive an error that looks like the following (_Please Note:_ Error message will not be identical but simliar):

```bash
ERROR:  Loading command: install (LoadError)
  dlopen(/Users/$home/ruby/2.6.5/x86_64-darwin18/openssl.bundle, 9): Library not loaded: /usr/local/opt/openssl/lib/libssl.1.0.0.dylib
  Referenced from: /Users/$home/ruby/2.6.5/x86_64-darwin18/openssl.bundle
ERROR:  While executing gem ... (NoMethodError)
```

This is because the version of Ruby you have installed does not have OpenSSL included.

You can fix this error by installing Ruby Version Manager (if you do not already have it), and reinstalling the version of Ruby required with OpenSSL using the following steps:

1. Install RVM following the instructions here: https://rvm.io/
1. Run the following command to install the version of Ruby needed with OpenSSL included, this will take a few minutes so be patient.

```bash
rvm reinstall 2.6.5 --with-openssl-dir=/usr/local/opt/openssl
```

You should now be able to install cocoapods and gem commands should now work.

---
