import SwiftUI
import CoreGraphics

/// Centralized design tokens for RECAP app.
/// Use these values throughout the app to ensure visual consistency
/// and enable systematic accessibility updates.
enum DesignTokens {

    // MARK: - Corner Radii

    enum CornerRadius {
        /// 4pt — smallest elements (trim handles, inline badges)
        static let tiny: CGFloat = 4

        /// 6pt — buttons, small chips
        static let button: CGFloat = 6

        /// 8pt — cards, list items, thumbnails
        static let card: CGFloat = 8

        /// 12pt — sections, modal sheets
        static let section: CGFloat = 12

        /// 16pt — large cards, preview areas
        static let large: CGFloat = 16
    }

    // MARK: - Spacing

    enum Spacing {
        /// 4pt
        static let xxSmall: CGFloat = 4

        /// 8pt — between related elements
        static let xSmall: CGFloat = 8

        /// 12pt — default padding for compact layouts
        static let small: CGFloat = 12

        /// 16pt — standard padding, between cards
        static let medium: CGFloat = 16

        /// 24pt — section padding, large gaps
        static let large: CGFloat = 24

        /// 32pt — page-level padding
        static let xLarge: CGFloat = 32
    }

    // MARK: - Touch Targets

    /// Minimum touch target size (44pt as per WCAG 2.1)
    static let minimumTouchTarget: CGFloat = 44

    // MARK: - Typography

    enum Typography {
        static let largeTitleSize: CGFloat = 34
        static let titleSize: CGFloat = 28
        static let headlineSize: CGFloat = 17
        static let bodySize: CGFloat = 17
        static let subheadlineSize: CGFloat = 15
        static let captionSize: CGFloat = 12
        static let footnoteSize: CGFloat = 13
    }

    // MARK: - Animation

    enum Animation {
        static let fast: Double = 0.15
        static let standard: Double = 0.3
        static let slow: Double = 0.5
    }

    // MARK: - Shadow

    static let cardShadowRadius: CGFloat = 8
    static let cardShadowOpacity: CGFloat = 0.1
}
