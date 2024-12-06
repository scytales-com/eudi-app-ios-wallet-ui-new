/*
 * Copyright (c) 2023 European Commission
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
import SwiftUI
import feature_common

struct SignDocumentView<Router: RouterHost>: View {

  @ObservedObject private var viewModel: SignDocumentViewModel<Router>

  public init(with viewModel: SignDocumentViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    ContentScreenView {

      ContentHeaderView(dismissIcon: Theme.shared.image.xmark) {
        viewModel.pop()
      }

      content(viewState: viewModel.viewState) {
        viewModel.onShowFilePicker()
      }
      .fileImporter(
        isPresented: $viewModel.showFilePicker,
        allowedContentTypes: [.pdf],
        onCompletion: { result in
          switch result {
          case .success(let url):
            viewModel.onFileSelection(with: url)
          case .failure:
            break
          }
        }
      )

      Spacer()
    }
  }
}

@MainActor
@ViewBuilder
private func content(
  viewState: SignDocumentState,
  action: @escaping () -> Void
) -> some View {

  VStack(spacing: SPACING_LARGE) {

    ContentTitleView(
      title: .signDocument,
      caption: .signDocumentSubtitle
    )

    AddNewDocumentCellView(
      isEnabled: true,
      title: .selectDocument,
      isLoading: false,
      action: action()
    )
  }
}

#Preview {
  ContentScreenView {
    content(viewState: .init(), action: {})
  }
}