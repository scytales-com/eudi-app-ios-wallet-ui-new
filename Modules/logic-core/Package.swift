// swift-tools-version: 6.0.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "logic-core",
  platforms: [.iOS(.v16)],
  products: [
    .library(
      name: "logic-core",
      targets: ["logic-core"])
  ],
  dependencies: [
	.package(url: "https://github.com/scytales-com/eudi-lib-ios-iso18013-data-model.git", branch: "test_fixed_de"),
	.package(url: "https://github.com/scytales-com/eudi-lib-ios-iso18013-data-transfer.git", branch: "test_fixed_de"),
    .package(
      url: "https://github.com/eu-digital-identity-wallet/eudi-lib-ios-wallet-kit.git",
      exact: "0.10.7"
    ),
    .package(
      name: "logic-resources",
      path: "./logic-resources"
    ),
    .package(
      name: "logic-business",
      path: "./logic-business"
    )
  ],
  targets: [
    .target(
      name: "logic-core",
      dependencies: [
        "logic-resources",
        "logic-business",
		.product(name: "MdocDataModel18013", package: "eudi-lib-ios-iso18013-data-model"),
		.product(name: "MdocDataTransfer18013", package: "eudi-lib-ios-iso18013-data-transfer"),
        .product(
          name: "EudiWalletKit",
          package: "eudi-lib-ios-wallet-kit"
        )
      ],
      path: "./Sources"
    )
  ]
)
