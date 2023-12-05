//
//  CanvasView.swift
//  DemoMap
//
//  Created by Gaurav Sara on 30/11/23.
//

import UIKit

protocol NotifyTouchEvents: AnyObject {
    func touchBegan(touch: UITouch)
    func touchMoved(touch: UITouch)
    func touchEnded(touch: UITouch)
}

class CanvasView: UIImageView {
    weak var delegate: NotifyTouchEvents?
    var lastPoint = CGPoint.zero
    var brushWidth: CGFloat = 3.0
    var opacity: CGFloat = 1.0
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            self.delegate?.touchBegan(touch: touch)
            lastPoint = touch.location(in: self)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            self.delegate?.touchMoved(touch: touch)
            let currentPoint = touch.location(in: self)
            drawLineFrom(fromPoint: lastPoint, toPoint: currentPoint)
            lastPoint = currentPoint
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            self.delegate?.touchEnded(touch: touch)
        }
    }
    
    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        UIGraphicsBeginImageContext(self.frame.size)
        let context = UIGraphicsGetCurrentContext()
        context?.move(to: fromPoint)
        context?.addLine(to: toPoint)
        context?.setLineCap(.round)
        context?.setLineWidth(brushWidth)
        context?.setStrokeColor(UIColor.init(red: 20.0/255.0, green: 119.0/255.0, blue: 234.0/255.0, alpha: 0.75).cgColor)
        context?.setBlendMode(.normal)
        context?.strokePath()
        
        self.image?.draw(in: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        self.image = UIGraphicsGetImageFromCurrentImageContext()
        self.alpha = opacity
        UIGraphicsEndImageContext()
    }
}
