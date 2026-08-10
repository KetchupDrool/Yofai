import SwiftUI
import SwiftData
import UIKit
import AVFoundation

/// System camera picker. Production only — never invents a capture image.
struct SystemCameraPicker: UIViewControllerRepresentable {
    var flashMode: UIImagePickerController.CameraFlashMode
    var onCapture: (UIImage) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraDevice = .rear
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        if UIImagePickerController.isFlashAvailable(for: .rear) {
            picker.cameraFlashMode = flashMode
        }
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        if UIImagePickerController.isFlashAvailable(for: .rear) {
            uiViewController.cameraFlashMode = flashMode
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        let onCancel: () -> Void

        init(onCapture: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onCapture = onCapture
            self.onCancel = onCancel
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            } else {
                onCancel()
            }
        }
    }
}

enum CameraPermissionSupport {
    static var status: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    static func requestAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    static var denialMessage: String {
        CameraCaptureError.permissionDenied.errorDescription
            ?? "Camera access is denied."
    }
}

struct ProjectCameraCaptureFlow: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: ItemProject
    var initialGoalID: PersistentIdentifier?

    @State private var flashMode: UIImagePickerController.CameraFlashMode = .auto
    @State private var selectedGoalStableIndex: Int? = nil
    @State private var pendingImage: UIImage?
    @State private var showPicker = false
    @State private var statusMessage: String?
    @State private var statusIsError = false
    @State private var permissionChecked = false

    private let systemSource = SystemCameraCaptureSource()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if !systemSource.isCameraAvailable {
                        Text(systemSource.unavailableMessage)
                            .foregroundStyle(DarkroomTheme.danger)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if CameraPermissionSupport.status == .denied || CameraPermissionSupport.status == .restricted {
                        Text(CameraPermissionSupport.denialMessage)
                            .foregroundStyle(DarkroomTheme.danger)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("Uses the system rear camera. No filters or network calls.")
                            .font(.subheadline)
                            .foregroundStyle(DarkroomTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Section {
                    Picker("Flash", selection: $flashMode) {
                        Text("Auto").tag(UIImagePickerController.CameraFlashMode.auto)
                        Text("On").tag(UIImagePickerController.CameraFlashMode.on)
                        Text("Off").tag(UIImagePickerController.CameraFlashMode.off)
                    }
                    .disabled(!UIImagePickerController.isFlashAvailable(for: .rear))

                    Picker("Attach to goal (optional)", selection: Binding(
                        get: { selectedGoalStableIndex ?? -1 },
                        set: { selectedGoalStableIndex = $0 < 0 ? nil : $0 }
                    )) {
                        Text("None").tag(-1)
                        ForEach(Array(project.sortedPhotoPlanGoals.enumerated()), id: \.element.persistentModelID) { index, goal in
                            Text(goal.name).tag(index)
                        }
                    }
                } header: {
                    Text("Capture Options")
                }

                if let pendingImage {
                    Section {
                        Image(uiImage: pendingImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Button("Save to Project") {
                            savePending()
                        }
                        .foregroundStyle(DarkroomTheme.accent)
                        Button("Retake") {
                            self.pendingImage = nil
                            openCameraIfPossible()
                        }
                        .foregroundStyle(DarkroomTheme.accent)
                    } header: {
                        Text("Confirm Capture")
                    }
                } else {
                    Section {
                        Button("Open Camera") {
                            openCameraIfPossible()
                        }
                        .foregroundStyle(DarkroomTheme.accent)
                        .disabled(!systemSource.isCameraAvailable)
                    }
                }

                if let statusMessage {
                    Section {
                        Text(statusMessage)
                            .foregroundStyle(statusIsError ? DarkroomTheme.danger : DarkroomTheme.accent)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .darkroomScreen()
            .navigationTitle("Capture Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                prepareGoalsAndPermission()
            }
            .fullScreenCover(isPresented: $showPicker) {
                SystemCameraPicker(
                    flashMode: flashMode,
                    onCapture: { image in
                        pendingImage = image
                        showPicker = false
                    },
                    onCancel: {
                        showPicker = false
                    }
                )
                .ignoresSafeArea()
            }
        }
    }

    private func prepareGoalsAndPermission() {
        PhotoPlanSupport.ensureStarterGoals(on: project, in: modelContext)
        if let initialGoalID,
           let index = project.sortedPhotoPlanGoals.firstIndex(where: { $0.persistentModelID == initialGoalID }) {
            selectedGoalStableIndex = index
        }
        permissionChecked = true
    }

    private func openCameraIfPossible() {
        statusMessage = nil
        do {
            try systemSource.requireAvailable()
        } catch {
            statusIsError = true
            statusMessage = (error as? LocalizedError)?.errorDescription ?? systemSource.unavailableMessage
            return
        }

        Task {
            let status = CameraPermissionSupport.status
            if status == .notDetermined {
                let granted = await CameraPermissionSupport.requestAccess()
                if !granted {
                    statusIsError = true
                    statusMessage = CameraPermissionSupport.denialMessage
                    return
                }
            } else if status == .denied || status == .restricted {
                statusIsError = true
                statusMessage = CameraPermissionSupport.denialMessage
                return
            }
            showPicker = true
        }
    }

    private func savePending() {
        guard let pendingImage else { return }
        do {
            let source = InjectedCaptureAdapter(image: pendingImage)
            let goal: PhotoPlanGoal?
            if let selectedGoalStableIndex, project.sortedPhotoPlanGoals.indices.contains(selectedGoalStableIndex) {
                goal = project.sortedPhotoPlanGoals[selectedGoalStableIndex]
            } else {
                goal = nil
            }
            _ = try ProjectPhotoCaptureSupport.insertCapturedPhoto(
                from: source,
                into: project,
                attachTo: goal,
                in: modelContext
            )
            try modelContext.save()
            dismiss()
        } catch {
            statusIsError = true
            statusMessage = (error as? LocalizedError)?.errorDescription ?? "Could not save captured photo."
        }
    }
}

/// Adapts an already-captured system camera image into the capture insertion path.
/// Not a fake camera — image came from UIImagePickerController.
private final class InjectedCaptureAdapter: ProjectPhotoCapturing {
    private let image: UIImage
    init(image: UIImage) { self.image = image }
    var isCameraAvailable: Bool { true }
    var unavailableMessage: String { "" }
    func requireAvailable() throws {}
    func captureImage() throws -> UIImage { image }
}
