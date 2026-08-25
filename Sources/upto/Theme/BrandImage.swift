import AppKit

// Loads the brand mark images. The build scripts copy the PNG files
// into the app's Resources folder, and Bundle.main finds them there.
// Bundle.module stays as the fallback for bare binary runs during
// development. A shipped app must never reach it: the swift build
// resource accessor only checks the top level of the app package and
// the absolute .build path of the machine that built the app, so it
// traps at launch on every other Mac.
enum BrandImage {
    static func named(_ name: String) -> NSImage {
        if let image = Bundle.main.image(forResource: name) {
            return image
        }
        return Bundle.module.image(forResource: name) ?? NSImage()
    }
}
