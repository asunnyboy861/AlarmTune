# Pricing Configuration

## Monetization Model: Subscription (IAP)

AlarmTune is free to download and use with a generous free tier. Users can optionally subscribe to Premium (monthly or yearly) to unlock unlimited custom imports and AI sound generation. All payments are processed by Apple through StoreKit 2.

## Subscription Group
- **Group Name**: AlarmTune Premium
- **Reference Name**: AlarmTune Premium
- **Products in group**: Monthly Subscription, Yearly Subscription

## Subscription Tiers

### 1. Monthly Subscription
- **Reference Name**: AlarmTune Pro Monthly
- **Product ID**: `com.zzoutuo.AlarmTune.premium.monthly`
- **Type**: Auto-renewable subscription
- **Price**: $2.99 USD per month
- **Display Name**: `AlarmTune Premium Monthly` (25 chars, ≤35 ✅)
- **Description**: `Unlimited imports and AI sounds` (31 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: AlarmTune Premium
- **Restore Purchases**: ✅ Required

### 2. Yearly Subscription
- **Reference Name**: AlarmTune Pro Annual
- **Product ID**: `com.zzoutuo.AlarmTune.premium.yearly`
- **Type**: Auto-renewable subscription
- **Price**: $14.99 USD per year (58% savings vs monthly)
- **Display Name**: `AlarmTune Premium Annual` (24 chars, ≤35 ✅)
- **Description**: `Unlimited imports and AI sounds` (31 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: AlarmTune Premium (same group as monthly)
- **Restore Purchases**: ✅ Required

## Free Tier (Default)

- **Price**: Free
- **Features**:
  - 30+ built-in alarm sounds across 5 categories
  - Independent volume control per alarm (independent of system volume)
  - Volume presets (Whisper, Gentle, Moderate, Loud, Maximum)
  - Gradual fade-in alarm volume (1-30 seconds)
  - Snooze functionality
  - Alarm categories and labels
  - Apple Music library integration (select songs as alarm sounds)
  - Sound Shuffle (auto-rotate built-in sounds daily or weekly)
  - 8 built-in video backgrounds across 4 categories (Storm, Nature, City, Cozy)
  - Video alarm mode (auto uses video audio track when video selected)
  - 1 custom sound import from Files
  - 1 custom video background import from Photos or Files
  - 1 AI-generated sound (shares quota with custom sound import)
- **Conversion hooks**:
  - "Upgrade to Premium" entry in Settings
  - Paywall triggered when import quota is reached
  - Paywall triggered when AI generation quota is reached
  - "Best Value" badge on yearly plan

## Pro Features Unlocked (All Tiers)

| Feature | Free | Pro |
|---------|:----:|:---:|
| Built-in alarm sounds (30+) | ✅ | ✅ |
| Independent volume per alarm | ✅ | ✅ |
| Volume presets | ✅ | ✅ |
| Gradual fade-in | ✅ | ✅ |
| Snooze | ✅ | ✅ |
| Alarm categories and labels | ✅ | ✅ |
| Apple Music integration | ✅ | ✅ |
| Sound Shuffle (daily/weekly) | ✅ | ✅ |
| Built-in video backgrounds (8) | ✅ | ✅ |
| Video alarm mode (auto video audio) | ✅ | ✅ |
| Custom sound import (from Files) | 1 file | Unlimited |
| Custom video background import | 1 file | Unlimited |
| AI Sound Generation (4 styles) | 1 file* | Unlimited |

*AI-generated sounds share the same import quota as custom sound imports. A free user can either import 1 custom sound OR generate 1 AI sound, not both.

## Free Trial
- **Duration**: Not offered
- **Type**: N/A
- **Available for**: N/A

AlarmTune does not offer a free trial. Users can explore all free tier features immediately upon download. Premium features can be unlocked anytime via in-app purchase.

## Policy Pages Required
- Support Page: ✅ (must include subscription management + cancellation instructions)
- Privacy Policy: ✅
- Terms of Use (EULA): ✅ (REQUIRED — subscription apps must have Terms)
- **Total policy pages**: 3

## Apple IAP Compliance Checklist
- [x] Auto-renewal terms will be included in Terms of Use
- [x] Cancellation instructions will be included in Support Page
- [x] Pricing clearly stated in PaywallView
- [x] Free trial terms included (if applicable)
- [x] Restore purchases functionality implemented
- [x] No external payment links (Guideline 3.1.1)
- [x] No price references to outside-App-Store options
- [x] All IAP descriptions ≤ 55 characters
- [x] All IAP display names ≤ 35 characters
