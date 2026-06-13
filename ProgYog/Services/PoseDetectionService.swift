@preconcurrency import AVFoundation
import Vision

@MainActor
final class PoseDetectionService: NSObject, ObservableObject {
    @Published private(set) var pose: BodyPose?
    @Published private(set) var isFrontCamera = true

    nonisolated let captureSession: AVCaptureSession
    private let captureQueue = DispatchQueue(label: "ProgYog.captureQueue", qos: .userInitiated)
    // Reused per-frame; only accessed serially on captureQueue
    nonisolated(unsafe) private var poseRequest = VNDetectHumanBodyPoseRequest()

    override init() {
        captureSession = AVCaptureSession()
        super.init()
    }

    func start() {
        if captureSession.isRunning { return }
        Task { @MainActor in
            if !captureSession.inputs.isEmpty {
                captureQueue.async { [session = captureSession] in session.startRunning() }
                return
            }
            let auth = AVCaptureDevice.authorizationStatus(for: .video)
            switch auth {
            case .authorized:
                setupAndStart()
            case .notDetermined:
                if await AVCaptureDevice.requestAccess(for: .video) { setupAndStart() }
            case .denied, .restricted:
                break
            @unknown default:
                break
            }
        }
    }

    func stop() {
        captureQueue.async { [session = captureSession] in session.stopRunning() }
        pose = nil
    }

    func flip() {
        let newPosition: AVCaptureDevice.Position = isFrontCamera ? .back : .front
        isFrontCamera = (newPosition == .front)
        pose = nil

        captureQueue.async { [session = captureSession, newPosition] in
            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                let newInput = try? AVCaptureDeviceInput(device: device)
            else { return }

            session.beginConfiguration()
            session.inputs.forEach { session.removeInput($0) }
            guard session.canAddInput(newInput) else {
                session.commitConfiguration()
                return
            }
            session.addInput(newInput)
            session.commitConfiguration()

            guard
                let output = session.outputs.first(where: { $0 is AVCaptureVideoDataOutput }),
                let connection = output.connection(with: .video)
            else { return }

            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = (newPosition == .front)
            }
        }
    }

    private func setupAndStart() {
        guard configure(position: .front) else { return }
        captureQueue.async { [session = captureSession] in session.startRunning() }
    }

    @discardableResult
    private func configure(position: AVCaptureDevice.Position) -> Bool {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
            let input = try? AVCaptureDeviceInput(device: device),
            captureSession.canAddInput(input)
        else {
            captureSession.commitConfiguration()
            return false
        }
        captureSession.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: captureQueue)
        guard captureSession.canAddOutput(output) else {
            captureSession.commitConfiguration()
            return false
        }
        captureSession.addOutput(output)
        captureSession.commitConfiguration()

        if let connection = output.connection(with: .video) {
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = (position == .front)
            }
        }
        return true
    }
}

extension PoseDetectionService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            .perform([poseRequest])
        let detected = poseRequest.results?.first.flatMap(BodyPose.from)
        Task { @MainActor [weak self] in
            self?.pose = detected
        }
    }
}
