import XCTest
@testable import HomeMaint

final class TaskStoreCategoryResolutionTests: XCTestCase {
    func testResolveCategoryIDPrefersLegacyCategoryWhenAvailable() {
        let hvacID = UUID()
        let categoriesByName = ["hvac": hvacID]

        let resolved = TaskStore.resolveCategoryID(
            taskName: "Any Task",
            legacyCategoryRaw: "HVAC",
            categoriesByName: categoriesByName,
            sampleTaskCategoryByName: [:],
            fallbackCategoryID: nil
        )

        XCTAssertEqual(resolved, hvacID)
    }

    func testResolveCategoryIDUsesSampleNameMappingWhenLegacyMissing() {
        let plumbingID = UUID()
        let categoriesByName = ["plumbing": plumbingID]
        let sampleMap = ["clean garbage disposal": "plumbing"]

        let resolved = TaskStore.resolveCategoryID(
            taskName: "Clean Garbage Disposal",
            legacyCategoryRaw: nil,
            categoriesByName: categoriesByName,
            sampleTaskCategoryByName: sampleMap,
            fallbackCategoryID: nil
        )

        XCTAssertEqual(resolved, plumbingID)
    }

    func testResolveCategoryIDFallsBackWhenLegacyUnknown() {
        let fallbackID = UUID()

        let resolved = TaskStore.resolveCategoryID(
            taskName: "Custom",
            legacyCategoryRaw: "Unknown Legacy",
            categoriesByName: [:],
            sampleTaskCategoryByName: [:],
            fallbackCategoryID: fallbackID
        )

        XCTAssertEqual(resolved, fallbackID)
    }

    func testResolveCategoryIDReturnsNilWhenNoMatchExists() {
        let resolved = TaskStore.resolveCategoryID(
            taskName: "Custom",
            legacyCategoryRaw: nil,
            categoriesByName: [:],
            sampleTaskCategoryByName: [:],
            fallbackCategoryID: nil
        )

        XCTAssertNil(resolved)
    }
}
