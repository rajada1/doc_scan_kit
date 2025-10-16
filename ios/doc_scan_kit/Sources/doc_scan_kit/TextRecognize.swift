//
//  TextRecog.swift
//  doc_scan_kit
//
//  Created by  Matheus Santos de Oliveira on 25/01/25.
//

import UIKit
import Vision

class TextRecognizeViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView?
    var transcript = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        textView?.text = transcript
    }
}
// MARK: RecognizedTextDataSource
extension TextRecognizeViewController: RecognizedTextDataSource {
    @available(iOS 13.0, *)
    func addRecognizedText(recognizedText: [VNRecognizedTextObservation]) {
        // Create a full transcript to run analysis on.
        let maximumCandidates = 1
        for observation in recognizedText {
            guard let candidate = observation.topCandidates(maximumCandidates).first else { continue }
            transcript += candidate.string
            transcript += "\n"
        }
        textView?.text = transcript
    }
    
    @available(iOS 13.0, *)
    func recognizeText(from image: UIImage, recognitionLevel: VNRequestTextRecognitionLevel, usesLanguageCorrection: Bool, customWords: [String], recognitionLanguages: [String]) -> String {
        guard let cgImage = image.cgImage else {
            return ""
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }

            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
        }
        
        if #available(iOS 16.0, *) {
            request.revision = VNRecognizeTextRequestRevision3
        } else {
            if #available(iOS 14.0, *) {
                request.revision = VNRecognizeTextRequestRevision2
            } else {
                request.revision = VNRecognizeTextRequestRevision1
            }
        }

        request.recognitionLevel = recognitionLevel
        request.usesLanguageCorrection = usesLanguageCorrection
        request.customWords = customWords
        request.recognitionLanguages = recognitionLanguages



        do {
            try requestHandler.perform([request])

            if let observations = request.results {
                return observations.compactMap {
                    $0.topCandidates(1).first?.string
                }.joined(separator: "\n")
            }
        } catch {
            print("Text recognition error: \(error)")
        }
        return ""
    }
    
    @available(iOS 13.0, *)
    func recognizeTextDetailed(from image: UIImage, recognitionLevel: VNRequestTextRecognitionLevel, usesLanguageCorrection: Bool, customWords: [String], recognitionLanguages: [String]) -> [String: Any] {
        guard let cgImage = image.cgImage else {
            return ["text": "", "blocks": NSNull()]
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        var resultData: [String: Any] = ["text": "", "blocks": NSNull()]
        
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = recognitionLevel
        request.usesLanguageCorrection = usesLanguageCorrection
        request.customWords = customWords
        request.recognitionLanguages = recognitionLanguages
        
        if #available(iOS 16.0, *) {
            request.revision = VNRecognizeTextRequestRevision3
        } else if #available(iOS 14.0, *) {
            request.revision = VNRecognizeTextRequestRevision2
        } else {
            request.revision = VNRecognizeTextRequestRevision1
        }

        do {
            try requestHandler.perform([request])
            
            guard let observations = request.results else {
                return ["text": "", "blocks": NSNull()]
            }

            var allText = ""
            var lines: [[String: Any]] = []
            let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
            
            for observation in observations {
                guard let candidate = observation.topCandidates(1).first else { continue }
                
                allText += candidate.string + "\n"
                
                // Extract line bounding box information
                let boundingBox = observation.boundingBox
                
                // Convert Vision normalized coordinates (origin bottom-left)
                // to pixel coordinates (origin top-left)
                let left = Int(boundingBox.minX * imageSize.width)
                let bottom = Int((1 - boundingBox.minY) * imageSize.height)
                let right = Int(boundingBox.maxX * imageSize.width)
                let top = Int((1 - boundingBox.maxY) * imageSize.height)
                
                // Line corner points
                let topLeft = observation.topLeft
                let topRight = observation.topRight
                let bottomLeft = observation.bottomLeft
                let bottomRight = observation.bottomRight
                
                let tlX = Int(topLeft.x * imageSize.width)
                let tlY = Int((1 - topLeft.y) * imageSize.height)
                let trX = Int(topRight.x * imageSize.width)
                let trY = Int((1 - topRight.y) * imageSize.height)
                let brX = Int(bottomRight.x * imageSize.width)
                let brY = Int((1 - bottomRight.y) * imageSize.height)
                let blX = Int(bottomLeft.x * imageSize.width)
                let blY = Int((1 - bottomLeft.y) * imageSize.height)
                
                let points: [[String: Int]] = [
                    ["x": tlX, "y": tlY],
                    ["x": trX, "y": trY],
                    ["x": brX, "y": brY],
                    ["x": blX, "y": blY]
                ]
                
                let rect: [String: Int] = [
                    "left": left,
                    "top": top,
                    "right": right,
                    "bottom": bottom
                ]
                
                // Extract elements (words) from the line
                var elements: [[String: Any]] = []
                
                // Split text into words
                let words = candidate.string.split(separator: " ")
                var currentIndex = candidate.string.startIndex
                
                for word in words {
                    let wordString = String(word)
                    
                    // Calculate the word range in the original text
                    guard let wordRange = candidate.string.range(of: wordString, range: currentIndex..<candidate.string.endIndex) else {
                        continue
                    }
                    
                    // Try to get the bounding box for this word
                    if let wordBox = try? candidate.boundingBox(for: wordRange) {
                        // Convert word coordinates
                        let wordLeft = Int(wordBox.boundingBox.minX * imageSize.width)
                        let wordBottom = Int((1 - wordBox.boundingBox.minY) * imageSize.height)
                        let wordRight = Int(wordBox.boundingBox.maxX * imageSize.width)
                        let wordTop = Int((1 - wordBox.boundingBox.maxY) * imageSize.height)
                        
                        // Word corner points
                        let wordTL = wordBox.topLeft
                        let wordTR = wordBox.topRight
                        let wordBL = wordBox.bottomLeft
                        let wordBR = wordBox.bottomRight
                        
                        let wordPoints: [[String: Int]] = [
                            ["x": Int(wordTL.x * imageSize.width), "y": Int((1 - wordTL.y) * imageSize.height)],
                            ["x": Int(wordTR.x * imageSize.width), "y": Int((1 - wordTR.y) * imageSize.height)],
                            ["x": Int(wordBR.x * imageSize.width), "y": Int((1 - wordBR.y) * imageSize.height)],
                            ["x": Int(wordBL.x * imageSize.width), "y": Int((1 - wordBL.y) * imageSize.height)]
                        ]
                        
                        let wordRect: [String: Int] = [
                            "left": wordLeft,
                            "top": wordTop,
                            "right": wordRight,
                            "bottom": wordBottom
                        ]
                        
                        let elementData: [String: Any] = [
                            "text": wordString,
                            "confidence": candidate.confidence,
                            "rect": wordRect,
                            "points": wordPoints,
                            "recognizedLanguages": [],
                            "symbols": [],
                            "angle": 0.0
                        ]
                        
                        elements.append(elementData)
                    }
                    
                    // Advance index to after current word
                    currentIndex = wordRange.upperBound
                }
                
                let lineData: [String: Any] = [
                    "text": candidate.string,
                    "confidence": candidate.confidence,
                    "rect": rect,
                    "points": points,
                    "recognizedLanguages": [],
                    "elements": elements,
                    "angle": 0.0
                ]
                
                lines.append(lineData)
            }
            
            // iOS Vision does not support block grouping, so returns null for blocks
            // but returns lines with extracted elements (words)
            resultData = [
                "text": allText.trimmingCharacters(in: .whitespacesAndNewlines),
                "blocks": NSNull(),
                "lines": lines
            ]
        } catch {
            print("Detailed text recognition error: \(error)")
        }
        
        return resultData
    }
    
    func detectBarcode(from image: UIImage) -> String {
        guard let cgImage = image.cgImage else {
            return ""
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        var barcodeResults = ""
        
        let request = VNDetectBarcodesRequest { request, error in
            guard let results = request.results as? [VNBarcodeObservation] else {
                return
            }
            
            if #available(iOS 17.0, *) {
                request.revision = VNDetectBarcodesRequestRevision4
            } else {
                if #available(iOS 16.0, *) {
                    request.revision = VNDetectBarcodesRequestRevision3
                    
                } else {
                    if #available(iOS 15.0, *) {
                        request.revision = VNDetectBarcodesRequestRevision2
                    } else {
                        request.revision = VNDetectBarcodesRequestRevision1
                    }
                }
            }
            barcodeResults = results.compactMap { observation in
                observation.payloadStringValue
            }.joined(separator: ", ")
        }
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Barcode detection error: \(error)")
        }
        
        return barcodeResults
    }
}


