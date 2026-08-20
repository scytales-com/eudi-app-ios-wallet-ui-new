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
extension DocElements: @retroactive Equatable {
  public static func == (lhs: EudiWalletKit.DocElements, rhs: EudiWalletKit.DocElements) -> Bool {
    lhs.id == rhs.id
  }
}

public extension Array where Element == DocElements {

  func toRequestedClaims() -> [RequestedClaim] {
    flatMap { element -> [RequestedClaim] in
      switch element {
      case .msoMdoc(let mdoc):
        mdoc.nameSpacedElements.flatMap { nameSpace in
          nameSpace.elements.map {
            RequestedClaim(
              queryId: mdoc.docId,
              path: [nameSpace.nameSpace, $0.elementIdentifier]
            )
          }
        }
      case .sdJwt(let sdJwt):
        sdJwt.sdJwtElements.map {
          RequestedClaim(queryId: sdJwt.docId, path: $0.elementPath)
        }
      }
    }
  }
}

public extension Array where Element == [DocElements] {

  func toRequestedClaims() -> [RequestedClaim] {
    var seen: Set<RequestedClaim> = []
    return flatMap { $0.toRequestedClaims() }.filter { seen.insert($0).inserted }
  }
}
