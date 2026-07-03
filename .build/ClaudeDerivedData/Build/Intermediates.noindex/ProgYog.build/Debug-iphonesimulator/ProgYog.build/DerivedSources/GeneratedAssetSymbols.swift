import Foundation
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "AccentColor" asset catalog color resource.
    static let accent = DeveloperToolsSupport.ColorResource(name: "AccentColor", bundle: resourceBundle)

    /// The "LaunchBackground" asset catalog color resource.
    static let launchBackground = DeveloperToolsSupport.ColorResource(name: "LaunchBackground", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "LaunchLogo" asset catalog image resource.
    static let launchLogo = DeveloperToolsSupport.ImageResource(name: "LaunchLogo", bundle: resourceBundle)

    /// The "Poses" asset catalog resource namespace.
    enum Poses {

        /// The "Poses/A-1-1-0" asset catalog image resource.
        static let A_1_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/A-1-1-0", bundle: resourceBundle)

        /// The "Poses/A-1-1-1" asset catalog image resource.
        static let A_1_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/A-1-1-1", bundle: resourceBundle)

        /// The "Poses/A-1-2-0" asset catalog image resource.
        static let A_1_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/A-1-2-0", bundle: resourceBundle)

        /// The "Poses/A-1-2-1" asset catalog image resource.
        static let A_1_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/A-1-2-1", bundle: resourceBundle)

        /// The "Poses/A-1-3-0" asset catalog image resource.
        static let A_1_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/A-1-3-0", bundle: resourceBundle)

        /// The "Poses/A-1-3-1" asset catalog image resource.
        static let A_1_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/A-1-3-1", bundle: resourceBundle)

        /// The "Poses/A-1-3-2" asset catalog image resource.
        static let A_1_3_2 = DeveloperToolsSupport.ImageResource(name: "Poses/A-1-3-2", bundle: resourceBundle)

        /// The "Poses/A-1-4-0" asset catalog image resource.
        static let A_1_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/A-1-4-0", bundle: resourceBundle)

        /// The "Poses/A-1-4-1" asset catalog image resource.
        static let A_1_4_1 = DeveloperToolsSupport.ImageResource(name: "Poses/A-1-4-1", bundle: resourceBundle)

        /// The "Poses/A-1-4-2" asset catalog image resource.
        static let A_1_4_2 = DeveloperToolsSupport.ImageResource(name: "Poses/A-1-4-2", bundle: resourceBundle)

        /// The "Poses/A-1-4-3" asset catalog image resource.
        static let A_1_4_3 = DeveloperToolsSupport.ImageResource(name: "Poses/A-1-4-3", bundle: resourceBundle)

        /// The "Poses/A-1-4-4" asset catalog image resource.
        static let A_1_4_4 = DeveloperToolsSupport.ImageResource(name: "Poses/A-1-4-4", bundle: resourceBundle)

        /// The "Poses/A-1-5-0" asset catalog image resource.
        static let A_1_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/A-1-5-0", bundle: resourceBundle)

        /// The "Poses/A-1-5-1" asset catalog image resource.
        static let A_1_5_1 = DeveloperToolsSupport.ImageResource(name: "Poses/A-1-5-1", bundle: resourceBundle)

        /// The "Poses/A-2-1-0" asset catalog image resource.
        static let A_2_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/A-2-1-0", bundle: resourceBundle)

        /// The "Poses/A-2-1-1" asset catalog image resource.
        static let A_2_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/A-2-1-1", bundle: resourceBundle)

        /// The "Poses/A-2-1-2" asset catalog image resource.
        static let A_2_1_2 = DeveloperToolsSupport.ImageResource(name: "Poses/A-2-1-2", bundle: resourceBundle)

        /// The "Poses/A-2-2-0" asset catalog image resource.
        static let A_2_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/A-2-2-0", bundle: resourceBundle)

        /// The "Poses/A-2-2-1" asset catalog image resource.
        static let A_2_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/A-2-2-1", bundle: resourceBundle)

        /// The "Poses/A-2-2-2" asset catalog image resource.
        static let A_2_2_2 = DeveloperToolsSupport.ImageResource(name: "Poses/A-2-2-2", bundle: resourceBundle)

        /// The "Poses/A-2-3-0" asset catalog image resource.
        static let A_2_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/A-2-3-0", bundle: resourceBundle)

        /// The "Poses/A-2-3-1" asset catalog image resource.
        static let A_2_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/A-2-3-1", bundle: resourceBundle)

        /// The "Poses/A-2-4-0" asset catalog image resource.
        static let A_2_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/A-2-4-0", bundle: resourceBundle)

        /// The "Poses/A-2-4-1" asset catalog image resource.
        static let A_2_4_1 = DeveloperToolsSupport.ImageResource(name: "Poses/A-2-4-1", bundle: resourceBundle)

        /// The "Poses/A-2-5-0" asset catalog image resource.
        static let A_2_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/A-2-5-0", bundle: resourceBundle)

        /// The "Poses/A-3-1-0" asset catalog image resource.
        static let A_3_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/A-3-1-0", bundle: resourceBundle)

        /// The "Poses/A-3-1-1" asset catalog image resource.
        static let A_3_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/A-3-1-1", bundle: resourceBundle)

        /// The "Poses/A-3-2-0" asset catalog image resource.
        static let A_3_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/A-3-2-0", bundle: resourceBundle)

        /// The "Poses/A-3-2-1" asset catalog image resource.
        static let A_3_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/A-3-2-1", bundle: resourceBundle)

        /// The "Poses/A-3-2-2" asset catalog image resource.
        static let A_3_2_2 = DeveloperToolsSupport.ImageResource(name: "Poses/A-3-2-2", bundle: resourceBundle)

        /// The "Poses/A-3-3-0" asset catalog image resource.
        static let A_3_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/A-3-3-0", bundle: resourceBundle)

        /// The "Poses/A-3-3-1" asset catalog image resource.
        static let A_3_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/A-3-3-1", bundle: resourceBundle)

        /// The "Poses/A-3-3-2" asset catalog image resource.
        static let A_3_3_2 = DeveloperToolsSupport.ImageResource(name: "Poses/A-3-3-2", bundle: resourceBundle)

        /// The "Poses/A-3-3-3" asset catalog image resource.
        static let A_3_3_3 = DeveloperToolsSupport.ImageResource(name: "Poses/A-3-3-3", bundle: resourceBundle)

        /// The "Poses/A-3-3-4" asset catalog image resource.
        static let A_3_3_4 = DeveloperToolsSupport.ImageResource(name: "Poses/A-3-3-4", bundle: resourceBundle)

        /// The "Poses/A-3-4-0" asset catalog image resource.
        static let A_3_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/A-3-4-0", bundle: resourceBundle)

        /// The "Poses/A-3-4-1" asset catalog image resource.
        static let A_3_4_1 = DeveloperToolsSupport.ImageResource(name: "Poses/A-3-4-1", bundle: resourceBundle)

        /// The "Poses/A-3-4-2" asset catalog image resource.
        static let A_3_4_2 = DeveloperToolsSupport.ImageResource(name: "Poses/A-3-4-2", bundle: resourceBundle)

        /// The "Poses/A-3-4-3" asset catalog image resource.
        static let A_3_4_3 = DeveloperToolsSupport.ImageResource(name: "Poses/A-3-4-3", bundle: resourceBundle)

        /// The "Poses/A-3-5-0" asset catalog image resource.
        static let A_3_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/A-3-5-0", bundle: resourceBundle)

        /// The "Poses/A-3-5-1" asset catalog image resource.
        static let A_3_5_1 = DeveloperToolsSupport.ImageResource(name: "Poses/A-3-5-1", bundle: resourceBundle)

        /// The "Poses/A-4-1-0" asset catalog image resource.
        static let A_4_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/A-4-1-0", bundle: resourceBundle)

        /// The "Poses/A-4-1-1" asset catalog image resource.
        static let A_4_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/A-4-1-1", bundle: resourceBundle)

        /// The "Poses/A-4-2-0" asset catalog image resource.
        static let A_4_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/A-4-2-0", bundle: resourceBundle)

        /// The "Poses/A-4-2-1" asset catalog image resource.
        static let A_4_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/A-4-2-1", bundle: resourceBundle)

        /// The "Poses/A-4-2-2" asset catalog image resource.
        static let A_4_2_2 = DeveloperToolsSupport.ImageResource(name: "Poses/A-4-2-2", bundle: resourceBundle)

        /// The "Poses/A-4-2-3" asset catalog image resource.
        static let A_4_2_3 = DeveloperToolsSupport.ImageResource(name: "Poses/A-4-2-3", bundle: resourceBundle)

        /// The "Poses/A-4-3-0" asset catalog image resource.
        static let A_4_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/A-4-3-0", bundle: resourceBundle)

        /// The "Poses/A-4-3-1" asset catalog image resource.
        static let A_4_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/A-4-3-1", bundle: resourceBundle)

        /// The "Poses/A-4-4-0" asset catalog image resource.
        static let A_4_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/A-4-4-0", bundle: resourceBundle)

        /// The "Poses/A-4-4-1" asset catalog image resource.
        static let A_4_4_1 = DeveloperToolsSupport.ImageResource(name: "Poses/A-4-4-1", bundle: resourceBundle)

        /// The "Poses/A-4-4-2" asset catalog image resource.
        static let A_4_4_2 = DeveloperToolsSupport.ImageResource(name: "Poses/A-4-4-2", bundle: resourceBundle)

        /// The "Poses/A-4-4-3" asset catalog image resource.
        static let A_4_4_3 = DeveloperToolsSupport.ImageResource(name: "Poses/A-4-4-3", bundle: resourceBundle)

        /// The "Poses/A-4-5-0" asset catalog image resource.
        static let A_4_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/A-4-5-0", bundle: resourceBundle)

        /// The "Poses/A-4-5-1" asset catalog image resource.
        static let A_4_5_1 = DeveloperToolsSupport.ImageResource(name: "Poses/A-4-5-1", bundle: resourceBundle)

        /// The "Poses/B-1-1-0" asset catalog image resource.
        static let B_1_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/B-1-1-0", bundle: resourceBundle)

        /// The "Poses/B-1-1-1" asset catalog image resource.
        static let B_1_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/B-1-1-1", bundle: resourceBundle)

        /// The "Poses/B-1-2-0" asset catalog image resource.
        static let B_1_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/B-1-2-0", bundle: resourceBundle)

        /// The "Poses/B-1-2-1" asset catalog image resource.
        static let B_1_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/B-1-2-1", bundle: resourceBundle)

        /// The "Poses/B-1-3-0" asset catalog image resource.
        static let B_1_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/B-1-3-0", bundle: resourceBundle)

        /// The "Poses/B-1-3-1" asset catalog image resource.
        static let B_1_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/B-1-3-1", bundle: resourceBundle)

        /// The "Poses/B-1-4-0" asset catalog image resource.
        static let B_1_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/B-1-4-0", bundle: resourceBundle)

        /// The "Poses/B-1-5-0" asset catalog image resource.
        static let B_1_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/B-1-5-0", bundle: resourceBundle)

        /// The "Poses/B-1-5-1" asset catalog image resource.
        static let B_1_5_1 = DeveloperToolsSupport.ImageResource(name: "Poses/B-1-5-1", bundle: resourceBundle)

        /// The "Poses/B-2-1-0" asset catalog image resource.
        static let B_2_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/B-2-1-0", bundle: resourceBundle)

        /// The "Poses/B-2-1-1" asset catalog image resource.
        static let B_2_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/B-2-1-1", bundle: resourceBundle)

        /// The "Poses/B-2-1-2" asset catalog image resource.
        static let B_2_1_2 = DeveloperToolsSupport.ImageResource(name: "Poses/B-2-1-2", bundle: resourceBundle)

        /// The "Poses/B-2-1-3" asset catalog image resource.
        static let B_2_1_3 = DeveloperToolsSupport.ImageResource(name: "Poses/B-2-1-3", bundle: resourceBundle)

        /// The "Poses/B-2-2-0" asset catalog image resource.
        static let B_2_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/B-2-2-0", bundle: resourceBundle)

        /// The "Poses/B-2-2-1" asset catalog image resource.
        static let B_2_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/B-2-2-1", bundle: resourceBundle)

        /// The "Poses/B-2-3-0" asset catalog image resource.
        static let B_2_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/B-2-3-0", bundle: resourceBundle)

        /// The "Poses/B-2-3-1" asset catalog image resource.
        static let B_2_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/B-2-3-1", bundle: resourceBundle)

        /// The "Poses/B-2-4-0" asset catalog image resource.
        static let B_2_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/B-2-4-0", bundle: resourceBundle)

        /// The "Poses/B-2-4-1" asset catalog image resource.
        static let B_2_4_1 = DeveloperToolsSupport.ImageResource(name: "Poses/B-2-4-1", bundle: resourceBundle)

        /// The "Poses/B-2-5-0" asset catalog image resource.
        static let B_2_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/B-2-5-0", bundle: resourceBundle)

        /// The "Poses/B-3-1-0" asset catalog image resource.
        static let B_3_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/B-3-1-0", bundle: resourceBundle)

        /// The "Poses/B-3-1-1" asset catalog image resource.
        static let B_3_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/B-3-1-1", bundle: resourceBundle)

        /// The "Poses/B-3-2-0" asset catalog image resource.
        static let B_3_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/B-3-2-0", bundle: resourceBundle)

        /// The "Poses/B-3-2-1" asset catalog image resource.
        static let B_3_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/B-3-2-1", bundle: resourceBundle)

        /// The "Poses/B-3-3-0" asset catalog image resource.
        static let B_3_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/B-3-3-0", bundle: resourceBundle)

        /// The "Poses/B-3-3-1" asset catalog image resource.
        static let B_3_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/B-3-3-1", bundle: resourceBundle)

        /// The "Poses/B-3-4-0" asset catalog image resource.
        static let B_3_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/B-3-4-0", bundle: resourceBundle)

        /// The "Poses/B-3-4-1" asset catalog image resource.
        static let B_3_4_1 = DeveloperToolsSupport.ImageResource(name: "Poses/B-3-4-1", bundle: resourceBundle)

        /// The "Poses/B-3-5-0" asset catalog image resource.
        static let B_3_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/B-3-5-0", bundle: resourceBundle)

        /// The "Poses/B-3-5-1" asset catalog image resource.
        static let B_3_5_1 = DeveloperToolsSupport.ImageResource(name: "Poses/B-3-5-1", bundle: resourceBundle)

        /// The "Poses/B-4-1-0" asset catalog image resource.
        static let B_4_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/B-4-1-0", bundle: resourceBundle)

        /// The "Poses/B-4-1-1" asset catalog image resource.
        static let B_4_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/B-4-1-1", bundle: resourceBundle)

        /// The "Poses/B-4-2-0" asset catalog image resource.
        static let B_4_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/B-4-2-0", bundle: resourceBundle)

        /// The "Poses/B-4-2-1" asset catalog image resource.
        static let B_4_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/B-4-2-1", bundle: resourceBundle)

        /// The "Poses/B-4-3-0" asset catalog image resource.
        static let B_4_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/B-4-3-0", bundle: resourceBundle)

        /// The "Poses/B-4-3-1" asset catalog image resource.
        static let B_4_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/B-4-3-1", bundle: resourceBundle)

        /// The "Poses/B-4-3-2" asset catalog image resource.
        static let B_4_3_2 = DeveloperToolsSupport.ImageResource(name: "Poses/B-4-3-2", bundle: resourceBundle)

        /// The "Poses/B-4-4-0" asset catalog image resource.
        static let B_4_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/B-4-4-0", bundle: resourceBundle)

        /// The "Poses/B-4-4-1" asset catalog image resource.
        static let B_4_4_1 = DeveloperToolsSupport.ImageResource(name: "Poses/B-4-4-1", bundle: resourceBundle)

        /// The "Poses/B-4-5-0" asset catalog image resource.
        static let B_4_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/B-4-5-0", bundle: resourceBundle)

        /// The "Poses/B-4-5-1" asset catalog image resource.
        static let B_4_5_1 = DeveloperToolsSupport.ImageResource(name: "Poses/B-4-5-1", bundle: resourceBundle)

        /// The "Poses/C-1-1-0" asset catalog image resource.
        static let C_1_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-1-1-0", bundle: resourceBundle)

        /// The "Poses/C-1-1-1" asset catalog image resource.
        static let C_1_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/C-1-1-1", bundle: resourceBundle)

        /// The "Poses/C-1-2-0" asset catalog image resource.
        static let C_1_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-1-2-0", bundle: resourceBundle)

        /// The "Poses/C-1-2-1" asset catalog image resource.
        static let C_1_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/C-1-2-1", bundle: resourceBundle)

        /// The "Poses/C-1-3-0" asset catalog image resource.
        static let C_1_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-1-3-0", bundle: resourceBundle)

        /// The "Poses/C-1-3-1" asset catalog image resource.
        static let C_1_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/C-1-3-1", bundle: resourceBundle)

        /// The "Poses/C-1-4-0" asset catalog image resource.
        static let C_1_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-1-4-0", bundle: resourceBundle)

        /// The "Poses/C-1-4-1" asset catalog image resource.
        static let C_1_4_1 = DeveloperToolsSupport.ImageResource(name: "Poses/C-1-4-1", bundle: resourceBundle)

        /// The "Poses/C-1-5-0" asset catalog image resource.
        static let C_1_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-1-5-0", bundle: resourceBundle)

        /// The "Poses/C-1-5-1" asset catalog image resource.
        static let C_1_5_1 = DeveloperToolsSupport.ImageResource(name: "Poses/C-1-5-1", bundle: resourceBundle)

        /// The "Poses/C-1-5-2" asset catalog image resource.
        static let C_1_5_2 = DeveloperToolsSupport.ImageResource(name: "Poses/C-1-5-2", bundle: resourceBundle)

        /// The "Poses/C-2-1-0" asset catalog image resource.
        static let C_2_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-2-1-0", bundle: resourceBundle)

        /// The "Poses/C-2-1-1" asset catalog image resource.
        static let C_2_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/C-2-1-1", bundle: resourceBundle)

        /// The "Poses/C-2-2-0" asset catalog image resource.
        static let C_2_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-2-2-0", bundle: resourceBundle)

        /// The "Poses/C-2-2-1" asset catalog image resource.
        static let C_2_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/C-2-2-1", bundle: resourceBundle)

        /// The "Poses/C-2-3-0" asset catalog image resource.
        static let C_2_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-2-3-0", bundle: resourceBundle)

        /// The "Poses/C-2-3-1" asset catalog image resource.
        static let C_2_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/C-2-3-1", bundle: resourceBundle)

        /// The "Poses/C-2-4-0" asset catalog image resource.
        static let C_2_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-2-4-0", bundle: resourceBundle)

        /// The "Poses/C-2-4-1" asset catalog image resource.
        static let C_2_4_1 = DeveloperToolsSupport.ImageResource(name: "Poses/C-2-4-1", bundle: resourceBundle)

        /// The "Poses/C-2-5-0" asset catalog image resource.
        static let C_2_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-2-5-0", bundle: resourceBundle)

        /// The "Poses/C-2-5-1" asset catalog image resource.
        static let C_2_5_1 = DeveloperToolsSupport.ImageResource(name: "Poses/C-2-5-1", bundle: resourceBundle)

        /// The "Poses/C-3-1-0" asset catalog image resource.
        static let C_3_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-3-1-0", bundle: resourceBundle)

        /// The "Poses/C-3-1-1" asset catalog image resource.
        static let C_3_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/C-3-1-1", bundle: resourceBundle)

        /// The "Poses/C-3-2-0" asset catalog image resource.
        static let C_3_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-3-2-0", bundle: resourceBundle)

        /// The "Poses/C-3-2-1" asset catalog image resource.
        static let C_3_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/C-3-2-1", bundle: resourceBundle)

        /// The "Poses/C-3-3-0" asset catalog image resource.
        static let C_3_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-3-3-0", bundle: resourceBundle)

        /// The "Poses/C-3-3-1" asset catalog image resource.
        static let C_3_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/C-3-3-1", bundle: resourceBundle)

        /// The "Poses/C-3-4-0" asset catalog image resource.
        static let C_3_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-3-4-0", bundle: resourceBundle)

        /// The "Poses/C-3-4-1" asset catalog image resource.
        static let C_3_4_1 = DeveloperToolsSupport.ImageResource(name: "Poses/C-3-4-1", bundle: resourceBundle)

        /// The "Poses/C-3-4-2" asset catalog image resource.
        static let C_3_4_2 = DeveloperToolsSupport.ImageResource(name: "Poses/C-3-4-2", bundle: resourceBundle)

        /// The "Poses/C-3-5-0" asset catalog image resource.
        static let C_3_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-3-5-0", bundle: resourceBundle)

        /// The "Poses/C-3-5-1" asset catalog image resource.
        static let C_3_5_1 = DeveloperToolsSupport.ImageResource(name: "Poses/C-3-5-1", bundle: resourceBundle)

        /// The "Poses/C-4-1-0" asset catalog image resource.
        static let C_4_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-4-1-0", bundle: resourceBundle)

        /// The "Poses/C-4-1-1" asset catalog image resource.
        static let C_4_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/C-4-1-1", bundle: resourceBundle)

        /// The "Poses/C-4-2-0" asset catalog image resource.
        static let C_4_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-4-2-0", bundle: resourceBundle)

        /// The "Poses/C-4-2-1" asset catalog image resource.
        static let C_4_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/C-4-2-1", bundle: resourceBundle)

        /// The "Poses/C-4-2-2" asset catalog image resource.
        static let C_4_2_2 = DeveloperToolsSupport.ImageResource(name: "Poses/C-4-2-2", bundle: resourceBundle)

        /// The "Poses/C-4-2-3" asset catalog image resource.
        static let C_4_2_3 = DeveloperToolsSupport.ImageResource(name: "Poses/C-4-2-3", bundle: resourceBundle)

        /// The "Poses/C-4-2-4" asset catalog image resource.
        static let C_4_2_4 = DeveloperToolsSupport.ImageResource(name: "Poses/C-4-2-4", bundle: resourceBundle)

        /// The "Poses/C-4-2-5" asset catalog image resource.
        static let C_4_2_5 = DeveloperToolsSupport.ImageResource(name: "Poses/C-4-2-5", bundle: resourceBundle)

        /// The "Poses/C-4-2-6" asset catalog image resource.
        static let C_4_2_6 = DeveloperToolsSupport.ImageResource(name: "Poses/C-4-2-6", bundle: resourceBundle)

        /// The "Poses/C-4-2-7" asset catalog image resource.
        static let C_4_2_7 = DeveloperToolsSupport.ImageResource(name: "Poses/C-4-2-7", bundle: resourceBundle)

        /// The "Poses/C-4-2-8" asset catalog image resource.
        static let C_4_2_8 = DeveloperToolsSupport.ImageResource(name: "Poses/C-4-2-8", bundle: resourceBundle)

        /// The "Poses/C-5-1-0" asset catalog image resource.
        static let C_5_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-5-1-0", bundle: resourceBundle)

        /// The "Poses/C-5-2-0" asset catalog image resource.
        static let C_5_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-5-2-0", bundle: resourceBundle)

        /// The "Poses/C-5-3-0" asset catalog image resource.
        static let C_5_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-5-3-0", bundle: resourceBundle)

        /// The "Poses/C-5-4-0" asset catalog image resource.
        static let C_5_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-5-4-0", bundle: resourceBundle)

        /// The "Poses/C-5-5-0" asset catalog image resource.
        static let C_5_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-5-5-0", bundle: resourceBundle)

        /// The "Poses/C-5-5-1" asset catalog image resource.
        static let C_5_5_1 = DeveloperToolsSupport.ImageResource(name: "Poses/C-5-5-1", bundle: resourceBundle)

        /// The "Poses/C-6-1-0" asset catalog image resource.
        static let C_6_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-6-1-0", bundle: resourceBundle)

        /// The "Poses/C-6-1-1" asset catalog image resource.
        static let C_6_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/C-6-1-1", bundle: resourceBundle)

        /// The "Poses/C-6-1-2" asset catalog image resource.
        static let C_6_1_2 = DeveloperToolsSupport.ImageResource(name: "Poses/C-6-1-2", bundle: resourceBundle)

        /// The "Poses/C-6-2-0" asset catalog image resource.
        static let C_6_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-6-2-0", bundle: resourceBundle)

        /// The "Poses/C-6-2-1" asset catalog image resource.
        static let C_6_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/C-6-2-1", bundle: resourceBundle)

        /// The "Poses/C-6-3-0" asset catalog image resource.
        static let C_6_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-6-3-0", bundle: resourceBundle)

        /// The "Poses/C-6-3-1" asset catalog image resource.
        static let C_6_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/C-6-3-1", bundle: resourceBundle)

        /// The "Poses/C-6-4-0" asset catalog image resource.
        static let C_6_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-6-4-0", bundle: resourceBundle)

        /// The "Poses/C-6-4-1" asset catalog image resource.
        static let C_6_4_1 = DeveloperToolsSupport.ImageResource(name: "Poses/C-6-4-1", bundle: resourceBundle)

        /// The "Poses/C-6-5-0" asset catalog image resource.
        static let C_6_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/C-6-5-0", bundle: resourceBundle)

        /// The "Poses/C-6-5-1" asset catalog image resource.
        static let C_6_5_1 = DeveloperToolsSupport.ImageResource(name: "Poses/C-6-5-1", bundle: resourceBundle)

        /// The "Poses/D-1-1-0" asset catalog image resource.
        static let D_1_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-1-1-0", bundle: resourceBundle)

        /// The "Poses/D-1-1-1" asset catalog image resource.
        static let D_1_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-1-1-1", bundle: resourceBundle)

        /// The "Poses/D-1-1-2" asset catalog image resource.
        static let D_1_1_2 = DeveloperToolsSupport.ImageResource(name: "Poses/D-1-1-2", bundle: resourceBundle)

        /// The "Poses/D-1-2-0" asset catalog image resource.
        static let D_1_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-1-2-0", bundle: resourceBundle)

        /// The "Poses/D-1-2-1" asset catalog image resource.
        static let D_1_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-1-2-1", bundle: resourceBundle)

        /// The "Poses/D-1-2-2" asset catalog image resource.
        static let D_1_2_2 = DeveloperToolsSupport.ImageResource(name: "Poses/D-1-2-2", bundle: resourceBundle)

        /// The "Poses/D-1-3-0" asset catalog image resource.
        static let D_1_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-1-3-0", bundle: resourceBundle)

        /// The "Poses/D-1-3-1" asset catalog image resource.
        static let D_1_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-1-3-1", bundle: resourceBundle)

        /// The "Poses/D-1-3-2" asset catalog image resource.
        static let D_1_3_2 = DeveloperToolsSupport.ImageResource(name: "Poses/D-1-3-2", bundle: resourceBundle)

        /// The "Poses/D-1-4-0" asset catalog image resource.
        static let D_1_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-1-4-0", bundle: resourceBundle)

        /// The "Poses/D-1-4-1" asset catalog image resource.
        static let D_1_4_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-1-4-1", bundle: resourceBundle)

        /// The "Poses/D-1-4-2" asset catalog image resource.
        static let D_1_4_2 = DeveloperToolsSupport.ImageResource(name: "Poses/D-1-4-2", bundle: resourceBundle)

        /// The "Poses/D-1-5-0" asset catalog image resource.
        static let D_1_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-1-5-0", bundle: resourceBundle)

        /// The "Poses/D-2-1-0" asset catalog image resource.
        static let D_2_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-2-1-0", bundle: resourceBundle)

        /// The "Poses/D-2-1-1" asset catalog image resource.
        static let D_2_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-2-1-1", bundle: resourceBundle)

        /// The "Poses/D-2-1-2" asset catalog image resource.
        static let D_2_1_2 = DeveloperToolsSupport.ImageResource(name: "Poses/D-2-1-2", bundle: resourceBundle)

        /// The "Poses/D-2-2-0" asset catalog image resource.
        static let D_2_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-2-2-0", bundle: resourceBundle)

        /// The "Poses/D-2-2-1" asset catalog image resource.
        static let D_2_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-2-2-1", bundle: resourceBundle)

        /// The "Poses/D-2-2-2" asset catalog image resource.
        static let D_2_2_2 = DeveloperToolsSupport.ImageResource(name: "Poses/D-2-2-2", bundle: resourceBundle)

        /// The "Poses/D-2-3-0" asset catalog image resource.
        static let D_2_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-2-3-0", bundle: resourceBundle)

        /// The "Poses/D-2-3-1" asset catalog image resource.
        static let D_2_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-2-3-1", bundle: resourceBundle)

        /// The "Poses/D-2-3-2" asset catalog image resource.
        static let D_2_3_2 = DeveloperToolsSupport.ImageResource(name: "Poses/D-2-3-2", bundle: resourceBundle)

        /// The "Poses/D-2-4-0" asset catalog image resource.
        static let D_2_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-2-4-0", bundle: resourceBundle)

        /// The "Poses/D-2-4-1" asset catalog image resource.
        static let D_2_4_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-2-4-1", bundle: resourceBundle)

        /// The "Poses/D-2-4-2" asset catalog image resource.
        static let D_2_4_2 = DeveloperToolsSupport.ImageResource(name: "Poses/D-2-4-2", bundle: resourceBundle)

        /// The "Poses/D-2-5-0" asset catalog image resource.
        static let D_2_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-2-5-0", bundle: resourceBundle)

        /// The "Poses/D-2-5-1" asset catalog image resource.
        static let D_2_5_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-2-5-1", bundle: resourceBundle)

        /// The "Poses/D-3-1-0" asset catalog image resource.
        static let D_3_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-3-1-0", bundle: resourceBundle)

        /// The "Poses/D-3-1-1" asset catalog image resource.
        static let D_3_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-3-1-1", bundle: resourceBundle)

        /// The "Poses/D-3-1-2" asset catalog image resource.
        static let D_3_1_2 = DeveloperToolsSupport.ImageResource(name: "Poses/D-3-1-2", bundle: resourceBundle)

        /// The "Poses/D-3-2-0" asset catalog image resource.
        static let D_3_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-3-2-0", bundle: resourceBundle)

        /// The "Poses/D-3-2-1" asset catalog image resource.
        static let D_3_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-3-2-1", bundle: resourceBundle)

        /// The "Poses/D-3-2-2" asset catalog image resource.
        static let D_3_2_2 = DeveloperToolsSupport.ImageResource(name: "Poses/D-3-2-2", bundle: resourceBundle)

        /// The "Poses/D-3-3-0" asset catalog image resource.
        static let D_3_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-3-3-0", bundle: resourceBundle)

        /// The "Poses/D-3-3-1" asset catalog image resource.
        static let D_3_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-3-3-1", bundle: resourceBundle)

        /// The "Poses/D-3-3-2" asset catalog image resource.
        static let D_3_3_2 = DeveloperToolsSupport.ImageResource(name: "Poses/D-3-3-2", bundle: resourceBundle)

        /// The "Poses/D-3-4-0" asset catalog image resource.
        static let D_3_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-3-4-0", bundle: resourceBundle)

        /// The "Poses/D-3-4-1" asset catalog image resource.
        static let D_3_4_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-3-4-1", bundle: resourceBundle)

        /// The "Poses/D-3-4-2" asset catalog image resource.
        static let D_3_4_2 = DeveloperToolsSupport.ImageResource(name: "Poses/D-3-4-2", bundle: resourceBundle)

        /// The "Poses/D-3-5-0" asset catalog image resource.
        static let D_3_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-3-5-0", bundle: resourceBundle)

        /// The "Poses/D-3-5-1" asset catalog image resource.
        static let D_3_5_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-3-5-1", bundle: resourceBundle)

        /// The "Poses/D-4-1-0" asset catalog image resource.
        static let D_4_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-4-1-0", bundle: resourceBundle)

        /// The "Poses/D-4-1-1" asset catalog image resource.
        static let D_4_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-4-1-1", bundle: resourceBundle)

        /// The "Poses/D-4-1-2" asset catalog image resource.
        static let D_4_1_2 = DeveloperToolsSupport.ImageResource(name: "Poses/D-4-1-2", bundle: resourceBundle)

        /// The "Poses/D-4-2-0" asset catalog image resource.
        static let D_4_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-4-2-0", bundle: resourceBundle)

        /// The "Poses/D-4-2-1" asset catalog image resource.
        static let D_4_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-4-2-1", bundle: resourceBundle)

        /// The "Poses/D-4-2-2" asset catalog image resource.
        static let D_4_2_2 = DeveloperToolsSupport.ImageResource(name: "Poses/D-4-2-2", bundle: resourceBundle)

        /// The "Poses/D-4-3-0" asset catalog image resource.
        static let D_4_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-4-3-0", bundle: resourceBundle)

        /// The "Poses/D-4-3-1" asset catalog image resource.
        static let D_4_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-4-3-1", bundle: resourceBundle)

        /// The "Poses/D-4-3-2" asset catalog image resource.
        static let D_4_3_2 = DeveloperToolsSupport.ImageResource(name: "Poses/D-4-3-2", bundle: resourceBundle)

        /// The "Poses/D-4-4-0" asset catalog image resource.
        static let D_4_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-4-4-0", bundle: resourceBundle)

        /// The "Poses/D-4-4-1" asset catalog image resource.
        static let D_4_4_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-4-4-1", bundle: resourceBundle)

        /// The "Poses/D-4-4-2" asset catalog image resource.
        static let D_4_4_2 = DeveloperToolsSupport.ImageResource(name: "Poses/D-4-4-2", bundle: resourceBundle)

        /// The "Poses/D-4-4-3" asset catalog image resource.
        static let D_4_4_3 = DeveloperToolsSupport.ImageResource(name: "Poses/D-4-4-3", bundle: resourceBundle)

        /// The "Poses/D-4-4-4" asset catalog image resource.
        static let D_4_4_4 = DeveloperToolsSupport.ImageResource(name: "Poses/D-4-4-4", bundle: resourceBundle)

        /// The "Poses/D-4-5-0" asset catalog image resource.
        static let D_4_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-4-5-0", bundle: resourceBundle)

        /// The "Poses/D-4-5-1" asset catalog image resource.
        static let D_4_5_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-4-5-1", bundle: resourceBundle)

        /// The "Poses/D-5-1-0" asset catalog image resource.
        static let D_5_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-5-1-0", bundle: resourceBundle)

        /// The "Poses/D-5-1-1" asset catalog image resource.
        static let D_5_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-5-1-1", bundle: resourceBundle)

        /// The "Poses/D-5-2-0" asset catalog image resource.
        static let D_5_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-5-2-0", bundle: resourceBundle)

        /// The "Poses/D-5-2-1" asset catalog image resource.
        static let D_5_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-5-2-1", bundle: resourceBundle)

        /// The "Poses/D-5-2-2" asset catalog image resource.
        static let D_5_2_2 = DeveloperToolsSupport.ImageResource(name: "Poses/D-5-2-2", bundle: resourceBundle)

        /// The "Poses/D-5-3-0" asset catalog image resource.
        static let D_5_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-5-3-0", bundle: resourceBundle)

        /// The "Poses/D-5-3-1" asset catalog image resource.
        static let D_5_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-5-3-1", bundle: resourceBundle)

        /// The "Poses/D-5-4-0" asset catalog image resource.
        static let D_5_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-5-4-0", bundle: resourceBundle)

        /// The "Poses/D-5-4-1" asset catalog image resource.
        static let D_5_4_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-5-4-1", bundle: resourceBundle)

        /// The "Poses/D-5-4-2" asset catalog image resource.
        static let D_5_4_2 = DeveloperToolsSupport.ImageResource(name: "Poses/D-5-4-2", bundle: resourceBundle)

        /// The "Poses/D-5-5-0" asset catalog image resource.
        static let D_5_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-5-5-0", bundle: resourceBundle)

        /// The "Poses/D-6-1-0" asset catalog image resource.
        static let D_6_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-6-1-0", bundle: resourceBundle)

        /// The "Poses/D-6-1-1" asset catalog image resource.
        static let D_6_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-6-1-1", bundle: resourceBundle)

        /// The "Poses/D-6-1-2" asset catalog image resource.
        static let D_6_1_2 = DeveloperToolsSupport.ImageResource(name: "Poses/D-6-1-2", bundle: resourceBundle)

        /// The "Poses/D-6-2-0" asset catalog image resource.
        static let D_6_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-6-2-0", bundle: resourceBundle)

        /// The "Poses/D-6-2-1" asset catalog image resource.
        static let D_6_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-6-2-1", bundle: resourceBundle)

        /// The "Poses/D-6-2-2" asset catalog image resource.
        static let D_6_2_2 = DeveloperToolsSupport.ImageResource(name: "Poses/D-6-2-2", bundle: resourceBundle)

        /// The "Poses/D-6-3-0" asset catalog image resource.
        static let D_6_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-6-3-0", bundle: resourceBundle)

        /// The "Poses/D-6-3-1" asset catalog image resource.
        static let D_6_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-6-3-1", bundle: resourceBundle)

        /// The "Poses/D-6-3-2" asset catalog image resource.
        static let D_6_3_2 = DeveloperToolsSupport.ImageResource(name: "Poses/D-6-3-2", bundle: resourceBundle)

        /// The "Poses/D-6-4-0" asset catalog image resource.
        static let D_6_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-6-4-0", bundle: resourceBundle)

        /// The "Poses/D-6-4-1" asset catalog image resource.
        static let D_6_4_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-6-4-1", bundle: resourceBundle)

        /// The "Poses/D-6-4-2" asset catalog image resource.
        static let D_6_4_2 = DeveloperToolsSupport.ImageResource(name: "Poses/D-6-4-2", bundle: resourceBundle)

        /// The "Poses/D-6-5-0" asset catalog image resource.
        static let D_6_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/D-6-5-0", bundle: resourceBundle)

        /// The "Poses/D-6-5-1" asset catalog image resource.
        static let D_6_5_1 = DeveloperToolsSupport.ImageResource(name: "Poses/D-6-5-1", bundle: resourceBundle)

        /// The "Poses/E-1-1-0" asset catalog image resource.
        static let E_1_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-1-1-0", bundle: resourceBundle)

        /// The "Poses/E-1-1-1" asset catalog image resource.
        static let E_1_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-1-1-1", bundle: resourceBundle)

        /// The "Poses/E-1-1-2" asset catalog image resource.
        static let E_1_1_2 = DeveloperToolsSupport.ImageResource(name: "Poses/E-1-1-2", bundle: resourceBundle)

        /// The "Poses/E-1-2-0" asset catalog image resource.
        static let E_1_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-1-2-0", bundle: resourceBundle)

        /// The "Poses/E-1-2-1" asset catalog image resource.
        static let E_1_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-1-2-1", bundle: resourceBundle)

        /// The "Poses/E-1-2-2" asset catalog image resource.
        static let E_1_2_2 = DeveloperToolsSupport.ImageResource(name: "Poses/E-1-2-2", bundle: resourceBundle)

        /// The "Poses/E-1-3-0" asset catalog image resource.
        static let E_1_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-1-3-0", bundle: resourceBundle)

        /// The "Poses/E-1-3-1" asset catalog image resource.
        static let E_1_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-1-3-1", bundle: resourceBundle)

        /// The "Poses/E-1-3-2" asset catalog image resource.
        static let E_1_3_2 = DeveloperToolsSupport.ImageResource(name: "Poses/E-1-3-2", bundle: resourceBundle)

        /// The "Poses/E-1-4-0" asset catalog image resource.
        static let E_1_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-1-4-0", bundle: resourceBundle)

        /// The "Poses/E-1-4-1" asset catalog image resource.
        static let E_1_4_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-1-4-1", bundle: resourceBundle)

        /// The "Poses/E-1-4-2" asset catalog image resource.
        static let E_1_4_2 = DeveloperToolsSupport.ImageResource(name: "Poses/E-1-4-2", bundle: resourceBundle)

        /// The "Poses/E-1-5-0" asset catalog image resource.
        static let E_1_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-1-5-0", bundle: resourceBundle)

        /// The "Poses/E-2-1-0" asset catalog image resource.
        static let E_2_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-2-1-0", bundle: resourceBundle)

        /// The "Poses/E-2-1-1" asset catalog image resource.
        static let E_2_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-2-1-1", bundle: resourceBundle)

        /// The "Poses/E-2-1-2" asset catalog image resource.
        static let E_2_1_2 = DeveloperToolsSupport.ImageResource(name: "Poses/E-2-1-2", bundle: resourceBundle)

        /// The "Poses/E-2-2-0" asset catalog image resource.
        static let E_2_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-2-2-0", bundle: resourceBundle)

        /// The "Poses/E-2-2-1" asset catalog image resource.
        static let E_2_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-2-2-1", bundle: resourceBundle)

        /// The "Poses/E-2-2-2" asset catalog image resource.
        static let E_2_2_2 = DeveloperToolsSupport.ImageResource(name: "Poses/E-2-2-2", bundle: resourceBundle)

        /// The "Poses/E-2-3-0" asset catalog image resource.
        static let E_2_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-2-3-0", bundle: resourceBundle)

        /// The "Poses/E-2-3-1" asset catalog image resource.
        static let E_2_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-2-3-1", bundle: resourceBundle)

        /// The "Poses/E-2-3-2" asset catalog image resource.
        static let E_2_3_2 = DeveloperToolsSupport.ImageResource(name: "Poses/E-2-3-2", bundle: resourceBundle)

        /// The "Poses/E-2-4-0" asset catalog image resource.
        static let E_2_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-2-4-0", bundle: resourceBundle)

        /// The "Poses/E-2-4-1" asset catalog image resource.
        static let E_2_4_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-2-4-1", bundle: resourceBundle)

        /// The "Poses/E-2-4-2" asset catalog image resource.
        static let E_2_4_2 = DeveloperToolsSupport.ImageResource(name: "Poses/E-2-4-2", bundle: resourceBundle)

        /// The "Poses/E-2-5-0" asset catalog image resource.
        static let E_2_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-2-5-0", bundle: resourceBundle)

        /// The "Poses/E-3-1-0" asset catalog image resource.
        static let E_3_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-3-1-0", bundle: resourceBundle)

        /// The "Poses/E-3-1-1" asset catalog image resource.
        static let E_3_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-3-1-1", bundle: resourceBundle)

        /// The "Poses/E-3-1-2" asset catalog image resource.
        static let E_3_1_2 = DeveloperToolsSupport.ImageResource(name: "Poses/E-3-1-2", bundle: resourceBundle)

        /// The "Poses/E-3-2-0" asset catalog image resource.
        static let E_3_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-3-2-0", bundle: resourceBundle)

        /// The "Poses/E-3-2-1" asset catalog image resource.
        static let E_3_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-3-2-1", bundle: resourceBundle)

        /// The "Poses/E-3-2-2" asset catalog image resource.
        static let E_3_2_2 = DeveloperToolsSupport.ImageResource(name: "Poses/E-3-2-2", bundle: resourceBundle)

        /// The "Poses/E-3-3-0" asset catalog image resource.
        static let E_3_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-3-3-0", bundle: resourceBundle)

        /// The "Poses/E-3-3-1" asset catalog image resource.
        static let E_3_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-3-3-1", bundle: resourceBundle)

        /// The "Poses/E-3-3-2" asset catalog image resource.
        static let E_3_3_2 = DeveloperToolsSupport.ImageResource(name: "Poses/E-3-3-2", bundle: resourceBundle)

        /// The "Poses/E-3-4-0" asset catalog image resource.
        static let E_3_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-3-4-0", bundle: resourceBundle)

        /// The "Poses/E-3-4-1" asset catalog image resource.
        static let E_3_4_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-3-4-1", bundle: resourceBundle)

        /// The "Poses/E-3-4-2" asset catalog image resource.
        static let E_3_4_2 = DeveloperToolsSupport.ImageResource(name: "Poses/E-3-4-2", bundle: resourceBundle)

        /// The "Poses/E-3-5-0" asset catalog image resource.
        static let E_3_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-3-5-0", bundle: resourceBundle)

        /// The "Poses/E-3-5-1" asset catalog image resource.
        static let E_3_5_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-3-5-1", bundle: resourceBundle)

        /// The "Poses/E-4-1-0" asset catalog image resource.
        static let E_4_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-4-1-0", bundle: resourceBundle)

        /// The "Poses/E-4-1-1" asset catalog image resource.
        static let E_4_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-4-1-1", bundle: resourceBundle)

        /// The "Poses/E-4-1-2" asset catalog image resource.
        static let E_4_1_2 = DeveloperToolsSupport.ImageResource(name: "Poses/E-4-1-2", bundle: resourceBundle)

        /// The "Poses/E-4-2-0" asset catalog image resource.
        static let E_4_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-4-2-0", bundle: resourceBundle)

        /// The "Poses/E-4-2-1" asset catalog image resource.
        static let E_4_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-4-2-1", bundle: resourceBundle)

        /// The "Poses/E-4-2-2" asset catalog image resource.
        static let E_4_2_2 = DeveloperToolsSupport.ImageResource(name: "Poses/E-4-2-2", bundle: resourceBundle)

        /// The "Poses/E-4-3-0" asset catalog image resource.
        static let E_4_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-4-3-0", bundle: resourceBundle)

        /// The "Poses/E-4-3-1" asset catalog image resource.
        static let E_4_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-4-3-1", bundle: resourceBundle)

        /// The "Poses/E-4-3-2" asset catalog image resource.
        static let E_4_3_2 = DeveloperToolsSupport.ImageResource(name: "Poses/E-4-3-2", bundle: resourceBundle)

        /// The "Poses/E-4-4-0" asset catalog image resource.
        static let E_4_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-4-4-0", bundle: resourceBundle)

        /// The "Poses/E-4-4-1" asset catalog image resource.
        static let E_4_4_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-4-4-1", bundle: resourceBundle)

        /// The "Poses/E-4-4-2" asset catalog image resource.
        static let E_4_4_2 = DeveloperToolsSupport.ImageResource(name: "Poses/E-4-4-2", bundle: resourceBundle)

        /// The "Poses/E-4-4-3" asset catalog image resource.
        static let E_4_4_3 = DeveloperToolsSupport.ImageResource(name: "Poses/E-4-4-3", bundle: resourceBundle)

        /// The "Poses/E-4-4-4" asset catalog image resource.
        static let E_4_4_4 = DeveloperToolsSupport.ImageResource(name: "Poses/E-4-4-4", bundle: resourceBundle)

        /// The "Poses/E-4-5-0" asset catalog image resource.
        static let E_4_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-4-5-0", bundle: resourceBundle)

        /// The "Poses/E-5-1-0" asset catalog image resource.
        static let E_5_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-5-1-0", bundle: resourceBundle)

        /// The "Poses/E-5-1-1" asset catalog image resource.
        static let E_5_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-5-1-1", bundle: resourceBundle)

        /// The "Poses/E-5-1-2" asset catalog image resource.
        static let E_5_1_2 = DeveloperToolsSupport.ImageResource(name: "Poses/E-5-1-2", bundle: resourceBundle)

        /// The "Poses/E-5-2-0" asset catalog image resource.
        static let E_5_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-5-2-0", bundle: resourceBundle)

        /// The "Poses/E-5-2-1" asset catalog image resource.
        static let E_5_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-5-2-1", bundle: resourceBundle)

        /// The "Poses/E-5-2-2" asset catalog image resource.
        static let E_5_2_2 = DeveloperToolsSupport.ImageResource(name: "Poses/E-5-2-2", bundle: resourceBundle)

        /// The "Poses/E-5-3-0" asset catalog image resource.
        static let E_5_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-5-3-0", bundle: resourceBundle)

        /// The "Poses/E-5-3-1" asset catalog image resource.
        static let E_5_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-5-3-1", bundle: resourceBundle)

        /// The "Poses/E-5-3-2" asset catalog image resource.
        static let E_5_3_2 = DeveloperToolsSupport.ImageResource(name: "Poses/E-5-3-2", bundle: resourceBundle)

        /// The "Poses/E-5-4-0" asset catalog image resource.
        static let E_5_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-5-4-0", bundle: resourceBundle)

        /// The "Poses/E-5-4-1" asset catalog image resource.
        static let E_5_4_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-5-4-1", bundle: resourceBundle)

        /// The "Poses/E-5-4-2" asset catalog image resource.
        static let E_5_4_2 = DeveloperToolsSupport.ImageResource(name: "Poses/E-5-4-2", bundle: resourceBundle)

        /// The "Poses/E-5-5-0" asset catalog image resource.
        static let E_5_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-5-5-0", bundle: resourceBundle)

        /// The "Poses/E-5-5-1" asset catalog image resource.
        static let E_5_5_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-5-5-1", bundle: resourceBundle)

        /// The "Poses/E-6-1-0" asset catalog image resource.
        static let E_6_1_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-6-1-0", bundle: resourceBundle)

        /// The "Poses/E-6-1-1" asset catalog image resource.
        static let E_6_1_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-6-1-1", bundle: resourceBundle)

        /// The "Poses/E-6-1-2" asset catalog image resource.
        static let E_6_1_2 = DeveloperToolsSupport.ImageResource(name: "Poses/E-6-1-2", bundle: resourceBundle)

        /// The "Poses/E-6-2-0" asset catalog image resource.
        static let E_6_2_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-6-2-0", bundle: resourceBundle)

        /// The "Poses/E-6-2-1" asset catalog image resource.
        static let E_6_2_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-6-2-1", bundle: resourceBundle)

        /// The "Poses/E-6-2-2" asset catalog image resource.
        static let E_6_2_2 = DeveloperToolsSupport.ImageResource(name: "Poses/E-6-2-2", bundle: resourceBundle)

        /// The "Poses/E-6-3-0" asset catalog image resource.
        static let E_6_3_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-6-3-0", bundle: resourceBundle)

        /// The "Poses/E-6-3-1" asset catalog image resource.
        static let E_6_3_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-6-3-1", bundle: resourceBundle)

        /// The "Poses/E-6-3-2" asset catalog image resource.
        static let E_6_3_2 = DeveloperToolsSupport.ImageResource(name: "Poses/E-6-3-2", bundle: resourceBundle)

        /// The "Poses/E-6-4-0" asset catalog image resource.
        static let E_6_4_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-6-4-0", bundle: resourceBundle)

        /// The "Poses/E-6-4-1" asset catalog image resource.
        static let E_6_4_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-6-4-1", bundle: resourceBundle)

        /// The "Poses/E-6-5-0" asset catalog image resource.
        static let E_6_5_0 = DeveloperToolsSupport.ImageResource(name: "Poses/E-6-5-0", bundle: resourceBundle)

        /// The "Poses/E-6-5-1" asset catalog image resource.
        static let E_6_5_1 = DeveloperToolsSupport.ImageResource(name: "Poses/E-6-5-1", bundle: resourceBundle)

    }

}

