//
//  main.swift
//  uPVC
//
//  Created by Reuben on 10/11/2020.
//  Copyright © 2020 Reuben. All rights reserved.
//

import Foundation
import AVFoundation

let arguments = Array(CommandLine.arguments[1...])
var stderr = StandardErrorOutputStream()

if(arguments.count == 0) {print("need a file", to: &stderr); exit(1)}

let videoPath = arguments[0]
let frameSkip = arguments.count > 1 ? Int(arguments[1]) : nil

let videoURL = URL(fileURLWithPath: videoPath)

let asset = AVAsset(url: videoURL)
let reader = try? AVAssetReader(asset: asset)

if(reader == nil) {print("sure this is a media file?", to: &stderr); exit(1)}

let videoTracks = asset.tracks(withMediaType: AVMediaType.video)

if(videoTracks.count == 0) {print("sure this is a video file?", to: &stderr); exit(1)}

let videoTrack = videoTracks[0]

let trackReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings:[String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])

reader!.add(trackReaderOutput)
reader!.startReading()

var frameIndex = 0

while let sampleBuffer = trackReaderOutput.copyNextSampleBuffer() {
  if((frameSkip != nil) && ((frameIndex % frameSkip!) == 0)) {
    if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
      let ciimage: CIImage = CIImage(cvPixelBuffer: imageBuffer)
      
      if let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) {
        do {
          let format = CIFormat.RGBA16 // 16-bit RGBA
          let quality = 1.0 // 1.0 = lossless
          
          let outFolderURL = videoURL.deletingPathExtension()
          let outURL = outFolderURL.appendingPathComponent("frame-\(frameIndex).png")
          
          let context = CIContext()
          
          try FileManager.default.createDirectory(at: outFolderURL, withIntermediateDirectories: true, attributes: nil)
          try context.writePNGRepresentation(of: ciimage, to: outURL, format: format, colorSpace: colorSpace, options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: quality])
        } catch {
          print(error.localizedDescription, to: &stderr)
        }
      }
    }
  }
  frameIndex += 1
}

final class StandardErrorOutputStream: TextOutputStream {
  func write(_ string: String) {
    FileHandle.standardError.write(Data(string.utf8))
  }
}
