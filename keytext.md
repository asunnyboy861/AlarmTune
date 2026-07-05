# App Store Metadata

## Subtitle
Loud Alarm with Volume Control

## Promotional Text
Set a different volume for each alarm. Your morning alarm can be loud while your afternoon reminder stays gentle. Now with video backgrounds, Apple Music, and AI sounds.

## Description
Wake up on your terms with AlarmTune -- the alarm clock that gives you independent volume control for every alarm, plus video backgrounds, Apple Music, and AI-generated sounds.

Most alarm apps tie your alarm volume to your system ringer volume. If you turned down your music before bed, your morning alarm might not wake you up. AlarmTune solves this by letting you set a custom volume level for each alarm individually -- and automatically ensures your alarm is always audible.

KEY FEATURES

Independent Volume Control
Set a unique volume level for each alarm. Your 6 AM wake-up can blast at maximum volume while your noon reminder plays at a whisper.

Volume Presets
Choose from five carefully tuned presets: Whisper, Gentle, Moderate, Loud, and Maximum. Pick the right level in one tap, or fine-tune with the precision slider.

Gradual Fade-In
Fade-in gradually increases the alarm volume from a safe minimum to your chosen level over 1 to 30 seconds. Wake up naturally instead of being jolted awake.

Video Backgrounds
Watch a stunning video when your alarm rings. Choose from 8 cinematic backgrounds across 4 categories: Storm, Nature, City, and Cozy. Each video plays with its own audio track. Preview videos in full before selecting.

Apple Music Integration
Pick any song from your Apple Music library as your alarm sound. Wake up to your favorite track every morning.

Custom Sound Import
Import your own sound files from the Files app. Use any audio clip as your alarm.

AI Sound Generation
Create unique alarm sounds with AI. Choose from 4 styles and generate a fresh sound instantly.

Sound Shuffle
Automatically rotate your alarm sound daily or weekly from the built-in sound library. No more alarm fatigue.

30+ Alarm Sounds
Select from 30+ alarm sounds across 5 categories: Loud, Nature, Gentle, Classic, and Fun. Preview each sound before committing.

Flexible Scheduling
Set one-time or repeating alarms for any day combination. Name your alarms, organize them by category, and manage them from a clean interface. Ideal for bedtime routines.

Snooze Control
Customize your snooze duration and how many times you can hit the button.

Alarm Categories
Organize alarms with categories like Work, Weekend, Important, Nap, and Medication. Each has its own icon and color.

System Volume Boost
AlarmTune automatically raises your system volume to maximum when an alarm fires, ensuring your chosen volume plays at full strength. Your original volume is restored when the alarm stops.

Notification Fallback Sound
Even if AlarmTune is closed or force-quit, your alarm notification plays a system sound to ensure you wake up.

Works When It Matters
Alarms fire reliably even when your phone is on silent mode or the screen is locked, thanks to background audio playback and notification fallback sounds.

Full Accessibility
AlarmTune supports VoiceOver with clearly labeled controls throughout the app. Dynamic Type lets you adjust text sizes to your preference.

WHO IS ALARMTUNE FOR?

- Heavy sleepers who need a loud alarm that cannot be accidentally muted
- Light sleepers who want a gentle wake-up
- Shift workers who need different volume levels at different times
- Anyone who has ever missed an alarm because they forgot to turn up their phone volume

NO DATA COLLECTION
AlarmTune respects your privacy. We do not collect, store, or transmit any personal data. All your alarm settings stay on your device.

SUBSCRIPTION INFORMATION:
- Payment will be charged to your Apple ID account at confirmation of purchase.
- Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period.
- You can manage and cancel your subscriptions by going to your account settings on the App Store after purchase.
- Any unused portion of a free trial period, if offered, will be forfeited when the user purchases a subscription.

Download AlarmTune today and never worry about your alarm volume again.

## Keywords
wake,sleep,sound,morning,reminder,snooze,bedtime,whisper,gentle,fade,video,music,ringer,preset,heavy

## What's New in This Version
- Video Backgrounds: Watch 8 cinematic videos when your alarm rings, across 4 categories (Storm, Nature, City, Cozy). Preview videos inline before selecting.
- Video Alarm Mode: Selecting a video automatically uses its audio track. Alarm cards show "Video" badge to clearly indicate the alarm type.
- Apple Music Integration: Wake up to any song from your Apple Music library.
- Custom Sound Import: Import your own audio files from the Files app as alarm sounds.
- AI Sound Generation: Generate unique alarm sounds with 4 styles -- Calm, Energetic, Nature, and Retro.
- Sound Shuffle: Automatically rotate your alarm sound daily or weekly to prevent alarm fatigue.
- Premium Subscription: Optional monthly or yearly subscription to unlock unlimited imports and AI sound generation.
- Custom Video Import: Import your own videos from Photos or Files as alarm backgrounds.
- Accessibility: Full VoiceOver support with labeled controls, and Dynamic Type for adjustable text sizes.
- Reliability: Improved alarm delivery with dismiss action handling, audio fallback protection, and crash recovery.

## Review Notes
This update adds video backgrounds, Apple Music integration, custom sound/video imports, AI sound generation, a premium subscription, and accessibility support.

Key technical details:
1. Video Backgrounds: 8 built-in CC0-licensed MP4 videos bundled in the app, organized into 4 categories (Storm, Nature, City, Cozy). Videos are stored in the app bundle and played via AVQueuePlayer with loop support. Inline video preview uses AVPlayerLayer-based InlineVideoPlayer component for reliable rendering in SwiftUI card views.
2. Video Alarm Mode: Selecting a video automatically sets the alarm to use the video's audio track (audioSource = videoSound). No manual selection needed -- video and sound are mutually exclusive alarm types (matches Alarmy competitor pattern). Alarm cards display "Video" badge (purple) or sound name (gray) to clearly indicate the alarm type. Default video volume is 55% (not 0%).
3. Apple Music Integration: Uses MPMediaPickerController to let users select songs from their Apple Music library. Songs are referenced by persistent ID and played via MPMusicPlayerApplicationController.
4. Custom Sound Import: Uses UIDocumentPickerViewController to import audio files from the Files app. Files are copied to the app's Documents directory and referenced by filename.
5. Custom Video Import: Uses PhotosPicker for Photo library and UIDocumentPickerViewController for Files. Videos are trimmed via VideoTrimmerView before import.
6. AI Sound Generation: Device-side audio synthesis using AVAudioEngine. Generates simple tones based on 4 style presets (Calm, Energetic, Nature, Retro). No cloud API calls, no external AI services. The "AI" label refers to procedural generation of alarm tones. This is NOT a third-party AI chatbot integration and does not use any external AI provider brand.
7. Sound Shuffle: Automatically rotates built-in alarm sounds daily or weekly using UserDefaults to track the last change date. Each alarm has its own shuffle state to prevent cross-alarm interference.
8. Subscription: StoreKit 2 implementation with two auto-renewable subscription products.
   - Product ID: com.zzoutuo.AlarmTune.premium.monthly ($2.99/month)
   - Product ID: com.zzoutuo.AlarmTune.premium.yearly ($14.99/year)
   - Free tier: 1 custom sound import, 1 custom video import, 1 AI sound generation (shared quota)
   - Premium tier: Unlimited imports and AI sound generation
   - Restore Purchases available in Settings and Paywall
   - PaywallView includes Privacy Policy and Terms of Use links below the Subscribe button
   - Auto-renewal disclosure with dynamic pricing from StoreKit Product, and cancellation instructions
9. Accessibility: Full VoiceOver support -- all icon-only buttons have accessibilityLabel/Hint, sliders have accessibilityValue, alarm ringing screen has labels for time/label/volume. Dynamic Type via @ScaledMetric-based DynamicFontModifier with capped max scaling.
10. Reliability: UNNotificationDismissActionIdentifier handling auto-disables one-time alarms on swipe. AudioFallbackReason enum provides user-facing messages when sounds are missing. Core Data uses recoverFromStoreCorruption() instead of fatalError. VolumeManager uses 3-attempt retry for MPVolumeView slider.

China App Store Compliance:
- This app does NOT include any third-party AI chatbot or large language model functionality.
- No external AI provider brands are referenced in any user-facing UI or metadata.
- AI Sound Generation is device-side procedural audio synthesis using AVAudioEngine. No cloud-based AI service is used.
- The "AI" label in "AI Sound Generation" refers to procedural generation, not a cloud-based AI service.

No HealthKit integration. No data collection. All user settings stay on-device.