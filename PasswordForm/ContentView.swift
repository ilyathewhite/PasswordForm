//
//  ContentView.swift
//  PasswordForm
//
//  Created by Ilya Belenkiy on 11/11/19.
//  Copyright © 2019 Ilya Belenkiy. All rights reserved.
//

import SwiftUI

enum SignUp {
    typealias Store = StateStore<State, MutatingAction, Never>
    typealias Reducer = Store.Reducer

    enum MutatingAction {
        case updateUsername(String)
        case updatePassword(String)
        case updatePasswordAgain(String)
        case updateUsernameMessage
        case updatePasswordMessage
        case showSignUpUI
        case hideSignUpUI
    }

    struct State {
        var username = ""
        var usernameMessage = ""
        var password = ""
        var passwordMessage = ""
        var passwordAgain = ""
        var canSignUp = false
        var userNameValidationState: UsernameValidationState
        var passwordValidationState: PasswordValidationState
        var showSignUpUI = false

        init() {
            userNameValidationState = SignUp.validateUsername(username)
            passwordValidationState = SignUp.validatePassword(password, passwordAgain)
        }
    }

    enum UsernameValidationState {
        case valid
        case tooShort

        var message: String {
            switch self {
            case .valid: return ""
            case .tooShort: return "Username must at least have 3 characters"
            }
        }
    }

    enum PasswordValidationState {
        case passwordEmpty
        case differentPasswords
        case tooShort
        case valid

        var maessage: String {
            switch self {
            case .passwordEmpty: return "Password must not be empty"
            case .differentPasswords: return "Passwords don't match"
            case .tooShort: return "Password not strong enough"
            case .valid: return ""
            }
        }
    }

    static let usernameLabel = "Username"
    static let passwordLabel = "Password"
    static let passwordAgainLabel = "Password again"
    static let signUpLabel = "Sign Up"
    static let welcomeLabel = "Welcome! Great to have you on board!"
}

extension SignUp {
    static func store() -> SignUp.Store {
        let store = Store(State(), reducer: reducer)
        store.addEffect(pausedTyping(store, keyPath: \.username, action: .updateUsernameMessage))
        store.addEffect(pausedTyping(store, keyPath: \.password, action: .updatePasswordMessage))
        store.addEffect(pausedTyping(store, keyPath: \.passwordAgain, action: .updatePasswordMessage))
        return store
    }

    static let reducer = Reducer { state, action in
        defer {
            state.canSignUp =
                state.userNameValidationState == .valid &&
                state.passwordValidationState == .valid
        }

        switch action {
        case .updateUsername(let username):
            state.username = username
            state.userNameValidationState = validateUsername(state.username)
            state.usernameMessage = ""

        case .updatePassword(let password):
            state.password = password
            state.passwordValidationState = validatePassword(state.password, state.passwordAgain)
            state.passwordMessage = ""

        case .updatePasswordAgain(let passwordAgain):
            state.passwordAgain = passwordAgain
            state.passwordValidationState = validatePassword(state.password, state.passwordAgain)
            state.passwordMessage = ""

        case .updateUsernameMessage:
            state.usernameMessage = state.userNameValidationState.message

        case .updatePasswordMessage:
            if (state.passwordValidationState == .differentPasswords) && state.passwordAgain.isEmpty {
                state.passwordMessage = ""
            }
            else {
                state.passwordMessage = state.passwordValidationState.maessage
            }

        case .showSignUpUI:
            state.showSignUpUI = true

        case .hideSignUpUI:
            state.showSignUpUI = false
        }

        return nil
    }

    static func pausedTyping(_ store: Store, keyPath: KeyPath<State, String>, action: MutatingAction) -> Reducer.Effect {
        store
            .updates(on: keyPath)
            .debounce(for: 0.8, scheduler: RunLoop.main)
            .map { _ in
                .mutating(action)
            }
            .eraseToAnyPublisher()
    }

    static func validateUsername(_ username: String) -> UsernameValidationState {
        username.count >= 3 ? .valid : .tooShort
    }

    static func validatePassword(_ password: String, _ passwordAgain: String) -> PasswordValidationState {
        if password.isEmpty {
            return .passwordEmpty
        }
        else if password.count < 5 {
            return .tooShort
        }
        else if password != passwordAgain {
            return .differentPasswords
        }
        else {
            return .valid
        }
    }
}

func errorText(_ content: String) -> Text {
    Text(content).foregroundColor(.red)
}

struct SignUpView: View {
    @ObservedObject var store = SignUp.store()

    var body: some View {
        Form {
            Section(footer: errorText(store.state.usernameMessage)) {
                TextField(
                    SignUp.usernameLabel,
                    text: store.binding(\.username, { .updateUsername($0) })
                )
                .autocapitalization(.none)
            }
            Section(footer: errorText(store.state.passwordMessage)) {
                SecureField(
                    SignUp.passwordLabel,
                    text: store.binding(\.password, { .updatePassword($0) })
                )
                SecureField(
                    SignUp.passwordAgainLabel,
                    text: store.binding(\.passwordAgain, { .updatePasswordAgain($0) })
                )
            }
            Section {
                Button(
                    SignUp.signUpLabel,
                    action: { self.store.send(.mutating(.showSignUpUI)) }
                )
                .disabled(!store.state.canSignUp)
            }
        }
        .sheet(
            isPresented: .constant(store.state.showSignUpUI),
            onDismiss: { self.store.send(.mutating(.hideSignUpUI)) },
            content: {
                WelcomeView()
            }
        )
    }
}

struct WelcomeView: View {
    var body: some View {
        Text(SignUp.welcomeLabel)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
