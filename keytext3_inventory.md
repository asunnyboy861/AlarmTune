# keytext Inventory -- Code-to-Metadata Audit Trail

## App Info
- **App Name (Title)**: AlarmTune
- **keytext File**: keytext3.md
- **Generated**: 2026-07-11
- **Codebase Path**: /Volumes/ORICO-APFS/app/20260407/AlarmTune/AlarmTune/AlarmTune

## Feature Verification Table

| Feature Name | Code Evidence (file + line/class) | Status | Monetization | keytext Description |
|--------------|-----------------------------------|--------|--------------|---------------------|
| Independent Volume Control | AudioService.swift playAlarm() + VolumeSliderView.swift | IMPLEMENTED | free | "Set a unique volume level for each alarm" |
| Three-Layer Silent Mode Reliability | BackgroundAudioKeeper.swift + VolumeManager.swift + AlarmScheduler.swift (.defaultCritical) | IMPLEMENTED | free | "Three-layer reliability system that works when it matters most" |
| Background Audio Keeper | BackgroundAudioKeeper.swift scheduleBackgroundPlayback() | IMPLEMENTED | free | "Pre-schedules audio playback so your alarm sounds even in the background" |
| System Volume Boost | VolumeManager.swift boostSystemVolume() + BackgroundAudioKeeper.swift scheduleVolumeBoost() | IMPLEMENTED | free | "Automatically raises system volume when your alarm fires, then restores it" |
| Critical Notification Fallback | AlarmScheduler.swift createNotificationContent() .defaultCritical + .timeSensitive | IMPLEMENTED | free | "A system notification sound plays even if the app is force-quit" |
| Background Alarm Guard Toggle | SettingsView.swift line 63-78 + Constants.swift backgroundKeepAliveKey | IMPLEMENTED | free | "Enable this toggle in Settings to keep your alarms protected in the background" |
| Reliability Indicators | AlarmEditView.swift line 173-423 + VolumeMonitor.swift reliabilityLevel() | IMPLEMENTED | free | "A reliability indicator on each alarm shows whether it will ring in silent mode" |
| Volume Presets | AlarmItem+Extensions.swift VolumePreset enum (5 presets) | IMPLEMENTED | free | "Choose from five carefully tuned presets" |
| Gradual Fade-In | AudioService.swift playLocalSound() fadeIn branch + Constants.swift fadeInMinStartVolume | IMPLEMENTED | free | "Fade-in gradually increases the alarm volume from a safe minimum to your chosen level" |
| Video Backgrounds | VideoBackgroundView.swift + VideoBackgroundPickerView.swift (8 videos, 4 categories) | IMPLEMENTED | free | "Watch a stunning video when your alarm rings. 8 cinematic backgrounds across 4 categories" |
| Apple Music Integration | SoundPickerView.swift MPMediaPickerController + AudioService.swift playAppleMusicSound() | IMPLEMENTED | free | "Pick any song from your Apple Music library as your alarm sound" |
| Custom Sound Import | SoundImportService.swift + SoundPickerView.swift import section | IMPLEMENTED | pro (1 free, unlimited pro) | "Import your own sound files from the Files app" |
| AI Sound Generation | AIAlarmGeneratorView.swift + AIGenerationService.swift (AVAudioEngine) | IMPLEMENTED | pro (1 free, unlimited pro) | "Create unique alarm sounds with AI. Choose from 4 styles" |
| Sound Shuffle | AlarmScheduler.swift resolveShuffledSound() + Constants.swift ShuffleMode | IMPLEMENTED | free | "Automatically rotate your alarm sound daily or weekly" |
| 30+ Alarm Sounds | Constants.swift Sound.builtInSounds (5 categories) | IMPLEMENTED | free | "Select from 30+ alarm sounds across 5 categories" |
| Flexible Scheduling | AlarmScheduler.swift scheduleOneTimeAlarm/scheduleRepeatingAlarm | IMPLEMENTED | free | "Set one-time or repeating alarms for any day combination" |
| Snooze Control | AlarmRingView.swift snooze button + AlarmScheduler.swift scheduleSnooze + BackgroundAudioKeeper reschedule | IMPLEMENTED | free | "Customize your snooze duration. Snoozed alarms rescheduled with full background reliability" |
| Alarm Categories | AlarmListView.swift groupedAlarms (Work/Weekend/Important/Nap/Medication/Other) | IMPLEMENTED | free | "Organize alarms with categories like Work, Weekend, Important, Nap, and Medication" |
| Full Accessibility (VoiceOver, Dynamic Type) | AlarmRingView.swift accessibilityLabel + DynamicFont DynamicType | IMPLEMENTED | free | "Full VoiceOver support with clearly labeled controls and Dynamic Type for adjustable text sizes" |
| One-Time Alarm Auto-Disable | AlarmViewModel.swift stopRingingAlarm() + AlarmScheduler.swift handleStopAction() | IMPLEMENTED | free | "One-time alarms auto-disable after firing" |
| Notification Permission (guides to Settings if denied) | AlarmListView.swift requestNotificationPermissionIfNeeded() + notification denied alert | IMPLEMENTED | free | "Requests permission on first alarm and guides you to Settings if denied" |
| Custom Video Import (from Photos or Files) | VideoImportService.swift + VideoBackgroundPickerView.swift import section | IMPLEMENTED | pro (1 free, unlimited pro) | "Import custom videos from Photos or Files" |
| Subscription Management (Paywall, Premium, Restore) | SubscriptionService.swift + PaywallView.swift + PremiumLockView.swift | IMPLEMENTED | pro | "Premium unlocks unlimited imports and generation" + SUBSCRIPTION INFORMATION section |
| Audio Fallback Protection | AudioService.swift playLocalSound() fallback to default + AudioFallbackReason enum | IMPLEMENTED | free | "If your sound is unavailable, falls back to a default so you never miss an alarm" |
| Vibration Option | AlarmItem isVibrate + AlarmScheduler vibrate + AudioServicesPlaySystemSound | IMPLEMENTED | free | "Enable vibration on any alarm for tactile wake-up, even with sound off" |
| Loudest Volume Preset | VolumePresets Maximum + VolumeSliderView | IMPLEMENTED | free | "Heavy sleepers who need the loudest alarm that cannot be muted" |
| Heavy Sleeper Target Audience | AlarmListView.swift + VolumeSliderView.swift | IMPLEMENTED | free | "Heavy sleepers who need the loudest alarm that cannot be muted" |
| Wake Up Experience | AudioService.swift + FadeIn | IMPLEMENTED | free | "Light sleepers who want a gentle, progressive wake-up" |
| Gentle Volume Preset | VolumePresets Gentle | IMPLEMENTED | free | "Five presets: Whisper, Gentle, Moderate, Loud, Maximum" |
| Progressive Fade-In | AudioService.swift playLocalSound() fadeIn branch | IMPLEMENTED | free | "Light sleepers who want a gentle, progressive wake-up" + "Increases alarm volume from a safe minimum" |
| Nap Alarm Category | AlarmItem category=Nap | IMPLEMENTED | free | "Organize by Work, Weekend, Important, Nap, Medication" |
| Vibrate Alarm | AlarmItem isVibrate + AudioServicesPlaySystemSound | IMPLEMENTED | free | "Enable vibration on any alarm for tactile wake-up" |
| Ringer Volume Independence | VolumeManager.swift + AudioService.swift .playback category | IMPLEMENTED | free | "Most alarm apps tie your alarm volume to your system ringer volume" |
| Volume Preset Quick Selection | VolumePresets + VolumeSliderView | IMPLEMENTED | free | "Five presets: Whisper, Gentle, Moderate, Loud, Maximum" |
| Video Backgrounds and Import | VideoBackgroundView.swift + VideoImportService.swift | IMPLEMENTED | free/pro | "8 cinematic videos across 4 categories. Import custom videos from Photos or Files" |
| Sound Shuffle Mode | AlarmScheduler.swift resolveShuffledSound() | IMPLEMENTED | free | "Auto-rotate alarm sounds daily or weekly" |
| Force-Quit Protection (Pre-Rendered Sound) | SoundPreRenderer.swift render() + AlarmScheduler.swift createNotificationContent() | IMPLEMENTED | free | "Your chosen alarm sound and volume are pre-rendered and saved on-device. If the app is force-quit, the notification still plays your exact sound at your chosen volume" |
| AlarmKit System-Level Alarm (iOS 26+) | AlarmKitAdapter.swift scheduleAlarm() + AlarmScheduler.swift dual-safeguard | IMPLEMENTED | free | Dual-safeguard: AlarmKit + UNNotification scheduled simultaneously for iOS 26+ |

**Status Rules Used**:
- IMPLEMENTED -> included in Description/Promotional Text/What's New
- NOT IMPLEMENTED -> never mentioned
- PARTIAL -> mentioned only if user will have it working at launch without manual config

## Document-Code Conflict Resolution

| # | Conflicting Document Claim | Actual Code Evidence | Resolution | Impact on keytext.md |
|---|---------------------------|----------------------|------------|----------------------|
| 1 | us.md says "One-time purchase $2.99" pricing model | price.md says subscription ($2.99/mo, $14.99/yr); SubscriptionService.swift implements StoreKit 2 subscriptions | Code wins: subscription model | Subscription info included in Description, not one-time purchase |
| 2 | us.md mentions "Smart snooze (progressive delay: 5, 10, 15 min)" | AlarmItem has single snoozeDuration field; no progressive delay logic found | Code wins: simple snooze duration only | Described as "Customize your snooze duration", not progressive delay |
| 3 | us.md mentions "Shake to snooze gesture" | No motion/shake detection code found in AlarmRingView or elsewhere | Code wins: no shake to snooze | Not mentioned in keytext |

## ASO Keyword Evidence

| Keyword | Source | Traffic | Difficulty | ROI | Placement | Rationale |
|---------|--------|---------|------------|-----|-----------|-----------|
| alarm clock | aso-mcp search_keywords | 9.1 | 9.4 | 0.97 | Title (AlarmTune contains "Alarm") | Category core word |
| reliable | aso-mcp search_keywords "reliable alarm" | 9.1 | 9.1 | 1.00 | Subtitle | Highest ROI for core differentiator |
| silent | aso-mcp search_keywords "alarm silent mode" | 7.7 | 9.3 | 0.83 | Subtitle + Keywords | Key differentiator: silent mode reliability |
| volume | aso-mcp keyword_gap | 9.3 | 9.8 | 0.95 | Title ("Tune" implies) | Core feature, gap keyword |
| loudest | aso-mcp keyword_gap | 8.1 | 7.6 | 1.07 | Keywords | Gap keyword, only 1 competitor targets |
| heavy sleeper | aso-mcp search_keywords "heavy sleeper alarm" | 9.1 | 9.4 | 0.97 | Keywords | Target audience segment |
| wake | aso-mcp search_keywords "wake up alarm" | 9.1 | 9.5 | 0.96 | Keywords | High-traffic scene word |
| music | aso-mcp search_keywords "music alarm clock" | 7.9 | 9.4 | 0.84 | Keywords | Apple Music feature |
| sound | aso-mcp search_keywords "alarm sound" | 9.2 | 9.7 | 0.95 | Keywords | Core feature word |
| headphone | aso-mcp search_keywords "headphone alarm" | 7.0 | 9.0 | 0.78 | Keywords | Niche gap keyword |
| gentle | aso-mcp search_keywords (from Description) | N/A | N/A | N/A | Keywords | Volume preset name |
| progressive | aso-mcp search_keywords "progressive alarm" | 7.8 | 9.0 | 0.87 | Keywords | Fade-in feature association |
| smart | aso-mcp search_keywords "smart alarm clock" | 8.1 | 9.4 | 0.86 | Keywords | Category scene word |
| nap | aso-mcp search_keywords "nap alarm" | 9.0 | 9.4 | 0.96 | Keywords | Use-case word |
| vibrate | aso-mcp search_keywords "vibrate alarm" | 6.8 | 9.2 | 0.74 | Keywords | Feature word |
| ringer | Derived from user reviews | N/A | N/A | N/A | Keywords | Pain point word (ringer volume) |
| preset | Derived from feature | N/A | N/A | N/A | Keywords | Feature word (volume presets) |

## Keyword-to-Feature Mapping

| Keyword | Maps to Feature | Relevance |
|---------|-----------------|-----------|
| reliable | Three-Layer Silent Mode Reliability | RELEVANT |
| silent | Silent Mode Reliability + Background Alarm Guard | RELEVANT |
| loudest | Volume Presets (Maximum) + WHO section ("loudest alarm") | RELEVANT |
| heavy sleeper | WHO section target audience | TANGENTIAL |
| wake | WHO section + Promotional Text ("wake up") | RELEVANT |
| music | Apple Music Integration | RELEVANT |
| sound | 30+ Alarm Sounds + Sound Import + Sound Shuffle | RELEVANT |
| gentle | Volume Presets (Gentle) + WHO section | RELEVANT |
| progressive | WHO section ("progressive wake-up") + Gradual Fade-In | RELEVANT |
| nap | Alarm Categories (Nap) | RELEVANT |
| vibrate | Vibration Option feature | RELEVANT |
| ringer | Description ("system ringer volume") | TANGENTIAL |
| preset | Volume Presets | RELEVANT |
| video | Video Backgrounds + Custom Video Import | RELEVANT |
| shuffle | Sound Shuffle | RELEVANT |

## Validation History

| Run | Date | Script Result | Issues Fixed |
|-----|------|---------------|--------------|
| 1 | 2026-07-11 | FAIL (5 issues) | Subtitle 32/30, Promotional 186/170, Description 4012/4000, Keywords 115/100, keyword dedup |
| 2 | 2026-07-11 | FAIL (4 issues) | Description 4070/4000, Keywords 107/100, keyword relevance, inventory consistency |
| 3 | 2026-07-11 | FAIL (4 issues) | Description 4233/4000, Keywords 107/100, keyword relevance, inventory consistency |
| 4 | 2026-07-11 | FAIL (2 issues) | 'vibrate' keyword relevance, 'Full Accessibility' inventory consistency |
| 5 | 2026-07-11 | FAIL (2 issues) | 'vibrate' not in Description (used 'vibration'), inventory mismatch |
| 6 | 2026-07-11 | PASS | Added Accessibility section to Description, updated inventory description |
