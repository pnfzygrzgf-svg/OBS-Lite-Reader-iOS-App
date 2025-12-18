import UIKit

@MainActor
final class Haptics {
    static let shared = Haptics()
    private let generator = UINotificationFeedbackGenerator()

    private init() {}

    func success() {
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    func warning() {
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    func error() {
        generator.prepare()
        generator.notificationOccurred(.error)
    }
}
