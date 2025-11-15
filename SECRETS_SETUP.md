# GitHub Secrets Setup Guide

This document provides step-by-step instructions for configuring GitHub repository secrets to enable automated CI/CD builds and releases.

## Table of Contents

- [Overview](#overview)
- [Required Secrets](#required-secrets)
- [Step-by-Step Setup](#step-by-step-setup)
- [Verification](#verification)
- [Security Best Practices](#security-best-practices)
- [Troubleshooting](#troubleshooting)
- [Rotating Secrets](#rotating-secrets)

## Overview

The GitHub Actions workflow requires several secrets to build, sign, and notarize the macOS application. These secrets are stored securely in GitHub and never exposed in logs or artifacts.

**Never commit these secrets to the repository!**

## Required Secrets

| Secret Name | Description | Type | Required |
|-------------|-------------|------|----------|
| `MACOS_CERTIFICATE_BASE64` | Developer ID Application certificate | Base64-encoded .p12 file | Yes |
| `MACOS_CERTIFICATE_PASSWORD` | Password for the .p12 certificate | String | Yes |
| `MACOS_PROVISIONING_PROFILE_APP_BASE64` | Main app provisioning profile | Base64-encoded .mobileprovision | Yes |
| `MACOS_PROVISIONING_PROFILE_EXT_BASE64` | Extension provisioning profile | Base64-encoded .mobileprovision | Yes |
| `APPLE_TEAM_ID` | 10-character Apple Developer Team ID | String | Yes |
| `NOTARIZATION_APPLE_ID` | Apple ID email for notarization | String (email) | Yes |
| `NOTARIZATION_PASSWORD` | App-specific password for notarization | String | Yes |

## Step-by-Step Setup

### Prerequisites

Before starting, ensure you have:
- [ ] Apple Developer Program membership
- [ ] Developer ID Application certificate installed in Keychain
- [ ] Provisioning profiles for app and extension
- [ ] GitHub repository with admin access

### 1. Export Code Signing Certificate

#### macOS Keychain Method

1. Open **Keychain Access** application
2. Select **login** keychain in the left sidebar
3. Select **My Certificates** category
4. Find your **Developer ID Application** certificate
   - Should be named: "Developer ID Application: Your Name (TEAM_ID)"
5. Right-click the certificate → **Export**
6. Save as: `Certificates.p12`
7. **Set a strong password** (you'll use this as `MACOS_CERTIFICATE_PASSWORD`)
8. Save the file to a secure location

#### Convert to Base64

```bash
# Navigate to where you saved the certificate
cd ~/Downloads  # or wherever you saved it

# Convert to base64
base64 -i Certificates.p12 -o Certificates.p12.base64

# Copy to clipboard
cat Certificates.p12.base64 | pbcopy

# The base64 string is now in your clipboard, ready to paste into GitHub
```

**Security Note:** Delete the .p12 file after encoding:
```bash
rm Certificates.p12 Certificates.p12.base64
```

### 2. Export Provisioning Profiles

#### Locate Provisioning Profiles

Provisioning profiles are stored at:
```
~/Library/MobileDevice/Provisioning Profiles/
```

To find your profiles:

```bash
# List all provisioning profiles
ls -la ~/Library/MobileDevice/Provisioning\ Profiles/

# Search for GigE profiles by examining each one
for profile in ~/Library/MobileDevice/Provisioning\ Profiles/*.provisionprofile; do
  echo "Profile: $profile"
  security cms -D -i "$profile" | grep -A 2 "application-identifier"
done
```

You need TWO profiles:
1. **Main App**: Bundle ID `com.lukechang.GigEVirtualCamera`
2. **Extension**: Bundle ID `com.lukechang.GigEVirtualCamera.Extension`

#### Download from Apple Developer Portal (if needed)

1. Go to https://developer.apple.com/account/resources/profiles/list
2. Find or create profiles for:
   - "GigE Virtual Camera Distribution" (Main App)
   - "GigE Camera Extension Distribution" (Extension)
3. Download both `.mobileprovision` files

#### Convert to Base64

```bash
# For the main app profile
base64 -i ~/Library/MobileDevice/Provisioning\ Profiles/YOUR_APP_PROFILE.mobileprovision \
  -o app_profile.base64

# For the extension profile
base64 -i ~/Library/MobileDevice/Provisioning\ Profiles/YOUR_EXT_PROFILE.mobileprovision \
  -o ext_profile.base64

# Copy each to clipboard
cat app_profile.base64 | pbcopy  # Paste this as MACOS_PROVISIONING_PROFILE_APP_BASE64
# Then:
cat ext_profile.base64 | pbcopy  # Paste this as MACOS_PROVISIONING_PROFILE_EXT_BASE64

# Clean up
rm app_profile.base64 ext_profile.base64
```

### 3. Get Apple Team ID

Your Team ID is a 10-character alphanumeric identifier.

**Method 1: Apple Developer Portal**

1. Go to https://developer.apple.com/account/#!/membership
2. Sign in
3. Your Team ID is displayed under "Membership Information"
4. Example: `S368GH6KF7`

**Method 2: From Keychain**

Your Developer ID certificate name includes your Team ID:
```
Developer ID Application: Your Name (TEAM_ID)
                                      ^^^^^^^^^^
```

**Method 3: Command Line**

```bash
# Extract from a provisioning profile
security cms -D -i ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision \
  | grep -A 1 "com.apple.developer.team-identifier" \
  | tail -1 \
  | sed 's/<[^>]*>//g' \
  | xargs
```

### 4. Create App-Specific Password for Notarization

Apple requires an app-specific password for notarization (not your regular Apple ID password).

1. Go to https://appleid.apple.com/account/manage
2. Sign in with your Apple ID
3. Under **Security** section, find **App-Specific Passwords**
4. Click **Generate Password** (or the "+" button)
5. Label it: `GitHub Actions - GigE Virtual Camera`
6. Apple will show a password like: `xxxx-xxxx-xxxx-xxxx`
7. **Copy this immediately** (you can't view it again!)
8. Save it as `NOTARIZATION_PASSWORD` secret

**Important:** This is NOT your Apple ID password. Never use your Apple ID password in GitHub secrets!

### 5. Add Secrets to GitHub

#### Via GitHub Web Interface

1. Go to your repository on GitHub
2. Click **Settings** tab
3. In left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Add each secret:

**For MACOS_CERTIFICATE_BASE64:**
- Name: `MACOS_CERTIFICATE_BASE64`
- Value: Paste the entire base64 string from Certificates.p12.base64

**For MACOS_CERTIFICATE_PASSWORD:**
- Name: `MACOS_CERTIFICATE_PASSWORD`
- Value: The password you set when exporting the .p12 file

**For MACOS_PROVISIONING_PROFILE_APP_BASE64:**
- Name: `MACOS_PROVISIONING_PROFILE_APP_BASE64`
- Value: Paste the base64-encoded app provisioning profile

**For MACOS_PROVISIONING_PROFILE_EXT_BASE64:**
- Name: `MACOS_PROVISIONING_PROFILE_EXT_BASE64`
- Value: Paste the base64-encoded extension provisioning profile

**For APPLE_TEAM_ID:**
- Name: `APPLE_TEAM_ID`
- Value: Your 10-character Team ID (e.g., `S368GH6KF7`)

**For NOTARIZATION_APPLE_ID:**
- Name: `NOTARIZATION_APPLE_ID`
- Value: Your Apple ID email address

**For NOTARIZATION_PASSWORD:**
- Name: `NOTARIZATION_PASSWORD`
- Value: The app-specific password you just generated

#### Via GitHub CLI (Optional)

If you have GitHub CLI installed:

```bash
# Set each secret (you'll be prompted for the value)
gh secret set MACOS_CERTIFICATE_BASE64 < Certificates.p12.base64
gh secret set MACOS_CERTIFICATE_PASSWORD
gh secret set MACOS_PROVISIONING_PROFILE_APP_BASE64 < app_profile.base64
gh secret set MACOS_PROVISIONING_PROFILE_EXT_BASE64 < ext_profile.base64
gh secret set APPLE_TEAM_ID
gh secret set NOTARIZATION_APPLE_ID
gh secret set NOTARIZATION_PASSWORD
```

## Verification

### Check Secrets Are Set

1. Go to repository **Settings** → **Secrets and variables** → **Actions**
2. You should see all 7 secrets listed:
   - ✅ MACOS_CERTIFICATE_BASE64
   - ✅ MACOS_CERTIFICATE_PASSWORD
   - ✅ MACOS_PROVISIONING_PROFILE_APP_BASE64
   - ✅ MACOS_PROVISIONING_PROFILE_EXT_BASE64
   - ✅ APPLE_TEAM_ID
   - ✅ NOTARIZATION_APPLE_ID
   - ✅ NOTARIZATION_PASSWORD

**Note:** GitHub shows when secrets were last updated, but never shows the values.

### Test the Workflow

1. Create a test tag:
   ```bash
   git tag v0.0.1-test
   git push origin v0.0.1-test
   ```

2. Go to **Actions** tab on GitHub
3. Watch the "Build and Release" workflow run
4. Check for any errors in the logs

If the workflow fails, check the [Troubleshooting](#troubleshooting) section below.

## Security Best Practices

### Do's ✅

- **Use app-specific passwords** for notarization (never your Apple ID password)
- **Set strong passwords** for .p12 certificate files
- **Delete local copies** of .p12 and base64 files after uploading
- **Rotate secrets regularly** (every 6-12 months)
- **Use GitHub's secret scanning** (automatically enabled)
- **Audit secret access** in GitHub Actions logs
- **Limit repository access** to trusted contributors

### Don'ts ❌

- ❌ Never commit secrets to git (even in private repos)
- ❌ Never echo secrets in GitHub Actions logs
- ❌ Never share .p12 files via email or Slack
- ❌ Never use your Apple ID password as notarization password
- ❌ Never store secrets in .env files in the repository
- ❌ Never screenshot or paste secrets in public forums

### Secret Masking

GitHub Actions automatically masks secrets in logs. However:
- Be careful with `echo` statements
- Secrets are masked by exact string match only
- Base64-decoded secrets may not be masked

The workflow uses `::add-mask::` where needed for extra protection.

## Troubleshooting

### Common Issues

#### "Certificate import failed"

**Cause:** Invalid base64 encoding or wrong password

**Solution:**
```bash
# Test base64 decode locally
base64 --decode Certificates.p12.base64 > test.p12

# Try importing
security import test.p12 -k ~/Library/Keychains/login.keychain-db

# If successful, re-upload to GitHub
# Clean up test file
rm test.p12
```

#### "Provisioning profile doesn't match"

**Cause:** Profile doesn't match bundle ID or Team ID

**Solution:**
```bash
# Verify profile contents
security cms -D -i profile.mobileprovision | grep -A 2 "application-identifier"

# Should show: TEAM_ID.com.lukechang.GigEVirtualCamera
# Or for extension: TEAM_ID.com.lukechang.GigEVirtualCamera.Extension
```

#### "Notarization failed: Invalid credentials"

**Cause:** Wrong Apple ID or app-specific password

**Solution:**
1. Test credentials locally:
   ```bash
   xcrun notarytool history \
     --apple-id "YOUR_APPLE_ID" \
     --password "YOUR_APP_SPECIFIC_PASSWORD" \
     --team-id "YOUR_TEAM_ID"
   ```

2. If failed, regenerate app-specific password at appleid.apple.com

#### "Team ID mismatch"

**Cause:** Certificate, provisioning profile, and APPLE_TEAM_ID don't match

**Solution:**
- Ensure all use the SAME Team ID
- Check certificate: `security find-identity -v -p codesigning`
- Check profile: `security cms -D -i profile.mobileprovision | grep TeamIdentifier`

### Debugging Workflow

To debug secret issues:

1. Check GitHub Actions logs (secrets are masked automatically)
2. Verify secret names match exactly (case-sensitive)
3. Check for trailing spaces or newlines in secrets
4. Ensure base64 strings are complete (no truncation)

### Getting Help

If you're still stuck:
1. Check [GitHub Actions documentation](https://docs.github.com/en/actions)
2. Review [Apple notarization docs](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
3. Open a GitHub Issue (don't include secret values!)

## Rotating Secrets

Secrets should be rotated periodically for security.

### When to Rotate

- Every 6-12 months (recommended)
- When a team member leaves
- If secrets may have been exposed
- When certificates expire or are renewed

### How to Rotate

#### Certificate and Provisioning Profiles

1. Renew or generate new certificate in Apple Developer Portal
2. Download new certificate
3. Create new provisioning profiles
4. Follow steps 1-2 above to export and re-encode
5. Update GitHub secrets with new values

#### App-Specific Password

1. Go to https://appleid.apple.com/account/manage
2. Revoke old app-specific password
3. Generate new password
4. Update `NOTARIZATION_PASSWORD` secret in GitHub

#### Team ID

Team ID rarely changes, but if you transfer the app:
1. Update to new Team ID
2. Update `APPLE_TEAM_ID` secret
3. Update all provisioning profiles for new team
4. Update certificate for new team

### Verification After Rotation

After rotating:
1. Trigger a test build (push a tag)
2. Monitor GitHub Actions for success
3. Download and verify the DMG
4. Test installation

## Additional Resources

- [GitHub Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Apple Developer Portal](https://developer.apple.com/account/)
- [App-Specific Passwords](https://support.apple.com/en-us/HT204397)
- [Notarization Documentation](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/Introduction/Introduction.html)

---

**Important:** Keep this document up-to-date as secrets or requirements change. Never commit actual secret values to this file!
