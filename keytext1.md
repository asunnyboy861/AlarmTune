# App Store Metadata

## Subtitle
Independent Volume Alarms

## Promotional Text
Set a different volume for each alarm. Your morning alarm can be loud while your afternoon reminder stays gentle. Auto-boosts system volume and warns if too low.

## Description
Wake up on your terms with AlarmTune -- the alarm clock that gives you independent volume control for every alarm.

Most alarm apps tie your alarm volume to your system ringer volume. That means if you turned down your music before bed, your morning alarm might not wake you up. AlarmTune solves this by letting you set a custom volume level for each alarm individually -- and now automatically ensures your alarm is always audible.

WHAT IS NEW

System Volume Boost
When your alarm fires, AlarmTune automatically raises your system volume to maximum so your chosen alarm volume plays at full strength. When the alarm stops, your original system volume is restored. No more missed alarms because you forgot to turn up your ringer.

System Volume Monitor
AlarmTune now monitors your system volume in real time. If your ringer is too low for your alarm to be audible, you will see a clear warning right in the alarm editor. Never set an alarm you cannot hear again.

Notification Fallback Sound
Even if AlarmTune is closed or force-quit by the system, your alarm notification now plays a system sound to make sure you wake up. This is a safety net that works even when the app is not running.

Improved Fade-In
The gradual fade-in feature now starts from a safe minimum volume instead of zero, so you hear your alarm from the very first second even at low volume settings.

KEY FEATURES

Independent Volume Control
Set a unique volume level for each alarm. Your 6 AM wake-up can blast at maximum volume while your noon reminder plays at a whisper. No other alarm app gives you this level of control.

Volume Presets
Choose from five carefully tuned presets: Whisper, Gentle, Moderate, Loud, and Maximum. Pick the right level in one tap, or fine-tune with the precision slider.

Gradual Fade-In
Start your morning gently. Fade-in gradually increases the alarm volume from a safe minimum to your chosen level over 1 to 30 seconds. Wake up naturally instead of being jolted awake.

Multiple Alarm Sounds
Select from a curated collection of alarm sounds designed to wake you up effectively. Preview each sound before committing to it.

Flexible Scheduling
Set one-time or repeating alarms for any day combination. Name your alarms, organize them by category, and manage them all from a clean, intuitive interface.

Snooze Control
Customize your snooze duration. Choose how long you want between snoozes and how many times you can hit the button.

Alarm Categories
Organize your alarms with categories like Work, Weekend, Important, Nap, and Medication. Each category has its own icon and color for quick visual identification.

Dark Mode First
Designed with your nighttime use in mind. The interface is easy on your eyes in any lighting condition, with a beautiful dark mode that looks right at home on your iPhone.

Theme Colors
Personalize AlarmTune with five beautiful theme colors: Ocean Blue, Sunrise Orange, Midnight, Rose Pink, and Fresh Mint. Choose the one that matches your style in Settings.

Works When It Matters
AlarmTune uses background audio playback and notification fallback sounds, so your alarms fire reliably even when your phone is on silent mode or the screen is locked.

WHO IS ALARMTUNE FOR?

- Heavy sleepers who need a loud alarm that cannot be accidentally muted
- Light sleepers who want a gentle wake-up without blasting their ears
- Shift workers who need different volume levels at different times
- Anyone who has ever missed an alarm because they forgot to turn up their phone volume
- Students who want a quiet reminder between classes and a loud alarm for morning

NO DATA COLLECTION
AlarmTune respects your privacy. We do not collect, store, or transmit any personal data. All your alarm settings stay on your device.

Download AlarmTune today and never worry about your alarm volume again.

## Keywords
gentle,wake,sleep,sound,morning,reminder,snooze,heavy,ringer,loud,bedtime,preset,whisper,theme

## What's New in This Version
- System Volume Boost: AlarmTune now automatically raises your system volume when an alarm fires, so your chosen volume level is always heard at full strength. Your original volume is restored when the alarm stops.
- System Volume Monitor: Get real-time warnings in the alarm editor if your system volume is too low for your alarm to be audible.
- Notification Fallback Sound: Alarms now play a system notification sound even if the app is closed or force-quit, ensuring you never miss an alarm.
- Improved Fade-In: Gradual volume fade-in now starts from a safe minimum instead of zero, so you hear the alarm from the very first second.
- System volume status display in Settings for quick reference.
- Theme Colors: Choose from five beautiful accent colors to personalize AlarmTune.
- Reliability improvements and bug fixes.

## Review Notes
This update addresses customer feedback about alarms not being audible when system volume is low.

Key technical changes:
1. VolumeManager (new): Temporarily boosts system volume to 1.0 during alarm playback via MPVolumeView, restores original volume on stop. Uses iOS 15+ compatible UIWindowScene for volume view hosting.
2. VolumeMonitor (new): Uses KVO on AVAudioSession.outputVolume to monitor system volume changes and provide low-volume warnings in the alarm editor UI.
3. AlarmScheduler: Changed notification content.sound from nil to .default, ensuring a fallback system sound plays even when the app is terminated. In willPresent callback, removed .sound from completionHandler to avoid double playback when AVAudioPlayer is active.
4. AudioService: Integrated VolumeManager for automatic system volume boost/restore. Added safe minimum start volume for fade-in playback.
5. ThemeManager (new): Manages user-selected accent color theme with 5 options (Ocean Blue, Sunrise Orange, Midnight, Rose Pink, Fresh Mint). Uses UserDefaults for persistence and .tint() modifier on root view for global application. No new frameworks required.
6. No new frameworks or capabilities required beyond existing MediaPlayer and AVFoundation.

No HealthKit, no AI features, no subscriptions, no data collection.
