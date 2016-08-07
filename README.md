# Draw
Smooth drawing app for watchOS 3

This app uses a `WKPanGestureRecognizer` to track finger movement and paints a random color stroke. The line is a `UIBezierPath`. It gets smoothed by `addQuadCurve(to:controlPoint)`. The algotrighm accounts for the delay in the pan gesture recognizer by creating a backward projection of the stroke using the velocity of the gesture. It also creates a forward projection to stroke precisely under the user's finger. The app captures the drawing with `UIGraphicsGetImageFromCurrentImageContext` and uses that image for the background of a `WKInterfaceGroup`.

Device screenshot | Movie
---|---
![](http://imgur.com/download/ith2uq7) | ![](http://imgur.com/download/nMWkEVm)
