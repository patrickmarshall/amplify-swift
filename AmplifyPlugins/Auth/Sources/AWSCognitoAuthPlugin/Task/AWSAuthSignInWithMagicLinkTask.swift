//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

import Foundation
import Amplify
import AWSPluginsCore

class AWSAuthSignInWithMagicLinkTask: AuthSignInWithMagicLinkTask, DefaultLogger {

    let passwordlessFlow: AuthPasswordlessFlow
    let passwordlessSignInHelper: PasswordlessSignInHelper
    let passwordlessSignUpHelper: PasswordlessSignUpHelper

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.signInWithMagicLinkAPI
    }

    init(_ request: AuthSignInWithMagicLinkRequest,
         authStateMachine: AuthStateMachine,
         configuration: AuthConfiguration,
         authEnvironment: AuthEnvironment) {
        passwordlessFlow = request.flow
        
        //sign in helper
        passwordlessSignInHelper = PasswordlessSignInHelper(
            authStateMachine: authStateMachine,
            username: request.username,
            // NOTE: answer is not applicable in this scenario
            // because this event is only responsible for initializing the passwordless OTP workflow
            challengeAnswer: "",
            signInRequestMetadata: .init(
                signInMethod: .magicLink, 
                action: .request,
                deliveryMedium: .email,
                redirectURL: request.redirectURL),
            passwordlessFlow: request.flow,
            pluginOptions: request.options.pluginOptions)
        
        // sign up helper
        passwordlessSignUpHelper = PasswordlessSignUpHelper(
            authStateMachine: authStateMachine,
            configuration: configuration,
            authEnvironment: authEnvironment,
            username: request.username,
            signInRequestMetadata: .init(
                signInMethod: .magicLink,
                action: .request,
                deliveryMedium: .email,
                redirectURL: request.redirectURL),
            pluginOptions: request.options.pluginOptions)
    }

    func execute() async throws -> AuthSignInResult {
        if passwordlessFlow == .signUpAndSignIn {
            log.verbose("Starting Passwordless Sign Up flow")
            try await passwordlessSignUpHelper.signUp()
            log.verbose("Passwordless Sign Up flow success")
        }
        
        return try await passwordlessSignInHelper.signIn()
    }
}
