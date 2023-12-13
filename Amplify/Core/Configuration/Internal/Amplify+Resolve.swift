//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Amplify {

    static func resolve(configuration: AmplifyConfiguration? = nil) throws -> AmplifyConfiguration {
        return try AmplifyConfiguration(bundle: Bundle.main, withOverride: configuration)
    }

}
