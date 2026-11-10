// CompositorCLI.swift — @main entry point, ArgumentParser command registration

import Foundation
import ArgumentParser

@main
struct CompositorCLI: ParsableCommand {

    static let version = "0.1.0"

    /// Shared verbose flag (progress reporting to stderr). Subcommands read this via `isVerbose()`.
    static var verboseEnabled = false

    @Flag(name: .customLong("verbose"), help: "Enable verbose progress output to stderr.")
    var verboseEnabled = false

    @Flag(name: .customLong("version"), help: "Print version and exit.")
    var showVersion: Bool = false

    static var configuration = CommandConfiguration(
        commandName: "compositor",
        abstract: "Deterministic image compositing CLI for AI agents.",
        subcommands: [
            ExtractCommand.self,
            CutoutCommand.self,
            InspectCommand.self,
            InpaintCommand.self,
            SelectionModifyCommand.self,
            ExportCommand.self,
            ModelsCommand.self,
            FaceDetectCommand.self,
            PoseEstimateCommand.self,
            FaceSwapCommand.self,
            CompositeCommand.self,
            PipelineCommand.self,
            ProjectCommand.self
        ]
    )

    mutating func run() throws {
        if showVersion {
            print("compositor version \(CompositorCLI.version)")
            return
        }
        // No subcommand was provided — show usage.
        throw CleanExit.helpRequest(nil)
    }

    /// True when `--verbose` appears anywhere in the command line (before or after the subcommand).
    static func isVerbose() -> Bool {
        verboseEnabled || CommandLine.arguments.contains("--verbose")
    }
}

// MARK: - Subcommands

extension CompositorCLI {

    struct ExtractCommand: ParsableCommand {
        static var configuration: CommandConfiguration {
            CommandConfiguration(commandName: "extract")
        }

        @Option(help: "Input image path")
        var input: String = ""

        @Option(help: "Output mask path. Must end in .png")
        var output: String = ""

        @Option(help: "Segmentation model (vision|sam2-lightweight). Default: vision")
        var model: String?

        @Option(help: "Guided Filter refinement radius in pixels. Default: 3")
        var refineRadius: Int = 3

        @Option(help: "Mask contrast threshold [0, 1]. Values below this are clamped to black. Default: 0.75")
        var contrastThreshold: Float = 0.75

        @Option(help: "Edge shift (negative=inward contraction in pixels). Default: 0")
        var edgeShift: Int = 0

        @Option(help: "SAM2 foreground point 'x,y' in image pixels. Requires --model sam2-lightweight.")
        var point: String?

        @Option(help: "SAM2 box 'x,y,width,height' in image pixels. Requires --model sam2-lightweight.")
        var box: String?

        @Option(help: "Output format (text|json)")
        var format: OutputFormat = .text

        func run() throws {
            let cmd = ExtractCommandRunner(
                input: URL(fileURLWithPath: input),
                output: URL(fileURLWithPath: output),
                model: model,
                refineRadius: refineRadius,
                contrastThreshold: contrastThreshold,
                edgeShift: edgeShift,
                format: format,
                pointText: point,
                boxText: box
            )
            let result = try cmd.execute()
            if case .json = format {
                print(String(data: result.toJSON(), encoding: .utf8)!)
            }
        }
    }

    struct CutoutCommand: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "cutout",
            abstract: "Apply a mask as alpha and write a straight RGBA PNG.",
            aliases: ["apply-mask"]
        )

        @Option(help: "Source image path")
        var image: String = ""

        @Option(help: "Mask path. White keeps the pixel, black clears alpha, gray is partial alpha.")
        var mask: String = ""

        @Option(help: "Output RGBA PNG path")
        var output: String = ""

        @Option(help: "Output format (text|json)")
        var format: OutputFormat = .text

        func run() throws {
            let cmd = CutoutCommandRunner(
                image: URL(fileURLWithPath: image),
                mask: URL(fileURLWithPath: mask),
                output: URL(fileURLWithPath: output),
                format: format
            )
            let result = try cmd.execute()
            if case .json = format {
                print(String(data: result.toJSON(), encoding: .utf8)!)
            }
        }
    }

    struct InspectCommand: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "inspect",
            abstract: "Print a JSON report of mask size, coverage, bounds, and components."
        )

        @Option(help: "Mask or image path")
        var input: String = ""

        @Option(help: "Channel to measure (luminance|alpha). Default: luminance")
        var channel: String = "luminance"

        @Option(help: "Also write the JSON document to this path")
        var output: String?

        @Option(help: "Accepted for compatibility. Success stdout is always the inspection document.")
        var format: OutputFormat = .text

        func run() throws {
            let cmd = InspectCommandRunner(
                input: URL(fileURLWithPath: input),
                channel: channel,
                output: output.map { URL(fileURLWithPath: $0) },
                format: format
            )
            let outcome = try cmd.execute()
            if outcome.result.status == "success", let document = outcome.document {
                print(document)
                return
            }
            print(String(data: outcome.result.toJSON(), encoding: .utf8)!)
        }
    }

    struct InpaintCommand: ParsableCommand {
        static var configuration: CommandConfiguration {
            CommandConfiguration(commandName: "inpaint")
        }

        @Option(help: "Input image path")
        var image: String = ""

        @Option(help: "Mask image path (white=fill, black=preserve)")
        var mask: String = ""

        @Option(help: "Inpainting algorithm (patch-based|lama). Default: patch-based")
        var algorithm: String?

        @Option(help: "LaMa quality preset (fast|balanced|high). Only effective with --algorithm lama. Default: balanced")
        var laMaPreset: String = "balanced"

        @Option(help: "Output path")
        var output: String = ""

        @Option(help: "Output format (text|json)")
        var format: OutputFormat = .text

        func run() throws {
            let cmd = InpaintCommandRunner(
                image: URL(fileURLWithPath: image),
                mask: URL(fileURLWithPath: mask),
                algorithm: algorithm,
                laMaPreset: laMaPreset,
                output: URL(fileURLWithPath: output),
                format: format
            )
            let result = try cmd.execute()
            if case .json = format {
                print(String(data: result.toJSON(), encoding: .utf8)!)
            }
        }
    }

    struct SelectionModifyCommand: ParsableCommand {
        static var configuration: CommandConfiguration {
            CommandConfiguration(commandName: "selection-modify")
        }

        @Option(help: "Input image or mask path (required for expand/contract/feather/edge-snap; source image for wand)")
        var input: String = ""

        @Option(help: "Operation type (expand|contract|feather|wand|edge-snap|invert|union|intersect|subtract)")
        var operation: String = ""

        @Option(help: "Amount in pixels or percent. Default: 10")
        var amount: Double = 10

        @Option(help: "Unit for --amount (pixels|percent). Default: pixels")
        var unit: String = "pixels"

        // Wand options
        @Option(help: "Click point as x,y. Required for wand operation.")
        var point: String?

        @Option(help: "Color tolerance [0, 255]. Default: 32")
        var tolerance: Int = 32

        @Option(help: "Sample size (point|3x3|5x5). Default: point")
        var sampleSize: String = "point"

        @Option(help: "Whether to only select contiguous pixels. Default: true")
        var contiguous: Bool = true

        // Edge-snap options
        @Option(help: "Guide image for edge detection (required for edge-snap)")
        var guide: String?

        @Option(name: .customLong("with"), help: "Second mask for union, intersect, and subtract. Ignored by invert.")
        var withMask: String?

        @Option(help: "Sobel threshold [0, 1] for edge snapping. Default: 0.5")
        var sobelThreshold: Float = 0.5

        @Option(help: "Snap search radius in pixels for edge-snap. Default: 20")
        var snapRadius: Int = 20

        @Option(help: "Output mask path (required)")
        var output: String?

        @Option(help: "Output format (text|json)")
        var format: OutputFormat = .text

        func run() throws {
            let cmd = SelectionModifyCommandRunner(
                input: URL(fileURLWithPath: input),
                operation: operation,
                amount: amount,
                unit: unit,
                point: point,
                tolerance: tolerance,
                sampleSize: sampleSize,
                contiguous: contiguous,
                guide: guide.map { URL(fileURLWithPath: $0) },
                withMask: withMask.map { URL(fileURLWithPath: $0) },
                sobelThreshold: sobelThreshold,
                snapRadius: snapRadius,
                output: output.map { URL(fileURLWithPath: $0) },
                format: format
            )
            let result = try cmd.execute()
            if case .json = format {
                print(String(data: result.toJSON(), encoding: .utf8)!)
            }
        }
    }

    struct ExportCommand: ParsableCommand {
        static var configuration: CommandConfiguration {
            CommandConfiguration(commandName: "export")
        }

        @Option(help: "Input .comp folder path or image file path")
        var input: String = ""

        @Option(help: "Output format (png|jpeg|pdf)")
        var format: String = "png"

        @Option(help: "JPEG quality [1, 100]. Default: 92")
        var jpegQuality: Int = 92

        @Option(help: "Scale factor. Default: 1.0")
        var scale: Double = 1.0

        @Option(help: "Output path (required)")
        var output: String = ""

        @Option(help: "Output format specifier for ArgumentParser (text|json)")
        var specFormat: OutputFormat = .text

        func run() throws {
            let cmd = ExportCommandRunner(
                input: URL(fileURLWithPath: input),
                exportFormat: format,
                jpegQuality: jpegQuality,
                scale: scale,
                output: URL(fileURLWithPath: output),
                format: specFormat
            )
            let result = try cmd.execute()
            if case .json = specFormat {
                print(String(data: result.toJSON(), encoding: .utf8)!)
            }
        }
    }

    // MARK: - Face Detect Command (Phase 2)

    struct FaceDetectCommand: ParsableCommand {
        static var configuration: CommandConfiguration {
            CommandConfiguration(commandName: "face-detect")
        }

        @Option(help: "Input image path")
        var input: String = ""

        @Option(help: "Minimum confidence threshold [0.0, 1.0]. Default: 0.5")
        var minConfidence: Double = 0.5

        @Option(help: "Output JSON file path for detected faces")
        var output: String = ""

        @Option(help: "Output format (text|json)")
        var format: OutputFormat = .text

        func run() throws {
            let cmd = FaceDetectCommandRunner(
                input: URL(fileURLWithPath: input),
                minConfidence: minConfidence,
                output: URL(fileURLWithPath: output),
                format: format
            )
            let result = try cmd.execute()
            if case .json = format {
                print(String(data: result.toJSON(), encoding: .utf8)!)
            }
        }
    }

    // MARK: - Pose Estimate Command (Phase 2)

    struct PoseEstimateCommand: ParsableCommand {
        static var configuration: CommandConfiguration {
            CommandConfiguration(commandName: "pose-estimate")
        }

        @Option(help: "Input image path")
        var input: String = ""

        @Option(help: "Pose model (rtmpose|dwpose). Default: rtmpose")
        var model: String = "rtmpose"

        @Option(help: "Output JSON file path for detected keypoints")
        var output: String = ""

        @Option(help: "Output format (text|json)")
        var format: OutputFormat = .text

        func run() throws {
            let cmd = PoseEstimateCommandRunner(
                input: URL(fileURLWithPath: input),
                model: model,
                output: URL(fileURLWithPath: output),
                format: format
            )
            let outcome = try cmd.execute()
            if outcome.result.status == "success", let document = outcome.document {
                print(document)
                return
            }
            print(String(data: outcome.result.toJSON(), encoding: .utf8)!)
        }
    }

    // MARK: - Face Swap Command (Phase 2)

    struct FaceSwapCommand: ParsableCommand {
        static var configuration: CommandConfiguration {
            CommandConfiguration(commandName: "face-swap")
        }

        @Option(help: "Source face image path (the face to swap in)")
        var source: String = ""

        @Option(help: "Target image path (where the face will be swapped into)")
        var target: String = ""

        @Option(help: "Face swap model. Default: insightface")
        var model: String = "insightface"

        @Option(name: .customLong("face-index"), help: "0-based index into faces sorted by confidence, then area. Applies to the target image.")
        var faceIndex: Int?

        @Option(name: .customLong("target-box"), help: "Target face box 'x,y,width,height' in top-left pixels. Picks the greatest overlap.")
        var targetBox: String?

        @Option(help: "Output path for the result image")
        var output: String = ""

        @Option(help: "Output format (text|json)")
        var format: OutputFormat = .text

        func run() throws {
            let cmd = FaceSwapCommandRunner(
                sourceFaceURL: URL(fileURLWithPath: source),
                targetImageURL: URL(fileURLWithPath: target),
                model: model,
                faceIndex: faceIndex,
                targetBoxText: targetBox,
                output: URL(fileURLWithPath: output),
                format: format
            )
            let result = try cmd.execute()
            if case .json = format {
                print(String(data: result.toJSON(), encoding: .utf8)!)
            }
        }
    }

    // MARK: - Composite Command (Phase 2)

    struct CompositeCommand: ParsableCommand {
        static var configuration: CommandConfiguration {
            CommandConfiguration(commandName: "composite")
        }

        @Option(help: "Foreground image path (layer to place on top)")
        var foreground: String = ""

        @Option(help: "Background image path (base layer)")
        var background: String = ""

        @Option(help: "Alpha mask path (optional; if omitted, uses foreground's alpha channel)")
        var mask: String?

        @Option(help: "Blend mode (alpha|difference|poisson). Default: alpha")
        var blendMode: String = "alpha"

        @Option(name: .customLong("origin"), help: "Layer top-left before rotation, 'x,y' in background pixels. Default: 0,0")
        var origin: String?

        @Option(name: .customLong("size"), help: "Displayed layer size 'width,height' in background pixels. Default: foreground pixel size")
        var placedSize: String?

        @Option(help: "Clockwise rotation in degrees around the layer center. Default: 0")
        var rotation: Double = 0

        @Flag(name: .customLong("flip-x"), help: "Flip the layer horizontally in local space.")
        var flipX: Bool = false

        @Flag(name: .customLong("flip-y"), help: "Flip the layer vertically in local space.")
        var flipY: Bool = false

        @Option(help: "Sampling (Nearest|Smooth|High quality). Default: Nearest")
        var sampling: String = "Nearest"

        @Option(help: "Output path for the result image")
        var output: String = ""

        @Option(help: "Output format (text|json)")
        var format: OutputFormat = .text

        func run() throws {
            let cmd = CompositeCommandRunner(
                foregroundURL: URL(fileURLWithPath: foreground),
                backgroundURL: URL(fileURLWithPath: background),
                maskURL: mask.map { URL(fileURLWithPath: $0) },
                blendMode: blendMode,
                originText: origin,
                sizeText: placedSize,
                rotationDegrees: rotation,
                flipX: flipX,
                flipY: flipY,
                sampling: sampling,
                output: URL(fileURLWithPath: output),
                format: format
            )
            let result = try cmd.execute()
            if case .json = format {
                print(String(data: result.toJSON(), encoding: .utf8)!)
            }
        }
    }

    // MARK: - Pipeline Command (Phase 2)

    struct PipelineCommand: ParsableCommand {
        static var configuration: CommandConfiguration {
            CommandConfiguration(commandName: "pipeline")
        }

        @Option(help: "Input image path for the first step in the pipeline")
        var input: String = ""

        @Option(help: "Reference image (e.g., source face for face-swap)")
        var reference: String?

        @Option(help: "Comma-separated list of steps to execute (e.g., extract,detect-faces,face-swap)")
        var steps: String = ""

        @Option(help: "Path to pipeline configuration JSON file")
        var pipelineConfig: String?

        @Option(help: "Output path for the final result")
        var output: String = ""

        @Option(help: "Output format (text|json)")
        var format: OutputFormat = .text

        func run() throws {
            var pipelineSteps: [PipelineStepConfig] = []

            if let configPath = pipelineConfig, !configPath.isEmpty {
                // Load step definitions from a JSON config file.
                let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
                pipelineSteps = try JSONDecoder().decode([PipelineStepConfig].self, from: data)
            } else {
                // Parse steps from comma-separated string
                let stepNames = steps.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                for stepName in stepNames {
                    var inputs: [String: String] = [:]

                    switch stepName.lowercased() {
                    case "extract":
                        inputs["input"] = "--input"
                    case "cutout", "apply-mask":
                        inputs["image"] = "--input"
                        inputs["mask"] = "${extract.mask}"
                    case "inspect":
                        inputs["input"] = "--input"
                    case "detect-faces", "face-detect":
                        inputs["input"] = "--input"
                    case "pose-estimate", "pose", "detect-poses":
                        inputs["input"] = "--input"
                    case "face-swap":
                        inputs["source"] = reference != nil ? "--reference" : "--input"
                        inputs["target"] = "--input"
                    case "inpaint":
                        inputs["image"] = "--input"
                        // Mask comes from a previous extract step
                        inputs["mask"] = "${extract.mask}"
                    case "composite":
                        inputs["foreground"] = "--input"
                        inputs["background"] = "--reference"
                    case "selection-modify":
                        inputs["input"] = "--input"
                    default:
                        break
                    }

                    pipelineSteps.append(PipelineStepConfig(name: stepName, inputs: inputs))
                }
            }

            // Resolve user inputs
            var userInputs: [String: URL] = [:]
            if !input.isEmpty {
                userInputs["--input"] = URL(fileURLWithPath: input)
            }
            if let ref = reference, !ref.isEmpty {
                userInputs["--reference"] = URL(fileURLWithPath: ref)
            }

            // Execute pipeline
            let runner = PipelineRunner(verbose: CompositorCLI.isVerbose())
            let outputURL = output.isEmpty ? nil : URL(fileURLWithPath: output)
            let result = try runner.execute(steps: pipelineSteps, inputs: userInputs, finalOutput: outputURL)

            switch format {
            case .text:
                print("Pipeline \(result.status). Final output: \(result.output ?? "N/A") (Total: \(result.total_ms)ms)")
            case .json:
                print(String(data: result.toJSON(), encoding: .utf8)!)
            }
        }
    }
}

// MARK: - Shared Types

/// Output format — shared across all subcommands to avoid ArgumentParser enum conflicts.
enum OutputFormat: String, ExpressibleByArgument {
    case text
    case json
}
