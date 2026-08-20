/*
 * Copyright (c) 2026 European Commission
 *
 * Licensed under the EUPL, Version 1.2 or - as soon they will be approved by the European
 * Commission - subsequent versions of the EUPL (the "Licence"); You may not use this work
 * except in compliance with the Licence.
 *
 * You may obtain a copy of the Licence at:
 * https://joinup.ec.europa.eu/software/page/eupl
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the Licence is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the Licence for the specific language
 * governing permissions and limitations under the Licence.
 */
import Foundation
import EudiWalletKit
import MdocDataModel18013
import struct OpenID4VP.ClaimPath

public extension Array where Element == DocElements {

  func overaskedClaims(policy: WrpRegistrationPolicy?) -> [String: Set<[String]>] {

    guard let policy else { return [:] }

    return self.reduce(into: [String: Set<[String]>]()) { result, element in

      let docType: String
      let claims: [DocClaim]

      switch element {
      case .msoMdoc(let doc):
        docType = doc.docType
        claims = doc.nameSpacedElements.flatMap(\.elements).compactMap(\.docClaim)
      case .sdJwt(let doc):
        docType = doc.vct
        claims = doc.sdJwtElements.compactMap(\.docClaim)
      }

      let overasked = policy.overaskedPaths(
        docType: docType,
        requestedPaths: claims.flatMap { $0.leafPaths() }
      )

      if !overasked.isEmpty { result[element.docId] = overasked }
    }
  }
}

public extension Dictionary where Key == String, Value == Set<[String]> {
  func toRequestedClaims() -> [RequestedClaim] {
    self.flatMap { docId, paths in
      paths.map { RequestedClaim(queryId: docId, path: $0) }
    }
  }
}

private extension DocClaim {
  func leafPaths() -> [[String]] {
    guard let children, !children.isEmpty else { return [path] }
    return children.flatMap { $0.leafPaths() }
  }
}

public extension WrpRegistrationPolicy {

  func overaskedPaths(docType: String, requestedPaths: [[String]]) -> Set<[String]> {

    let policyCredential = credentials?.first { credential in
      if let doctypeValue = credential.meta.doctypeValue { return doctypeValue == docType }
      if let vctValues = credential.meta.vctValues { return vctValues.contains(docType) }
      return false
    }

    guard let policyCredential else { return Set(requestedPaths) }

    let policyPaths = (policyCredential.claims ?? []).map(\.path)

    return Set(
      requestedPaths.filter { requestedPath in
        let claimPath = ClaimPath(requestedPath.map { .claim(name: $0) })
        return !policyPaths.contains { $0.contains2(claimPath) }
      }
    )
  }
}
