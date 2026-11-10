// PipelineRunner.swift — Orchestrates multi-step image processing pipelines
// Executes a sequence of operations with timing, intermediate file management, and error handling.

import Foundation

/// Represents a single step in the pipeline execution.
struct PipelineStep: Codable {
    let name: String                // e.g., "extract", "detect-faces", "pose-estimate"
    var status: String              // "success" | "error" | "skipped"
    var outputs: [String: String]   // step-specific output paths (e.g., {"mask": "/path/to/mask.png"})
    var timing_ms: Int
    var error: StepError?           // present only on failure

    struct StepError: Codable {
        let type: String
        let detail: String
        let hint: String?
    }

    init(name: String, outputs: [String: String] = [:], timing_ms: Int = 0, error: StepError? = nil) {
        self.name = name
        self.status = error != nil ? "error" : (outputs.isEmpty && timing_ms == 0 ? "skipped" : "success")
        self.outputs = outputs
        self.timing_ms = timing_ms
        self.error = error
    }
}

/// Error type for pipeline-level failures.
enum PipelineError: Error {
    case stepFailed(step: String, error: String)
    case invalidStepConfiguration(String)
    case missingRequiredInput(String)
}

extension PipelineError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .stepFailed(let step, let error):
            return "Step '\(step)' failed: \(error)"
        case .invalidStepConfiguration(let detail):
            return detail
        case .missingRequiredInput(let detail):
            return detail
        }
    }

    /// Error type reported in pipeline JSON.
    var cliErrorType: String {
        switch self {
        case .stepFailed: return "stepFailed"
        case .invalidStepConfiguration: return "invalidConfiguration"
        case .missingRequiredInput: return "missingInput"
        }
    }
}

/// The main pipeline orchestrator engine.
/// Executes steps sequentially, manages intermediate files, and tracks timing.
final class PipelineRunner {

    /// Maximum number of steps allowed in a single pipeline (prevents infinite loops).
    static let maxSteps = 50

    /// Temporary directory for intermediate pipeline outputs.
    private let tempDirectory: URL

    /// Verbose logging flag.
    private let verbose: Bool

    /// Map of step names to their input/output variable names for data passing.
    /// e.g., "extract" -> ["mask": "/tmp/pipeline-{uuid}/mask.png"]
    private var stepOutputs: [String: [String: URL]] = [:]

    init(verbose: Bool = false) {
        self.verbose = verbose
        self.tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("compositor-pipeline-\(UUID().uuidString)")

        // Create temp directory
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    deinit {
        // Clean up temp directory on destruction (best effort)
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    /// Execute a pipeline defined by a sequence of steps.
    ///
    /// - Parameters:
    ///   - steps: Array of step configurations (name + parameters).
    ///   - inputs: Map of user-provided input paths (--input, --reference, etc.).
    /// - Returns: PipelineResult with per-step timing and output paths.
    func execute(steps: [PipelineStepConfig], inputs: [String: URL], finalOutput: URL? = nil) throws -> PipelineResult {
        guard !steps.isEmpty else {
            throw PipelineError.invalidStepConfiguration("No steps provided")
        }

        guard steps.count <= Self.maxSteps else {
            throw PipelineError.invalidStepConfiguration(
                "Too many steps (\(steps.count)). Maximum is \(Self.maxSteps)."
            )
        }

        let pipelineStart = DispatchTime.now()
        var executedSteps: [PipelineStep] = []
        var failedAt: String? = nil

        // Execute each step sequentially
        for (index, stepConfig) in steps.enumerated() {
            // If a previous step failed, mark remaining as skipped
            if let failurePoint = failedAt {
                executedSteps.append(PipelineStep(
                    name: stepConfig.name,
                    outputs: [:],
                    timing_ms: 0,
                    error: PipelineStep.StepError(
                        type: "skipped",
                        detail: "Skipped due to failure in step '\(failurePoint)'",
                        hint: nil
                    )
                ))
                continue
            }

            if verbose {
                fputs("[compositor] Executing step \(index + 1)/\(steps.count): \(stepConfig.name)\n", stderr)
            }

            let stepStart = DispatchTime.now()

            // Resolve inputs for this step (merge user inputs with previous step outputs)
            let resolvedInputs = try resolveStepInputs(stepConfig, using: inputs, fromPreviousOutputs: stepOutputs)

            // Execute the step
            var stepResult = try executeSingleStep(stepConfig, inputs: resolvedInputs)
            stepResult.timing_ms = dispatchTimeIntervalMs(stepStart, DispatchTime.now())

            executedSteps.append(stepResult)

            // Store outputs for next steps to consume
            if stepResult.status == "success" {
                stepOutputs[stepConfig.name] = stepResult.outputs.mapValues { URL(fileURLWithPath: $0) }
            } else {
                failedAt = stepConfig.name
            }
        }

        let pipelineEnd = DispatchTime.now()
        let totalMs = max(dispatchTimeIntervalMs(pipelineStart, pipelineEnd), 1)

        // Determine overall status
        let hasError = executedSteps.contains { $0.status == "error" }
        let reportedOutput: String?
        if let lastSuccessfulStep = executedSteps.last(where: { $0.status == "success" }),
           let lastOutput = lastSuccessfulStep.outputs.values.first {
            // Copy the final intermediate result to the user-specified --output path if given.
            if let dest = finalOutput, !hasError {
                do {
                    try FileManager.default.createDirectory(at: dest.deletingLastPathComponent(),
                                                            withIntermediateDirectories: true)
                    try? FileManager.default.removeItem(at: dest)
                    try FileManager.default.copyItem(at: URL(fileURLWithPath: lastOutput), to: dest)
                } catch {
                    executedSteps.append(PipelineStep(
                        name: "finalize",
                        outputs: [:],
                        timing_ms: 0,
                        error: PipelineStep.StepError(type: "renderFailed",
                                                      detail: "Cannot write final output: \(error.localizedDescription)",
                                                      hint: nil)
                    ))
                    return PipelineResult(
                        command: "pipeline",
                        version: "0.1.0",
                        status: "error",
                        output: nil,
                        steps: executedSteps,
                        total_ms: max(dispatchTimeIntervalMs(pipelineStart, DispatchTime.now()), 1)
                    )
                }
            }
            reportedOutput = (finalOutput != nil && !hasError) ? finalOutput!.path : lastOutput
        } else {
            reportedOutput = nil
        }

        return PipelineResult(
            command: "pipeline",
            version: "0.1.0",
            status: hasError ? "error" : "success",
            output: reportedOutput,
            steps: executedSteps,
            total_ms: totalMs
        )
    }

    // MARK: - Step Execution

    private func executeSingleStep(_ stepConfig: PipelineStepConfig, inputs: [String: URL]) throws -> PipelineStep {
        let stepName = stepConfig.name
        do {
            switch stepName.lowercased() {
            case "extract":
                return try runExtractStep(inputs)
            case "cutout", "apply-mask":
                return try runCutoutStep(stepName, inputs)
            case "inspect":
                return try runInspectStep(stepName, stepConfig, inputs)
            case "detect-faces", "face-detect":
                return try runFaceDetectStep(inputs)
            case "detect-poses", "pose-estimate", "pose":
                return try runPoseEstimateStep(inputs)
            case "face-swap":
                return try runFaceSwapStep(inputs)
            case "inpaint":
                return try runInpaintStep(inputs)
            case "composite":
                return try runCompositeStep(inputs)
            case "selection-modify":
                return try runSelectionModifyStep(stepConfig, inputs)
            default:
                throw PipelineError.invalidStepConfiguration("Unknown step name: \(stepName)")
            }
        } catch let error as PipelineError {
            return PipelineStep(
                name: stepName,
                outputs: [:],
                timing_ms: 0,
                error: PipelineStep.StepError(type: error.cliErrorType, detail: error.localizedDescription, hint: nil)
            )
        } catch {
            return PipelineStep(
                name: stepName,
                outputs: [:],
                timing_ms: 0,
                error: PipelineStep.StepError(type: "stepFailed", detail: error.localizedDescription, hint: nil)
            )
        }
    }

    /// Build a PipelineStep from a CommandResult returned by a command runner.
    /// Command errors are surfaced in the step JSON instead of being thrown,
    /// so the pipeline reports the real error type/detail/hint from the step.
    private func stepFromResult(_ name: String, _ result: CommandResult, outputs: [String: String]) -> PipelineStep {
        if result.status == "success" {
            var out = outputs
            if out.isEmpty, let o = result.output {
                out["result"] = o
            }
            return PipelineStep(name: name, outputs: out, timing_ms: 0, error: nil)
        }
        return PipelineStep(
            name: name,
            outputs: [:],
            timing_ms: 0,
            error: PipelineStep.StepError(
                type: result.error?.type ?? "stepFailed",
                detail: result.error?.detail ?? "step failed",
                hint: result.error?.hint
            )
        )
    }

    // MARK: - Step Runners (delegate to existing command runners)

    private func runExtractStep(_ inputs: [String: URL]) throws -> PipelineStep {
        guard let input = inputs["input"] else {
            throw PipelineError.missingRequiredInput("extract requires 'input'")
        }

        let outputPath = tempDirectory.appendingPathComponent("extract-mask.png")
        let runner = ExtractCommandRunner(
            input: input,
            output: outputPath,
            model: nil,
            refineRadius: 3,
            contrastThreshold: 0.75,
            edgeShift: 0,
            format: .json
        )
        let result = try runner.execute()
        return stepFromResult("extract", result, outputs: ["mask": outputPath.path])
    }

    private func runCutoutStep(_ name: String, _ inputs: [String: URL]) throws -> PipelineStep {
        guard let image = inputs["image"] else {
            throw PipelineError.missingRequiredInput("cutout requires 'image'")
        }
        guard let mask = inputs["mask"] else {
            throw PipelineError.missingRequiredInput("cutout requires 'mask'")
        }
        let outputPath = tempDirectory.appendingPathComponent("cutout.png")
        let runner = CutoutCommandRunner(
            image: image,
            mask: mask,
            output: outputPath,
            format: .json
        )
        let result = try runner.execute()
        return stepFromResult(name, result, outputs: ["image": outputPath.path])
    }

    private func runInspectStep(_ name: String, _ stepConfig: PipelineStepConfig, _ inputs: [String: URL]) throws -> PipelineStep {
        guard let input = inputs["input"] else {
            throw PipelineError.missingRequiredInput("inspect requires 'input'")
        }
        let outputPath = tempDirectory.appendingPathComponent("inspect.json")
        let channel = stepConfig.parameters?["channel"] ?? "luminance"
        let runner = InspectCommandRunner(
            input: input,
            channel: channel,
            output: outputPath,
            format: .json
        )
        let outcome = try runner.execute()
        return stepFromResult(name, outcome.result, outputs: ["report": outputPath.path])
    }

    private func runFaceDetectStep(_ inputs: [String: URL]) throws -> PipelineStep {
        guard let input = inputs["input"] else {
            throw PipelineError.missingRequiredInput("face-detect requires 'input'")
        }

        let outputPath = tempDirectory.appendingPathComponent("faces.json")
        let runner = FaceDetectCommandRunner(
            input: input,
            minConfidence: 0.5,
            output: outputPath,
            format: .json
        )
        let result = try runner.execute()
        return stepFromResult("detect-faces", result, outputs: ["faces": outputPath.path])
    }

    private func runPoseEstimateStep(_ inputs: [String: URL]) throws -> PipelineStep {
        guard let input = inputs["input"] else {
            throw PipelineError.missingRequiredInput("pose-estimate requires 'input'")
        }

        let outputPath = tempDirectory.appendingPathComponent("poses.json")
        let runner = PoseEstimateCommandRunner(
            input: input,
            model: "rtmpose",
            output: outputPath,
            format: .json
        )
        let outcome = try runner.execute()
        return stepFromResult("pose-estimate", outcome.result, outputs: ["poses": outputPath.path])
    }

    private func runFaceSwapStep(_ inputs: [String: URL]) throws -> PipelineStep {
        guard let source = inputs["source"] else {
            throw PipelineError.missingRequiredInput("face-swap requires 'source'")
        }
        guard let target = inputs["target"] else {
            throw PipelineError.missingRequiredInput("face-swap requires 'target'")
        }

        let outputPath = tempDirectory.appendingPathComponent("faceswap-result.png")
        let runner = FaceSwapCommandRunner(
            sourceFaceURL: source,
            targetImageURL: target,
            model: "insightface",
            faceIndex: nil,
            targetBoxText: nil,
            output: outputPath,
            format: .json
        )
        let result = try runner.execute()
        return stepFromResult("face-swap", result, outputs: ["result": outputPath.path])
    }

    private func runInpaintStep(_ inputs: [String: URL]) throws -> PipelineStep {
        guard let image = inputs["image"] else {
            throw PipelineError.missingRequiredInput("inpaint requires 'image'")
        }
        guard let mask = inputs["mask"] else {
            throw PipelineError.missingRequiredInput("inpaint requires 'mask'")
        }

        let outputPath = tempDirectory.appendingPathComponent("inpainted.png")
        let runner = InpaintCommandRunner(
            image: image,
            mask: mask,
            algorithm: "patch-based",
            laMaPreset: "balanced",
            output: outputPath,
            format: .json
        )
        let result = try runner.execute()
        return stepFromResult("inpaint", result, outputs: ["result": outputPath.path])
    }

    private func runCompositeStep(_ inputs: [String: URL]) throws -> PipelineStep {
        guard let foreground = inputs["foreground"] else {
            throw PipelineError.missingRequiredInput("composite requires 'foreground'")
        }
        guard let background = inputs["background"] else {
            throw PipelineError.missingRequiredInput("composite requires 'background'")
        }

        let maskURL = inputs["mask"]
        let outputPath = tempDirectory.appendingPathComponent("composite-result.png")
        let runner = CompositeCommandRunner(
            foregroundURL: foreground,
            backgroundURL: background,
            maskURL: maskURL,
            blendMode: "alpha",
            originText: nil,
            sizeText: nil,
            rotationDegrees: 0,
            flipX: false,
            flipY: false,
            sampling: "Nearest",
            output: outputPath,
            format: .json
        )
        let result = try runner.execute()
        return stepFromResult("composite", result, outputs: ["result": outputPath.path])
    }

    private func runSelectionModifyStep(_ stepConfig: PipelineStepConfig, _ inputs: [String: URL]) throws -> PipelineStep {
        guard let input = inputs["input"] else {
            throw PipelineError.missingRequiredInput("selection-modify requires 'input'")
        }
        let operation = stepConfig.parameters?["operation"] ?? "expand"
        let amount = Double(stepConfig.parameters?["amount"] ?? "5") ?? 5
        let outputPath = tempDirectory.appendingPathComponent("selection-modified.png")
        let runner = SelectionModifyCommandRunner(
            input: input,
            operation: operation,
            amount: amount,
            unit: "pixels",
            point: nil,
            tolerance: 32,
            sampleSize: "point",
            contiguous: true,
            guide: nil,
            withMask: inputs["with"],
            sobelThreshold: 0.2,
            snapRadius: 3,
            output: outputPath,
            format: .json
        )
        let result = try runner.execute()
        return stepFromResult("selection-modify", result, outputs: ["mask": outputPath.path])
    }

    // MARK: - Input Resolution

    private func resolveStepInputs(_ stepConfig: PipelineStepConfig, using userInputs: [String: URL], fromPreviousOutputs previousOutputs: [String: [String: URL]]) throws -> [String: URL] {
        var resolved: [String: URL] = [:]

        for (paramName, paramSource) in stepConfig.inputs {
            let inputURL: URL

            // Check if source is a variable reference (e.g., "${extract.mask}")
            if paramSource.hasPrefix("${") && paramSource.hasSuffix("}") {
                // Variable reference: resolve from previous step outputs
                let ref = String(paramSource.dropFirst(2).dropLast())
                guard let dotIndex = ref.firstIndex(of: ".") else {
                    throw PipelineError.invalidStepConfiguration("Invalid variable reference: \(paramSource)")
                }
                let stepName = String(ref[..<dotIndex])
                let outputKey = String(ref[ref.index(after: dotIndex)...])

                guard let stepOutputMap = previousOutputs[stepName],
                      let url = stepOutputMap[outputKey] else {
                    throw PipelineError.missingRequiredInput(
                        "Variable '\(paramSource)' not found. Step '\(stepName)' output key '\(outputKey)' missing."
                    )
                }

                inputURL = url
            } else if let userURL = userInputs[paramSource] {
                // Direct user-provided input
                inputURL = userURL
            } else {
                // Try as literal file path
                inputURL = URL(fileURLWithPath: paramSource)
            }

            resolved[paramName] = inputURL
        }

        return resolved
    }

    // MARK: - Timing Helper

    private func dispatchTimeIntervalMs(_ start: DispatchTime, _ end: DispatchTime) -> Int {
        let interval = end.uptimeNanoseconds - start.uptimeNanoseconds
        return max(Int(interval / 1_000_000), 1)
    }
}

// MARK: - Pipeline Configuration

/// Represents a single step configuration in the pipeline definition.
public struct PipelineStepConfig: Codable {
    public let name: String                           // Step identifier (e.g., "extract", "face-detect")
    public let inputs: [String: String]               // Parameter name -> source path or variable ref
    public let parameters: [String: String]?          // Optional per-step parameters (e.g., operation, amount)

    public init(name: String, inputs: [String: String], parameters: [String: String]? = nil) {
        self.name = name
        self.inputs = inputs
        self.parameters = parameters
    }
}

/// Final result of a complete pipeline execution.
struct PipelineResult: Codable {
    let command: String                        // Always "pipeline"
    let version: String                        // e.g., "0.1.0"
    let status: String                         // "success" | "error"
    let output: String?                        // Final output path (if successful)
    let steps: [PipelineStep]                  // Per-step details
    let total_ms: Int                          // Total pipeline execution time

    func toJSON() -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try! encoder.encode(self)
    }
}
