@preconcurrency import AVFoundation
import Vision

@MainActor
final class PoseDetectionService: NSObject, ObservableObject {
    @Published private(set) var pose: BodyPose?
    @Published private(set) var status = "Starting…"

    nonisolated let captureSession: AVCaptureSession
    private let captureQueue = DispatchQueue(label: "ProgYog.captureQueue", qos: .userInitiated)
    private var framesReceived = 0

    override init() {
        captureSession = AVCaptureSession()
        super.init()
    }

    func start() {
        Task { @MainActor in
            let auth = AVCaptureDevice.authorizationStatus(for: .video)
            switch auth {
            case .authorized:
                setupAndStart()
            case .notDetermined:
                status = "Requesting camera permission…"
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                if granted { setupAndStart() }
                else { status = "Camera access denied — enable in Settings → Privacy → Camera" }
            case .denied, .restricted:
                status = "Camera access denied — enable in Settings → Privacy → Camera"
            @unknown default:
                status = "Unknown camera authorization status"
            }
        }
    }

    func stop() {
        captureQueue.async { [session = captureSession] in
            session.stopRunning()
        }
        pose = nil
        framesReceived = 0
    }

    private func setupAndStart() {
        guard configure() else { return }
        captureQueue.async { [session = captureSession] in
            session.startRunning()
        }
        status = "Session started, detecting…"
    }

    // Returns true if session was configured successfully.
    @discardableResult
    private func configure() -> Bool {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: device),
            captureSession.canAddInput(input)
        else {
            captureSession.commitConfiguration()
            status = "Failed to open front camera"
            return false
        }
        captureSession.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        // BGRA is the format Vision handles most efficiently
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.setSampleBufferDelegate(self, queue: captureQueue)
        guard captureSession.canAddOutput(output) else {
            captureSession.commitConfiguration()
            status = "Failed to add video output"
            return false
        }
        captureSession.addOutput(output)
        captureSession.commitConfiguration()

        // Configure connection AFTER commit — connections aren't fully wired until then.
        if let connection = output.connection(with: .video) {
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
                status = "Connection: rotation=90°"
            } else {
                // Fallback for devices where videoRotationAngle isn't supported
                connection.videoOrientation = .portrait
                status = "Connection: orientation=portrait (fallback)"
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        } else {
            status = "No video connection after commit"
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

        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([request])
        } catch {
            Task { @MainActor [weak self] in
                self?.status = "Vision error: \(error.localizedDescription)"
            }
            return
        }

        let detected: BodyPose?
        if let observation = request.results?.first {
            detected = BodyPose.from(observation)
        } else {
            detected = nil
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.framesReceived += 1
            self.status = detected != nil
                ? "Detected ✓ (frame \(self.framesReceived))"
                : "No body found (frame \(self.framesReceived))"
            self.pose = detected
        }
    }
}
