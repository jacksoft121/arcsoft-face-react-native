import AVFoundation
import CoreVideo
import Foundation
import NitroModules
import VisionCamera

final class HybridArcsoftFrameDetector: HybridArcsoftFrameDetectorSpec {
  func detectFaces(
    frame: any HybridFrameSpec,
    options: ArcsoftDetectFacesOptions
  ) throws -> ArcsoftDetectFacesResult {
    let sampleBuffer = try sampleBuffer(from: frame)
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      throw RuntimeError.error(
        withMessage: "The given Frame does not contain a valid image buffer!")
    }

    let rawResult = ArcsoftFrameDetectorRuntime.detectFaces(
      pixelBuffer: pixelBuffer,
      options: optionsDictionary(options))
    return parseResult(rawResult)
  }

  private func sampleBuffer(from frame: any HybridFrameSpec) throws -> CMSampleBuffer {
    guard let nativeFrame = frame as? any NativeFrame else {
      throw RuntimeError.error(withMessage: "The given Frame is not of type `NativeFrame`!")
    }
    guard let sampleBuffer = nativeFrame.sampleBuffer else {
      throw RuntimeError.error(withMessage: "The given Frame's `sampleBuffer` is no longer valid!")
    }
    return sampleBuffer
  }

  private func optionsDictionary(_ options: ArcsoftDetectFacesOptions) -> [AnyHashable: Any] {
    var dict: [AnyHashable: Any] = [:]
    if let saveImage = options.saveImage {
      dict[AnyHashable("saveImage")] = saveImage
    }
    if let captureUserIds = options.captureUserIds {
      dict[AnyHashable("captureUserIds")] = captureUserIds
    }
    if let extractFeature = options.extractFeature {
      dict[AnyHashable("extractFeature")] = extractFeature
    }
    if let retExtractFeatureBase64 = options.retExtractFeatureBase64 {
      dict[AnyHashable("retExtractFeatureBase64")] = retExtractFeatureBase64
    }
    if let score = options.score {
      dict[AnyHashable("score")] = score
    }
    if let maxRetryCount = options.maxRetryCount {
      dict[AnyHashable("maxRetryCount")] = maxRetryCount
    }
    return dict
  }

  private func parseResult(_ result: [AnyHashable: Any]) -> ArcsoftDetectFacesResult {
    let rawFaces = value("faces", in: result) as? [Any] ?? []
    let faces = rawFaces.compactMap { rawFace -> ArcsoftDetectedFace? in
      guard let face = dictionaryValue(rawFace) else {
        return nil
      }
      return parseFace(face)
    }

    return ArcsoftDetectFacesResult(
      faces: faces,
      imagePath: value("imagePath", in: result) as? String)
  }

  private func parseFace(_ face: [AnyHashable: Any]) -> ArcsoftDetectedFace? {
    guard let rectDict = dictionaryValue(value("rect", in: face)) else {
      return nil
    }

    let rect = ArcsoftFrameRect(
      left: doubleValue(value("left", in: rectDict)),
      top: doubleValue(value("top", in: rectDict)),
      right: doubleValue(value("right", in: rectDict)),
      bottom: doubleValue(value("bottom", in: rectDict)))

    // 保留 SDK 的真实 3D 姿态；字段缺失时返回 nil，业务层会阻止注册，
    // 不能用 0 度伪装成正脸。
    let angle: ArcsoftFrameAngle?
    if let angleDict = dictionaryValue(value("angle", in: face)) {
      angle = ArcsoftFrameAngle(
        yaw: doubleValue(value("yaw", in: angleDict)),
        pitch: doubleValue(value("pitch", in: angleDict)),
        roll: doubleValue(value("roll", in: angleDict)),
        valid: boolValue(value("valid", in: angleDict)))
    } else {
      angle = nil
    }

    return ArcsoftDetectedFace(
      rect: rect,
      orient: doubleValue(value("orient", in: face)),
      faceId: doubleValue(value("faceId", in: face)),
      angle: angle,
      featureBase64: value("featureBase64", in: face) as? String,
      userId: value("userId", in: face) as? String,
      score: optionalDoubleValue(value("score", in: face)))
  }

  private func value(_ key: String, in dict: [AnyHashable: Any]) -> Any? {
    return dict[AnyHashable(key)]
  }

  private func dictionaryValue(_ value: Any?) -> [AnyHashable: Any]? {
    if let dict = value as? [AnyHashable: Any] {
      return dict
    }
    if let dict = value as? NSDictionary {
      var result: [AnyHashable: Any] = [:]
      for (key, value) in dict {
        if let key = key as? String {
          result[AnyHashable(key)] = value
        }
      }
      return result
    }
    return nil
  }

  private func doubleValue(_ value: Any?) -> Double {
    return optionalDoubleValue(value) ?? 0
  }

  private func boolValue(_ value: Any?) -> Bool {
    if let number = value as? NSNumber {
      return number.boolValue
    }
    if let bool = value as? Bool {
      return bool
    }
    return false
  }

  private func optionalDoubleValue(_ value: Any?) -> Double? {
    if let number = value as? NSNumber {
      return number.doubleValue
    }
    if let double = value as? Double {
      return double
    }
    if let float = value as? Float {
      return Double(float)
    }
    if let int = value as? Int {
      return Double(int)
    }
    if let string = value as? String {
      return Double(string)
    }
    return nil
  }
}
