import Foundation
import SwiftData

enum AppError: LocalizedError {
    case swiftDataError(Error)
    case taskNotFound
    case categoryNotFound
    case invalidData(String)
    case saveFailed(Error)
    case fetchFailed(Error)

    var errorDescription: String? {
        switch self {
        case .swiftDataError(let error):
            return "Database error: \(error.localizedDescription)"
        case .taskNotFound:
            return "The requested task could not be found."
        case .categoryNotFound:
            return "The requested category could not be found."
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .saveFailed(let error):
            return "Failed to save changes: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to load data: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .swiftDataError:
            return "Please try again. If the problem persists, restart the app."
        case .taskNotFound:
            return "The task may have been deleted or moved."
        case .categoryNotFound:
            return "The category may have been deleted."
        case .invalidData:
            return "Please check the data and try again."
        case .saveFailed:
            return "Please try saving your changes again."
        case .fetchFailed:
            return "Please try refreshing the data."
        }
    }
}

@Observable
class ErrorManager {
    static let shared = ErrorManager()

    var currentError: AppError?
    var showingError = false

    private init() {}

    func handleError(_ error: Error) {
        if let appError = error as? AppError {
            currentError = appError
        } else if let swiftDataError = error as? SwiftDataError {
            currentError = .swiftDataError(swiftDataError)
        } else {
            currentError = .swiftDataError(error)
        }
        showingError = true

        // Log error for debugging
        print("Error occurred: \(String(describing: currentError))")
    }

    func clearError() {
        currentError = nil
        showingError = false
    }
}
