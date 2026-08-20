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
import XCTest
import EudiWalletKit
import struct OpenID4VP.ClaimPath
@testable import logic_core
@testable import logic_test

final class TestWrpRegistrationPolicyOverasking: EudiTest {

  private let pidDocType = "eu.europa.ec.eudi.pid.1"
  private let nameSpace = "eu.europa.ec.eudi.pid.1"

  func testOveraskedPaths_whenEveryClaimIsRegistered_thenNothingIsOverasked() {
    let policy = policy(
      matching: .doctype(pidDocType),
      registeredPaths: [[nameSpace, "family_name"], [nameSpace, "given_name"]]
    )

    let overasked = policy.overaskedPaths(
      docType: pidDocType,
      requestedPaths: [[nameSpace, "family_name"], [nameSpace, "given_name"]]
    )

    XCTAssertTrue(overasked.isEmpty)
  }

  func testOveraskedPaths_whenSomeClaimsAreNotRegistered_thenOnlyThoseAreReturned() {
    let policy = policy(
      matching: .doctype(pidDocType),
      registeredPaths: [[nameSpace, "family_name"]]
    )

    let overasked = policy.overaskedPaths(
      docType: pidDocType,
      requestedPaths: [[nameSpace, "family_name"], [nameSpace, "age_over_18"]]
    )

    XCTAssertEqual(overasked, [[nameSpace, "age_over_18"]])
  }

  func testOveraskedPaths_whenDocumentIsAbsentFromThePolicy_thenEveryClaimIsOverasked() {
    let policy = policy(
      matching: .doctype("org.iso.18013.5.1.mDL"),
      registeredPaths: [["org.iso.18013.5.1", "family_name"]]
    )

    let requested = [[nameSpace, "family_name"], [nameSpace, "given_name"]]
    let overasked = policy.overaskedPaths(docType: pidDocType, requestedPaths: requested)

    XCTAssertEqual(overasked, Set(requested))
  }

  func testOveraskedPaths_whenCredentialDeclaresNoClaims_thenEveryClaimIsOverasked() {
    let policy = WrpRegistrationPolicy(
      sub: "rp:test",
      credentials: [
        PolicyCredential(
          format: "mso_mdoc",
          meta: PolicyCredentialMeta(doctypeValue: pidDocType),
          claim: nil
        )
      ]
    )

    let requested = [[nameSpace, "family_name"]]
    let overasked = policy.overaskedPaths(docType: pidDocType, requestedPaths: requested)

    XCTAssertEqual(overasked, Set(requested))
  }

  func testOveraskedPaths_whenPolicyHasNoCredentials_thenEveryClaimIsOverasked() {
    let policy = WrpRegistrationPolicy(sub: "rp:test", credentials: [])

    let requested = [[nameSpace, "family_name"]]
    let overasked = policy.overaskedPaths(docType: pidDocType, requestedPaths: requested)

    XCTAssertEqual(overasked, Set(requested))
  }

  func testOveraskedPaths_whenCredentialIsMatchedByVct_thenTheClaimListApplies() {
    let vct = "urn:eu.europa.ec.eudi:pid:1"
    let policy = policy(matching: .vct([vct]), registeredPaths: [["family_name"]])

    let overasked = policy.overaskedPaths(
      docType: vct,
      requestedPaths: [["family_name"], ["birth_date"]]
    )

    XCTAssertEqual(overasked, [["birth_date"]])
  }

  func testOveraskedPaths_whenPolicyRegistersAShorterPath_thenNestedClaimsAreCovered() {
    let policy = policy(matching: .doctype(pidDocType), registeredPaths: [[nameSpace]])

    let overasked = policy.overaskedPaths(
      docType: pidDocType,
      requestedPaths: [[nameSpace, "family_name"], [nameSpace, "age_over_18"]]
    )

    XCTAssertTrue(overasked.isEmpty)
  }

  func testToRequestedClaims_whenPathsAreKeyedByDocument_thenEachPathKeepsItsDocumentId() {
    let overasked: [String: Set<[String]>] = [
      "doc-1": [["ns", "family_name"]],
      "doc-2": [["ns", "given_name"]]
    ]

    let claims = overasked.toRequestedClaims()

    XCTAssertEqual(claims.count, 2)
    XCTAssertTrue(claims.contains(RequestedClaim(queryId: "doc-1", path: ["ns", "family_name"])))
    XCTAssertTrue(claims.contains(RequestedClaim(queryId: "doc-2", path: ["ns", "given_name"])))
  }

  func testToRequestedClaims_whenThereIsNothingOverasked_thenNoClaimsAreProduced() {
    XCTAssertTrue([String: Set<[String]>]().toRequestedClaims().isEmpty)
  }
}

private extension TestWrpRegistrationPolicyOverasking {

  enum CredentialMatch {
    case doctype(String)
    case vct([String])
  }

  func policy(matching match: CredentialMatch, registeredPaths: [[String]]) -> WrpRegistrationPolicy {
    let meta = switch match {
    case .doctype(let value): PolicyCredentialMeta(doctypeValue: value)
    case .vct(let values): PolicyCredentialMeta(vctValues: values)
    }

    return WrpRegistrationPolicy(
      sub: "rp:test",
      credentials: [
        PolicyCredential(
          format: "mso_mdoc",
          meta: meta,
          claim: registeredPaths.map { path in
            PolicyClaim(path: ClaimPath(path.map { .claim(name: $0) }))
          }
        )
      ]
    )
  }
}
