**FUSIONNFT**

**Overview**

This program is a SwiftUI-based application that allows users to select a folder containing sub-folders of images. Each sub-folder should contain images that the user intends to merge. The application then merges the images from each sub-folder in the order they are placed.

**How It Works**

Folder Selection: The user selects a folder containing sub-folders of images.

Image Display: If there's a processed image, it will be displayed in the app UI.

Merge Process: The user has the option to merge the images using two buttons:
"Select folder and merge" which prepares images with a default batch size of 8500.
"Test with 50 images only" which prepares images with a test size of 50.

Continuation: If the merging process isn't complete, the user can continue the merge using the "Continue the merge" button.

Image Combination: The program fetches image URLs from the selected folder, sorts them, and then computes all possible combinations of these images.

Image Merging: Images from different sub-folders are merged into a single image, ensuring the final image dimensions are the maximum width and height of the images being merged.

Metadata Creation: After merging, metadata associated with the merged image is generated, which includes the image URL, an external link, a description, the name, and the attributes (derived from the file names of the merged images).

**Features**

Batch Processing: The program processes images in batches, defaulting to 8500 images per batch. This ensures efficiency and avoids potential memory overflows when working with a large number of images.
Error Handling: Proper error messages are displayed in case of issues during the merging process or metadata generation.
Dynamic Metadata Generation: The program generates metadata for each merged image, which includes dynamic attributes based on the file names of the merged images.

**Prerequisite**
macOS with SwiftUI support.
Ensure that the image file format in the sub-folders is .png

**Usage**
Clone the repository.
Open the SwiftUI project in Xcode.
Run the application and follow the on-screen instructions.
