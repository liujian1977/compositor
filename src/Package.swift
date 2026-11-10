// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "CompositorCLI",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "compositor", targets: ["CompositorCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
    ],
    targets: [
        // CoreC — pure C library for pixel-level rendering operations.
        .target(
            name: "CoreC",
            path: "CompositorCore/CoreRendering",
            sources: [
                "MorphologyOp.c",
                "SobelOp.c",
                "WandOp.c",
                "BlurOp.c",
                "PatchInpaintOp.c",
                "CompositeOp.c",
                "MaskOps.c",
                "LayerPlacement.c",
                "FaceSelect.c",
                "PoseLayout.c",
                "ModelPrep.c",
                "ProjectEdit.c"
            ],
            publicHeadersPath: "."  // exposes CompositeOp.h, MorphologyOp.h, SobelOp.h, WandOp.h, BlurOp.h, PatchInpaintOp.h, MaskOps.h
        ),

        // Main library — pure Swift, depends on CoreC (links the C code).
        .target(
            name: "CompositorCore",
            dependencies: [
                "CoreC"
            ],
            path: "CompositorCore",
            exclude: [
                // These are compiled by the CoreC target (its path overlaps this one).
                "CoreRendering/MorphologyOp.c",
                "CoreRendering/SobelOp.c",
                "CoreRendering/WandOp.c",
                "CoreRendering/BlurOp.c",
                "CoreRendering/PatchInpaintOp.c",
                "CoreRendering/CompositeOp.c",
                "CoreRendering/MaskOps.c",
                "CoreRendering/LayerPlacement.c",
                "CoreRendering/FaceSelect.c",
                "CoreRendering/PoseLayout.c",
                "CoreRendering/ModelPrep.c",
                "CoreRendering/ProjectEdit.c"
            ],
            sources: [
                "CoreDocument/CanvasSize.swift",
                "CoreDocument/Errors.swift",
                "CoreDocument/ModelLoader.swift",
                "CoreDocument/Selection.swift",
                "CoreDocument/SoftMask.swift",
                "CoreIO/ImageExporter.swift",
                "CoreIO/ProjectManifest.swift",
                "CoreIO/ProjectStore.swift",
                "CoreRendering/MorphologyOp.swift",
                "CoreRendering/SobelOp.swift",
                "CoreRendering/WandOp.swift",
                "CoreRendering/BlurOp.swift",
                "CoreRendering/PatchInpaintOp.swift",
                "CoreRendering/CompositeOp.swift",
                "CoreRendering/MaskOps.swift",
                "CoreRendering/LayerPlacement.swift",
                "CoreRendering/FaceSelect.swift",
                "CoreRendering/PoseLayout.swift",
                "CoreRendering/ModelPrep.swift",
                "CoreRendering/ProjectEdit.swift"
            ],
            linkerSettings: [
                .linkedLibrary("c")  // for memset in C functions
            ]
        ),

        // CLI executable — depends on Core + ArgumentParser.
        .executableTarget(
            name: "CompositorCLI",
            dependencies: [
                "CompositorCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "CompositorCLI",
            linkerSettings: [
                .linkedFramework("Vision"),
                .linkedFramework("CoreML"),
                .linkedFramework("CoreImage")
            ]
        ),

        // Unit tests for CompositorCore (deterministic algorithms).
        .testTarget(
            name: "CompositorCoreTests",
            dependencies: ["CompositorCore"],
            path: "Tests/CompositorCoreTests"
        ),

        // End-to-end CLI tests (spawns the built `compositor` binary).
        .testTarget(
            name: "CompositorCLITests",
            dependencies: ["CompositorCLI"],
            path: "Tests/CompositorCLITests"
        )
    ]
)
