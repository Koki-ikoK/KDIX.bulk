import SwiftUI
import AVFoundation
import Photos
import Combine

// MARK: - 📸 1. Camera Manager (AVFoundation)
class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var session = AVCaptureSession()
    @Published var capturedImage: UIImage? = nil
    @Published var isCameraReady = false
    
    private let photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput? 
    
    override init() {
        super.init()
        checkPermission()
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted { DispatchQueue.main.async { self.setupCamera() } }
            }
        default:
            break
        }
    }
    
    private func setupCamera() {
        do {
            session.beginConfiguration()
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
            let input = try AVCaptureDeviceInput(device: device)
            self.videoDeviceInput = input
            
            if session.canAddInput(input) { session.addInput(input) }
            if session.canAddOutput(photoOutput) { 
                session.addOutput(photoOutput)
            }
            
            session.commitConfiguration()
            
            // 💥 重要：コミット後にミラーリングを強制設定
            updateMirroring(for: photoOutput)
            
            DispatchQueue.global(qos: .background).async {
                self.session.startRunning()
                DispatchQueue.main.async { self.isCameraReady = true }
            }
        } catch {
            print("❌ Camera Setup Error: \(error.localizedDescription)")
        }
    }
    
    func switchCamera() {
        guard isCameraReady else { return }
        
        session.beginConfiguration()
        guard let currentInput = videoDeviceInput else { 
            session.commitConfiguration()
            return 
        }
        session.removeInput(currentInput)
        
        let newPosition: AVCaptureDevice.Position = (currentInput.device.position == .back) ? .front : .back
        
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
              let newInput = try? AVCaptureDeviceInput(device: newDevice) else {
            session.addInput(currentInput)
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(newInput) {
            session.addInput(newInput)
            videoDeviceInput = newInput
        } else {
            session.addInput(currentInput)
        }
        
        session.commitConfiguration()
        
        // 💥 切り替え直後に設定を強制リフレッシュ
        updateMirroring(for: photoOutput)
    }
    
    // 💥 修正：より強力なミラーリング強制ロジック
    private func updateMirroring(for output: AVCapturePhotoOutput) {
        // 出力側のコネクションを全てチェックしてミラーリングを適用
        for connection in output.connections {
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = (videoDeviceInput?.device.position == .front)
                print("📸 Capture Connection Mirroring Set: \(connection.isVideoMirrored)")
            }
        }
    }
    
    func capturePhoto() {
        print("📸 Shutter button pressed")
        guard photoOutput.connection(with: .video) != nil else {
            print("⚠️ No video connection found. Are you on a simulator?")
            #if targetEnvironment(simulator)
            if let dummyImage = UIImage(systemName: "photo.fill") {
                print("📝 Setting dummy image for simulator")
                DispatchQueue.main.async { self.capturedImage = dummyImage }
            }
            #endif
            return
        }
        
        // 撮影直前にも念のため設定を再確認
        updateMirroring(for: photoOutput)
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("📸 photoOutput delegate called")
        if let error = error {
            print("❌ Capture Error: \(error.localizedDescription)")
            return
        }
        
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            print("❌ Failed to get image data")
            return
        }
        
        // 💥 修正：向きを正しく修正しつつ、内カメなら鏡面にする
        var finalImage = image
        
        if let cgImage = image.cgImage {
            let isFront = videoDeviceInput?.device.position == .front
            
            // 撮影時のデバイスの向きにかかわらず、縦向き(Up)として扱うための補正
            // 内カメの場合は .leftMirrored または .upMirrored で調整
            if isFront {
                // 内カメ：鏡面を維持したまま、正しい回転にする
                // 多くのデバイスでは CGImage の生データは横向きなので、ここで縦向きの鏡面に変換
                finalImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: .leftMirrored)
            } else {
                // 外カメ：通常の縦向きにする
                finalImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: .right)
            }
        }
        
        // 🚨 もし上記でまだ90度ズレる場合は、ここを .up や .right など調整します
        // 基本的に iOS のカメラ生データは 90度回転した状態で届くため補正が必要です
        
        print("✅ Captured image processed. Size: \(finalImage.size)")
        DispatchQueue.main.async {
            self.capturedImage = finalImage
        }
    }
}

// MARK: - 📺 2. Camera Preview (UIViewRepresentable)
struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var camera: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: camera.session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        // 💥 修正：OSの設定ではなく、Viewそのものを反転させて「100%鏡」にする
        updateTransform(view)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        updateTransform(uiView)
    }
    
    private func updateTransform(_ view: UIView) {
        let isFront = camera.session.inputs.contains(where: { ($0 as? AVCaptureDeviceInput)?.device.position == .front })
        // 前面カメラの時だけ、ビューを左右反転（鏡）にする
        view.transform = isFront ? CGAffineTransform(scaleX: -1, y: 1) : .identity
    }
}

// MARK: - 🖼️ 3. ShareToSNSView
struct ShareToSNSView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var cameraManager = CameraManager()
    
    let totalTime: String
    let totalVolume: Int
    let routineName: String
    let themeColor: Color
    var onComplete: (UIImage, CGSize, CGFloat) -> Void
    
    @State private var isRendering = false
    @State private var overlayOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var overlayScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var contentSize: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if cameraManager.isCameraReady {
                    CameraPreviewView(camera: cameraManager)
                        .ignoresSafeArea()
                } else {
                    Color.black.ignoresSafeArea()
                }
                
                HUDStatsOverlay(
                    totalTime: totalTime, 
                    totalVolume: totalVolume, 
                    themeColor: themeColor,
                    isForRender: false,
                    scale: overlayScale,
                    measuredSize: $contentSize
                )
                .contentShape(Rectangle()) 
                .offset(overlayOffset)
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            overlayOffset = calculateBoundedOffset(
                                proposedWidth: lastOffset.width + value.translation.width,
                                proposedHeight: lastOffset.height + value.translation.height,
                                screen: geometry.size,
                                content: contentSize
                            )
                        }
                        .onEnded { value in
                            lastOffset = overlayOffset
                        }
                )
                .simultaneousGesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let newScale = min(max(lastScale * value, 0.3), 1.2)
                            overlayScale = newScale
                            
                            overlayOffset = calculateBoundedOffset(
                                proposedWidth: overlayOffset.width,
                                proposedHeight: overlayOffset.height,
                                screen: geometry.size,
                                content: CGSize(
                                    width: (contentSize.width / lastScale) * newScale,
                                    height: (contentSize.height / lastScale) * newScale
                                )
                            )
                        }
                        .onEnded { value in
                            lastScale = overlayScale
                            lastOffset = overlayOffset
                        }
                )
                
                VStack {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Drag to Move")
                            Text("Pinch to Resize")
                        }
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 10)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // 💥 修正：シャッターボタンの完全中央揃え
                    ZStack {
                        // 中央：シャッター
                        Button {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            cameraManager.capturePhoto()
                        } label: {
                            ZStack {
                                Circle().stroke(Color.white, lineWidth: 4).frame(width: 80, height: 80)
                                Circle().fill(Color.white).frame(width: 65, height: 65)
                            }
                        }
                        
                        // 右側：カメラ切り替え
                        HStack {
                            Spacer()
                            Button {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                cameraManager.switchCamera()
                            } label: {
                                Image(systemName: "camera.rotate.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, 30)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onChange(of: cameraManager.capturedImage) { _, image in
            if let img = image {
                onComplete(img, overlayOffset, overlayScale)
                dismiss()
            }
        }
    }
    
    private func calculateBoundedOffset(proposedWidth: CGFloat, proposedHeight: CGFloat, screen: CGSize, content: CGSize) -> CGSize {
        let limitX = max(0, (screen.width - content.width) / 2)
        let limitY = max(0, (screen.height - content.height) / 2)
        
        return CGSize(
            width: min(max(proposedWidth, -limitX), limitX),
            height: min(max(proposedHeight, -limitY), limitY)
        )
    }
}

// MARK: - 📐 4. HUDスタッツコンポーネント
struct HUDStatsOverlay: View {
    let totalTime: String
    let totalVolume: Int
    let themeColor: Color
    var isForRender: Bool = false
    var scale: CGFloat = 1.0
    var measuredSize: Binding<CGSize>? = nil 
    
    var body: some View {
        VStack(spacing: 25 * scale) {
            Spacer()
            
            // 1. 人体モデル
            ZStack {
                AnatomicalHumanShape(isFront: true)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    .frame(width: 100 * scale, height: 200 * scale)
                Text("ACTIVE")
                    .font(.system(size: 8 * scale, weight: .black, design: .monospaced))
                    .foregroundColor(.green)
                    .padding(4 * scale)
                    .background(Color.black.opacity(0.5))
                    .offset(y: 85 * scale)
            }
            .padding(.bottom, 10 * scale)
            
            // 2. TOTAL ELAPSED TIME
            VStack(spacing: 4 * scale) {
                Text("TOTAL ELAPSED TIME")
                    .font(.system(size: 12 * scale, weight: .black, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                Text(formatDisplayTime(totalTime))
                    .font(.system(size: 50 * scale, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: true, vertical: false)
            }
            
            // 3. TOTAL MASS OUTPUT
            VStack(spacing: 4 * scale) {
                Text("TOTAL MASS OUTPUT")
                    .font(.system(size: 12 * scale, weight: .black, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                Text("\(totalVolume) KG")
                    .font(.system(size: 50 * scale, weight: .black, design: .monospaced))
                    .foregroundColor(themeColor)
                    .fixedSize(horizontal: true, vertical: false)
            }
            
            // 4. アプリロゴ
            Image("redline_logo_transparent")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 160 * scale)
                .shadow(color: themeColor.opacity(0.5), radius: 15 * scale)
            
            // 5. アプリ名 (REDLINE)
            Text("REDLINE")
                .font(.system(size: 28 * scale, weight: .black, design: .monospaced))
                .foregroundColor(.white)
                .tracking(10 * scale)
                .fixedSize(horizontal: true, vertical: false)
            
            Spacer()
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { measuredSize?.wrappedValue = proxy.size }
                    .onChange(of: proxy.size) { _, newSize in measuredSize?.wrappedValue = newSize }
            }
        )
        .padding(.horizontal, 30 * scale)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .shadow(color: .black.opacity(0.5), radius: 10 * scale)
    }
    
    private func formatDisplayTime(_ time: String) -> String {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        var h = 0, m = 0, s = 0
        if parts.count == 2 { m = parts[0]; s = parts[1] }
        else if parts.count == 3 { h = parts[0]; m = parts[1]; s = parts[2] }
        m += s / 60; s = s % 60; h += m / 60; m = m % 60
        return String(format: "%02dh%02dm%02ds", h, m, s)
    }
}

// MARK: - 🎨 5. 合成用レンダリングView
struct CompositeShareView: View {
    let photo: UIImage
    let totalTime: String
    let totalVolume: Int
    let themeColor: Color
    let offset: CGSize
    let scale: CGFloat
    
    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        ZStack {
            Image(uiImage: photo)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: screenWidth, height: screenHeight)
                .clipped()
            HUDStatsOverlay(
                totalTime: totalTime, 
                totalVolume: totalVolume, 
                themeColor: themeColor,
                isForRender: true,
                scale: scale
            )
            .offset(offset)
            .frame(width: screenWidth, height: screenHeight)
        }
        .frame(width: screenWidth, height: screenHeight)
    }
}

#Preview {
    ShareToSNSView(
        totalTime: "48:20",
        totalVolume: 8400,
        routineName: "Chest & Triceps Day",
        themeColor: .cyan,
        onComplete: { _, _, _ in }
    )
}
