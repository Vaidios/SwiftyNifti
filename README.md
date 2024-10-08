# SwiftyNifti
[![SPM compatible](https://img.shields.io/badge/Swift_Package_Manager-compatible-4BC51D.svg?style=flat)](https://swift.org/package-manager/)



This package makes it easier to read nifti(.nii) files using native Swift code

## Integration

#### Swift Package Manager

You can use [The Swift Package Manager](https://swift.org/package-manager) to install `SwiftyNifti` by adding the proper description to your `Package.swift` file:

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "YOUR_PROJECT_NAME",
    dependencies: [
        .package(url: "https://github.com/Vaidios/swift-nifti.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "YOUR_TARGET", dependencies: [.product(name: "SwiftyNifti", package: "swift-nifti")]
        )
    ]
)
```
