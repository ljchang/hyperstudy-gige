# Contributing to GigE Virtual Camera

Thank you for your interest in contributing to GigE Virtual Camera! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Release Process](#release-process)

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all contributors. We expect respectful and constructive communication in all interactions.

### Expected Behavior

- Be respectful and considerate
- Provide constructive feedback
- Accept criticism gracefully
- Focus on what is best for the project
- Show empathy towards other contributors

### Unacceptable Behavior

- Harassment, trolling, or insulting comments
- Personal attacks or political arguments
- Publishing others' private information
- Other conduct that would be inappropriate in a professional setting

## Getting Started

### Prerequisites

Before contributing, ensure you have:

- macOS 12.3 or later (Apple Silicon recommended)
- Xcode 15.0 or later
- Homebrew installed
- Basic knowledge of Swift and macOS development
- Familiarity with Git and GitHub

### Setting Up Your Development Environment

1. **Fork the repository**
   ```bash
   # Click "Fork" on GitHub, then clone your fork:
   git clone https://github.com/YOUR_USERNAME/hyperstudy-gige.git
   cd hyperstudy-gige
   ```

2. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/hyperstudy-gige.git
   git fetch upstream
   ```

3. **Install dependencies**
   ```bash
   brew install aravis
   ```

4. **Open in Xcode**
   ```bash
   open macos/GigEVirtualCamera.xcodeproj
   ```

5. **Build and test**
   - Select "GigEVirtualCamera" scheme
   - Press Cmd+B to build
   - Press Cmd+R to run

See [BUILDING.md](BUILDING.md) for detailed build instructions.

## Development Setup

### Local Configuration

For development without code signing (community contributors):

```bash
# No special configuration needed!
# Just open the project in Xcode and build
```

For distribution builds (maintainers only):

```bash
# Set up environment variables
cp .env.example .env
# Edit .env with your Apple Developer credentials
source .env
```

### Project Structure

```
macos/
├── GigECameraApp/           # Main application UI and logic
├── GigECameraExtension/     # Camera extension (CMIO provider)
└── Shared/                  # Code shared between app and extension
    ├── AravisBridge/        # Objective-C++ wrapper for Aravis
    ├── CameraManager.swift  # Camera discovery and control
    └── ...

Scripts/                     # Build and distribution scripts
Resources/                   # Assets and resources
```

### Key Components

- **AravisBridge**: Objective-C++ wrapper around the Aravis C library
- **Camera Extension**: CMIO extension providing the virtual camera
- **Main App**: SwiftUI interface for camera control
- **XPC Communication**: Frame passing between app and extension

## Making Changes

### Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write clear, documented code
   - Follow the coding standards below
   - Add tests if applicable

3. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add feature: description of changes"
   ```

4. **Keep your branch updated**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Open a Pull Request**
   - Go to GitHub and click "New Pull Request"
   - Fill out the PR template
   - Request review from maintainers

### Branch Naming

Use descriptive branch names:
- `feature/add-new-camera-format` - New features
- `fix/crash-on-disconnect` - Bug fixes
- `docs/update-readme` - Documentation
- `refactor/simplify-camera-manager` - Code refactoring

### Commit Messages

Write clear commit messages:

**Good:**
```
Add support for Bayer format cameras

- Implement Bayer pattern detection in AravisBridge
- Add color conversion for RGGB, BGGR, GRBG, GBRG
- Update UI to display format information
```

**Bad:**
```
fix stuff
```

Format:
```
<type>: <short summary>

<optional detailed description>

<optional footer with issue references>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

## Coding Standards

### Swift Style Guide

Follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).

**Key points:**
- Use descriptive names
- Prefer clarity over brevity
- Use Swift native types (avoid NSString, etc.)
- Prefer `let` over `var`
- Use guard for early returns
- Document public APIs with comments

**Example:**
```swift
/// Connects to a GigE camera by ID
/// - Parameter cameraId: Unique identifier for the camera
/// - Returns: True if connection successful, false otherwise
func connect(to cameraId: String) -> Bool {
    guard !cameraId.isEmpty else {
        logger.error("Empty camera ID provided")
        return false
    }

    // Connection logic...
    return true
}
```

### Objective-C++ Style (AravisBridge)

- Minimize Objective-C++ code (keep it thin)
- Use Swift-friendly interfaces
- Handle C++ exceptions safely
- Document memory management

### Code Organization

- Group related functionality
- Use extensions for protocol conformance
- Keep files focused and modular
- Use MARK comments for organization

```swift
// MARK: - Properties
// MARK: - Initialization
// MARK: - Public Methods
// MARK: - Private Methods
```

### Error Handling

- Use Swift errors, not optionals, for recoverable errors
- Log errors with appropriate severity
- Provide user-friendly error messages

```swift
enum CameraError: LocalizedError {
    case connectionFailed(reason: String)
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let reason):
            return "Failed to connect to camera: \(reason)"
        case .invalidFormat:
            return "Unsupported camera format"
        }
    }
}
```

## Testing

### Manual Testing

Before submitting a PR, test your changes:

1. **Build successfully**
   ```bash
   xcodebuild -project macos/GigEVirtualCamera.xcodeproj \
     -scheme GigEVirtualCamera \
     -configuration Debug \
     build
   ```

2. **Run the app**
   - Test with both real cameras and test camera
   - Verify UI changes work as expected
   - Check system extension functionality

3. **Test integration**
   - Open QuickTime Player
   - Verify virtual camera appears and works
   - Test frame rate and quality

### Test Checklist

- [ ] App builds without warnings
- [ ] App runs on clean macOS install (if possible)
- [ ] Virtual camera appears in other apps
- [ ] Camera discovery works
- [ ] Frame streaming works
- [ ] No memory leaks (use Instruments)
- [ ] UI is responsive
- [ ] Error handling works correctly

### Automated Testing

We're working on adding automated tests. Contributions to testing infrastructure are welcome!

Future test areas:
- Unit tests for CameraManager
- Integration tests for Aravis Bridge
- UI tests for main app

## Submitting Changes

### Pull Request Process

1. **Update documentation**
   - Update README.md if needed
   - Update CLAUDE.md for build changes
   - Add/update code comments

2. **Self-review your code**
   - Check for TODO comments
   - Remove debug code
   - Verify formatting

3. **Create Pull Request**
   - Use a descriptive title
   - Fill out the PR template completely
   - Reference related issues
   - Add screenshots/videos for UI changes

4. **Address review feedback**
   - Respond to comments
   - Make requested changes
   - Push updates to your branch

5. **Merge**
   - Maintainers will merge when approved
   - Delete your branch after merge

### PR Template

```markdown
## Description
Brief description of what this PR does

## Changes
- Change 1
- Change 2

## Testing
How I tested these changes

## Screenshots (if applicable)
[Add screenshots or videos]

## Checklist
- [ ] Code builds successfully
- [ ] Manual testing completed
- [ ] Documentation updated
- [ ] No new warnings
```

## Release Process

Releases are automated via GitHub Actions.

### For Maintainers

To create a new release:

1. **Update version number**
   - Update `MARKETING_VERSION` in project.yml
   - Update CHANGELOG.md

2. **Create and push tag**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

3. **GitHub Actions automatically:**
   - Builds the app
   - Signs with Developer ID
   - Notarizes with Apple
   - Creates DMG
   - Creates GitHub Release
   - Uploads DMG to release

4. **Verify release**
   - Download DMG from GitHub
   - Install and test
   - Update release notes if needed

### Version Numbering

We use [Semantic Versioning](https://semver.org/):
- `v1.0.0` - Major release (breaking changes)
- `v1.1.0` - Minor release (new features)
- `v1.0.1` - Patch release (bug fixes)

## Areas for Contribution

We welcome contributions in these areas:

### High Priority
- **Camera format support**: Add support for more pixel formats
- **Performance optimization**: Improve frame rate and latency
- **Error handling**: Better error messages and recovery
- **Testing**: Add unit and integration tests

### Medium Priority
- **Documentation**: Improve guides and examples
- **UI improvements**: Better camera controls, settings
- **Logging**: Enhanced debugging capabilities
- **Intel support**: Add x86_64 architecture support

### Low Priority
- **Internationalization**: Translate UI to other languages
- **Themes**: Dark mode improvements
- **Automation**: More build scripts and tools

### Good First Issues

Look for issues labeled `good first issue` - these are suitable for newcomers.

## Getting Help

### Resources

- **Documentation**: Start with README.md and BUILDING.md
- **Issues**: Search existing issues before creating new ones
- **Discussions**: Ask questions in GitHub Discussions
- **Code**: Read existing code for examples

### Asking Questions

When asking for help:
1. Search existing issues and discussions first
2. Provide context (OS version, Xcode version, etc.)
3. Include error messages and logs
4. Describe what you've tried
5. Include minimal reproduction steps if reporting a bug

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and general discussion
- **Pull Requests**: Code reviews and technical discussions

## Recognition

Contributors will be:
- Listed in the project README
- Acknowledged in release notes
- Added to the contributors list on GitHub

Thank you for contributing to GigE Virtual Camera!

---

## Additional Resources

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Semantic Versioning](https://semver.org/)
- [How to Write a Git Commit Message](https://chris.beams.io/posts/git-commit/)

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.
