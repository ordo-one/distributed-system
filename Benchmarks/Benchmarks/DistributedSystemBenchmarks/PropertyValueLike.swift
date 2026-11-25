import DistributedABI

/// Property value — an enum with associated values, every case a single payload.
enum PropertyValueLike {
    case integer(Int)
    case decimal(Int64)
    case boolean(Bool)
    case text(String)
    case timestamp(UInt64)
    case instrument(UInt64)
}
extension PropertyValueLike: Equatable {}
extension PropertyValueLike: Transferable {
    var transferSize: Int {
        switch self {
        case .integer(let self): 1 + self.transferSize
        case .decimal(let self): 1 + self.transferSize
        case .boolean(let self): 1 + self.transferSize
        case .text(let self): 1 + self.transferSize
        case .timestamp(let self): 1 + self.transferSize
        case .instrument(let self): 1 + self.transferSize
        }
    }

    func transfer(into output: inout TransferWriter) {
        switch self {
        case .integer(let self):
            output.append(0)
            self.transfer(into: &output)
        case .decimal(let self):
            output.append(1)
            self.transfer(into: &output)
        case .boolean(let self):
            output.append(2)
            self.transfer(into: &output)
        case .text(let self):
            output.append(3)
            self.transfer(into: &output)
        case .timestamp(let self):
            output.append(4)
            self.transfer(into: &output)
        case .instrument(let self):
            output.append(5)
            self.transfer(into: &output)
        }
    }
    init(transferring input: inout TransferReader) throws(TransferError) {
        switch try input.readByte() {
        case 0: self = .integer(try .init(transferring: &input))
        case 1: self = .decimal(try .init(transferring: &input))
        case 2: self = .boolean(try .init(transferring: &input))
        case 3: self = .text(try .init(transferring: &input))
        case 4: self = .timestamp(try .init(transferring: &input))
        case 5: self = .instrument(try .init(transferring: &input))
        case let code: throw .init(.invalidDiscriminant(.init(code)))
        }
    }
}
