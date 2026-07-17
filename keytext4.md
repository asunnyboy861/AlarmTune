# App Store Metadata

## Subtitle
Reliable Alarm in Silent Mode

## Promotional Text
Set a different volume for each alarm. Reliable in silent mode, background, and even if the app is force-quit. Video backgrounds now work reliably when the app is killed.

## Description
Wake up on your terms with AlarmTune -- the alarm clock with independent volume control for every alarm, plus reliable alarm delivery even in silent mode.

Most alarm apps tie your alarm volume to your system ringer volume. If you turned down your music before bed, your morning alarm might not wake you up. AlarmTune solves this with independent volume per alarm and a three-layer reliability system that works when it matters most.

KEY FEATURES

Independent Volume Control
Set a unique volume level for each alarm. Your 6 AM wake-up can blast at maximum while your noon reminder plays at a whisper.

Three-Layer Silent Mode Reliability
Alarms fire reliably even when your phone is on silent mode or the screen is locked:
1. Background Audio Keeper -- pre-schedules audio so your alarm sounds in the background
2. System Volume Boost -- raises system volume when your alarm fires, restores it on stop
3. Critical Notification Fallback -- notification sound plays even if the app is force-quit

Force-Quit Protection
Your chosen alarm sound and volume are pre-rendered and saved on-device. If the app is force-quit or the system kills it in the background, the notification still plays your exact sound at your chosen volume -- not a generic system tone.

Background Alarm Guard
Toggle in Settings to keep alarms protected in the background. Reliability indicators show whether each alarm will ring in silent mode.

Volume Presets
Five presets: Whisper, Gentle, Moderate, Loud, Maximum. One-tap selection or fine-tune with the slider.

Gradual Fade-In
Increases alarm volume from a safe minimum to your chosen level over 1-30 seconds. Wake up naturally.

Video Backgrounds
8 cinematic videos across 4 categories (Storm, Nature, City, Cozy). Each plays with its own audio. Import custom videos from Photos or Files. Video alarms now work reliably even when the app is force-quit.

Apple Music Integration
Pick any song from your Apple Music library as your alarm sound.

Custom Sound Import
Import your own sound files from the Files app. Premium unlocks unlimited imports.

AI Sound Generation
Create unique alarm sounds with 4 AI styles. Premium unlocks unlimited generation.

Sound Shuffle
Auto-rotate alarm sounds daily or weekly. No more alarm fatigue.

30+ Alarm Sounds
Built-in sounds across 5 categories: Loud, Nature, Gentle, Classic, Fun.

Flexible Scheduling
One-time or repeating alarms. One-time alarms auto-disable after firing.

Snooze Control
Custom snooze duration. Snoozed alarms reschedule with background reliability.

Alarm Categories
Organize by Work, Weekend, Important, Nap, Medication with icons and colors.

Audio Fallback Protection
If your sound is unavailable, falls back to a default so you never miss an alarm.

Vibration Option
Enable vibration on any alarm for tactile wake-up. Vibrate works even with sound off for discreet alerts.

Accessibility
Full VoiceOver support with clearly labeled controls and Dynamic Type for adjustable text sizes.

Notification Permission
Requests permission on first alarm and guides you to Settings if denied.

WHO IS ALARMTUNE FOR?
- Heavy sleepers who need the loudest alarm that cannot be muted
- Light sleepers who want a gentle, progressive wake-up
- Shift workers who need different volumes at different times
- Anyone who has missed an alarm because their phone was on silent

NO DATA COLLECTION
We do not collect, store, or transmit any personal data.

SUBSCRIPTION INFORMATION:
- Payment will be charged to your Apple ID account at confirmation of purchase.
- Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period.
- You can manage and cancel your subscriptions by going to your account settings on the App Store after purchase.
- Any unused portion of a free trial period, if offered, will be forfeited when you purchase a subscription.

Download AlarmTune today and never worry about your alarm volume again.

## Keywords
loudest,heavy sleeper,wake,music,sound,gentle,progressive,nap,vibrate,ringer,preset,video,shuffle

## What's New in This Version
- Video Alarm Reliability Fix: Video alarms now work reliably when the app is force-quit. The alarm triggers on time, and when you open the app, the video alarm UI appears correctly with video audio playing.
- Fixed issue where video alarms would play bridge audio instead of video audio when the app was killed.
- Fixed race condition where app state was lost during cold launch, causing video alarms to be incorrectly stopped.
- Improved persistence of videoSound mode state across app restarts using UserDefaults.
- Stop/Snooze actions now properly clean up video alarm state to prevent stale data.
- Performance and reliability improvements.

## Review Notes
This update fixes critical video alarm reliability issues when the app is force-quit.

Key technical details:
1. BackgroundAudioKeeper: Uses AVAudioPlayer.play(atTime:) to pre-schedule audio playback for background alarms. Keeps AudioSession active via UIBackgroundModes: audio.
2. System Volume Boost: VolumeManager.boostSystemVolume() uses MPVolumeView slider to raise system volume to 1.0 when alarms fire. For background alarms, a Timer scheduled 1 second before fire time triggers the boost. Volume restored via VolumeManager.restoreSystemVolume() on stop.
3. Critical Notification: All alarms use .defaultCritical with .timeSensitive as fallback. Without Critical Alert entitlement, system may degrade to standard sound, so BackgroundAudioKeeper is the primary mechanism.
4. Snooze Rescheduling: scheduleSnooze() now calls BackgroundAudioKeeper.scheduleBackgroundPlayback() for snooze background protection.
5. Background Alarm Guard: UserDefaults toggle (default: ON) in SettingsView. When disabled, BackgroundAudioKeeper skips scheduling.
6. Reliability Indicators: AlarmEditView shows badge (Reliable/Partial/At Risk) based on volume, sound source, and Background Alarm Guard status.
7. AppDelegate: Does not deactivate AudioSession when BackgroundAudioKeeper has active sessions.
8. Sound Pre-Rendering (R8): SoundPreRenderer renders the alarm sound with volume gain and fade-in to Library/Sounds/alarm_{id}.caf using AVAudioFile and AVAudioPCMBuffer. UNNotificationSound uses this pre-rendered file so the correct sound and volume play even if the app is force-quit. Apple Music sounds fall back to .defaultCritical (DRM prevents extraction). Files are created on alarm save/update and deleted on alarm delete.
9. AlarmKit Integration (R7, iOS 26+): AlarmKitAdapter uses AlarmManager to schedule system-level alarms that bypass silent mode and Focus automatically. Only applies to built-in .caf sounds without video backgrounds. Apple Music, imported sounds, and video backgrounds fall back to the three-layer architecture (R1-R5) with pre-rendered sound (R8).
10. Video Alarm Persistence (NEW): registerVideoSoundAlarm() persists videoSound mode to UserDefaults at schedule time (not fire time). This ensures app can correctly identify video alarms even if cold-launched after AlarmKit triggers. handleAlarmDisappeared/Snoozed now use isVideoSoundAlarm() to check UserDefaults state instead of memory variable.

Subscription products: Monthly ($2.99/mo) and Yearly ($14.99/yr).
Product IDs: com.zzoutuo.AlarmTune.premium.monthly, com.zzoutuo.AlarmTune.premium.yearly
Paywall includes Privacy Policy and Terms of Use links. Auto-renewal disclosure with dynamic pricing. Restore Purchases available in Settings and Paywall.

China App Store Compliance:
- This app does NOT include any third-party AI chatbot or large language model functionality.
- No external AI provider brands referenced in user-facing UI or metadata.
- AI Sound Generation is device-side procedural audio synthesis using AVAudioEngine.

No HealthKit integration. No data collection. All user settings stay on-device.