import SwiftUI
import SpriteKit

/// 紙吹雪（SpriteKitパーティクル・アセット不要のプログラム生成）
struct ConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.allowsTransparency = true
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false

        let scene = SKScene(size: UIScreen.main.bounds.size)
        scene.backgroundColor = .clear
        scene.scaleMode = .resizeFill

        let colors: [UIColor] = [
            UIColor(red: 0.97, green: 0.79, blue: 0.28, alpha: 1), // チョーク黄
            UIColor(red: 1.00, green: 0.66, blue: 0.75, alpha: 1), // ピンクチョーク
            UIColor(red: 0.99, green: 0.98, blue: 0.95, alpha: 1), // チョーク白
            UIColor(red: 0.18, green: 0.62, blue: 0.36, alpha: 1), // 緑
        ]
        for color in colors {
            let emitter = SKEmitterNode()
            emitter.particleTexture = Self.particleTexture(color: color)
            emitter.position = CGPoint(x: scene.size.width / 2, y: scene.size.height + 10)
            emitter.particlePositionRange = CGVector(dx: scene.size.width, dy: 0)
            emitter.particleBirthRate = 30
            emitter.numParticlesToEmit = 60
            emitter.particleLifetime = 5
            emitter.particleSpeed = -220
            emitter.particleSpeedRange = 120
            emitter.emissionAngle = -.pi / 2
            emitter.emissionAngleRange = .pi / 8
            emitter.particleRotationSpeed = 4
            emitter.particleRotationRange = .pi
            emitter.particleScale = 0.6
            emitter.particleScaleRange = 0.3
            emitter.yAcceleration = -120
            scene.addChild(emitter)
        }
        view.presentScene(scene)
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {}

    private static func particleTexture(color: UIColor) -> SKTexture {
        let size = CGSize(width: 10, height: 14)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        return SKTexture(image: image)
    }
}
