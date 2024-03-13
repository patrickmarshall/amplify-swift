//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct ConfigurationHelper {

    static func parseUserPoolData(_ config: JSONValue) throws -> UserPoolConfigurationData? {
        // TODO: Use JSON serialization here to convert.
        guard let cognitoUserPoolJSON = config.value(at: "CognitoUserPool.Default") else {
            Amplify.Logging.info("Could not find Cognito User Pool configuration")
            return nil
        }
        guard case .string(let poolId)  = cognitoUserPoolJSON.value(at: "PoolId"),
              case .string(let appClientId) = cognitoUserPoolJSON.value(at: "AppClientId"),
              case .string(let region) = cognitoUserPoolJSON.value(at: "Region")
        else {
            return nil
        }

        // parse `pinpointId`
        var pinpointId: String?
        if case .string(let pinpointIdFromConfig) = cognitoUserPoolJSON.value(at: "PinpointAppId") {
            pinpointId = pinpointIdFromConfig
        }

        // If there's a value for the key `Endpoint` let's validate
        // that input here. This allows us to validate once instead
        // of repeatedly whenever `AWSCongnitoAuthPlugin().makeUserPool()`
        // is called. It also allows us to throw an appropriate error
        // at configuration time to reduce the "distance" between invalid
        // input and error handling.
        let endpoint: UserPoolConfigurationData.CustomEndpoint? = try {
            if case .string(let endpoint) = cognitoUserPoolJSON.value(at: "Endpoint") {
                return try .init(
                    endpoint: endpoint,
                    validator: EndpointResolving.userPool.run
                )
            }
            return nil
        }()

        // parse `authFlowType`
        var authFlowType: AuthFlowType
        if case .boolean(let isMigrationEnabled) = cognitoUserPoolJSON.value(at: "MigrationEnabled"),
           isMigrationEnabled == true {
            authFlowType = .userPassword
        } else if let authJson = config.value(at: "Auth.Default"),
                  case .string(let authFlowTypeJSON) = authJson.value(at: "authenticationFlowType"),
                  authFlowTypeJSON == "CUSTOM_AUTH" {
            authFlowType = .customWithSRP
        } else {
            authFlowType = .userSRP
        }

        // parse `clientSecret`
        var clientSecret: String?
        if case .string(let clientSecretFromConfig) = cognitoUserPoolJSON.value(at: "AppClientSecret") {
            clientSecret = clientSecretFromConfig
        }

        // parse `hostedUIConfig`
        let hostedUIConfig = parseHostedConfiguration(
            configuration: config.value(at: "Auth.Default.OAuth"))

        // parse `passwordProtectionSettings`
        let cognitoConfiguration = config.value(at: "Auth.Default")
        var passwordProtectionSettings: PasswordProtectionSettings?
        if case .object(let passwordSettings) = cognitoConfiguration?.value(at: "passwordProtectionSettings") {

            // parse `minLength`
            var minLength: Int?
            if case .number(let value) = passwordSettings["passwordPolicyMinLength"] {
                minLength = Int(value)
            } else if case .string(let value) = passwordSettings["passwordPolicyMinLength"],
                      let intValue = Int(value) {
                minLength = intValue
            }

            // parse `characterPolicy`
            var characterPolicy: [PasswordCharacterPolicy] = []
            if case .array(let characters) = passwordSettings["passwordPolicyCharacters"] {
                characterPolicy = characters.compactMap { value in
                    guard case .string(let string) = value else {
                        return nil
                    }

                    return .init(rawValue: string)
                }
            }

            passwordProtectionSettings =  PasswordProtectionSettings(
                minLength: minLength,
                characterPolicy: characterPolicy
            )
        }

        // parse `usernameAttributes`
        var usernameAttributes: [UsernameAttribute] = []
        if case .array(let attributes) = cognitoConfiguration?["usernameAttributes"] {
            usernameAttributes = attributes.compactMap { value in
                guard case .string(let string) = value else {
                    return nil
                }

                return .init(rawValue: string)
            }
        }

        // parse `signUpAttributes`
        var signUpAttributes: [SignUpAttributeType] = []
        if case .array(let attributes) = cognitoConfiguration?["signupAttributes"] {
            signUpAttributes = attributes.compactMap { value in
                guard case .string(let string) = value else {
                    return nil
                }

                return .init(rawValue: string)
            }
        }

        // parse `verificationMechanisms`
        var verificationMechanisms: [VerificationMechanism] = []
        if case .array(let attributes) = cognitoConfiguration?["verificationMechanisms"] {
            verificationMechanisms = attributes.compactMap { value in
                guard case .string(let string) = value else {
                    return nil
                }

                return .init(rawValue: string)
            }
        }

        return UserPoolConfigurationData(poolId: poolId,
                                         clientId: appClientId,
                                         region: region,
                                         endpoint: endpoint,
                                         clientSecret: clientSecret,
                                         pinpointAppId: pinpointId,
                                         authFlowType: authFlowType,
                                         hostedUIConfig: hostedUIConfig,
                                         passwordProtectionSettings: passwordProtectionSettings,
                                         usernameAttributes: usernameAttributes,
                                         signUpAttributes: signUpAttributes,
                                         verificationMechanisms: verificationMechanisms)

    }

    static func parseHostedConfiguration(configuration: JSONValue?) -> HostedUIConfigurationData? {

        guard case .string(let domain)  = configuration?.value(at: "WebDomain"),
              case .array(let scopes) = configuration?.value(at: "Scopes"),
              case .string(let appClientId) = configuration?.value(at: "AppClientId"),
              case .string(let signInRedirectURI) = configuration?.value(at: "SignInRedirectURI"),
              case .string(let signOutRedirectURI) = configuration?.value(at: "SignOutRedirectURI")
        else {
            return nil
        }
        let scopesArray = scopes.map { value -> String in
            if case .string(let scope) = value {
                return scope
            }
            return ""
        }
        let oauth = OAuthConfigurationData(domain: domain,
                                           scopes: scopesArray,
                                           signInRedirectURI: signInRedirectURI,
                                           signOutRedirectURI: signOutRedirectURI)
        var clientSecret: String?
        if case .string(let appClientSecret) = configuration?.value(at: "AppClientSecret") {
            clientSecret = appClientSecret
        }
        return HostedUIConfigurationData(clientId: appClientId, oauth: oauth, clientSecret: clientSecret)
    }

    static func parseIdentityPoolData(_ config: JSONValue) -> IdentityPoolConfigurationData? {

        guard let cognitoIdentityPoolJSON = config.value(at: "CredentialsProvider.CognitoIdentity.Default") else {
            Amplify.Logging.info("Could not find Cognito Identity Pool configuration")
            return nil
        }
        guard case .string(let poolId) = cognitoIdentityPoolJSON.value(at: "PoolId"),
              case .string(let region) = cognitoIdentityPoolJSON.value(at: "Region")
        else {
            return nil
        }
        return IdentityPoolConfigurationData(poolId: poolId, region: region)
    }

    static func authConfiguration(_ config: JSONValue) throws -> AuthConfiguration {
        let userPoolConfig = try parseUserPoolData(config)
        let identityPoolConfig = parseIdentityPoolData(config)

        if let userPoolConfigNonNil = userPoolConfig, let identityPoolConfigNonNil = identityPoolConfig {
            return .userPoolsAndIdentityPools(userPoolConfigNonNil, identityPoolConfigNonNil)
        }
        if  let userPoolConfigNonNil = userPoolConfig {
            return .userPools(userPoolConfigNonNil)
        }
        if  let identityPoolConfigNonNil = identityPoolConfig {
            return .identityPools(identityPoolConfigNonNil)
        }
        // Could not get either Userpool or Identitypool configuration
        // Throw an error to stop the configure flow.
        throw AuthError.configuration(
            "Error configuring \(String(describing: self))",
            AuthPluginErrorConstants.configurationMissingError
        )
    }
}
