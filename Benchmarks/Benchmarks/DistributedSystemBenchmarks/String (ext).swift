#if _runtime(_ObjC)
import Foundation

extension String {
    /// A string of `count` UTF-16 code units, each “é”, bridged lazily from an `NSString`, so
    /// its UTF-8 view is not contiguous.
    static func bridged(count: Int) -> Self {
        let units: [UInt16] = .init(repeating: 0xe9, count: count)
        let string: NSString = units.withUnsafeBufferPointer {
            NSString.init(characters: $0.baseAddress!, length: $0.count)
        }
        return string as String
    }
}
#endif
