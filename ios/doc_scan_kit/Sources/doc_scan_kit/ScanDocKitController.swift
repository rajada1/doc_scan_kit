import Foundation
import VisionKit
import Vision
import Flutter
import PDFKit

@available(iOS 13.0, *)
class ScanDocKitController: UIViewController, VNDocumentCameraViewControllerDelegate {
    
    let result: FlutterResult
    let compressionQuality: CGFloat
    let format: DocScanKitFormat
    let colorList : [NSNumber]
    var activityIndicator: UIActivityIndicatorView!
    
    
    init(result: @escaping FlutterResult, compressionQuality: CGFloat, format: DocScanKitFormat, colorList:[NSNumber] ) {
        self.result = result
        self.compressionQuality = compressionQuality
        self.format = format
        self.colorList = colorList
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        self.view.addSubview(activityIndicator)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if self.isBeingPresented {
            let documentCameraVC = VNDocumentCameraViewController()
            documentCameraVC.delegate = self
            
            //Apply tint color
            applyTintColor(controller: documentCameraVC)
            
            
            present(documentCameraVC, animated: true)
        }
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        result(nil)
        controller.dismiss(animated: true)
        dismiss(animated: true)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: any Error) {
        result(FlutterError(code: "SCAN_FAIL", message: error.localizedDescription, details: error.localizedDescription))
        controller.dismiss(animated: true)
        dismiss(animated: true)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        controller.dismiss(animated: true) {
            var resultArray: [[String: Any?]] = []
            
            switch self.format {
            case .document:
                // Save as PDF with each image on separate page
                if let pdfPath = self.createPDF(from: scan) {
                    resultArray.append([
                        "type": "pdf",
                        "path": pdfPath
                    ])
                } else {
                    print("Error creating PDF")
                }
            case .images:
                // Save as individual images
                for i in (0 ..< scan.pageCount) {
                    autoreleasepool {
                        let image = scan.imageOfPage(at: i)
                        if let imageData = image.jpegData(compressionQuality: self.compressionQuality) {
                            let filePath = self.saveImg(image: imageData)
                            
                            resultArray.append([
                              "type": "jpeg",
                              "path": filePath
                            ])
                        } else {
                            print("Error converting image to jpeg")
                        }
                    }
                }
            }

            
            self.activityIndicator.stopAnimating()
            self.result(resultArray)
            self.dismiss(animated: true)
        }
    }
    
    func saveImg(image: Data) -> String? {
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
            return nil
        }
        let fileName = UUID().uuidString + ".jpeg"
        
        guard let filePath = directory.appendingPathComponent(fileName) else {
            return nil
        }
        do {
            try image.write(to: filePath)
            return filePath.path
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func createPDF(from scan: VNDocumentCameraScan) -> String? {
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
            return nil
        }
        
        let fileName = UUID().uuidString + ".pdf"
        let pdfURL = directory.appendingPathComponent(fileName)
        
        let pdfDocument = PDFDocument()
        
        for i in 0..<scan.pageCount {
            autoreleasepool {
                let image = scan.imageOfPage(at: i)
                
                // Apply compression quality to the image
                if let imageData = image.jpegData(compressionQuality: self.compressionQuality),
                   let compressedImage = UIImage(data: imageData),
                   let pdfPage = PDFPage(image: compressedImage) {
                    pdfDocument.insert(pdfPage, at: i)
                }
            }
        }
        
        if pdfDocument.write(to: pdfURL) {
            return pdfURL.path
        } else {
            return nil
        }
    }
    
    func applyTintColor(controller: VNDocumentCameraViewController) {
        if self.colorList.count >= 4 {
            let red = CGFloat(truncating: colorList[0])
            let green = CGFloat(truncating: colorList[1])
            let blue = CGFloat(truncating: colorList[2])
            let alpha = CGFloat(truncating: colorList[3])

            controller.view.tintColor = UIColor(red: red, green: green, blue: blue, alpha: alpha)
        }
    }
}

