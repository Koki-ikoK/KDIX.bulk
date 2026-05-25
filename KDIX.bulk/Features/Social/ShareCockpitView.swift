import SwiftUI

struct ShareCockpitView: View {
    @Environment(\.dismiss) var dismiss
    let routineName: String
    let routineID: String 
    let driverName: String
    let totalVolume: Int
    let totalTime: String
    let themeColor: Color
    let isPublic: Bool // 💥 追加
    
    // 💥 投稿完了時のコールバックを追加
    var onPosted: (() -> Void)? = nil
    
    @State private var selectedStyle: ShareStyle = .classic
    @State private var showCameraShare = false
    
    @State private var capturedPhoto: UIImage? = nil
    @State private var photoOffset: CGSize = .zero
    @State private var photoScale: CGFloat = 1.0
    
    @State private var showPostSuccess = false
    @State private var isUploading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 15) {
                        VStack(spacing: 8) {
                            Text("PREVIEW").font(.system(size: 10, weight: .black, design: .monospaced)).foregroundColor(.gray)
                            
                            ZStack(alignment: .bottomTrailing) {
                                if let photo = capturedPhoto {
                                    let screenBounds = UIScreen.main.bounds
                                    let aspectRatio = screenBounds.height / screenBounds.width
                                    let previewWidth: CGFloat = 240 
                                    
                                    CompositeShareView(
                                        photo: photo,
                                        totalTime: totalTime,
                                        totalVolume: totalVolume,
                                        themeColor: themeColor,
                                        offset: photoOffset,
                                        scale: photoScale
                                    )
                                    .scaleEffect(previewWidth / screenBounds.width)
                                    .frame(width: previewWidth, height: previewWidth * aspectRatio)
                                    .clipped()
                                } else {
                                    ShareResultImageView(
                                        routineName: routineName,
                                        driverName: driverName,
                                        totalVolume: totalVolume,
                                        totalTime: totalTime,
                                        themeColor: themeColor,
                                        style: selectedStyle
                                    )
                                    .scaleEffect(0.5)
                                    .frame(width: 260, height: 260)
                                }
                            }
                            .background(Color.black)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.5), radius: 15, y: 8)
                        }
                        .padding(.top, 10)
                        
                        if capturedPhoto == nil {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("SELECT STYLE").font(.system(size: 10, weight: .black, design: .monospaced)).foregroundColor(.gray).padding(.horizontal, 24)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        Button {
                                            showCameraShare = true
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        } label: {
                                            VStack(spacing: 4) {
                                                Image(systemName: "camera.shutter.button.fill")
                                                Text("PHOTO").font(.system(size: 8, weight: .black))
                                            }
                                            .foregroundColor(.white)
                                            .frame(width: 54, height: 40)
                                            .background(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .cornerRadius(8)
                                        }
                                        
                                        ForEach(ShareStyle.allCases) { style in
                                            Button {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    selectedStyle = style
                                                }
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            } label: {
                                                Text(style.rawValue)
                                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                                    .foregroundColor(selectedStyle == style ? .black : .white)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(selectedStyle == style ? themeColor : Color.white.opacity(0.1))
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                        } else {
                            Button {
                                showCameraShare = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                    Text("RETAKE PHOTO").font(.system(size: 12, weight: .bold))
                                }
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(20)
                            }
                        }
                        
                        Spacer(minLength: 30)
                        
                        Button {
                            shareAction()
                        } label: {
                            HStack(spacing: 12) {
                                if isUploading {
                                    ProgressView().tint(.black)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                    Text("FINALIZE & POST").font(.system(size: 16, weight: .black, design: .rounded))
                                }
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(themeColor)
                            .cornerRadius(16)
                            .padding(.horizontal, 24)
                        }
                        .disabled(isUploading)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("POST TO FEED") 
            .alert("POSTED!", isPresented: $showPostSuccess) {
                Button("OK") { 
                    dismiss()
                    onPosted?() 
                }
            } message: {
                Text("Your mission report has been sent to the community feed.")
            }
            .fullScreenCover(isPresented: $showCameraShare) {
                ShareToSNSView(
                    totalTime: totalTime,
                    totalVolume: totalVolume,
                    routineName: routineName,
                    themeColor: themeColor,
                    onComplete: { photo, offset, scale in
                        self.capturedPhoto = photo
                        self.photoOffset = offset
                        self.photoScale = scale
                    }
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("CLOSE") { dismiss() }.foregroundColor(.white).font(.system(size: 14, weight: .bold))
                }
            }
        }
    }
    
    @MainActor private func shareAction() {
        isUploading = true
        
        var base64String: String? = nil
        if let photo = capturedPhoto {
            let compositeView = CompositeShareView(
                photo: photo,
                totalTime: totalTime,
                totalVolume: totalVolume,
                themeColor: themeColor,
                offset: photoOffset,
                scale: photoScale
            )
            let renderer = ImageRenderer(content: compositeView)
            renderer.scale = 1.0 
            if let uiImage = renderer.uiImage,
               let jpegData = uiImage.jpegData(compressionQuality: 0.1) {
                base64String = jpegData.base64EncodedString()
            }
        }
        
        let report = SharedMissionReport(
            ownerName: driverName,
            routineName: routineName,
            routineID: routineID, 
            totalVolume: totalVolume,
            totalTime: totalTime,
            themeColor: themeColor.toHex() ?? "#00FFFF",
            date: Date(),
            hasPhoto: capturedPhoto != nil,
            photoBase64: base64String,
            styleName: capturedPhoto == nil ? selectedStyle.rawValue : nil,
            isRoutinePublic: isPublic // 💥 追加
        )
        
        FirebaseManager.shared.uploadMissionReport(report: report)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isUploading = false
            self.showPostSuccess = true
        }
    }
    
    @MainActor private func renderAndSystemShare() {
        let viewToRender: AnyView
        if let photo = capturedPhoto {
            viewToRender = AnyView(
                CompositeShareView(
                    photo: photo,
                    totalTime: totalTime,
                    totalVolume: totalVolume,
                    themeColor: themeColor,
                    offset: photoOffset,
                    scale: photoScale
                )
            )
        } else {
            viewToRender = AnyView(
                ShareResultImageView(
                    routineName: routineName,
                    driverName: driverName,
                    totalVolume: totalVolume,
                    totalTime: totalTime,
                    themeColor: themeColor,
                    style: selectedStyle
                )
            )
        }
        
        let renderer = ImageRenderer(content: viewToRender)
        renderer.scale = 3.0 
        
        if let uiImage = renderer.uiImage {
            let activityVC = UIActivityViewController(activityItems: [uiImage], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               var topVC = windowScene.windows.first?.rootViewController {
                while let presentedVC = topVC.presentedViewController {
                    topVC = presentedVC
                }
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = topVC.view
                    popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                topVC.present(activityVC, animated: true)
            }
        }
    }
}

extension Color {
    func toHex() -> String? {
        let uiColor = UIColor(self)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
        }
        return nil
    }
}
