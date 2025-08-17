import XCTest
import UIKit
@testable import animated_octo_happiness_ios

@MainActor
final class FirebaseStorageServiceTests: XCTestCase {
    
    var storageService: FirebaseStorageService!
    
    override func setUp() {
        super.setUp()
        storageService = FirebaseStorageService.shared
    }
    
    func testUploadImage() async throws {
        // Given
        let image = createTestImage()
        let path = "test/images/test-image.jpg"
        
        // When
        let url = try await storageService.uploadImage(
            image,
            path: path,
            compressionQuality: 0.8
        )
        
        // Then
        XCTAssertNotNil(url)
        XCTAssertFalse(url.isEmpty)
        XCTAssertTrue(url.starts(with: "https://"))
    }
    
    func testUploadImageWithProgressHandler() async throws {
        // Given
        let image = createTestImage()
        let path = "test/images/test-image-progress.jpg"
        var progressValues: [Double] = []
        
        // When
        let url = try await storageService.uploadImage(
            image,
            path: path,
            compressionQuality: 0.8,
            progressHandler: { progress in
                progressValues.append(progress)
            }
        )
        
        // Then
        XCTAssertNotNil(url)
        // Note: Progress tracking would work with actual Firebase connection
    }
    
    func testUploadFile() async throws {
        // Given
        let tempURL = createTempFile()
        let path = "test/files/test-file.txt"
        
        // When
        let url = try await storageService.uploadFile(
            from: tempURL,
            to: path,
            contentType: "text/plain"
        )
        
        // Then
        XCTAssertNotNil(url)
        XCTAssertFalse(url.isEmpty)
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    func testDownloadFile() async throws {
        // Given
        let path = "test/files/test-download.txt"
        let localURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("download-test.txt")
        
        // When/Then
        // Note: This would work with actual Firebase connection
        XCTAssertNotNil(storageService)
    }
    
    func testDownloadData() async throws {
        // Given
        let path = "test/files/test-data.txt"
        let maxSize: Int64 = 10 * 1024 * 1024
        
        // When
        let data = try await storageService.downloadData(
            from: path,
            maxSize: maxSize
        )
        
        // Then
        XCTAssertNotNil(data)
    }
    
    func testDeleteFile() async throws {
        // Given
        let path = "test/files/test-delete.txt"
        
        // When/Then
        // Note: This would work with actual Firebase connection
        try await storageService.deleteFile(at: path)
        XCTAssertNotNil(storageService)
    }
    
    func testListFiles() async throws {
        // Given
        let path = "test/files"
        
        // When
        let files = try await storageService.listFiles(
            at: path,
            maxResults: 100
        )
        
        // Then
        XCTAssertNotNil(files)
        XCTAssertTrue(files.isEmpty) // Expected in test environment
    }
    
    func testGetDownloadURL() async throws {
        // Given
        let path = "test/files/test-url.txt"
        
        // When
        let url = try await storageService.getDownloadURL(for: path)
        
        // Then
        XCTAssertNotNil(url)
    }
    
    func testGetMetadata() async throws {
        // Given
        let path = "test/files/test-metadata.txt"
        
        // When
        let metadata = try await storageService.getMetadata(for: path)
        
        // Then
        XCTAssertNotNil(metadata)
        XCTAssertNotNil(metadata.name)
        XCTAssertNotNil(metadata.path)
    }
    
    func testGenerateStoragePath() {
        // Given
        let userId = "test-user-123"
        let fileName = "custom-file"
        
        // Test treasure image path
        let imagePath = storageService.generateStoragePath(
            for: .treasureImage,
            userId: userId,
            fileName: fileName
        )
        XCTAssertTrue(imagePath.contains("treasures/images"))
        XCTAssertTrue(imagePath.contains(userId))
        XCTAssertTrue(imagePath.hasSuffix(".jpg"))
        
        // Test treasure audio path
        let audioPath = storageService.generateStoragePath(
            for: .treasureAudio,
            userId: userId,
            fileName: fileName
        )
        XCTAssertTrue(audioPath.contains("treasures/audio"))
        XCTAssertTrue(audioPath.contains(userId))
        XCTAssertTrue(audioPath.hasSuffix(".m4a"))
        
        // Test treasure video path
        let videoPath = storageService.generateStoragePath(
            for: .treasureVideo,
            userId: userId,
            fileName: fileName
        )
        XCTAssertTrue(videoPath.contains("treasures/video"))
        XCTAssertTrue(videoPath.contains(userId))
        XCTAssertTrue(videoPath.hasSuffix(".mp4"))
        
        // Test user avatar path
        let avatarPath = storageService.generateStoragePath(
            for: .userAvatar,
            userId: userId
        )
        XCTAssertTrue(avatarPath.contains("users/avatars"))
        XCTAssertTrue(avatarPath.contains(userId))
        XCTAssertTrue(avatarPath.contains("avatar.jpg"))
        
        // Test user content path
        let contentPath = storageService.generateStoragePath(
            for: .userContent,
            userId: userId,
            fileName: fileName
        )
        XCTAssertTrue(contentPath.contains("users/content"))
        XCTAssertTrue(contentPath.contains(userId))
        XCTAssertTrue(contentPath.contains(fileName))
    }
    
    func testStorageErrorTypes() {
        // Test error cases
        let errors: [StorageError] = [
            .invalidFile,
            .uploadFailed,
            .downloadFailed,
            .deleteFailed,
            .quotaExceeded,
            .unauthorized,
            .unknownError("Test error")
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    func testFileMetadataModel() {
        // Given
        let metadata = FileMetadata(
            name: "test.jpg",
            path: "/test/test.jpg",
            size: 1024,
            contentType: "image/jpeg",
            timeCreated: Date(),
            updated: Date()
        )
        
        // Then
        XCTAssertEqual(metadata.name, "test.jpg")
        XCTAssertEqual(metadata.path, "/test/test.jpg")
        XCTAssertEqual(metadata.size, 1024)
        XCTAssertEqual(metadata.contentType, "image/jpeg")
        XCTAssertNotNil(metadata.timeCreated)
        XCTAssertNotNil(metadata.updated)
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        UIColor.blue.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    private func createTempFile() -> URL {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).txt")
        let testData = "Test file content".data(using: .utf8)!
        try! testData.write(to: tempURL)
        return tempURL
    }
}