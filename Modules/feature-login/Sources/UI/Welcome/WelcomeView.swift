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
import logic_ui
import logic_resources

struct WelcomeView<Router: RouterHost>: View {

  @ObservedObject private var viewModel: WelcomeViewModel<Router>

  public init(with viewModel: WelcomeViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    ContentScreenView(
      padding: .zero
    ) {
      content(
        viewState: viewModel.viewState,
        onClickLogin: viewModel.onClickLogin,
        onClickFAQ: viewModel.onClickFAQ
      )
      .onAppear {
        withAnimation(
          .easeOut(duration: 0.66)
          .delay(0.4)
        ) {
          viewModel.onAnimationCompletion()
        }
      }
    }
  }
}

@MainActor
@ViewBuilder
private func content(
  viewState: WelcomeState,
  onClickLogin: @escaping () -> Void,
  onClickFAQ: @escaping () -> Void
) -> some View {
  VStack {
    ZStack {
      Rectangle()
        .fill(Theme.shared.color.backgroundPaper)
        .ignoresSafeArea()

      SplashBackgroundView(
        isAnimating: true
      )
      .ignoresSafeArea()
      .roundedCorner(Theme.shared.shape.medium, corners: [.bottomLeft, .bottomRight])

    }
    if !viewState.isAnimating {
      VStack(spacing: SPACING_MEDIUM) {
        WrapButtonView(
          style: .primary,
          title: .loginButton,
          onAction: onClickLogin()
        )
        .accesibilityLocator(WelcomeLocators.loginButton)

        WrapButtonView(
          style: .secondary,
          title: .readFaqButton,
          onAction: onClickFAQ()
        )
        .accesibilityLocator(WelcomeLocators.readFaqButton)
      }
      .padding(.vertical, Theme.shared.shape.extraLarge)
      .padding(viewState.isAnimating ? 0 : Theme.shared.dimension.padding)
      .transition(.move(edge: .bottom))
    }
  }
  .background(Theme.shared.color.backgroundPaper)
}

#Preview {
  let viewState = WelcomeState(
    isAnimating: false
  )

  ContentScreenView(
    padding: .zero
  ) {
    content(
      viewState: viewState,
      onClickLogin: {},
      onClickFAQ: {}
    )
  }
}

#Preview("isAnimating") {
  let viewState = WelcomeState(
    isAnimating: true
  )

  ContentScreenView(
    padding: .zero
  ) {
    content(
      viewState: viewState,
      onClickLogin: {},
      onClickFAQ: {}
    )
  }
}
