import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let madCADJSON = UTType.json
}

struct MadCADScanDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.madCADJSON]
    static let writableContentTypes: [UTType] = [.madCADJSON]

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
