# Deployment Guide

Complete guide for deploying Trading Cockpit to TestFlight and the App Store.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Build Configuration](#build-configuration)
- [Code Signing](#code-signing)
- [App Store Connect Setup](#app-store-connect-setup)
- [TestFlight Deployment](#testflight-deployment)
- [App Store Submission](#app-store-submission)
- [Post-Release](#post-release)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Accounts

- **Apple Developer Account** (Individual or Organization)
  - Cost: $99/year
  - Sign up: [developer.apple.com](https://developer.apple.com/programs/)

- **App Store Connect Access**
  - Automatic with Developer Account
  - Access: [appstoreconnect.apple.com](https://appstoreconnect.apple.com)

### Required Software

- **macOS 14.0+** (Sonoma or later)
- **Xcode 15.2+** with visionOS SDK
- **Apple Vision Pro** (for device testing)
- **fastlane** (optional but recommended)

### Required Certificates

- **Development Certificate**: For testing on devices
- **Distribution Certificate**: For App Store submission
- **Provisioning Profiles**: Development and Distribution

---

## Build Configuration

### 1. Update Version Number

Update version in `TradingCockpit.xcodeproj`:

**Manual Method:**
1. Open project in Xcode
2. Select project root → Target → General
3. Update **Version** (e.g., 1.0.0)
4. Update **Build** number (e.g., 1)

**Command Line Method:**
```bash
# Update version
agvtool new-marketing-version 1.0.0

# Update build number
agvtool next-version -all
```

### 2. Set Build Configuration

Create release configuration:

**Build Settings:**
- **Configuration**: Release
- **Optimization Level**: Optimize for Speed [-O]
- **Swift Optimization Level**: Optimize for Speed [-O]
- **Debug Information Format**: DWARF with dSYM
- **Strip Debug Symbols**: Yes
- **Strip Swift Symbols**: Yes

**Info.plist Updates:**
```xml
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>CFBundleVersion</key>
<string>1</string>
```

### 3. Environment Configuration

For production, update API endpoints:

```swift
// Config.swift
#if DEBUG
let alpacaBaseURL = "https://paper-api.alpaca.markets"  // Paper trading
#else
let alpacaBaseURL = "https://api.alpaca.markets"        // Live trading
#endif
```

**⚠️ Important:** Ensure users are warned before live trading!

### 4. Remove Debug Code

```bash
# Search for debug-only code
grep -r "print(" --include="*.swift" TradingCockpit/
grep -r "TODO" --include="*.swift" TradingCockpit/
grep -r "FIXME" --include="*.swift" TradingCockpit/
```

Remove or comment out:
- `print()` statements
- Debug logging
- Test data generators
- Development shortcuts

---

## Code Signing

### 1. Create App ID

**In Apple Developer Portal:**
1. Go to [developer.apple.com/account](https://developer.apple.com/account)
2. Navigate to **Certificates, IDs & Profiles**
3. Click **Identifiers** → **+** button
4. Select **App IDs** → **App**
5. Set Bundle ID: `com.tradingcockpit.TradingCockpit`
6. Enable capabilities:
   - ✅ Keychain Sharing
   - ✅ Network Extensions (for WebSocket)
   - ✅ Associated Domains (if using universal links)

### 2. Create Certificates

**Development Certificate:**
```bash
# Generate Certificate Signing Request (CSR)
# Keychain Access → Certificate Assistant → Request a Certificate from a CA
# Save to disk

# Upload CSR to Developer Portal
# Download and install certificate
```

**Distribution Certificate:**
- Same process as Development
- Choose "App Store and Ad Hoc" distribution

### 3. Create Provisioning Profiles

**Development Profile:**
1. Developer Portal → Provisioning Profiles → **+**
2. Select **visionOS App Development**
3. Choose App ID: `com.tradingcockpit.TradingCockpit`
4. Select development certificate
5. Select test devices (Apple Vision Pro)
6. Download and install

**Distribution Profile:**
1. Select **App Store**
2. Choose App ID and distribution certificate
3. Download and install

### 4. Configure Xcode Signing

**Automatic Signing (Recommended):**
1. Open project in Xcode
2. Select target → Signing & Capabilities
3. ✅ Automatically manage signing
4. Select Team
5. Xcode handles the rest

**Manual Signing:**
1. ❌ Uncheck automatic signing
2. Select provisioning profiles manually
3. Ensure certificate is installed in Keychain

---

## App Store Connect Setup

### 1. Create App Record

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Go to **My Apps** → **+** → **New App**
3. Fill in details:
   - **Platform**: visionOS
   - **Name**: Trading Cockpit
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: com.tradingcockpit.TradingCockpit
   - **SKU**: TRADING-COCKPIT-001

### 2. App Information

**Category:**
- Primary: Finance
- Secondary: Productivity

**Content Rights:**
- ✅ Contains third-party content (market data)

**Age Rating:**
- Rating: 17+
- Reasons: Unrestricted web access, simulated gambling

### 3. Pricing and Availability

**Price:**
- Free (with potential in-app purchases)
- Or: Tier 1 ($0.99), Tier 10 ($9.99), etc.

**Availability:**
- All countries (or select specific regions)
- Release: Automatic or manual after approval

### 4. App Privacy

**Data Collection:**
1. Trading data (for order execution)
2. Usage data (analytics)
3. Contact information (support)

**Privacy Policy:**
- Create privacy policy (required)
- Host at: `https://tradingcockpit.com/privacy`
- Add URL in App Store Connect

### 5. App Information Fields

**Description** (4000 chars):
```
Trading Cockpit is the first professional-grade trading platform built exclusively for Apple Vision Pro. Experience financial markets in stunning 3D with immersive visualizations, real-time data, and intuitive spatial controls.

KEY FEATURES:
• 3D Portfolio Visualization - Watch your portfolio come to life in stunning 3D terrain
• Real-Time Trading - Execute trades instantly with sub-second market data
• Advanced Analytics - Track performance with real-time P&L calculations
• Smart Watchlists - Create and manage multiple watchlists with real-time quotes
• Enterprise Security - Credentials protected with industry-standard encryption
• Spatial Interactions - Natural hand gestures designed for Vision Pro

TRADING CAPABILITIES:
• Market and limit orders
• Position sizing calculator
• Real-time portfolio tracking
• Order history and status monitoring
• Buying power validation

MARKET DATA:
• Real-time quotes (sub-100ms latency)
• 10,000+ tradable securities
• 24/7 data streaming
• Live price updates

BROKER INTEGRATION:
• Alpaca Markets integration
• Paper trading support
• Secure credential storage

Perfect for:
• Active traders seeking spatial computing advantages
• Portfolio managers visualizing positions
• Anyone wanting to experience trading in a new dimension

REQUIREMENTS:
• Apple Vision Pro
• Alpaca Markets account (free paper trading available)
• Polygon.io API key (free tier available)

DISCLAIMER:
Trading involves risk. Past performance does not guarantee future results.
```

**Keywords** (100 chars):
```
trading,stocks,finance,portfolio,3d,visualization,visionos,market,invest,real-time
```

**Support URL:**
```
https://tradingcockpit.com/support
```

**Marketing URL:**
```
https://tradingcockpit.com
```

### 6. Screenshots

**Required Sizes for visionOS:**
- 2732 x 2048 pixels (landscape)
- 2048 x 2732 pixels (portrait)

**Screenshots Needed:**
1. Main menu with spatial UI
2. 3D portfolio visualization
3. Order entry screen
4. Watchlist with real-time quotes
5. Portfolio positions view

**Capture on Device:**
```bash
# Take screenshot on Vision Pro
# Press Digital Crown + Volume Up simultaneously

# Or capture from simulator
xcrun simctl io booted screenshot screenshot.png
```

### 7. App Preview Video (Optional)

**Specifications:**
- Resolution: 1920x1080 or 3840x2160
- Format: .mov, .m4v, or .mp4
- Duration: 15-30 seconds
- Show key features and 3D visualization

---

## TestFlight Deployment

### 1. Archive Build

**From Xcode:**
1. Select **Any visionOS Device** (not simulator)
2. **Product** → **Archive**
3. Wait for archive to complete (2-5 minutes)
4. Archive Organizer opens automatically

**From Command Line:**
```bash
xcodebuild clean archive \
  -scheme TradingCockpit \
  -configuration Release \
  -archivePath "build/TradingCockpit.xcarchive" \
  -destination "generic/platform=visionOS"
```

### 2. Upload to App Store Connect

**From Xcode:**
1. In Archive Organizer, select archive
2. Click **Distribute App**
3. Choose **App Store Connect**
4. Select **Upload**
5. Choose distribution certificate and profile
6. Review summary → **Upload**
7. Wait for processing (10-30 minutes)

**Using fastlane:**
```bash
fastlane pilot upload \
  --ipa build/TradingCockpit.ipa \
  --skip_waiting_for_build_processing
```

### 3. Configure TestFlight

**In App Store Connect:**
1. Go to **TestFlight** tab
2. Select build (once processing completes)
3. Fill in **What to Test**:
   ```
   v1.0.0 (Build 1)

   New in this build:
   - Initial release
   - 3D portfolio visualization
   - Real-time trading execution
   - Watchlist management
   - Market data streaming

   Testing Focus:
   - Test order placement and execution
   - Verify 3D visualization performance
   - Check watchlist functionality
   - Report any crashes or bugs
   ```

### 4. Add Internal Testers

**Internal Testing:**
1. TestFlight → Internal Testing
2. Add testers (max 100)
3. Testers must have App Store Connect access
4. Automatic distribution

### 5. Add External Testers

**External Testing:**
1. TestFlight → External Testing → **+** Create Group
2. Group name: "Beta Testers"
3. Add testers by email (max 10,000)
4. Submit for Beta App Review (1-2 days)
5. Once approved, testers receive email

### 6. Monitor TestFlight

**Metrics to Track:**
- Install rate
- Session count
- Crash rate
- Feedback submissions

**Collect Feedback:**
- In-app feedback screenshots
- Crash reports
- Tester comments

---

## App Store Submission

### 1. Prepare for Review

**Checklist:**
- ✅ All screenshots uploaded
- ✅ Description and keywords finalized
- ✅ Privacy policy URL added
- ✅ Demo account credentials provided (if needed)
- ✅ Contact information updated
- ✅ Age rating completed
- ✅ Export compliance information added

**Demo Account (Required for Financial Apps):**
```
Username: demo@tradingcockpit.com
Password: DemoPass123!
Note: Uses Alpaca paper trading account
```

### 2. Submit Build

1. Go to **App Store** tab (not TestFlight)
2. Click **+ Version** → Enter version number (1.0.0)
3. Select build from TestFlight
4. Review all information
5. Click **Save**
6. Click **Submit for Review**

### 3. App Review Information

**Contact Information:**
- First Name, Last Name
- Phone Number
- Email Address

**Notes for Reviewer:**
```
Trading Cockpit requires API credentials for full functionality:

ALPACA MARKETS (broker):
- Paper trading credentials provided above
- No real money used in demo mode

POLYGON.IO (market data):
- Demo account included
- Shows real-time market data

TESTING INSTRUCTIONS:
1. Launch app
2. Login with provided credentials
3. Navigate to Portfolio → 3D View
4. Try placing a test order (paper trading only)
5. Add symbols to watchlist

The app is designed for Apple Vision Pro and showcases spatial computing for financial trading. All trading is simulated (paper trading) unless user provides their own live trading credentials.
```

### 4. Review Process

**Timeline:**
- Submission → In Review: 24-48 hours
- Review Duration: 1-3 days
- Total: 2-5 days typically

**Possible Outcomes:**
- ✅ **Approved** - App goes live (or scheduled release)
- ❌ **Rejected** - Fix issues and resubmit
- ⚠️ **Metadata Rejected** - Fix app info only (no new build needed)

**Common Rejection Reasons:**
1. Crashes during review
2. Missing demo credentials
3. Privacy policy issues
4. Incomplete app information
5. Age rating mismatch

---

## Post-Release

### 1. Monitor Launch

**First 24 Hours:**
- Check crash reports in App Store Connect
- Monitor user reviews
- Track downloads and conversions
- Respond to user feedback

**Key Metrics:**
- Downloads
- Crashes per user
- Average session duration
- Retention (Day 1, Day 7, Day 30)

### 2. User Reviews

**Respond to Reviews:**
- Positive reviews: Thank users
- Negative reviews: Offer help, fix issues
- Bug reports: Acknowledge and provide timeline

**Example Response:**
```
Thank you for the feedback! We're working on a fix for the issue you reported. Update 1.0.1 will be available next week. If you need immediate assistance, please contact support@tradingcockpit.com.
```

### 3. Hotfix Process

If critical bug found:

1. Fix bug in code
2. Increment build number
3. Archive and upload
4. Submit for expedited review
5. Request expedited review (use sparingly)

**Expedited Review Request:**
- App Store Connect → Versions → Request Expedited Review
- Explain severity (crashes, security, etc.)
- Typical approval: 1-2 days instead of 3-5

### 4. Regular Updates

**Update Schedule:**
- Bug fixes: As needed
- Minor updates: Every 2-4 weeks
- Major updates: Every 2-3 months

**Version Numbering:**
- Major.Minor.Patch (1.0.0)
- Major: Breaking changes
- Minor: New features
- Patch: Bug fixes

---

## Troubleshooting

### Build Issues

**Issue: "No signing certificate found"**

**Solution:**
1. Open Keychain Access
2. Verify distribution certificate is installed
3. Developer Portal → Certificates → Re-download if needed
4. Double-click to install

**Issue: "Provisioning profile doesn't match"**

**Solution:**
1. Delete all provisioning profiles: `~/Library/MobileDevice/Provisioning Profiles`
2. Xcode → Preferences → Accounts → Download Manual Profiles
3. Or enable automatic signing

### Upload Issues

**Issue: "Invalid binary"**

**Solution:**
- Ensure target is visionOS (not simulator)
- Check deployment target is correct
- Verify all required frameworks are included

**Issue: "Missing compliance information"**

**Solution:**
- Answer export compliance questions
- Most apps: "No" to encryption (unless custom crypto)

### Review Issues

**Issue: "App crashes on launch"**

**Solution:**
- Test on actual Vision Pro device
- Check crash logs
- Verify all required API keys are not hardcoded
- Test with slow network connection

**Issue: "Missing functionality"**

**Solution:**
- Provide clearer instructions for reviewers
- Include demo video if complex
- Update "Notes for Reviewer" section

---

## Automation with fastlane

### Setup

```bash
# Install fastlane
brew install fastlane

# Initialize in project
cd TradingCockpit
fastlane init
```

### Fastfile Example

```ruby
default_platform(:visionos)

platform :visionos do
  desc "Build and upload to TestFlight"
  lane :beta do
    increment_build_number
    build_app(scheme: "TradingCockpit")
    upload_to_testflight(
      skip_waiting_for_build_processing: true
    )
  end

  desc "Submit to App Store"
  lane :release do
    increment_version_number(
      bump_type: "minor"
    )
    build_app(scheme: "TradingCockpit")
    upload_to_app_store(
      submit_for_review: true,
      automatic_release: false
    )
  end
end
```

### Usage

```bash
# Deploy to TestFlight
fastlane beta

# Submit to App Store
fastlane release
```

---

## Resources

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [Human Interface Guidelines - visionOS](https://developer.apple.com/design/human-interface-guidelines/visionos)

---

**Last Updated:** 2025-11-24
**Version:** 1.0.0
**Platform:** visionOS 2.0+
