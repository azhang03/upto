import AppKit

// Loads the brand mark images. The build scripts copy the PNG files
// into the app's Resources folder, so Bundle.main finds them first.
// The swift build resource bundle stays as the fallback for bare
// binary runs during development. Bundle.main must come first: some
// macOS versions refuse to open the nested resource bundle while the
// app carries the download quarantine flag, and the app then crashes
// before its first window appears.
enum BrandImage {
    static func named(_ name: String) -> NSImage {
        if let image = Bundle.main.image(forResource: name) {
            return image
        }
        return Bundle.module.image(forResource: name) ?? NSImage()
    }
}
