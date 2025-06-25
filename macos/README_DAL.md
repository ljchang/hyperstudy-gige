# Alternative: DAL Plugin Approach

Due to the complexity of System Extensions requiring special signing and notarization, here's an alternative approach using a DAL (CoreMediaIO DAL) plugin that's easier to test:

## DAL Plugin vs System Extension

**DAL Plugin (Legacy, but works):**
- Can be installed in /Library/CoreMediaIO/Plug-Ins/DAL/
- Works immediately without approval
- Easier to test during development
- Still supported on macOS

**System Extension (Modern):**
- Requires notarization for distribution
- Needs user approval in System Settings
- More secure but harder to test

## Quick Test with Existing Virtual Camera

To verify the concept works, you can test with an existing virtual camera:

1. Install OBS Studio: `brew install --cask obs`
2. Start OBS, go to Tools → Start Virtual Camera
3. In QuickTime or other apps, select "OBS Virtual Camera"

This proves that virtual cameras work on your system.

## Converting to DAL Plugin

If the System Extension approach is too complex for testing, we can convert the project to use a DAL plugin instead. This would:

1. Use the same camera capture code
2. Install to /Library/CoreMediaIO/Plug-Ins/DAL/
3. Work immediately without security prompts
4. Be easier to iterate on during development

Would you like me to create a DAL plugin version for easier testing?