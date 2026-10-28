import DeviceCheck
import Flutter
import Foundation

final class AppAttestBridge {
  private let service = DCAppAttestService.shared

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "isSupported" { result(service.isSupported); return }
    guard ["generateKey", "attestKey", "generateAssertion"].contains(call.method) else {
      result(FlutterMethodNotImplemented); return
    }
    guard service.isSupported else {
      result(FlutterError(code: "unavailable", message: "App Attest unavailable", details: nil)); return
    }
    if call.method == "generateKey" {
      service.generateKey { keyID, error in
        DispatchQueue.main.async {
          if error != nil || keyID == nil {
            result(FlutterError(code: "attest_failed", message: "Key generation failed", details: nil))
          } else { result(keyID) }
        }
      }
      return
    }
    guard let args = call.arguments as? [String: Any], let keyID = args["keyId"] as? String,
      !keyID.isEmpty, let encodedHash = args["clientDataHash"] as? String,
      let hash = Self.decodeHash(encodedHash), hash.count == 32 else {
      result(FlutterError(code: "invalid_request", message: "Invalid attestation request", details: nil)); return
    }
    let completion: (Data?, Error?) -> Void = { data, error in
      DispatchQueue.main.async {
        if let error = error {
          let code = (error as? DCError)?.code == .invalidKey ? "invalid_key" : "attest_failed"
          result(FlutterError(code: code, message: "App Attest operation failed", details: nil))
        } else if let data = data { result(data.base64EncodedString()) }
        else { result(FlutterError(code: "attest_failed", message: "Empty App Attest response", details: nil)) }
      }
    }
    if call.method == "attestKey" {
      service.attestKey(keyID, clientDataHash: hash, completionHandler: completion)
    } else { service.generateAssertion(keyID, clientDataHash: hash, completionHandler: completion) }
  }

  private static func decodeHash(_ value: String) -> Data? {
    var base64 = value.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
    return Data(base64Encoded: base64)
  }
}
