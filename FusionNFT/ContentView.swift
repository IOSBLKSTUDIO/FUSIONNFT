import SwiftUI
import Combine

struct ContentView: View {
    @State private var image: NSImage? = nil
    @State private var selectedFolderPath: URL?
    @State private var combinations: [[URL]] = []
    @State private var currentIndex: Int = 0
    @State private var progress: Double = 0
    
    let batchSize: Int = 8500
    let testSize: Int = 50
    
    var body: some View {
        VStack(spacing: 20) {
            // Titre
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 400, height: 180)
                .fixedSize()
                .padding()

            // Explications
            Text("Select a folder containing sub-folders of images. Each sub-folder should contain images you want to merge. The images from each sub-folder will be merged in order.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .frame(maxWidth: 150, maxHeight: 150)
            }
         

            Button("Select folder and merge") {
                self.prepareImages(with: self.batchSize)
            }
            
            Button("Test with 50 images only") {
                self.prepareImages(with: self.testSize)
            }
            
            if currentIndex < combinations.count {
                Button("Continue the merge") {
                    self.processBatch()
                }
            }
        }
        .padding()
    }

    
    func prepareImages(with size: Int) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        
        openPanel.begin { (result) in
            if result == .OK {
                selectedFolderPath = openPanel.urls.first
                if let selectedFolderPath = selectedFolderPath {
                    let imageGroups = self.fetchImageURLGroups(from: selectedFolderPath)
                    self.combinations = Array(self.getAllCombinations(of: imageGroups).prefix(size))
                    self.currentIndex = 0
                    self.processBatch()
                }
            }
        }
    }
    
    func processBatch() {
        let endIndex = min(currentIndex + batchSize, combinations.count)
        let batch = combinations[currentIndex..<endIndex]
        
        for (index, combination) in batch.enumerated() {
            image = self.mergeImages(from: combination, fileName: "merged_image_\(currentIndex + index).png")
            self.progress = Double(currentIndex + index + 1) / Double(combinations.count)
        }
        
        currentIndex = endIndex
    }
    
    
    
    
    func fetchImageURLGroups(from url: URL?) -> [[URL]] {
        guard let url = url else {
            return []
        }
        
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return []
        }
        
        var imageURLGroups: [[URL]] = []
        var directories: [URL] = []
        
        for case let fileURL as URL in enumerator {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory),
               isDirectory.boolValue {
                directories.append(fileURL)
            }
        }
        
        // Trier les dossiers par nom
        directories.sort { $0.lastPathComponent < $1.lastPathComponent }

        for directory in directories {
            let imageUrls = fetchImageURLs(from: directory)
            if !imageUrls.isEmpty {
                imageURLGroups.append(imageUrls)
            }
        }
        
        return imageURLGroups
    }

    
    func fetchImageURLs(from url: URL) -> [URL] {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return []
        }
        
        var imageUrls: [URL] = []
        
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "png" {
                imageUrls.append(fileURL)
            }
        }
        
        // Tri par ordre croissant du nom de fichier
        imageUrls.sort {
            let number1 = Int($0.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "image", with: "")) ?? 0
            let number2 = Int($1.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "image", with: "")) ?? 0
            return number1 < number2
        }
        
        return imageUrls
    }
    
    func getAllCombinations<T>(of arrays: [[T]]) -> [[T]] {
        guard !arrays.isEmpty else { return [] }
        
        if arrays.count == 1 {
            return arrays[0].map { [$0] }
        }
        
        var result: [[T]] = []
        
        let firstArray = arrays[0]
        let subCombinations = getAllCombinations(of: Array(arrays[1...]))
        
        for item in firstArray {
            for subCombination in subCombinations {
                result.append([item] + subCombination)
            }
        }
        
        return result
    }
    
    
    func mergeImages(from urls: [URL], fileName: String) -> NSImage? {
        let images = urls.compactMap { NSImage(contentsOf: $0) }
        
        guard !images.isEmpty else { return nil }
        
        let maxWidth = images.map { $0.size.width }.max() ?? 0
        let maxHeight = images.map { $0.size.height }.max() ?? 0
        
        let finalSize = NSSize(width: maxWidth, height: maxHeight)
        let finalImage = NSImage(size: finalSize)
        
        finalImage.lockFocus()
        
        for image in images {
            let rect = NSRect(origin: .zero, size: image.size)
            image.draw(in: rect, from: rect, operation: .sourceOver, fraction: 1.0)
        }
        
        finalImage.unlockFocus()
        
        if let selectedFolderPath = selectedFolderPath {
            let saveURL = selectedFolderPath.appendingPathComponent(fileName)
            
            if let tiffData = finalImage.tiffRepresentation,
               let bitmapImage = NSBitmapImageRep(data: tiffData) {
                let pngData = bitmapImage.representation(using: .png, properties: [:])
                
                do {
                    try pngData?.write(to: saveURL)
                    
                    var metadata: [String: Any] = [:]
                    metadata["image"] = saveURL.absoluteString
                    metadata["external_url"] = "https://www.exemple.fr"
                    metadata["description"] = "Offical OpenSea RainbowBread collection."
                    metadata["name"] = "RainbowBread"
                    
                    var attributes: [[String: String]] = []
                    
                    for url in urls {
                        var attribute: [String: String] = [:]
                        let fileName = url.deletingPathExtension().lastPathComponent

                        let parts = fileName.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: true)
                        if parts.count == 2 {
                            attribute["trait_type"] = String(parts[0])
                            attribute["value"] = String(parts[1])
                        } else {
                      //error message
                            continue
                        }
                        
                        attributes.append(attribute)
                    }
                    metadata["attributes"] = attributes
                    
                    let metadataURL = selectedFolderPath.appendingPathComponent("metadata_\(fileName).json")
                    if let metadataData = try? JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted) {
                        try metadataData.write(to: metadataURL)
                    }
                } catch {
                    print("Erreur lors de l'enregistrement de l'image ou des métadonnées : \(error)")
                }
            }
        }
        
        return finalImage
    }



}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
