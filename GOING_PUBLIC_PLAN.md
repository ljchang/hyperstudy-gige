# Going Public Plan: GigE Virtual Camera

**Goal**: Make this repository public on GitHub with automated CI/CD for building and releasing macOS applications.

**Status**: ✅ FEASIBLE - All requirements can be met with GitHub Actions

---

## Overview

This plan will:
- Remove all personal identifiers and secrets from the codebase
- Set up GitHub Actions for automated builds and releases
- Enable community contributions with local build support
- Maintain your personal signing identity for official releases

**Estimated Timeline**: 5-7 hours total work

---

## Phase 1: Security Audit & Cleanup

### Critical Files Requiring Changes (30+ files)

**High Priority - Contains Personal Info**:
- `project.yml` - Lines 11, 78, 234 (Team ID: S368GH6KF7)
- `GigEVirtualCamera.xcodeproj/project.pbxproj` - Multiple Team ID references
- `Scripts/build_and_distribute.sh` - Lines 16-17 (signing identity), Line 96 (Dropbox path)
- All scripts in `Scripts/` directory (35 files) - Replace hardcoded Team ID

**Files Already Secure** ✅:
- No passwords in repository
- Notarization credentials stored in macOS Keychain (not in repo)
- Provisioning profiles excluded by .gitignore

### Tasks:
1. ✅ Replace all instances of `S368GH6KF7` with `${APPLE_TEAM_ID}` or environment variable
2. ✅ Remove "Luke Chang" from signing identity strings (use generic "Developer ID Application")
3. ✅ Remove Dropbox path: `/Users/lukechang/Dartmouth College Dropbox/Luke Chang/HyperStudy/GigE/ProvisioningProfile`
4. ✅ Update .gitignore to exclude certificates, secrets, .env files
5. ✅ Scan git history for any accidentally committed secrets

---

## Phase 2: Configuration Refactoring

### Create Template Files

**1. `.env.example`** - Template for local development:
```bash
# Apple Developer Configuration
APPLE_TEAM_ID=YOUR_TEAM_ID_HERE
CODE_SIGN_IDENTITY=Developer ID Application
BUNDLE_ID_PREFIX=com.yourcompany

# Notarization (for local builds)
NOTARIZATION_APPLE_ID=your.email@example.com
NOTARIZATION_TEAM_ID=YOUR_TEAM_ID_HERE
```

**2. `project.yml.template`** - Template for generating Xcode project:
- Replace hardcoded Team ID with `${APPLE_TEAM_ID}`
- Add instructions for customization

**3. `Scripts/setup_local_dev.sh`** - Helper script:
- Guides developers through configuration
- Validates environment variables
- Checks for required dependencies

### Parameterize Build Scripts

**Files to modify** (35 scripts in `Scripts/`):
- Replace hardcoded `S368GH6KF7` with `$APPLE_TEAM_ID`
- Make signing identity configurable via environment variable
- Add conditional signing (skip if no certificate available for community builds)
- Remove absolute paths to Dropbox

**Key scripts**:
- `build_and_distribute.sh`
- `sign_developer_id.sh`
- `notarize.sh`
- `create_dmg.sh`
- All signing/distribution scripts

---

## Phase 3: GitHub Secrets Setup

### Required Secrets (7 total)

You will need to add these to: **GitHub Repository → Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | Description | How to Get It |
|-------------|-------------|---------------|
| `MACOS_CERTIFICATE_BASE64` | Developer ID Application certificate | Export from Keychain as .p12, then base64 encode |
| `MACOS_CERTIFICATE_PASSWORD` | Password for .p12 certificate | Password you set during export |
| `MACOS_PROVISIONING_PROFILE_APP_BASE64` | Main app provisioning profile | Base64 encode the .mobileprovision file |
| `MACOS_PROVISIONING_PROFILE_EXT_BASE64` | Extension provisioning profile | Base64 encode the .mobileprovision file |
| `APPLE_TEAM_ID` | Your Team ID | `S368GH6KF7` |
| `NOTARIZATION_APPLE_ID` | Apple ID email for notarization | Your Apple Developer email |
| `NOTARIZATION_PASSWORD` | App-specific password | Generate at appleid.apple.com |

### Detailed Instructions for Creating Secrets

#### 1. Export Certificate from Keychain

```bash
# Find your Developer ID Application certificate in Keychain Access
# Right-click → Export "Developer ID Application: Luke Chang (S368GH6KF7)"
# Save as: Certificates.p12
# Set a strong password (you'll use this as MACOS_CERTIFICATE_PASSWORD)

# Convert to base64
base64 -i Certificates.p12 -o Certificates.p12.base64

# Copy the contents and add to GitHub as MACOS_CERTIFICATE_BASE64
cat Certificates.p12.base64 | pbcopy
```

#### 2. Export Provisioning Profiles

```bash
# Provisioning profiles are located at:
# ~/Library/MobileDevice/Provisioning Profiles/

# Find your profiles:
ls -la ~/Library/MobileDevice/Provisioning\ Profiles/

# Or use the ones from Dropbox if you have them there

# Convert to base64:
base64 -i "path/to/GigE_Virtual_Camera_Distribution.mobileprovision" -o app_profile.base64
base64 -i "path/to/GigE_Camera_Extension_Distribution.mobileprovision" -o ext_profile.base64

# Copy contents to GitHub secrets
cat app_profile.base64 | pbcopy  # Add as MACOS_PROVISIONING_PROFILE_APP_BASE64
cat ext_profile.base64 | pbcopy  # Add as MACOS_PROVISIONING_PROFILE_EXT_BASE64
```

#### 3. Generate App-Specific Password

```bash
# 1. Go to: https://appleid.apple.com/account/manage
# 2. Sign in with your Apple ID
# 3. In "Security" section, click "App-Specific Passwords"
# 4. Click "Generate an app-specific password"
# 5. Label it: "GitHub Actions - GigE Virtual Camera"
# 6. Copy the generated password
# 7. Add to GitHub as NOTARIZATION_PASSWORD
```

#### 4. Simple Secrets

- `APPLE_TEAM_ID`: Just enter `S368GH6KF7`
- `NOTARIZATION_APPLE_ID`: Your Apple Developer email address

---

## Phase 4: GitHub Actions Workflow

### Create `.github/workflows/build-and-release.yml`

**Trigger**: Automatic on version tags (push tags matching `v*.*.*`)

**Runner**: `macos-14` (Apple Silicon)

**Build Steps**:
1. Checkout code
2. Install dependencies (Homebrew: aravis, xcodegen)
3. Import code signing certificate from secrets
4. Install provisioning profiles
5. Build Release configuration with Xcode
6. Bundle Aravis libraries
7. Sign app, extension, and bundled libraries
8. Notarize with Apple
9. Create DMG
10. Create GitHub Release with DMG attachment

**Estimated Build Time**: 15-20 minutes per release

**Cost**: Free on GitHub (macOS runners included in free tier with some limits)

### Additional Workflows (Optional)

- `.github/workflows/test-build.yml` - Test builds on PRs (without signing/notarization)
- `.github/workflows/dependency-update.yml` - Check for Aravis updates

---

## Phase 5: Documentation

### New Documents to Create

**1. `BUILDING.md`** - Community build instructions:
- Prerequisites (Xcode, Homebrew, Aravis)
- How to configure local environment
- How to build with your own signing certificate
- Troubleshooting common issues

**2. `SECRETS_SETUP.md`** - For repository maintainers:
- Detailed instructions for setting up GitHub secrets
- How to rotate certificates/passwords
- Security best practices

**3. `CONTRIBUTING.md`** - Contribution guidelines:
- How to set up development environment
- Code style guidelines
- How to submit PRs
- Testing requirements

### Documents to Update

**1. `README.md`** - Add:
- CI/CD status badge
- Download links to latest release
- Quick start instructions
- Link to BUILDING.md

**2. `CLAUDE.md`** - Add:
- CI/CD workflow documentation
- Environment variable configuration
- GitHub Actions troubleshooting

---

## Phase 6: Pre-Release Testing

### Test Checklist

- [ ] Test GitHub Actions workflow in private repository first
- [ ] Verify secrets are correctly configured
- [ ] Test full build completes successfully
- [ ] Verify notarization succeeds
- [ ] Download DMG from release and test installation
- [ ] Verify app runs and camera functionality works
- [ ] Check that no personal information appears in:
  - [ ] Build artifacts
  - [ ] DMG installer
  - [ ] GitHub release notes
  - [ ] App About/Info windows
- [ ] Test on fresh Mac (not your development machine)
- [ ] Verify `spctl -a -v` shows app is notarized

### Testing Procedure

```bash
# 1. Create a test tag
git tag v0.0.1-test
git push origin v0.0.1-test

# 2. Watch GitHub Actions run
# Go to: https://github.com/YOUR_USERNAME/hyperstudy-gige/actions

# 3. Download the DMG from Releases when complete

# 4. Test installation
# - Open DMG
# - Drag to Applications
# - Open app
# - Check System Settings → Privacy & Security for extension approval
# - Test camera discovery and streaming
```

---

## Phase 7: Going Public

### Pre-Flight Checklist

- [ ] All secrets removed from codebase
- [ ] .gitignore updated and tested
- [ ] Git history scanned (no secrets ever committed)
- [ ] All hardcoded personal identifiers parameterized
- [ ] Documentation complete and reviewed
- [ ] Test release successful
- [ ] Download and installation tested
- [ ] All contributors/maintainers notified

### Go Public Steps

1. **Final security scan**:
   ```bash
   # Search for any remaining personal info
   grep -r "S368GH6KF7" .
   grep -r "Luke Chang" .
   grep -r "Dropbox" .
   ```

2. **Make repository public**:
   - GitHub → Repository Settings → General
   - Scroll to "Danger Zone"
   - Click "Change visibility" → "Make public"
   - Confirm

3. **Create first official release**:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

4. **Monitor workflow**:
   - Watch GitHub Actions complete
   - Verify release appears
   - Test download

5. **Announce**:
   - Update README with release info
   - Share on relevant communities
   - Update project description

---

## What You Need to Do (Action Items)

### Before Implementation

- [ ] Review this plan and approve approach
- [ ] Gather required files:
  - [ ] Developer ID Application certificate (.p12 from Keychain)
  - [ ] Provisioning profiles from `~/Library/MobileDevice/Provisioning Profiles/` or Dropbox
  - [ ] Apple ID and app-specific password

### During Implementation

- [ ] Add GitHub Secrets (using instructions in Phase 3)
- [ ] Test the first workflow run
- [ ] Review build artifacts

### After Going Public

- [ ] Monitor initial releases
- [ ] Respond to community feedback
- [ ] Update documentation as needed
- [ ] Rotate app-specific password periodically

---

## Architecture Decisions Made

Based on your preferences:

✅ **Keep personal signing identity** - Official releases use Luke Chang / S368GH6KF7
✅ **Full community build support** - Anyone can fork and build with their own certs
✅ **Automatic releases on tags** - Push `v*.*.*` tag → automatic build and release
✅ **Apple Silicon only (arm64)** - Uses macos-14 runners, simpler configuration

---

## Security Considerations

### What's Safe to Commit

✅ Team ID as environment variable (public info anyway)
✅ Bundle IDs (public info)
✅ Entitlements (standard configuration)
✅ Build scripts (parameterized)

### What Must Stay Secret

🔒 Developer ID certificate (.p12 file)
🔒 Certificate password
🔒 Provisioning profiles
🔒 Apple ID credentials
🔒 App-specific passwords

### Additional Security Measures

- Use environment variables for all sensitive config
- Never log secrets in GitHub Actions output
- Use `::add-mask::` for sensitive output in workflows
- Rotate app-specific passwords every 6-12 months
- Monitor GitHub Actions logs for any exposed secrets
- Use GitHub's secret scanning (automatically enabled)

---

## Troubleshooting

### Common Issues

**1. "Provisioning profile doesn't match"**
- Ensure profile matches Bundle ID and Team ID
- Verify profile is for Distribution, not Development
- Check profile hasn't expired

**2. "Notarization failed"**
- Verify app-specific password is correct
- Check all binaries are signed
- Ensure Hardened Runtime is enabled
- Review notarization logs

**3. "Certificate not found"**
- Verify certificate is imported to build keychain
- Check certificate hasn't expired
- Ensure it's "Developer ID Application" type

**4. GitHub Actions fails on dependency installation**
- Check Homebrew is available
- Verify Aravis formula exists
- May need to pin Aravis version

---

## Future Enhancements

### Potential Additions

- [ ] Build universal binaries (arm64 + x86_64)
- [ ] Add Intel Mac support
- [ ] Automated testing suite
- [ ] Code signing verification in CI
- [ ] Dependency version locking
- [ ] Automated changelog generation
- [ ] Discord/Slack notifications for releases
- [ ] Download statistics tracking

---

## References

- [GitHub Actions: Building macOS apps](https://docs.github.com/en/actions/guides/building-and-testing-swift)
- [Apple: Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [GitHub: Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Your Tauri project] - Reference for workflow patterns

---

**Document Version**: 1.0
**Last Updated**: 2025-11-15
**Status**: Ready for Implementation
