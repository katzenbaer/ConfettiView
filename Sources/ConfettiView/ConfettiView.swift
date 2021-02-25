import SwiftUI
import UIKit

public struct ConfettiView: UIViewRepresentable {

    private var confetti = [Confetti]()

    public init(confetti: [Confetti]) {
        self.confetti = confetti
    }

    public func makeUIView(context: Context) -> UIConfettiView {
        return UIConfettiView()
    }

    public func updateUIView(_ uiView: UIConfettiView, context: Context) {
        uiView.emit(with: confetti)
    }
}

public enum Confetti {
    /// Confetti shapes
    public enum Shape {

        case circle
        case triangle
        case square

        // A custom shape.
        case custom(CGPath)
    }
    
    public struct Details {
        public init(spin: Bool, birthRate: Float = 50, lifetime: Float = 10, scale: CGFloat = 1, scaleRange: CGFloat = 0.25, color: UIColor? = UIColor.random) {
            self.spin = spin
            self.birthRate = birthRate
            self.lifetime = lifetime
            self.scale = scale
            self.scaleRange = scaleRange
            self.color = color
        }
        
        public var spin: Bool
        public var birthRate: Float = 50
        public var lifetime: Float = 10
        public var scale: CGFloat = 1
        public var scaleRange: CGFloat = 0.25
        public var color: UIColor? = UIColor.random
    }

    /// A shape with a color.
    case shape(Shape, Details)

    /// An image with a tint color.
    case image(UIImage, Details)

    /// A string of characters.
    case text(String, Details)
}


/// The UIView Confetti Emitter
public final class UIConfettiView: UIView {
    
    private var once: Bool = false
    
    func emit(with contents: [Confetti]) {
        if once {
            return
        }
        
        let layer = Layer()
        layer.configure(with: contents)
        layer.frame = self.bounds
        layer.needsDisplayOnBoundsChange = true
        layer.position = CGPoint(x: UIScreen.main.bounds.width / 2 , y: -UIScreen.main.bounds.height)
        layer.emitterShape = .line
        self.layer.addSublayer(layer)
        once.toggle()
    }

}

/// shapes, images, text to be emitted as confetti
fileprivate final class Layer: CAEmitterLayer {
     func configure(with contents: [Confetti]) {
        emitterCells = contents.map { content in
            let cell = CAEmitterCell()

            cell.birthRate = content.details.birthRate
            cell.lifetime = content.details.lifetime
            cell.velocity = CGFloat(cell.birthRate * cell.lifetime)
            cell.velocityRange = cell.velocity / 2
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spinRange = content.details.spin ? .pi * 8 : 0
            cell.scaleRange = content.details.scaleRange
            cell.scale = (1.0 - cell.scaleRange) * content.details.scale
            cell.contents = content.image.cgImage

            if let color = content.details.color {
                cell.color = color.cgColor
            }

            return cell
        }
    }
}

fileprivate extension Confetti.Shape {
    func path(in rect: CGRect) -> CGPath {
        switch self {
        case .circle:
            return CGPath(ellipseIn: rect, transform: nil)
        case .triangle:
            let path = CGMutablePath()
            path.addLines(between: [
                CGPoint(x: rect.midX, y: 0),
                CGPoint(x: rect.maxX, y: rect.maxY),
                CGPoint(x: rect.minX, y: rect.maxY),
                CGPoint(x: rect.midX, y: 0)
            ])

            return path
        case .square:
            return CGPath(rect: rect, transform: nil)
        case .custom(let path):
            return path
        }
    }

    func image(with color: UIColor) -> UIImage {
        let rect = CGRect(origin: .zero, size: CGSize(width: 12.0, height: 12.0))
        return UIGraphicsImageRenderer(size: rect.size).image { context in
            context.cgContext.setFillColor(color.cgColor)
            context.cgContext.addPath(path(in: rect))
            context.cgContext.fillPath()
        }
    }
}

fileprivate extension Confetti {
    var details: Confetti.Details {
        switch self {
        case let .image(_, details),
             let .shape(_, details),
             let .text(_, details):
            return details
        }
    }

    var image: UIImage {
        switch self {
        case let .shape(shape, _):
            return shape.image(with: .white)
        case let .image(image, _):
            return image
        case let .text(string, _):
            let defaultAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16.0)
            ]

            return NSAttributedString(string: "\(string)", attributes: defaultAttributes).image()
        }
    }
}

fileprivate extension NSAttributedString {
    func image() -> UIImage {
        return UIGraphicsImageRenderer(size: size()).image { _ in
            self.draw(at: .zero)
        }
    }
}

fileprivate extension UIColor
{
    public class var random: UIColor {
        let hue : CGFloat = CGFloat(arc4random() % 256) / 256 // use 256 to get full range from 0.0 to 1.0
        let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from white
        let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from black

        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }

}

