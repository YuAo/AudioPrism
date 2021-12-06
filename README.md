# AudioPrism

![](https://github.com/YuAo/AudioPrism/workflows/Swift/badge.svg)

AudioPrism implements the `AnalyserNode` functionality defined in the Web Audio API. https://webaudio.github.io/web-audio-api/#AnalyserNode

## Usage

```Swift
import AudioPrism

// Create a `AudioPrism` object.
let prism = try AudioPrism(options: ...)

// Update the `AudioPrism` object with audio buffers.
prism.update(with: ...)

// Get the most recent frequency data
let frequencyData = prism.frequencyData
```

## Documentation

[API Reference](#)

## Swift Package

To use this package in a SwiftPM project, add the following line to the dependencies in your Package.swift file:

```swift
.package(url: "https://github.com/YuAo/AudioPrism", from: "1.0.0"),
```

## Acknowledgements

### Example Audio

Endless Light

by Siddhartha Corsus

https://creativecommons.org/licenses/by-nc/4.0/
