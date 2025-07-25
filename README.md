# OpenMultitouchSupport

**This is a fork of [Kyome22/OpenMultitouchSupport](https://github.com/Kyome22/OpenMultitouchSupport) with some added features.**

It adds support for:
- Listing all available devices
- Selecting a device
- Getting device name

---

This enables you easily to observe global multitouch events on the trackpad (only default device).  
I created this library to make MultitouchSupport.framework (Private Framework) easy to use.

## References

This library refers the following frameworks very much. Special Thanks!

- [mhuusko5/M5MultitouchSupport](https://github.com/mhuusko5/M5MultitouchSupport)
- [calftrail/Touch](https://github.com/calftrail/Touch/blob/master/TouchSynthesis/MultitouchSupport.h)

## Requirements

- Development with Xcode 16.0+
- swift-tools-version: 6.0
- Compatible with macOS 13.0+

## Demo

<img src="Screenshots/demo.png" alt="demo" width="632px" />

## Usage

App SandBox must be disabled to use OpenMultitouchSupport.

```swift
import OpenMultitouchSupport

let manager = OMSManager.shared()

Task { [weak self, manager] in
    for await touchData in manager.touchDataStream {
        // use touchData
    }
}

manager.startListening()
manager.stopListening()
```

### The data you can get are as follows

```swift
struct OMSPosition: Sendable {
    var x: Float
    var y: Float
}

struct OMSAxis: Sendable {
    var major: Float
    var minor: Float
}

enum OMSState: String, Sendable {
    case notTouching
    case starting
    case hovering
    case making
    case touching
    case breaking
    case lingering
    case leaving
}

struct OMSTouchData: Sendable {
    var id: Int32
    var position: OMSPosition
    var total: Float // total value of capacitance
    var pressure: Float
    var axis: OMSAxis
    var angle: Float // finger angle
    var density: Float // area density of capacitance
    var state: OMSState
    var timestamp: String
}
```

## Development Workflow

This package uses a hybrid approach with both Swift wrapper code and binary XCFramework distribution. Here's how to update the library:

### Updating Swift Wrapper Code Only

When you need to modify the Swift API layer (files in `Sources/OpenMultitouchSupport/`):

1. **Edit** the Swift files in `Sources/OpenMultitouchSupport/`
2. **Commit and push** changes to GitHub
3. **In consuming projects**: Update packages in Xcode (File → Packages → Update to Latest Package Versions)

Since consuming projects typically use `branch: main`, they will automatically get the latest Swift wrapper changes.

### Updating the Binary XCFramework

When you need to modify the underlying Framework code:

1. **Update** the Framework code in `Framework/OpenMultitouchSupportXCF/`
2. **Build new XCFramework**: 
   ```bash
   ./build_framework.sh
   ```
3. **Create new release**:
   ```bash
   ./release.sh 1.0.x  # Replace x with next version number
   ```
4. **Update Package.swift** to point to the new release URL and checksum
5. **Commit and push** the Package.swift changes
6. **In consuming projects**: Update packages in Xcode

### Release Script

The `release.sh` script automates the binary release process:
- Builds the XCFramework
- Creates a GitHub release with the binary artifact
- Updates Package.swift with the correct URL and checksum
- Commits the changes

This workflow allows rapid iteration on the Swift API while maintaining stable binary releases for the underlying multitouch framework.
