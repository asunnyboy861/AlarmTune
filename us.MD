# AlarmTune — Custom Volume for Every Alarm

> **App Name**: AlarmTune  
> **Subtitle**: Custom Volume for Every Alarm  
> **Target Market**: United States (Global iOS Users)  
> **Platform**: iOS 17+ / Swift + SwiftUI  
> **Bundle ID**: com.zzoutuo.AlarmTune  
> **Document Date**: April 18, 2026  

---

## Table of Contents

1. [App Naming Analysis](#1-app-naming-analysis)
2. [Pain Point Analysis & Market Demand](#2-pain-point-analysis--market-demand)
3. [Competitive Analysis](#3-competitive-analysis)
4. [GitHub Projects for Secondary Development](#4-github-projects-for-secondary-development)
5. [Core Technical Architecture](#5-core-technical-architecture)
6. [Core Code Implementation Examples](#6-core-code-implementation-examples)
7. [Feature Implementation Flowcharts](#7-feature-implementation-flowcharts)
8. [User Flow Diagrams](#8-user-flow-diagrams)
9. [UI Design Guidelines (US Market)](#9-ui-design-guidelines-us-market)
10. [Development Rules & Coding Standards](#10-development-rules--coding-standards)
11. [MVP Iteration Plan](#11-mvp-iteration-plan)
12. [Monetization Strategy](#12-monetization-strategy)
13. [App Store Review Compliance](#13-app-store-review-compliance)
14. [Testing & Acceptance Criteria](#14-testing--acceptance-criteria)

---

## 1. App Naming Analysis

### 1.1 Final Naming Decision

| Item | Content |
|------|------|
| **Primary Name** | **AlarmTune** |
| **Subtitle** | **Custom Volume for Every Alarm** |
| **App Store Full Name** | AlarmTune - Custom Volume Alarm |
| **Bundle ID** | com.zzoutuo.AlarmTune |
| **Keywords** | alarm, volume, clock, wake, sound, custom, timer |

### 1.2 Five-Dimension Deep Evaluation

#### Dimension 1: ASO Search Optimization (9/10)

**High-Frequency Search Keyword Coverage**:

| Search Keyword | Monthly Searches (Est.) | AlarmTune Coverage | Notes |
|-----------|------------|--------------|------|
| alarm clock | 500K+ | "Alarm" | Highest frequency |
| alarm volume | 50K+ | Full coverage | Core differentiation |
| volume control | 80K+ | "Tune" implies | Indirect coverage |
| custom alarm | 30K+ | Subtitle coverage | Exact match |
| alarm clock loud | 20K+ | Feature association | Pain point keyword |
| alarm different volume | 10K+ | Full coverage | Long-tail keyword |
| wake up alarm | 40K+ | "Alarm" | Generic coverage |
| alarm sound | 35K+ | "Tune" double meaning | Sound + tuning |

**ASO Strategy**:
- Title includes "Alarm" (highest frequency word)
- "Tune" is both a brand word and a functional word (tuning = adjusting volume)
- Subtitle covers "Volume" + "Alarm" dual keywords
- Keyword field supplements: clock, wake, sound, custom, timer, loud, quiet, ringtone

#### Dimension 2: Brand Memorability (8/10)

| Metric | Score | Notes |
|------|------|------|
| Syllables | 8/10 | 2 syllables (Alarm-Tune), short and powerful |
| Pronunciation Difficulty | 9/10 | Common English combination, globally universal |
| Spelling Difficulty | 9/10 | Unambiguous spelling |
| Visual Recognition | 7/10 | Two common words combined, can design unique Logo |
| Word-of-Mouth Spread | 8/10 | "Have you tried AlarmTune?" — natural and fluent |

**Brand Association Path**:
```
AlarmTune → Tune (tuning) → Volume adjustment → Personalized alarm → Independent volume control
```

#### Dimension 3: Functional Descriptiveness (8/10)

| Level | Analysis |
|------|------|
| Intuitive Understanding | "Alarm" = alarm clock, "Tune" = adjust/tune → adjust alarm |
| Competitor Differentiation | All competitors are called "Alarm Clock" or "Sleep Cycle", AlarmTune is unique |
| Functional Hint | "Tune" implies users can "adjust" a certain attribute of the alarm (volume) |
| Extensibility | Can be extended to "tune" more alarm attributes (vibration patterns, fade-in speed, etc.) |

#### Dimension 4: Emotional Resonance (7/10)

| Emotional Connection | Description |
|----------|------|
| Sense of Control | "Tune" = I control my alarms, no longer passive |
| Personalization | "Tune" implies personalized customization, not one-size-fits-all |
| Gentleness | "Tune" is gentler than "Control", implying fine adjustment rather than brute force |
| Musical Feel | "Tune" has musical tuning associations, fitting "alarm ringtone" |

**User Voice Mapping**:
```
"I hate being startled awake by a loud alarm" → AlarmTune: Lower volume
"My alarm is too quiet to hear" → AlarmTune: Raise volume  
"Workdays and weekends need different volumes" → AlarmTune: Independent settings per alarm
```

#### Dimension 5: Internationalization (9/10)

| Market | "Alarm" Understanding | "Tune" Understanding | Overall Fit |
|------|-------------|-------------|---------|
| US | 100% | 100% | Perfect |
| UK | 100% | 100% | Perfect |
| Germany | 95% | 90% | Excellent |
| France | 90% | 85% | Excellent |
| Japan | 85% | 80% | Good |
| Korea | 80% | 75% | Good |
| Brazil | 85% | 80% | Good |
| China | 70% | 65% | Fair (usable) |

### 1.3 Alternative Naming Options

| Rank | Primary Name | Subtitle | Total Score | Pros & Cons |
|------|--------|--------|------|----------|
| **1** | **AlarmTune** | **Custom Volume for Every Alarm** | **41/50** | Best brand feel + ASO + extensibility |
| 2 | VolAlarm | Your Alarms, Your Volume | 39/50 | Strongest ASO but weak brand feel |
| 3 | AlarmDial | Dial In Your Perfect Wake-Up | 39/50 | Strong visual but weaker ASO |
| 4 | VolumeAlarm | Set Different Volume for Each Alarm | 38/50 | Most functional but lacks brand personality |

---

## 2. Pain Point Analysis & Market Demand

### 2.1 Core Pain Point

**Pain Point Level**: Diamond (95/100) — Ranked #1 in reports

| Dimension | Details |
|------|------|
| **Pain Point Description** | iOS alarm apps cannot set individual volume for each alarm, causing users to either be startled awake or miss their alarms |
| **Affected Population** | All iPhone users (1.4B+ devices), especially those needing different volume alarms |
| **Pain Point Frequency** | Multiple times daily (exposed every time an alarm triggers) |
| **Pain Point Intensity** | High (affects sleep quality, work punctuality, household harmony) |

### 2.2 User Quotes (Data Source: Reddit/TikTok/Instagram)

> "Very simple. The native alarm app. Why can't we have a volume slider for each saved alarm. So I can create loud ones and quiet ones." — Reddit user (3 months ago)

> "The one that allows me to control ringer, media and alarm volumes individually." — Reddit user (3 months ago)

> "something that lets me turn up my god damn notification sound volume. it's so quiet. the ringer and media are maxed out but notifications are still too quiet." — Reddit user (3 months ago)

> "I have to change my phone volume every night before bed and every morning after waking up. It's so annoying." — Reddit user

> "My wife gets mad when my alarm is too loud, but if I lower it I can't hear it." — Reddit user

### 2.3 Specific User Scenarios

| Scenario | Current Pain Point | AlarmTune Solution |
|------|----------|-------------------|
| Workday early shift | Need loud alarm to ensure not late | Set workday alarm volume to 100% |
| Weekend rest | Don't want to be startled by loud alarm | Set weekend alarm volume to 30% |
| Nap reminder | Need gentle reminder | Set nap alarm volume to 20% |
| Meeting reminder | Need vibration or very quiet | Set reminder volume to 5% or vibration only |
| Spouse/roommate | Don't want to wake them | Set alarm volume to 40% |
| Hearing impairment | Need extra loud volume | Set alarm volume to 100% + vibration |
| Medication reminder | Need moderate volume | Set reminder alarm volume to 50% |

### 2.4 Market Size

| Metric | Value |
|------|------|
| Global iOS Devices | 1.4B+ |
| US iPhone Users | 120M |
| Users Using Alarm Feature | ~90% |
| Users Needing Independent Volume | ~30% |
| **Total Addressable Market (TAM)** | **420M users** |
| **Serviceable Addressable Market (SAM)** | **36M users** (30% of US iPhone users) |
| **Serviceable Obtainable Market (SOM)** | **3.6M users** (1% conversion rate) |

---

## 3. Competitive Analysis

### 3.1 Competitor Comparison Matrix

| Competitor | Rating | Price | Independent Volume | Core Defect | AlarmTune Advantage |
|------|------|------|---------|---------|--------------|
| iOS Clock (Native) | 4.8 | Free | No | Cannot set individual volume per alarm | Core feature differentiation |
| Alarm Clock Pro | 3.2 | $3.99 | No | Complex interface, too many features, difficult settings | Minimalist design + independent volume |
| Sleep Cycle | 4.7 | $39.99/year | No | Over-designed, expensive, too complex | Lightweight + one-time purchase |
| Alarmy | 4.5 | Free + IAP | No | Sells "task to dismiss", not volume control | Simple direct volume control |
| Loud Alarm Clock | 4.3 | Free + IAP | Partial | Only supports "extra loud", no fine control | 0-100% fine volume slider |
| Morning Routine | 4.1 | Free + IAP | No | Focuses on habit tracking, not alarm features | Focuses on core alarm functionality |
| Awake: Smart Alarm | 4.7 | Free + IAP | No | Mission-based wake-up, over-engineered | Simple volume-first approach |
| Alarm Clock HD | 4.5 | Free + IAP | Partial | Requires app open for volume control, unreliable | Works in background with AVAudioPlayer |

### 3.2 Competitor App Store Negative Review Analysis

**iOS Clock (Native) — Most Common Complaints**:
- "Why can't I set different volumes for different alarms?" — Most frequent feature request
- "I have to manually adjust volume before bed every night"
- "Almost missed my flight because I accidentally left the volume low"

**Alarm Clock Pro — Negative Review Keywords**:
- "Too complicated" — Interface too complex
- "Too many features I don't need" — Feature bloat
- "Just want a simple alarm with volume control" — User core need

**Sleep Cycle — Negative Review Keywords**:
- "$40/year for an alarm?" — Price too high
- "Too many things I don't need" — Over-designed
- "I just want to wake up on time" — Core need buried

**Alarm Clock HD — Negative Review Keywords**:
- "Alarm failed to make any noise and wake me up" — Reliability issues
- "Requires ringer to be on for alarm to sound" — System volume dependency
- "No room for possibility of it failing" — Users need consistency

### 3.3 AlarmTune Differentiation Positioning

```
                 Simple ←————————————————→ Complex
                  |                        |
     AlarmTune    |                        |
     (Independent |                        |
      Volume      |                        |
      Minimalist) |                        |
                  |                        |
         iOS Clock|              Sleep Cycle|
          (Simple |              (Complex   |
           No Vol)|               Expensive)|
                  |                        |
                 Free ←————————————————→ Expensive
```

**Core Differentiation**:
1. **Only app solving the independent volume pain point** — Market gap
2. **Minimalist design** — Only alarm + volume, not over-designed like Sleep Cycle
3. **One-time purchase $2.99** — No annual fees, unlike competitors charging $40/year
4. **Fine volume control** — 0-100% continuous slider, not just "loud/quiet" toggle

---

## 4. GitHub Projects for Secondary Development

### 4.1 Best Secondary Development Projects

#### Project 1: FlipByBlink/FadeInAlarm (Primary Base)

| Attribute | Details |
|------|------|
| **GitHub** | https://github.com/FlipByBlink/FadeInAlarm |
| **Description** | Alarm with fade-in sound |
| **Language** | Swift + SwiftUI |
| **License** | MIT |
| **Core Value** | **Already implements AVAudioPlayer volume fade-in control** — directly relevant to this project's core functionality |
| **Code Structure** | FadeInAlarmApp.swift + ContentView.swift + AppModel.swift + Sub modules |
| **Secondary Development Direction** | Expand from fade-in volume to independent volume per alarm |

**Key Code Modules**:
- `AppModel.swift` — App data model
- `ContentView.swift` — Main SwiftUI view
- `Sub/` — Sub-modules (volume control logic here)
- `AlarmPlayer.swift` — AVAudioPlayer wrapper with volume control
- `Notification.swift` — Local notification handling
- `SystemVolumeSlider.swift` — System volume UI

**Secondary Development Focus**:
1. Extend AppModel to add volume property per alarm
2. Add volume slider UI in alarm list
3. Read independent volume value when alarm triggers
4. Retain fade-in feature as an additional option

---

#### Project 2: andreanlay/stalarm-swiftui (Architecture Reference)

| Attribute | Details |
|------|------|
| **GitHub** | https://github.com/andreanlay/stalarm-swiftui |
| **Description** | iOS app that helps reduce procrastination by forcing movement when stopping alarm |
| **Language** | Swift + SwiftUI |
| **License** | MIT |
| **Core Value** | **Best reference for SwiftUI + CoreData + MVVM architecture** |
| **Code Structure** | Application / Core Data / View Models / Views / Helper / Utils / Singleton |
| **Secondary Development Direction** | Borrow complete MVVM architecture and CoreData persistence |

**Key Code Modules**:
- `Core Data/` — CoreData model definition and persistence
- `View Models/` — MVVM ViewModel layer
- `Views/` — SwiftUI view layer
- `Helper/` — Utility classes (notification scheduling, audio playback)
- `Singleton/` — Singleton managers

**Secondary Development Focus**:
1. Borrow CoreData Alarm model, extend with volume property
2. Borrow ViewModel pattern for alarm state management
3. Borrow notification scheduling logic
4. Replace "move to stop alarm" logic with "independent volume control" logic

---

#### Project 3: natsu1211/Alarm-ios-swift (Feature Reference)

| Attribute | Details |
|------|------|
| **GitHub** | https://github.com/natsu1211/Alarm-ios-swift |
| **Description** | Clone of the official iOS Clock alarm app written in Swift |
| **Language** | Swift (UIKit + MVC) |
| **License** | MIT |
| **Core Value** | **Most complete iOS native alarm app clone** — all alarm feature reference |
| **Code Structure** | MVC/Alarm/ — Complete alarm app implementation |
| **Secondary Development Direction** | Reference complete alarm feature logic, rewrite in SwiftUI + add volume control |

**Key Code Modules**:
- Complete MVC architecture
- Alarm CRUD operations
- Repeat date settings
- Ringtone picker
- Alarm toggle

**Secondary Development Focus**:
1. Reference alarm edit screen interaction logic
2. Reference repeat date picker UI design
3. Reference ringtone picker implementation
4. **Add**: Volume slider in each alarm setting

---

#### Project 4: RedMadRobot/Alarm-Clock (Design Reference)

| Attribute | Details |
|------|------|
| **GitHub** | https://github.com/RedMadRobot/Alarm-Clock |
| **Description** | Alarm Clock / Proof of concept for colored alarm clock interface |
| **Language** | Swift |
| **License** | MIT |
| **Core Value** | **Professional UI design reference** — Dribbble design concept implementation |
| **Secondary Development Direction** | Borrow visual design and animation effects |

---

### 4.2 Secondary Development Strategy Summary

```
Best Secondary Development Path:

FadeInAlarm (Volume Control Core)
    ├── Keep: AVAudioPlayer volume control logic
    ├── Keep: Fade-in playback feature
    ├── Modify: Expand to independent volume per alarm
    │
    ├── stalarm-swiftui (Architecture Reference)
    │   ├── Borrow: MVVM + CoreData architecture
    │   ├── Borrow: ViewModel + View separation pattern
    │   └── Borrow: Notification scheduling Helper
    │
    ├── Alarm-ios-swift (Feature Reference)
    │   ├── Borrow: Complete alarm CRUD logic
    │   ├── Borrow: Repeat date/ringtone picker
    │   └── Borrow: Alarm toggle interaction
    │
    └── RedMadRobot/Alarm-Clock (Design Reference)
        └── Borrow: Visual design and animations
```

---

## 5. Core Technical Architecture

### 5.1 Tech Stack

| Layer | Technology | Purpose |
|------|------|------|
| **Language** | Swift 5.9+ | Primary development language |
| **UI Framework** | SwiftUI | Modern declarative UI |
| **Architecture Pattern** | MVVM | Model-View-ViewModel |
| **Data Persistence** | CoreData + UserDefaults | Alarm data + settings |
| **Audio Playback** | AVFoundation / AVAudioPlayer | Core volume control |
| **Notifications** | UserNotifications | Alarm trigger notifications |
| **Background Mode** | Background Modes (Audio) | Background audio playback |
| **Shortcuts** | AppIntents | Siri shortcut integration |
| **Minimum Version** | iOS 17.0 | Target modern devices |

### 5.2 System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                       AlarmTune App                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   Views      │  │  ViewModels  │  │    Models        │  │
│  │  (SwiftUI)   │──│  (Observable)│──│  (CoreData)      │  │
│  │              │  │              │  │                  │  │
│  │ AlarmListView│  │ AlarmListVM  │  │ AlarmItem        │  │
│  │ AddAlarmView │  │ AddAlarmVM   │  │   - id           │  │
│  │ EditAlarmView│  │ EditAlarmVM  │  │   - time         │  │
│  │ VolumeSlider │  │ AudioVM      │  │   - volume CORE  │  │
│  │ SoundPicker  │  │              │  │   - soundName    │  │
│  │ SettingsView │  │              │  │   - repeatDays   │  │
│  │ RingingView  │  │              │  │   - label        │  │
│  └──────────────┘  └──────────────┘  │   - category     │  │
│                                       │   - isEnabled    │  │
│                                       │   - isFadeIn     │  │
│                                       │   - isVibrate    │  │
│                                       └──────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                 Services Layer                        │   │
│  │                                                      │   │
│  │  AudioService    NotificationSvc   AlarmScheduler    │   │
│  │  playAlarm()     schedule()        scheduleAll()     │   │
│  │  setVolume()     cancel()          cancelAll()       │   │
│  │  fadeIn()        handleWake        getNextAlarm()    │   │
│  │  fadeOut()                                             │   │
│  │                                                      │   │
│  │  SoundManager      VolumeEngine                      │   │
│  │  loadSound()       adjustGain()                      │   │
│  │  listSounds()      presetVol()                       │   │
│  │  importFile()      autoAdjust()                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                 Platform Layer                        │   │
│  │  AVFoundation │ UserNotifications │ CoreData │ AppIntents│
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 5.3 Core Technical Challenge: Independent Volume Control

**iOS System Limitation**: System volume is globally unified; there is no native API to set individual volume per notification/alarm.

**Solution: Hybrid Audio Playback Architecture**

```
Core Approach:
  Do NOT use UNNotificationSound (system unified volume)
  Instead, use AVAudioPlayer to play custom audio (independent volume control)

┌─────────────────────────────────────────────────────────┐
│                   Alarm Trigger Flow                     │
│                                                         │
│  1. UNUserNotification triggers (silent/minimal prompt)  │
│         │                                               │
│  2. Notification handler extracts alarm info            │
│         │                                               │
│  3. AVAudioSession configured (.playback category)      │
│         │                                               │
│  4. AVAudioPlayer loads alarm sound file                │
│         │                                               │
│  5. AVAudioPlayer.volume = alarm.volume ← CORE          │
│         │                                               │
│  6. Audio plays with independent volume                 │
│         │                                               │
│  7. Full-screen ringing UI displayed                    │
│         │                                               │
│  8. User stops/snoozes alarm                            │
└─────────────────────────────────────────────────────────┘
```

**Key Technical Points**:

1. **Background Audio Mode**: Must declare `UIBackgroundModes` with `audio` in Info.plist
2. **AVAudioSession Configuration**: Use `.playback` category with `.mixWithOthers` option
3. **Notification Sound = nil**: Set `content.sound = nil` to prevent system sound interference
4. **Volume Range**: 0.0 (silent) to 1.0 (maximum) — continuous slider
5. **Fade-in Support**: Timer-based gradual volume increase from 0 to target
6. **Fade-out Support**: Timer-based gradual volume decrease to 0 on snooze

### 5.4 CoreData Model Design

```
Entity: AlarmItem
├── id: UUID (unique identifier)
├── time: Date (alarm time)
├── label: String (alarm label/name)
├── volume: Float (0.0 - 1.0, independent volume)
├── soundName: String (ringtone file name)
├── repeatDays: Transformable [Int] (0=Sun, 1=Mon, ... 6=Sat)
├── category: String (work/weekend/important/nap/medication)
├── color: String (hex color for UI)
├── isEnabled: Boolean (alarm on/off)
├── isFadeIn: Boolean (fade-in mode enabled)
├── fadeInDuration: Double (fade-in duration in seconds)
├── isVibrate: Boolean (vibration enabled)
├── createdAt: Date (creation timestamp)
└── updatedAt: Date (last modification timestamp)
```

### 5.5 Project Structure

```
AlarmTune/
├── AlarmTuneApp.swift              # App entry point
├── Models/
│   ├── AlarmItem+CoreData.swift    # CoreData model (generated)
│   ├── AlarmItem+Extensions.swift  # Model extensions
│   └── Sound.swift                 # Ringtone model
├── ViewModels/
│   ├── AlarmListViewModel.swift    # Alarm list VM
│   ├── AddEditAlarmViewModel.swift # Add/edit alarm VM
│   └── RingingViewModel.swift      # Ringing screen VM
├── Views/
│   ├── AlarmListView.swift         # Main screen
│   ├── AddEditAlarmView.swift      # Add/edit alarm screen
│   ├── RingingView.swift           # Full-screen ringing UI
│   ├── VolumeSliderView.swift      # Volume slider component
│   ├── SoundPickerView.swift       # Ringtone picker
│   ├── DayPickerView.swift         # Repeat day picker
│   └── SettingsView.swift          # Settings screen
├── Services/
│   ├── AudioService.swift          # Audio playback + volume control
│   ├── AlarmScheduler.swift        # Notification scheduling
│   └── SoundManager.swift          # Ringtone management
├── Helpers/
│   ├── PersistenceController.swift # CoreData stack
│   ├── DateHelper.swift            # Date utilities
│   └── HapticManager.swift         # Haptic feedback
├── Resources/
│   ├── Sounds/                     # Built-in ringtone files
│   └── Assets.xcassets/           # Image assets
└── AlarmTune.xcdatamodeld/        # CoreData model file
```

---

## 6. Core Code Implementation Examples

### 6.1 CoreData Model Extension — AlarmItem+Extensions.swift

```swift
import Foundation

extension AlarmItem {
    enum VolumePreset: String, CaseIterable {
        case whisper = "Whisper"
        case gentle = "Gentle"
        case moderate = "Moderate"
        case loud = "Loud"
        case maximum = "Maximum"
        
        var volumeValue: Float {
            switch self {
            case .whisper: return 0.15
            case .gentle: return 0.30
            case .moderate: return 0.55
            case .loud: return 0.80
            case .maximum: return 1.0
            }
        }
        
        var icon: String {
            switch self {
            case .whisper: return "speaker.fill"
            case .gentle: return "speaker.wave.1.fill"
            case .moderate: return "speaker.wave.2.fill"
            case .loud: return "speaker.wave.3.fill"
            case .maximum: return "speaker.wave.3.fill"
            }
        }
    }
    
    var volumePreset: VolumePreset {
        switch volume {
        case 0.0..<0.2: return .whisper
        case 0.2..<0.4: return .gentle
        case 0.4..<0.65: return .moderate
        case 0.65..<0.9: return .loud
        default: return .maximum
        }
    }
    
    var repeatDaysText: String {
        let daySymbols = ["S", "M", "T", "W", "T", "F", "S"]
        return (repeatDays as? [Int])?.sorted().map { daySymbols[$0] }.joined(separator: " ") ?? ""
    }
}
```

### 6.2 Audio Service — AudioService.swift

```swift
import Foundation
import AVFoundation

class AudioService: ObservableObject {
    static let shared = AudioService()
    
    private var audioPlayer: AVAudioPlayer?
    private var fadeTimer: Timer?
    
    @Published var isPlaying: Bool = false
    @Published var currentVolume: Float = 0.0
    
    private init() {
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio session configuration failed: \(error)")
        }
    }
    
    func playAlarm(soundName: String, volume: Float, fadeIn: Bool = false, fadeInDuration: Double = 5.0) {
        stopAlarm()
        
        guard let soundURL = getSoundURL(for: soundName) else {
            print("Sound file not found: \(soundName)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.prepareToPlay()
            
            if fadeIn {
                audioPlayer?.volume = 0.0
                audioPlayer?.play()
                animateFadeIn(targetVolume: volume, duration: fadeInDuration)
            } else {
                audioPlayer?.volume = volume
                audioPlayer?.play()
            }
            
            isPlaying = true
            currentVolume = volume
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio playback failed: \(error)")
        }
    }
    
    func setVolume(_ volume: Float) {
        audioPlayer?.volume = volume
        currentVolume = volume
    }
    
    private func animateFadeIn(targetVolume: Float, duration: Double) {
        let steps = 60.0
        let interval = duration / steps
        let volumeStep = targetVolume / Float(steps)
        var currentStep = 0
        
        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            currentStep += 1
            let newVolume = min(volumeStep * Float(currentStep), targetVolume)
            self.audioPlayer?.volume = newVolume
            self.currentVolume = newVolume
            
            if currentStep >= Int(steps) {
                timer.invalidate()
                self.audioPlayer?.volume = targetVolume
                self.currentVolume = targetVolume
            }
        }
    }
    
    func stopAlarm() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentVolume = 0.0
    }
    
    func snooze(fadeOutDuration: Double = 2.0, completion: @escaping () -> Void) {
        let steps = 30.0
        let interval = fadeOutDuration / steps
        let volumeStep = currentVolume / Float(steps)
        var currentStep = 0
        
        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            currentStep += 1
            let newVolume = max(self.currentVolume - volumeStep, 0)
            self.audioPlayer?.volume = newVolume
            self.currentVolume = newVolume
            
            if newVolume <= 0 || currentStep >= Int(steps) {
                timer.invalidate()
                self.stopAlarm()
                completion()
            }
        }
    }
    
    func previewSound(soundName: String, volume: Float) {
        playAlarm(soundName: soundName, volume: volume, fadeIn: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.stopAlarm()
        }
    }
    
    private func getSoundURL(for name: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: "caf") { return url }
        if let url = Bundle.main.url(forResource: name, withExtension: "mp3") { return url }
        if let url = Bundle.main.url(forResource: name, withExtension: "m4a") { return url }
        
        let importedDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ImportedSounds", isDirectory: true)
        let importedURL = importedDir.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: importedURL.path) { return importedURL }
        return nil
    }
}
```

### 6.3 Notification Scheduling — AlarmScheduler.swift

```swift
import Foundation
import UserNotifications

class AlarmScheduler {
    static let shared = AlarmScheduler()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {}
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .criticalAlert])
            return granted
        } catch {
            print("Notification permission denied: \(error)")
            return false
        }
    }
    
    func scheduleAlarm(_ alarm: AlarmItem) {
        guard alarm.isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "AlarmTune"
        content.body = alarm.label?.isEmpty ?? true ? "Wake up!" : alarm.label ?? ""
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.userInfo = [
            "alarmId": alarm.id?.uuidString ?? "",
            "volume": alarm.volume,
            "soundName": alarm.soundName ?? "",
            "isFadeIn": alarm.isFadeIn,
            "fadeInDuration": alarm.fadeInDuration,
            "isVibrate": alarm.isVibrate
        ]
        
        content.sound = nil
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: alarm.time ?? Date())
        
        if (alarm.repeatDays as? [Int])?.isEmpty ?? true {
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: alarm.id?.uuidString ?? "", content: content, trigger: trigger)
            notificationCenter.add(request)
        } else {
            for day in (alarm.repeatDays as? [Int]) ?? [] {
                var repeatingComponents = components
                repeatingComponents.weekday = day + 1
                let trigger = UNCalendarNotificationTrigger(dateMatching: repeatingComponents, repeats: true)
                let requestId = "\(alarm.id?.uuidString ?? "")-\(day)"
                let request = UNNotificationRequest(identifier: requestId, content: content, trigger: trigger)
                notificationCenter.add(request)
            }
        }
    }
    
    func cancelAlarm(_ alarm: AlarmItem) {
        if (alarm.repeatDays as? [Int])?.isEmpty ?? true {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [alarm.id?.uuidString ?? ""])
        } else {
            let ids = (alarm.repeatDays as? [Int])?.map { "\(alarm.id?.uuidString ?? "")-\($0)" } ?? []
            notificationCenter.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
    
    func rescheduleAllAlarms(alarms: [AlarmItem]) {
        notificationCenter.removeAllPendingNotificationRequests()
        for alarm in alarms where alarm.isEnabled {
            scheduleAlarm(alarm)
        }
    }
}
```

### 6.4 Notification Handler — AppDelegate.swift

```swift
import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, 
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                 willPresent notification: UNNotification, 
                                 withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        handleAlarmNotification(notification)
        completionHandler([])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                 didReceive response: UNNotificationResponse, 
                                 withCompletionHandler completionHandler: @escaping () -> Void) {
        handleAlarmNotification(response.notification)
        completionHandler()
    }
    
    private func handleAlarmNotification(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        
        guard let volume = userInfo["volume"] as? Float,
              let soundName = userInfo["soundName"] as? String else {
            return
        }
        
        let isFadeIn = userInfo["isFadeIn"] as? Bool ?? false
        let fadeInDuration = userInfo["fadeInDuration"] as? Double ?? 5.0
        let isVibrate = userInfo["isVibrate"] as? Bool ?? true
        
        AudioService.shared.playAlarm(
            soundName: soundName,
            volume: volume,
            fadeIn: isFadeIn,
            fadeInDuration: fadeInDuration
        )
    }
}
```

### 6.5 Volume Slider Component — VolumeSliderView.swift

```swift
import SwiftUI

struct VolumeSliderView: View {
    @Binding var volume: Float
    var onPreview: ((Float) -> Void)?
    
    private let presets: [(name: String, icon: String, value: Float)] = [
        ("Whisper", "speaker.fill", 0.15),
        ("Gentle",  "speaker.wave.1.fill", 0.30),
        ("Moderate", "speaker.wave.2.fill", 0.55),
        ("Loud",    "speaker.wave.3.fill", 0.80),
        ("Max",     "speaker.wave.3.fill", 1.0)
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Volume")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(volume * 100))%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(volumeColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.6), volumeColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(volume), height: 8)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        .overlay {
                            Circle()
                                .fill(volumeColor)
                                .frame(width: 20, height: 20)
                        }
                        .offset(x: geometry.size.width * CGFloat(volume) - 14)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newVolume = max(0.05, min(1.0, Float(value.location.x / geometry.size.width)))
                            volume = newVolume
                        }
                        .onEnded { _ in
                            onPreview?(volume)
                        }
                )
            }
            .frame(height: 28)
            
            HStack(spacing: 8) {
                ForEach(presets, id: \.name) { preset in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            volume = preset.value
                        }
                        onPreview?(preset.value)
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: preset.icon)
                                .font(.title3)
                            Text(preset.name)
                                .font(.caption2)
                                .foregroundColor(abs(volume - preset.value) < 0.1 ? .blue : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(abs(volume - preset.value) < 0.1 ? Color.blue.opacity(0.1) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private var volumeColor: Color {
        switch volume {
        case 0.0..<0.2: return .cyan
        case 0.2..<0.4: return .blue
        case 0.4..<0.65: return .indigo
        case 0.65..<0.9: return .orange
        default: return .red
        }
    }
}
```

### 6.6 Main Interface — AlarmListView.swift

```swift
import SwiftUI

struct AlarmListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \AlarmItem.time, ascending: true)],
        animation: .default)
    private var alarms: FetchedResults<AlarmItem>
    
    @State private var showingAddAlarm = false
    @State private var nextAlarmText: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if alarms.isEmpty {
                    emptyStateView
                } else {
                    alarmListView
                }
            }
            .navigationTitle("AlarmTune")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddAlarm = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAlarm) {
                AddEditAlarmView(mode: .add)
            }
        }
    }
    
    private var alarmListView: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "alarm")
                        .foregroundColor(.blue)
                    Text(nextAlarmText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            ForEach(groupedAlarms.keys.sorted(), id: \.self) { category in
                Section(header: Text(categoryDisplayName(category))) {
                    ForEach(groupedAlarms[category] ?? []) { alarm in
                        AlarmRowView(alarm: alarm)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .onAppear { updateNextAlarmText() }
    }
    
    struct AlarmRowView: View {
        let alarm: AlarmItem
        @State private var isEnabled: Bool
        
        init(alarm: AlarmItem) {
            self.alarm = alarm
            self._isEnabled = State(initialValue: alarm.isEnabled)
        }
        
        var body: some View {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(alarm.time ?? Date(), style: .time)
                        .font(.system(size: 48, weight: .light, design: .rounded))
                        .foregroundColor(isEnabled ? .primary : .secondary)
                    
                    HStack(spacing: 8) {
                        Text(alarm.label ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        volumeIndicator
                    }
                    
                    if !((alarm.repeatDays as? [Int])?.isEmpty ?? true) {
                        Text(alarm.repeatDaysText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
                    .tint(.blue)
                    .onChange(of: isEnabled) { newValue in
                        alarm.isEnabled = newValue
                        if newValue {
                            AlarmScheduler.shared.scheduleAlarm(alarm)
                        } else {
                            AlarmScheduler.shared.cancelAlarm(alarm)
                        }
                    }
            }
            .padding(.vertical, 8)
        }
        
        private var volumeIndicator: some View {
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Float(index) < alarm.volume * 5 ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 4, height: 6 + CGFloat(index) * 2)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "alarm.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.5))
            Text("No Alarms Yet")
                .font(.title2.weight(.semibold))
            Text("Add your first alarm with custom volume")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Add Alarm") {
                showingAddAlarm = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var groupedAlarms: [String: [AlarmItem]] {
        Dictionary(grouping: alarms) { ($0.category as String?)?.isEmpty ?? true ? "Other" : $0.category as String ?? "Other" }
    }
    
    private func categoryDisplayName(_ category: String) -> String {
        switch category {
        case "work": return "Work"
        case "weekend": return "Weekend"
        case "important": return "Important"
        case "nap": return "Nap"
        case "medication": return "Medication"
        default: return category
        }
    }
    
    private func updateNextAlarmText() {
        let enabledAlarms = alarms.filter { $0.isEnabled }
        nextAlarmText = enabledAlarms.isEmpty ? "No alarms set" : "Next alarm in X hours"
    }
}
```

### 6.7 AppIntents — Siri Shortcut Integration

```swift
import AppIntents

struct ToggleAlarmIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Alarm in AlarmTune"
    static var description = IntentDescription("Turn an alarm on or off in AlarmTune")
    
    @Parameter(title: "Alarm Label")
    var alarmLabel: String
    
    @Parameter(title: "Enabled", default: true)
    var enabled: Bool
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult {
        let alarms = PersistenceController.shared.fetchAlarms(label: alarmLabel)
        guard let alarm = alarms.first else {
            return .result(dialog: "No alarm found with label \(alarmLabel)")
        }
        
        alarm.isEnabled = enabled
        if enabled {
            AlarmScheduler.shared.scheduleAlarm(alarm)
        } else {
            AlarmScheduler.shared.cancelAlarm(alarm)
        }
        
        return .result(dialog: "Alarm \(alarmLabel) is now \(enabled ? "on" : "off")")
    }
}

struct SetAlarmVolumeIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Alarm Volume in AlarmTune"
    static var description = IntentDescription("Set the volume for a specific alarm")
    
    @Parameter(title: "Alarm Label")
    var alarmLabel: String
    
    @Parameter(title: "Volume", controlStyle: .slider, 
               scope: .quantity(0...100), unit: .percent)
    var volume: Int
    
    func perform() async throws -> some IntentResult {
        let alarms = PersistenceController.shared.fetchAlarms(label: alarmLabel)
        guard let alarm = alarms.first else {
            return .result(dialog: "No alarm found with label \(alarmLabel)")
        }
        
        alarm.volume = Float(volume) / 100.0
        
        if alarm.isEnabled {
            AlarmScheduler.shared.scheduleAlarm(alarm)
        }
        
        return .result(dialog: "Volume for \(alarmLabel) set to \(volume)%")
    }
}
```

---

## 7. Feature Implementation Flowcharts

### 7.1 Alarm Trigger & Volume Control Flow

```
[Scheduled Time Reached]
      │
      ▼
┌──────────────────┐
│ UNCalendarTrigger │  iOS system triggers local notification
│ (dateMatching)   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     NO
│ App in foreground?├──────────┐
└────────┬─────────┘          │
         │ YES                ▼
         │           ┌──────────────────┐
         │           │ System shows      │
         │           │ notification banner│
         │           │ (sound = nil)     │
         │           └────────┬─────────┘
         │                    │
         │                    ▼
         │           ┌──────────────────┐
         │           │ User taps         │
         │           │ notification      │
         │           └────────┬─────────┘
         │                    │
         ▼                    ▼
┌──────────────────────────────────────┐
│   willPresent / didReceive callback  │
│   Extract userInfo:                  │
│   - volume (Float)                   │
│   - soundName (String)               │
│   - isFadeIn (Bool)                  │
│   - fadeInDuration (Double)          │
│   - isVibrate (Bool)                 │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│   Configure AVAudioSession           │
│   - category: .playback              │
│   - options: .mixWithOthers          │
│   - setActive(true)                  │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│   Create AVAudioPlayer               │
│   - Load audio file (soundName)       │
│   - numberOfLoops = -1 (loop)        │
│   - volume = alarm.volume ← CORE     │
└──────────────────┬───────────────────┘
                   │
          ┌────────┴────────┐
          │                 │
    [isFadeIn = true]  [isFadeIn = false]
          │                 │
          ▼                 ▼
┌──────────────────┐ ┌──────────────────┐
│ player.volume = 0│ │ player.volume =  │
│ player.play()    │ │  alarm.volume    │
│ Timer gradually  │ │ player.play()    │
│ increases volume │ │                  │
└────────┬─────────┘ └────────┬─────────┘
         │                     │
         └──────────┬──────────┘
                    │
                    ▼
┌──────────────────────────────────────┐
│   Display full-screen ringing UI     │
│   - Alarm label                      │
│   - Current time                     │
│   - Volume indicator                 │
│   - [STOP] button                    │
│   - [SNOOZE] button (if enabled)     │
└──────────────────┬───────────────────┘
                   │
          ┌────────┴────────┐
          │                 │
    [User taps STOP]  [User taps SNOOZE]
          │                 │
          ▼                 ▼
┌──────────────────┐ ┌──────────────────┐
│ audioPlayer.stop │ │ Fade out volume  │
│ isPlaying = false│ │ → Reschedule      │
│ Reschedule next  │ │ (snooze minutes) │
└──────────────────┘ └──────────────────┘
```

### 7.2 Volume Adjustment Interaction Flow

```
[User adds/edits alarm]
      │
      ▼
┌──────────────────┐
│ Set alarm time    │
│ Set label/category│
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────────┐
│ Volume Setting Area               │
│                                  │
│  Volume Slider (0% ─────── 100%) │
│  Drag to adjust / tap preset     │
│                                  │
│  Preset buttons:                 │
│  [Whisper] [Gentle] [Moderate]   │
│  [Loud]    [Max]                 │
│                                  │
│  Fade-in mode toggle             │
│  Fade-in duration: [5s] [10s] [30s]│
│                                  │
│  [Preview] ← Plays 3s at current │
└──────────────────┬───────────────┘
                   │
                   ▼
┌──────────────────┐
│ Select ringtone   │
│ - Built-in list   │
│ - Import from library│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Select vibration  │
│ - Default         │
│ - Heartbeat       │
│ - Emergency       │
│ - None            │
└────────┬─────────┘
         │
         ▼
[Save alarm → CoreData + Schedule notification]
```

---

## 8. User Flow Diagrams

### 8.1 First-Time User Flow

```
[Download from App Store]
      │
      ▼
┌──────────────────┐
│ Launch App        │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     ┌──────────────────┐
│ Request notification│──→│ User denied?      │
│ permission         │    │ → Show guide popup│
└────────┬─────────┘    │ → Jump to Settings│
         │               └──────────────────┘
         ▼
┌──────────────────┐
│ Brief Onboarding  │
│ (3-page swipe)    │
│ 1. "Independent volume per alarm"│
│ 2. "Drag slider, fine control"  │
│ 3. "Workdays loud, weekends gentle"│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Main screen (empty)│
│ "Add your first alarm"│
└────────┬─────────┘
         │
         ▼
[Tap "+" → Add alarm]
```

### 8.2 Daily Usage Flow

```
┌──────────────────────────────────────────────────────┐
│                    Daily Usage Main Flow              │
└──────────────────────────────────────────────────────┘

[Open App] ─→ [Alarm List Main Screen]
                  │
    ┌─────────────┼─────────────┐
    │             │             │
    ▼             ▼             ▼
[Add Alarm]   [Edit Alarm]    [Quick Toggle]
    │             │             │
    ▼             ▼             ▼
Set time     Modify settings  On/Off toggle
    │             │             │
    ▼             ▼             │
Set volume ←CORE  Modify volume │
    │             │             │
    ▼             ▼             │
Select ringtone  Select ringtone│
    │             │             │
    ▼             ▼             ▼
[Save] ───→ [Alarm List Updates] ←── [Auto reschedule]
```

### 8.3 Alarm Ringing Flow

```
[Alarm time reached]
      │
      ▼
┌──────────────────────────────────┐
│        Full-Screen Ringing UI     │
│                                  │
│        7:00 AM                   │
│        "Work - Monday"           │
│                                  │
│    Volume: ████████░░░ 80%       │ ← Volume indicator
│                                  │
│   ┌──────────┐  ┌──────────┐    │
│   │  STOP    │  │  SNOOZE  │    │
│   │          │  │  (9 min) │    │
│   └──────────┘  └──────────┘    │
│                                  │
│   Slide up for more options      │
└──────────────────────────────────┘
      │                  │
[Tap STOP]         [Tap SNOOZE]
      │                  │
      ▼                  ▼
[Stop audio]        [Fade out audio]
[Close UI]          [Retrigger in 9 min]
[Return to main]    [Update countdown]
```

---

## 9. UI Design Guidelines (US Market)

### 9.1 Design Principles

| Principle | Description | Implementation |
|------|------|----------|
| **Simplicity** | US users prefer simple and intuitive | One core task per screen |
| **Control** | Give users a sense of control | Volume slider + preset buttons |
| **Feedback** | Immediate visual/audio feedback | Real-time preview on slider drag |
| **Consistency** | Match iOS design language | Follow Human Interface Guidelines |
| **Accessibility** | Accessible design | VoiceOver + Dynamic Type |

### 9.2 Color Scheme

```
Primary Color: #007AFF (iOS Blue)
  → Used for: Primary buttons, slider fill, toggles

Secondary Color: #5856D6 (Indigo)
  → Used for: Category tags, fade-in mode indicator

Volume Gradient Colors:
  Low volume: #00C7BE (Teal)
  Medium volume: #007AFF (Blue)
  High volume: #FF9500 (Orange)
  Maximum volume: #FF3B30 (Red)

Background Colors:
  Light mode: #F2F2F7 (systemGroupedBackground)
  Dark mode: #000000 (pure black - better for alarm app)

Card Colors:
  Light mode: #FFFFFF
  Dark mode: #1C1C1E

Text Colors:
  Primary text: #000000 / #FFFFFF
  Secondary text: #8E8E93 (secondaryLabel)
  Time display: .systemFont(size: 48, weight: .light, design: .rounded)
```

### 9.3 Typography Standards

| Usage | Font | Size | Weight |
|------|------|------|------|
| Alarm time | SF Pro Rounded | 48pt | Light |
| Alarm label | SF Pro | 17pt | Regular |
| Volume percentage | SF Pro | 15pt | Semibold |
| Category title | SF Pro | 13pt | Medium |
| Preset buttons | SF Pro | 11pt | Regular |
| Secondary text | SF Pro | 12pt | Regular |

### 9.4 Main Screen Design (Wireframe)

```
┌─────────────────────────────────────┐
│  AlarmTune              [Settings][+]│ ← Navigation Bar
├─────────────────────────────────────┤
│                                     │
│  Next alarm: 6:30 AM (in 7h 23m)   │ ← Next alarm indicator
│                                     │
├─────────────────────────────────────┤
│  Work                               │ ← Category header
│  ┌─────────────────────────────────┐│
│  │ 6:30 AM                [Toggle] ││ ← Time + toggle
│  │ Weekday    Volume: ████████░ 80%││ ← Repeat days + volume
│  └─────────────────────────────────┘│
│  ┌─────────────────────────────────┐│
│  │ 8:00 AM                [Toggle] ││
│  │ Mon Wed Fri Volume: ████░░░ 40% ││
│  └─────────────────────────────────┘│
│                                     │
│  Weekend                            │
│  ┌─────────────────────────────────┐│
│  │ 9:00 AM                [Toggle] ││ ← OFF state (gray)
│  │ Sat Sun    Volume: ██░░░░░ 20% ││
│  └─────────────────────────────────┘│
│                                     │
│  Nap                                │
│  ┌─────────────────────────────────┐│
│  │ 2:00 PM                [Toggle] ││
│  │ Today only Volume: █░░░░░░ 15% ││
│  └─────────────────────────────────┘│
│                                     │
└─────────────────────────────────────┘
```

### 9.5 Add Alarm Screen Design (Wireframe)

```
┌─────────────────────────────────────┐
│  ← Cancel              Save        │
├─────────────────────────────────────┤
│                                     │
│          ┌─────────────┐            │
│          │   7 : 30    │            │ ← Time picker
│          │     AM      │            │
│          └─────────────┘            │
│                                     │
│  Label                              │
│  ┌─────────────────────────────────┐│
│  │ Work Morning                    ││
│  └─────────────────────────────────┘│
│                                     │
│  Repeat                             │
│  [S] [M] [T] [W] [T] [F] [S]      │ ← Day picker
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Volume                         80% │ ← Core feature area
│  ┌─────────────────────────────────┐│
│  │ ━━━━━━━━━━━━━━━━━━━━━━●━━━━━━ ││ ← Volume slider
│  └─────────────────────────────────┘│
│                                     │
│  [Whisper][Gentle][Moderate]        │ ← Preset buttons
│  [Loud]   [Max]                    │
│                                     │
│  Fade-in  [5s ▼]                   │ ← Fade-in option
│  Vibrate                           │ ← Vibration option
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Sound                   Classic  ▶│ ← Ringtone picker
│  Category                     Work ▶│ ← Category picker
│  Color                        Blue ▶│ ← Color picker
│                                     │
│           [ Preview Sound ]         │ ← Preview button
│                                     │
└─────────────────────────────────────┘
```

### 9.6 2026 US Market UI Trends Adaptation

| Trend | AlarmTune Implementation |
|------|--------------|
| **Dark Mode First** | Default dark theme, pure black background (#000000), battery saving + comfortable for alarm scenarios |
| **Large Rounded Cards** | 16pt rounded corners, consistent with iOS system style |
| **SF Symbols** | All icons use SF Symbols, maintaining system consistency |
| **Dynamic Island Adaptation** | Display status in Dynamic Island when alarm rings |
| **Widget Support** | Provide "Next Alarm" widget showing alarm time and volume |
| **Haptic Feedback** | Tactile feedback when dragging volume slider, different vibration intensity per volume level |
| **Live Activity** | Lock screen Live Activity when alarm rings |
| **Typography First** | Time display uses SF Pro Rounded 48pt Light, matching Apple design language |

---

## 10. Development Rules & Coding Standards

### 10.1 Module Principles

**Rule 1: Single Responsibility, High Cohesion, Low Coupling**

Each feature must be a separate module with clear naming and semantic file structure. This ensures easy maintenance and lookup in the future.

```
Example:
- VolumeSliderView.swift → Only handles volume slider UI
- AudioService.swift → Only handles audio playback and volume control
- AlarmScheduler.swift → Only handles notification scheduling
```

**Rule 2: Code Reuse, DRY Principle**

Reuse existing modules whenever possible. Abstract only when the "Rule of Three" is met (code is used in 3+ places). Follow the principle of minimal code.

```
Example:
- VolumeSliderView is a reusable component used in both AddAlarmView and EditAlarmView
- AudioService is a singleton used across the entire app
- Do NOT abstract until you see the same pattern 3 times
```

**Rule 3: Clean Refactoring**

When new code replaces old code or modules:
1. Mark old code as deprecated
2. Verify no impact on existing functionality
3. Delete deprecated code
4. Document cleanup scope in commit messages

```
Example commit message:
"refactor: Replace legacy VolumeControl with VolumeSliderView component
- Removed: VolumeControl.swift (deprecated)
- Added: VolumeSliderView.swift
- Updated: AddEditAlarmView.swift, RingingView.swift
- Cleanup: Removed 3 duplicate volume slider implementations"
```

**Rule 4: GitHub Project Integration**

Use open-source GitHub projects as base for secondary development and integration. This reduces time, reduces errors, and creates a stronger, more competitive software product.

```
Integration Strategy:
1. FadeInAlarm → Core volume control logic (AVAudioPlayer)
2. stalarm-swiftui → MVVM architecture + CoreData persistence
3. Alarm-ios-swift → Alarm CRUD logic + UI patterns
4. RedMadRobot/Alarm-Clock → Visual design reference
```

**Rule 5: Native Apple Code Priority**

Prioritize using Apple native system code. If open-source projects are not native, convert them to native Apple code.

```
Conversion Examples:
- UIKit → SwiftUI
- NotificationCenter → Combine/ObservableObject
- Manual layout → SwiftUI declarative layout
- UserDefaults for complex data → CoreData
```

### 10.2 Naming Conventions

```swift
// Classes/Structs: PascalCase           → AlarmItem, AudioService
// Functions/Methods: camelCase          → playAlarm(), setVolume()
// Variables/Properties: camelCase       → volume, soundName
// Constants: PascalCase                 → VolumePreset, DefaultVolume
// Protocols: PascalCase + able/Protocol → AlarmPlayable
// Enums: PascalCase                     → VolumeLevel

// File naming: PascalCase.swift         → AlarmItem.swift, AudioService.swift
```

### 10.3 Comment Standards

```swift
/// Single-line documentation — for public APIs
/// - Parameter volume: Volume value, range 0.0-1.0
/// - Returns: Whether audio played successfully

/*
  Multi-line comments — for complex logic
  Include algorithm steps or important notes
*/

// MARK: - Organizational markers
// Use MARK: - to group code sections
// Examples:
// MARK: - Public API
// MARK: - Private Helpers
// MARK: - Lifecycle
```

### 10.4 Error Handling

```swift
enum AlarmError: LocalizedError {
    case audioSessionNotConfigured
    case soundFileNotFound(String)
    case notificationPermissionDenied
    
    var errorDescription: String? {
        switch self {
        case .audioSessionNotConfigured:
            return "Audio session is not configured properly"
        case .soundFileNotFound(let name):
            return "Sound file '\(name)' not found"
        case .notificationPermissionDenied:
            return "Notification permission is required for alarms"
        }
    }
}
```

### 10.5 CoreData Writing Rules

```swift
// CoreData Stack must use NSPersistentContainer
// Use @FetchRequest in SwiftUI to fetch data
// Use BackgroundContext for batch operations

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "AlarmTune")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData failed: \(error)")
            }
        }
    }
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    func saveContext() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            print("CoreData save failed: \(error)")
        }
    }
}
```

### 10.6 Background Mode Configuration

```xml
<!-- Info.plist Required Configuration -->
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>  <!-- Background audio playback -->
</array>

<!-- Supported Audio Formats -->
<!-- .caf (recommended, iOS native) -->
<!-- .mp3 (good compatibility) -->
<!-- .m4a (AAC, good quality) -->
<!-- .wav (lossless, large file) -->

<!-- Notification Permission Description -->
<key>NSUserNotificationsUsageDescription</key>
<string>AlarmTune needs notifications to play your alarms at the right time.</string>
```

### 10.7 Git Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>

Types:
- feat: New feature
- fix: Bug fix
- refactor: Code refactoring
- docs: Documentation changes
- test: Test additions/changes
- chore: Build process or auxiliary tool changes
- style: Code style changes (formatting, no logic changes)
- perf: Performance improvements

Examples:
feat(audio): add independent volume control for alarms
fix(notification): resolve alarm not firing in background
refactor(coredata): extract alarm storage into dedicated service
docs(readme): update installation instructions
test(audio): add unit tests for volume fade-in logic
```

---

## 11. MVP Iteration Plan

### Phase 1: Core Alarm Functionality (Weeks 1-2)

**Objective**: Deliver a working alarm app with independent volume control

**Features**:
- Add/Edit/Delete alarms with time picker
- Independent volume slider (0-100%) per alarm
- 5 volume presets (Whisper, Gentle, Moderate, Loud, Max)
- 5 built-in alarm sounds
- Fade-in volume option (configurable duration)
- Vibration toggle
- Alarm enable/disable toggle
- Basic alarm list view (sorted by time)
- Full-screen ringing UI with STOP/SNOOZE buttons
- Background audio playback
- Notification scheduling via UserNotifications

**Technical Tasks**:
1. Setup Xcode project with iOS 17+ deployment target
2. Configure CoreData stack with AlarmItem entity
3. Implement AudioService with AVAudioPlayer
4. Build AlarmScheduler for notification management
5. Create AlarmListView with SwiftUI
6. Implement AlarmEditView with volume controls
7. Configure Info.plist for background audio mode
8. Integrate AppDelegate for notification callbacks

**Acceptance Criteria**:
- [ ] User can create alarm with custom volume
- [ ] Alarm fires at scheduled time with correct volume
- [ ] Volume is independent from system volume
- [ ] Fade-in works smoothly over configured duration
- [ ] Alarm plays in background (app closed)
- [ ] STOP button silences alarm immediately
- [ ] SNOOZE button reschedules alarm (default 5 min)
- [ ] All alarms persist across app restarts

---

### Phase 2: Enhanced User Experience (Weeks 3-4)

**Objective**: Improve usability and add quality-of-life features

**Features**:
- Alarm categories (Work, Weekend, Important, Nap, Medication)
- Custom alarm labels
- Smart snooze (progressive delay: 5, 10, 15 min)
- Shake to snooze gesture
- Volume preview button (test volume before saving)
- Sound picker with preview
- Haptic feedback on interactions
- Dark mode optimization
- Empty state illustration
- Next alarm indicator on home screen

**Technical Tasks**:
1. Add category field to CoreData model (migration)
2. Implement sound picker with AVAudioPlayer preview
3. Add haptic feedback using UINotificationFeedbackGenerator
4. Create category-based grouping in AlarmListView
5. Implement shake detection via motion events
6. Add smart snooze logic with progressive delays
7. Design empty state view with SF Symbols
8. Calculate and display next alarm time

**Acceptance Criteria**:
- [ ] Alarms can be categorized and grouped
- [ ] User can preview sounds and volume before saving
- [ ] Shake gesture triggers snooze
- [ ] Haptic feedback feels responsive
- [ ] Next alarm displays correctly on home screen
- [ ] Dark mode UI passes accessibility contrast ratios

---

### Phase 3: Advanced Features (Weeks 5-6)

**Objective**: Differentiate from competitors with premium features

**Features**:
- Sleep schedule integration (bedtime reminder)
- Weather-based volume adjustment (rainy days = louder)
- Siri shortcuts via AppIntents
- Home Screen Widgets (iOS 17)
- Lock Screen Widgets
- Export/Import alarm backups
- iCloud sync (optional)
- Custom sound import (from Files app)
- Math puzzle to dismiss alarm
- Gradual wake-up (light simulation via screen brightness)

**Technical Tasks**:
1. Implement AppIntents for Siri integration
2. Create WidgetExtension for Home/Lock screen
3. Add weather API integration (OpenWeatherMap)
4. Build backup/restore with JSON serialization
5. Implement CloudKit sync for iCloud
6. Add UIDocumentPicker for custom sound import
7. Create math puzzle dismissal view
8. Implement screen brightness animation for wake-up

**Acceptance Criteria**:
- [ ] Siri can toggle alarms via voice command
- [ ] Widgets display next alarm correctly
- [ ] Weather-based volume adjusts automatically
- [ ] Backup/restore preserves all alarm data
- [ ] Custom sounds play correctly
- [ ] Math puzzle blocks accidental dismissals
- [ ] Gradual wake-up simulates sunrise effect

---

### Phase 4: Polish & Launch Prep (Weeks 7-8)

**Objective**: Prepare for App Store submission

**Features**:
- Onboarding flow (3 screens)
- Settings page (default volume, default snooze, sound library)
- Analytics integration (privacy-compliant, opt-in)
- App Store screenshots (6.7", 6.1", iPad)
- Privacy policy page
- Terms of service page
- Rate app prompt (SKStoreReviewController)
- Localization readiness (structure for future languages)

**Technical Tasks**:
1. Design onboarding carousel with SwiftUI
2. Create SettingsView with all configurable options
3. Integrate privacy-compliant analytics (TelemetryDeck)
4. Generate App Store screenshots via Simulator
5. Write privacy policy and terms of service
6. Implement SKStoreReviewController trigger logic
7. Add NSLocalizedString wrappers for all user-facing text
8. Perform final accessibility audit

**Acceptance Criteria**:
- [ ] Onboarding explains core value proposition
- [ ] Settings persist correctly
- [ ] Analytics only collects anonymized data
- [ ] Screenshots meet App Store requirements
- [ ] Privacy policy is accessible from app
- [ ] Rate prompt appears after 3 successful alarm firings
- [ ] All text is localizable (no hardcoded strings)

---

## 12. Monetization Strategy

### Free Tier Features
- Up to 5 alarms
- 5 built-in sounds
- Basic volume control (slider + 5 presets)
- Fade-in/fade-out
- Vibration toggle
- Standard snooze

### Premium Tier ($4.99 one-time or $1.99/month)
- Unlimited alarms
- 20+ premium sounds
- Custom sound import
- Alarm categories
- Smart snooze
- Siri shortcuts
- Home/Lock screen widgets
- Weather-based volume
- Math puzzle dismissal
- iCloud sync
- Backup/restore
- Priority support

### Implementation Approach
- Use StoreKit 2 for in-app purchases
- Implement as non-consumable (one-time) or auto-renewable subscription
- Use RevenueCat for subscription management (recommended)
- Offer 7-day free trial for subscription option
- Premium features unlock immediately after purchase verification

### Pricing Rationale
- US market average for utility apps: $2.99-$9.99 one-time
- Competitive analysis shows:
  - Alarmy: Free with ads, $4.99 premium
  - Sleep Cycle: Free trial, $39.99/year
  - AutoSleep: $6.99 one-time
- Position at $4.99 one-time for competitive advantage
- Subscription option for users who prefer lower upfront cost

---

## 13. App Store Review Compliance

### 13.1 Background Audio Requirements

Apple requires legitimate use of background audio mode. To comply:

**Must Do**:
- Declare `UIBackgroundModes` with `audio` in Info.plist
- Actually play audio in background (not just declare it)
- Use `.playback` category for AVAudioSession
- Handle audio session interruptions properly
- Stop audio playback when alarm is dismissed

**Must Not Do**:
- Use background audio for non-audio purposes
- Continue playing audio after user dismisses alarm
- Play silent audio to keep app alive in background

**Verification**:
- Test with app in background for 30+ minutes
- Verify audio plays correctly when screen is locked
- Ensure audio stops immediately on STOP button tap

### 13.2 Notification Guidelines

**Must Do**:
- Request notification permission at appropriate time (not on first launch)
- Provide clear explanation via `NSUserNotificationsUsageDescription`
- Handle permission denial gracefully (show settings prompt)
- Use local notifications only (no remote notifications for alarms)

**Must Not Do**:
- Spam notifications
- Send notifications without user consent
- Use notifications for advertising

### 13.3 Privacy Requirements

**Data Collection Disclosure**:
- If using analytics, disclose in App Privacy section
- Mark data as "Not Linked to User" if anonymized
- Provide privacy policy URL
- Offer opt-in for analytics (default: off)

**Required Privacy Labels**:
- Data Used to Track You: None (if no tracking)
- Data Linked to You: None (if no account system)
- Data Not Linked to You: Usage Data (if analytics enabled)

### 13.4 Accessibility Requirements

**Must Support**:
- Dynamic Type (all text scales correctly)
- VoiceOver (all interactive elements have labels)
- Switch Control (all actions accessible)
- Reduce Motion (disable animations if preferred)
- Color contrast ratios (WCAG AA minimum 4.5:1)

**Testing**:
- Run Accessibility Inspector in Xcode
- Test with VoiceOver enabled
- Test with Dynamic Type at largest size
- Verify all buttons have meaningful accessibility labels

### 13.5 Common Rejection Reasons to Avoid

1. **Crash on launch**: Test on physical device before submission
2. **Incomplete features**: Remove placeholder UI or mark as "Coming Soon"
3. **Broken links**: Verify all URLs in app are valid
4. **Missing metadata**: Fill all required App Store Connect fields
5. **IPv6 support**: Ensure app works on IPv6-only networks (default for Apple review)
6. **Account deletion**: If accounts are supported, provide in-app deletion option
7. **Misleading description**: App description must match actual functionality

---

## 14. Testing & Acceptance Criteria

### 14.1 Unit Testing Strategy

**Test Targets**:
- `AlarmTuneTests`: Unit tests for business logic
- `AlarmTuneUITests`: UI automation tests

**Core Test Cases**:

```swift
// AudioService Tests
func testVolumePresetValues() {
    XCTAssertEqual(AlarmItem.VolumePreset.whisper.volumeValue, 0.15)
    XCTAssertEqual(AlarmItem.VolumePreset.gentle.volumeValue, 0.30)
    XCTAssertEqual(AlarmItem.VolumePreset.moderate.volumeValue, 0.55)
    XCTAssertEqual(AlarmItem.VolumePreset.loud.volumeValue, 0.80)
    XCTAssertEqual(AlarmItem.VolumePreset.maximum.volumeValue, 1.0)
}

func testAudioServiceSingleton() {
    let instance1 = AudioService.shared
    let instance2 = AudioService.shared
    XCTAssertTrue(instance1 === instance2)
}

// AlarmScheduler Tests
func testScheduleAlarmCreatesNotification() {
    let alarm = AlarmItem(context: PersistenceController.shared.viewContext)
    alarm.fireDate = Date().addingTimeInterval(60)
    alarm.volume = 0.5
    alarm.soundName = "default"
    
    AlarmScheduler.shared.scheduleAlarm(alarm)
    
    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
        XCTAssertEqual(requests.count, 1)
    }
}

func testCancelAlarmRemovesNotification() {
    let alarm = AlarmItem(context: PersistenceController.shared.viewContext)
    alarm.fireDate = Date().addingTimeInterval(60)
    
    AlarmScheduler.shared.scheduleAlarm(alarm)
    AlarmScheduler.shared.cancelAlarm(alarm)
    
    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
        XCTAssertEqual(requests.count, 0)
    }
}

// CoreData Tests
func testAlarmPersistence() {
    let context = PersistenceController.shared.viewContext
    let alarm = AlarmItem(context: context)
    alarm.fireDate = Date()
    alarm.volume = 0.7
    alarm.label = "Test Alarm"
    
    PersistenceController.shared.saveContext()
    
    let fetchRequest: NSFetchRequest<AlarmItem> = AlarmItem.fetchRequest()
    let results = try? context.fetch(fetchRequest)
    
    XCTAssertEqual(results?.count, 1)
    XCTAssertEqual(results?.first?.label, "Test Alarm")
}
```

### 14.2 UI Testing Strategy

```swift
// UI Automation Tests
func testAddAlarmFlow() {
    let app = XCUIApplication()
    app.launch()
    
    // Tap add button
    app.navigationBars["AlarmTune"].buttons["Add"].tap()
    
    // Set time
    app.datePickers.adjust(toPickerWheelValue: "7")
    app.datePickers.adjust(toPickerWheelValue: "00")
    app.datePickers.adjust(toPickerWheelValue: "AM")
    
    // Set volume
    let slider = app.sliders["Volume"]
    slider.adjust(toNormalizedSliderPosition: 0.5)
    
    // Save
    app.navigationBars["Add Alarm"].buttons["Save"].tap()
    
    // Verify alarm appears in list
    XCTAssertTrue(app.staticTexts["7:00 AM"].exists)
}

func testAlarmToggleFlow() {
    let app = XCUIApplication()
    app.launch()
    
    // Toggle alarm off
    app.switches["Toggle Alarm"].tap()
    XCTAssertFalse(app.switches["Toggle Alarm"].value as! Bool == 1)
    
    // Toggle alarm on
    app.switches["Toggle Alarm"].tap()
    XCTAssertTrue(app.switches["Toggle Alarm"].value as! Bool == 1)
}
```

### 14.3 Manual Testing Checklist

**Functional Testing**:
- [ ] Create alarm with default settings
- [ ] Create alarm with custom volume (test 0%, 25%, 50%, 75%, 100%)
- [ ] Create alarm with fade-in enabled
- [ ] Create alarm with vibration enabled
- [ ] Edit existing alarm (change time, volume, sound)
- [ ] Delete alarm (verify notification removed)
- [ ] Toggle alarm on/off (verify notification scheduled/cancelled)
- [ ] Test alarm fires at correct time (set alarm 1 min in future)
- [ ] Test STOP button silences alarm
- [ ] Test SNOOZE button reschedules alarm
- [ ] Test alarm fires when app is in background
- [ ] Test alarm fires when app is killed
- [ ] Test alarm fires when device is locked
- [ ] Test alarm fires when device is in Do Not Disturb mode
- [ ] Test multiple alarms fire in sequence
- [ ] Test alarm persists after app restart
- [ ] Test alarm persists after device restart

**Edge Cases**:
- [ ] Create alarm with volume at 0% (should still fire, just silent)
- [ ] Create alarm with volume at 100% (should not distort)
- [ ] Create alarm for time in the past (should schedule for next day)
- [ ] Create 50+ alarms (test performance)
- [ ] Test with no notification permission (show prompt)
- [ ] Test with no audio files (fallback to default sound)
- [ ] Test with low storage space (handle gracefully)
- [ ] Test with airplane mode enabled (alarms should still fire)

**Device Testing**:
- [ ] iPhone 15 Pro Max (iOS 17)
- [ ] iPhone 15 (iOS 17)
- [ ] iPhone 14 (iOS 17)
- [ ] iPhone SE 3rd gen (iOS 17)
- [ ] iPad Air (iOS 17, if supported)

**Accessibility Testing**:
- [ ] VoiceOver reads all elements correctly
- [ ] Dynamic Type scales all text appropriately
- [ ] Color contrast meets WCAG AA standards
- [ ] Switch Control can navigate all screens
- [ ] Reduce Motion disables unnecessary animations

### 14.4 Performance Benchmarks

**Metrics**:
- App launch time: < 2 seconds (cold start)
- Alarm list scroll: 60 FPS (no dropped frames)
- Alarm creation: < 500ms (from tap to saved)
- Audio playback latency: < 100ms (from notification to sound)
- Memory usage: < 100 MB (idle), < 150 MB (ringing)
- Battery impact: < 1% per hour (background mode)

**Profiling Tools**:
- Instruments (Time Profiler, Allocations, Leaks)
- Xcode Debug Navigator (CPU, Memory, Energy)
- MetricKit (production performance monitoring)

### 14.5 UI Acceptance Standards

**Visual Consistency**:
- [ ] All colors use design system tokens (no hardcoded hex values)
- [ ] All spacing uses consistent scale (4pt, 8pt, 12pt, 16pt, 24pt, 32pt)
- [ ] All corner radii follow standard (8pt for cards, 12pt for modals)
- [ ] All typography uses Dynamic Type styles (no fixed font sizes)
- [ ] All icons use SF Symbols (no custom images unless necessary)

**Interaction Quality**:
- [ ] All buttons provide haptic feedback
- [ ] All transitions animate smoothly (0.3s duration)
- [ ] All loading states show progress indicators
- [ ] All error states display clear messages
- [ ] All empty states provide actionable guidance

**Dark Mode**:
- [ ] All backgrounds adapt to light/dark mode
- [ ] All text maintains contrast in both modes
- [ ] All images/icons have dark mode variants if needed
- [ ] No hardcoded `.white` or `.black` colors (use `.primary`, `.secondary`)

---

## 15. Build & Deployment Pipeline

### 15.1 Xcode Build Configuration

**Debug Configuration**:
- Optimization: None [-Onone]
- Debug symbols: Yes
- Enable assertions: Yes
- Preprocessor macros: DEBUG=1

**Release Configuration**:
- Optimization: Fastest, Smallest [-Os]
- Debug symbols: No
- Enable assertions: No
- Strip linked product: Yes
- Generate debug symbols: Yes (for crash symbolication)

### 15.2 CI/CD Setup (Optional)

**GitHub Actions Workflow**:

```yaml
name: iOS CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode_15.0.app
    
    - name: Build
      run: |
        xcodebuild build \
          -project AlarmTune.xcodeproj \
          -scheme AlarmTune \
          -sdk iphonesimulator \
          -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
          CODE_SIGN_IDENTITY="" \
          CODE_SIGNING_REQUIRED=NO
    
    - name: Test
      run: |
        xcodebuild test \
          -project AlarmTune.xcodeproj \
          -scheme AlarmTune \
          -sdk iphonesimulator \
          -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
          CODE_SIGN_IDENTITY="" \
          CODE_SIGNING_REQUIRED=NO
```

### 15.3 App Store Submission Checklist

**Pre-Submission**:
- [ ] All features tested and working
- [ ] No placeholder UI or "Coming Soon" text
- [ ] Privacy policy URL is valid
- [ ] Support URL is valid
- [ ] App icon meets all size requirements
- [ ] Screenshots for all required device sizes
- [ ] App description is accurate and complete
- [ ] Keywords are optimized (100 character limit)
- [ ] Age rating is appropriate (4+ for utility apps)
- [ ] In-app purchases configured (if applicable)

**Submission**:
- [ ] Build uploaded via Xcode or Transporter
- [ ] TestFlight beta testing completed (internal + external)
- [ ] App Review information provided (demo account if needed)
- [ ] Contact information is current
- [ ] Export compliance documentation completed

**Post-Submission**:
- [ ] Monitor review status in App Store Connect
- [ ] Respond to review feedback within 24 hours
- [ ] Prepare marketing materials for launch
- [ ] Set up analytics dashboard
- [ ] Monitor crash reports after launch

---

## 16. GitHub Project Integration Guide

### 16.1 FadeInAlarm Integration

**Source**: `github-projects/FadeInAlarm`

**What to Extract**:
- Volume fade-in algorithm (Timer-based gradual increase)
- Audio player lifecycle management
- Phase-based alarm state machine

**How to Integrate**:
1. Copy fade-in logic from `📻AlarmPlayer.swift` into `AudioService.swift`
2. Adapt phase management from `AppModel.swift` into `AlarmViewModel.swift`
3. Convert any UIKit components to SwiftUI equivalents

**Code Mapping**:
```
FadeInAlarm → AlarmTune
AppModel → AlarmViewModel
📻AlarmPlayer → AudioService
🎛VolumeControl → VolumeSliderView
ContentView → AlarmListView + AlarmEditView
```

### 16.2 stalarm-swiftui Integration

**Source**: `github-projects/stalarm-swiftui`

**What to Extract**:
- CoreData model structure (Alarm entity)
- MVVM architecture patterns
- Notification scheduling logic
- AlarmStorage singleton pattern

**How to Integrate**:
1. Adapt CoreData model from `Stalarm.xcdatamodeld` into `AlarmTune.xcdatamodeld`
2. Copy CRUD operations from `AlarmStorage.swift` into `PersistenceController.swift`
3. Adapt notification logic from `NotificationManager.swift` into `AlarmScheduler.swift`

**Code Mapping**:
```
stalarm-swiftui → AlarmTune
Alarm (CoreData entity) → AlarmItem
AlarmStorage → PersistenceController
NotificationManager → AlarmScheduler
AlarmViewModel → AlarmViewModel (merge with FadeInAlarm's AppModel)
```

### 16.3 Alarm-ios-swift Integration

**Source**: `github-projects/Alarm-ios-swift`

**What to Extract**:
- Alarm time calculation logic
- Recurring alarm patterns (daily, weekdays, weekends)
- Alarm list sorting and filtering

**How to Integrate**:
1. Adapt recurring alarm logic into `AlarmItem+Extensions.swift`
2. Copy time calculation utilities into `DateExtensions.swift`
3. Integrate sorting logic into `AlarmListView`

### 16.4 RedMadRobot/Alarm-Clock Integration

**Source**: `github-projects/Alarm-Clock`

**What to Extract**:
- UI design patterns (clean, minimal aesthetic)
- Alarm card layout
- Time picker customization

**How to Integrate**:
1. Adapt alarm card design into `AlarmRowView.swift`
2. Copy time picker styling into custom SwiftUI component
3. Use design inspiration for overall app aesthetic

---

## 17. File Structure Reference

```
AlarmTune/
├── AlarmTune/
│   ├── AlarmTuneApp.swift              # App entry point
│   ├── AppDelegate.swift               # Notification callbacks
│   │
│   ├── Models/
│   │   ├── AlarmItem+CoreDataClass.swift
│   │   ├── AlarmItem+CoreDataProperties.swift
│   │   └── AlarmItem+Extensions.swift  # VolumePreset, computed properties
│   │
│   ├── Services/
│   │   ├── AudioService.swift          # AVAudioPlayer, volume control
│   │   ├── AlarmScheduler.swift        # UserNotifications scheduling
│   │   └── HapticService.swift         # Haptic feedback wrapper
│   │
│   ├── Persistence/
│   │   └── PersistenceController.swift # CoreData stack
│   │
│   ├── ViewModels/
│   │   └── AlarmViewModel.swift        # ObservableObject for alarms
│   │
│   ├── Views/
│   │   ├── AlarmListView.swift         # Main screen
│   │   ├── AlarmEditView.swift         # Add/Edit alarm
│   │   ├── AlarmRingView.swift         # Full-screen ringing UI
│   │   ├── VolumeSliderView.swift      # Volume control component
│   │   ├── SoundPickerView.swift       # Sound selection
│   │   └── Components/
│   │       ├── AlarmRowView.swift      # Single alarm card
│   │       ├── EmptyStateView.swift    # No alarms illustration
│   │       └── NextAlarmIndicator.swift # Next alarm display
│   │
│   ├── Intents/
│   │   └── ToggleAlarmIntent.swift     # Siri shortcut
│   │
│   ├── Resources/
│   │   ├── Sounds/                     # Alarm sound files (.caf)
│   │   │   ├── gentle_morning.caf
│   │   │   ├── digital_beep.caf
│   │   │   ├── nature_chirp.caf
│   │   │   ├── soft_bell.caf
│   │   │   └── classic_alarm.caf
│   │   └── Assets.xcassets/
│   │
│   └── Utilities/
│       ├── DateExtensions.swift
│       └── Constants.swift
│
├── AlarmTuneTests/
│   ├── AudioServiceTests.swift
│   ├── AlarmSchedulerTests.swift
│   └── PersistenceTests.swift
│
├── AlarmTuneUITests/
│   └── AlarmTuneUITests.swift
│
├── AlarmTuneWidget/                    # Widget extension
│   ├── AlarmTuneWidget.swift
│   └── TimelineProvider.swift
│
└── Info.plist                          # Background modes, permissions
```

---

## 18. Quick Reference: Key Implementation Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Architecture | MVVM | SwiftUI-native, testable, separates concerns |
| Data Persistence | CoreData + @FetchRequest | iOS-native, integrates with SwiftUI |
| Audio Playback | AVAudioPlayer | Supports independent volume, looping, fade-in |
| Alarm Scheduling | UserNotifications | System-level, works in background/killed state |
| Background Mode | UIBackgroundModes: audio | Required for alarm playback when app is backgrounded |
| Volume Control | Per-alarm Float (0.0-1.0) | Independent from system volume |
| UI Framework | SwiftUI | Modern, declarative, iOS 17+ |
| Minimum iOS | 17.0 | Access to latest SwiftUI features, WidgetKit, AppIntents |
| Siri Integration | AppIntents | iOS 17+ replacement for SiriKit |
| In-App Purchases | StoreKit 2 + RevenueCat | Modern API, subscription management |
| Analytics | TelemetryDeck (opt-in) | Privacy-compliant, no personal data |

---

## 19. Risk Mitigation

### Technical Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| iOS blocks background audio | Low | Critical | Test thoroughly; use system notifications as fallback |
| AVAudioPlayer fails in background | Medium | High | Configure audio session properly; test on physical devices |
| CoreData migration breaks existing data | Medium | High | Use lightweight migration; test migration paths |
| Notification permission denied | High | Medium | Graceful degradation; educate user on importance |
| App Store rejection for background audio | Low | High | Follow guidelines; document legitimate use case |

### Business Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Competitors add volume control | Medium | Medium | Build brand around this feature; continuous innovation |
| Low conversion to premium | High | Medium | Optimize onboarding; A/B test pricing |
| Negative reviews due to bugs | Medium | High | Thorough testing; rapid bug fix releases |
| Apple changes notification behavior | Low | High | Monitor WWDC; maintain fallback mechanisms |

---

## 20. Success Metrics

### Launch Metrics (First 30 Days)
- Downloads: 1,000+
- Retention (Day 7): 40%+
- Retention (Day 30): 25%+
- Average rating: 4.5+ stars
- Crash-free rate: 99.5%+

### Monetization Metrics (First 90 Days)
- Premium conversion rate: 5%+
- Monthly recurring revenue: $500+
- Customer acquisition cost: < $2.00
- Lifetime value: > $10.00

### Engagement Metrics (Ongoing)
- Daily active alarms per user: 2.5+
- Volume customization usage: 60%+
- Fade-in feature adoption: 40%+
- Widget installation rate: 20%+

---

*This document serves as the comprehensive operational guide for developing AlarmTune. All implementation decisions, code patterns, and architectural choices documented herein should be followed consistently throughout the development process. Updates to this document should be made as new requirements emerge or technical decisions evolve.*

```
<type>(<scope>): <subject>