# keytext Inventory — Code-to-Metadata Audit Trail

## App Info
- **App Name (Title)**: AlarmTune
- **keytext File**: keytext4.md
- **Generated**: 2026-07-17
- **Codebase Path**: /Volumes/ORICO-APFS/app/20260407/AlarmTune

## Feature Verification Table

| Feature Name | Code Evidence (file + line/class) | Status | Monetization | keytext Description |
|--------------|-----------------------------------|--------|--------------|---------------------|
| Independent Volume Control | `VolumeSliderView.swift` + `VolumeManager.swift` | IMPLEMENTED | free | Set a unique volume level for each alarm |
| Volume Presets | `Constants.swift` + `VolumeSliderView.swift` | IMPLEMENTED | free | Five presets: Whisper, Gentle, Moderate, Loud, Maximum. Loudest preset for heavy sleepers |
| Three-Layer Silent Mode Reliability | `BackgroundAudioKeeper.swift` + `VolumeManager.swift` + `AlarmScheduler.swift` | IMPLEMENTED | free | Alarms fire reliably in silent mode, background, and force-quit |
| Force-Quit Protection | `SoundPreRenderer.swift` + `AlarmKitAdapter.swift` | IMPLEMENTED | free | Pre-rendered sound plays your exact alarm even if app is killed |
| System Volume Boost | `VolumeManager.swift` + `BackgroundAudioKeeper.swift` | IMPLEMENTED | free | Automatically raises system ringer volume when alarms fire |
| Background Alarm Guard | `BackgroundAudioKeeper.swift` | IMPLEMENTED | free | Toggle in Settings keeps alarms protected in background |
| Video Backgrounds | `VideoBackgroundView.swift` + `VideoBackgroundService.swift` | IMPLEMENTED | free | 8 cinematic videos with audio, import custom videos |
| Video Alarm Reliability | `AlarmKitAdapter.swift` L222-227 (registerVideoSoundAlarm) | IMPLEMENTED | free | Video alarms now work reliably when app is force-quit |
| Apple Music Integration | `MusicLibraryService.swift` + `AudioService.swift` | IMPLEMENTED | free | Pick any song from Apple Music library as alarm sound |
| Custom Sound Import | `SoundImportService.swift` | IMPLEMENTED | pro | Import your own sound files (unlimited with Premium) |
| AI Sound Generation | `AIGenerationService.swift` | IMPLEMENTED | pro | Create unique alarm sounds with 4 AI styles (unlimited with Premium) |
| Sound Shuffle | `AlarmScheduler.swift` L135-159 (resolveShuffledSound) | IMPLEMENTED | free | Auto-rotate alarm sounds daily or weekly |
| 30+ Alarm Sounds | `AudioService.swift` + `Constants.swift` | IMPLEMENTED | free | Built-in sounds across 5 categories |
| Gradual Fade-In | `AudioService.swift` L191-206 (startFadeIn) | IMPLEMENTED | free | Progressive volume increase from gentle to your chosen level over 1-30 seconds |
| Snooze Functionality | `AlarmScheduler.swift` L216-276 (scheduleSnooze) | IMPLEMENTED | free | Custom snooze duration with background reliability |
| Alarm Categories | `AlarmViewModel.swift` L447-457 (groupedAlarms) | IMPLEMENTED | free | Organize by Work, Weekend, Important, Nap, Medication |
| Vibration Option | `AlarmScheduler.swift` L515-529 (vibrate) | IMPLEMENTED | free | Vibrate alarm for tactile wake-up, works even with sound off |
| Accessibility | `DynamicFont.swift` + VoiceOver labels in Views | IMPLEMENTED | free | Full VoiceOver support and Dynamic Type |

## Document-Code Conflict Resolution

| # | Conflicting Document Claim | Actual Code Evidence | Resolution | Impact on keytext.md |
|---|---------------------------|----------------------|------------|----------------------|
| 1 | keytext3 mentions "Video backgrounds" but didn't highlight force-quit reliability fix | `AlarmKitAdapter.swift` now has `registerVideoSoundAlarm` for video alarm persistence | Code wins: video alarms now persist across app kills | Added video alarm reliability to What's New |
| 2 | No conflict - all features in keytext3 verified in code | All features mapped to code files | No changes needed | - |

## ASO Keyword Evidence

| Keyword | Source | Traffic | Difficulty | ROI | Placement | Rationale |
|---------|--------|---------|------------|-----|-----------|-----------|
| alarm clock | aso-mcp search_keywords | 9.1 | 9.4 | 0.97 | Keywords | High traffic, already in Title context |
| alarm volume | aso-mcp search_keywords | 8.5 | 9.1 | 0.93 | Subtitle | Core differentiation, high traffic |
| loud alarm | aso-mcp search_keywords | 8.5 | 9.5 | 0.89 | Keywords | High traffic, describes heavy sleeper use case |
| wake up alarm | aso-mcp search_keywords | 9.1 | 9.5 | 0.96 | Keywords | High traffic, scene word |
| video alarm | aso-mcp search_keywords | 7.8 | 9.1 | 0.86 | Keywords | Medium-high traffic, unique feature |
| gentle alarm | aso-mcp search_keywords | 7.3 | 9.6 | 0.76 | Keywords | Medium traffic, light sleeper use case |
| silent alarm | aso-mcp search_keywords | 7.5 | 8.9 | 0.84 | Subtitle | Medium traffic, better ROI (lower difficulty) |
| custom alarm sound | aso-mcp search_keywords | 9.4 | 9.6 | 0.98 | Keywords | High traffic, describes premium feature |

## Keyword-to-Feature Mapping

| Keyword | Maps to Feature | Relevance |
|---------|-----------------|-----------|
| alarm clock | Core app functionality | RELEVANT |
| alarm volume | Independent Volume Control | RELEVANT |
| loud alarm | Volume presets (Maximum, Loud), heavy sleeper use case | RELEVANT |
| wake up alarm | Core alarm functionality | RELEVANT |
| video alarm | Video Backgrounds | RELEVANT |
| gentle alarm | Volume presets (Gentle, Whisper), Gradual Fade-In | RELEVANT |
| silent alarm | Three-Layer Silent Mode Reliability | RELEVANT |
| custom alarm sound | Custom Sound Import, AI Sound Generation | RELEVANT |
| loudest | Volume presets (Maximum) | RELEVANT |
| heavy sleeper | Volume presets, System Volume Boost, use case for heavy sleepers | TANGENTIAL |
| wake | Core alarm functionality | RELEVANT |
| music | Apple Music Integration | RELEVANT |
| sound | 30+ Alarm Sounds, Custom Sound Import | RELEVANT |
| gentle | Volume presets (Gentle), Gradual Fade-In | RELEVANT |
| progressive | Gradual Fade-In (progressive volume increase) | RELEVANT |
| nap | Alarm Categories (Nap category), flexible scheduling | TANGENTIAL |
| vibrate | Vibration Option | RELEVANT |
| ringer | System Volume Boost (boosts ringer volume), Volume presets | RELEVANT |
| preset | Volume Presets (5 presets: Whisper, Gentle, Moderate, Loud, Maximum) | RELEVANT |
| video | Video Backgrounds | RELEVANT |
| shuffle | Sound Shuffle | RELEVANT |

## Validation History

| Run | Date | Script Result | Issues Fixed |
|-----|------|---------------|--------------|
| 1 | 2026-07-17 | FAIL: Keyword-to-Feature Mapping missing for loudest, heavy sleeper, gentle, progressive, vibrate, ringer, preset | Added Volume Presets feature, updated feature descriptions to include keywords |
| 2 | 2026-07-17 | ALL PASS | - |