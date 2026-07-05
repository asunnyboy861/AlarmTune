# App Review Information — AlarmTune

## App Details
- **App Name**: AlarmTune
- **Bundle ID**: com.zzoutuo.AlarmTune
- **Version**: 1.1
- **Category**: Utilities

## Review Notes

### Core Functionality
AlarmTune is a volume-controlled alarm clock. Each alarm has its own independent volume level, so users can have a loud morning alarm and a gentle afternoon reminder.

### Subscription Details
- **Product IDs**:
  - `com.zzoutuo.AlarmTune.premium.monthly` ($2.99/month)
  - `com.zzoutuo.AlarmTune.premium.yearly` ($14.99/year)
- **Free Tier**: 1 custom sound import, 1 custom video import, 1 AI sound generation (shared quota)
- **Premium Tier**: Unlimited imports and AI sound generation
- **Restore Purchases**: Available in both Settings and Paywall views
- **Paywall Compliance**: Includes Privacy Policy link, Terms of Use link, auto-renewal disclosure with dynamic pricing from StoreKit Product, and cancellation instructions (Guideline 3.1.2)

### IAP Implementation (StoreKit 2)
- Uses `Transaction.currentEntitlement(for:)` for reliable entitlement checking
- `SubscriptionService` is an `@MainActor ObservableObject` singleton
- All views bind via `@ObservedObject` for reactive purchase state updates
- `Transaction.updates` listener processes pending transactions on launch
- Restore Purchases uses `AppStore.sync()` with success/failure feedback alerts

### Video Backgrounds
- 8 built-in CC0-licensed MP4 videos in 4 categories (Storm, Nature, City, Cozy)
- Videos are bundled in the app bundle, played via AVQueuePlayer with loop
- Audio Source selection: users choose between alarm sound or video's own audio
- Note: `AVPlayer.volume` is not functional on iOS — video volume is controlled via `VolumeManager.boostSystemVolume(to:)` during alarm firing

### AI Sound Generation
- Device-side procedural audio synthesis using AVAudioEngine
- Generates simple tones based on 4 style presets (Calm, Energetic, Nature, Retro)
- **No cloud API calls, no external AI services**
- The "AI" label refers to procedural generation, not a cloud-based AI service

### Apple Music Integration
- Uses MPMediaPickerController for song selection
- Checks `SKCloudServiceController.requestCapabilities` before allowing picker
- Shows alert if user lacks active Apple Music subscription

### Accessibility
- Full VoiceOver support: all icon-only buttons have accessibilityLabel/Hint
- Sliders have accessibilityLabel, accessibilityValue, accessibilityHint
- Alarm ringing screen has labels for time, label, volume
- Dynamic Type via @ScaledMetric-based DynamicFontModifier with capped scaling

### Reliability
- `UNNotificationDismissActionIdentifier` handling: auto-disables one-time alarms on swipe
- `AudioFallbackReason` enum: user-facing messages when alarm sounds are missing
- Core Data: `recoverFromStoreCorruption()` instead of `fatalError`
- `VolumeManager`: 3-attempt retry for MPVolumeView slider lookup

### China App Store Compliance
- This app does NOT include any third-party AI chatbot or large language model functionality
- No external AI provider brands are referenced in any user-facing UI or metadata
- AI Sound Generation is device-side procedural audio synthesis using AVAudioEngine
- The "AI" label refers to procedural generation, not a cloud-based AI service

### Privacy
- No data collection, no analytics, no third-party SDKs
- All user settings stay on-device
- No HealthKit integration
- API keys (if any) stored in Keychain, not UserDefaults

## Sandbox Testing
1. Create a sandbox test account in App Store Connect
2. Use the sandbox account to test monthly/yearly subscription purchase
3. Test Restore Purchases from both PaywallView and SettingsView
4. Verify premium features unlock immediately after purchase
5. Verify premium features lock after subscription expiry

## Policy Page URLs
- Privacy Policy: https://zzoutuo.github.io/AlarmTune/privacy.html
- Terms of Use: https://zzoutuo.github.io/AlarmTune/terms.html
- Support: https://zzoutuo.github.io/AlarmTune/support.html
