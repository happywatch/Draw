//
//  InterfaceController.swift
//  Draw WatchKit Extension
//
//  Created by temporary on 8/7/16.
//  Copyright © 2016 benmorrow. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {
  
  var penWidth: CGFloat = 7
  
  var previousPoint1: CGPoint!
  var previousPoint2: CGPoint!
  var savedImage: UIImage?
  var penColorHistory = [UIColor](repeating: UIColor.white, count: 3)
  var isInstructionVisible = true
  
  @IBOutlet var canvasGroup: WKInterfaceGroup!
  @IBOutlet var instructionLabel: WKInterfaceLabel!
  
  
  // this method calculates the midpoint between two points
  func midPoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
    return CGPoint(x: (a.x + b.x) * 0.5, y: (a.y + b.y) * 0.5)
  }
  
  
  // this method helps tame large velocity values
  // the plot of sqrt() curves up and out from zero
  // sqrt() doesn't work for negative numbers, so we have to use the absolute value and add the negative sign back in
  func exponentialScale(_ a: CGFloat) -> CGFloat {
    return a >= 0 ? sqrt(a) : -sqrt(abs(a))
  }
  
  func randomColor() {
    var randomColor: UIColor
    
    // don't allow a color that has been already been used during one of the last three draws
    repeat {
      randomColor = colors[Int(arc4random_uniform(UInt32(colors.count)))]
    } while penColorHistory.index(of: randomColor) != nil
    
    // propogate the color history back
    penColorHistory.insert(randomColor, at: 0)
    penColorHistory.removeLast()
  }
  
  func curveThrough(a: CGPoint, b: CGPoint, c: CGPoint, in rect: CGRect, with alphaComponent: CGFloat = 1) -> UIImage {
    let mid2 = midPoint(b, a)
    let mid1 = midPoint(c, b)
    
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
    savedImage?.draw(in: rect)
    let linePath = UIBezierPath()
    linePath.move(to: mid2)
    linePath.addQuadCurve(to: mid1, controlPoint: b)
    penColorHistory.first?.withAlphaComponent(alphaComponent).setStroke()
    linePath.lineWidth = penWidth
    linePath.lineCapStyle = .round
    linePath.stroke()
    let image = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return image
  }
  
  @IBAction func panRecognized(_ sender: AnyObject) {
    guard let panGesture = sender as? WKPanGestureRecognizer else {
      return
    }
    
    if isInstructionVisible {
      instructionLabel.setHidden(true)
      isInstructionVisible = false
    }
    
    let rect = panGesture.objectBounds()
    switch panGesture.state {
    case .began:
      randomColor()
      
      previousPoint1 = panGesture.locationInObject()
      
      // create backward projection
      let velocity = panGesture.velocityInObject()
      // the pan gesture recognizer requires some movement before recognition
      // this multiplier accounts for the delay
      let multiplier: CGFloat = 1.75
      previousPoint2 = CGPoint(x: previousPoint1.x - exponentialScale(velocity.x) * multiplier,
                               y: previousPoint1.y - exponentialScale(velocity.y) * multiplier)
      
    case .changed:
      let currentPoint = panGesture.locationInObject()
      
      // draw a curve through the two mid points between three points. The middle point acts as a control point
      // this creates a smoothly connected curve
      // a downside to this apprach is that the drawing doesn't reach all the way to the the user's finger touch. We create forward and backward projections with the velocity to account for the lag
      let actualImage = curveThrough(a: previousPoint2, b: previousPoint1, c: currentPoint, in: rect)
      savedImage = actualImage
      
      // create forward projection
      let velocity = panGesture.velocityInObject()
      let projectedPoint = CGPoint(x: currentPoint.x + exponentialScale(velocity.x), y: currentPoint.y + exponentialScale(velocity.y))
      let projectedImage = curveThrough(a: previousPoint1,
                                        b: currentPoint,
                                        c: midPoint(currentPoint, projectedPoint),
                                        in: rect,
                                        with: 0.5)
      // show the forward projection but don't save it
      canvasGroup.setBackgroundImage(projectedImage)
      
      previousPoint2 = previousPoint1
      previousPoint1 = currentPoint
      
    case .ended:
      let currentPoint = panGesture.locationInObject()
      let image = curveThrough(a: previousPoint2, b: previousPoint1, c: currentPoint, in: rect)
      canvasGroup.setBackgroundImage(image)
      savedImage = image
    default:
      break
    }
  }
  
  @IBAction func resetButtonPressed() {
    savedImage = nil
    canvasGroup.setBackgroundImage(nil)
    instructionLabel.setHidden(false)
    isInstructionVisible = true
  }
}
