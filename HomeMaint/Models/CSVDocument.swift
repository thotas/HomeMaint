import SwiftUI
import UniformTypeIdentifiers

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText, .plainText] }

    var csvContent: String = ""

    init() {}

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            csvContent = String(data: data, encoding: .utf8) ?? ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(csvContent.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}
