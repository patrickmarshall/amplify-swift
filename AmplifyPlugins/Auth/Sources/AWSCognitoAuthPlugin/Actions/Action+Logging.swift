//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Action {

    func logError(_ message: String, environment: Environment) {
        let logger = (environment as? AuthEnvironment)?.logger
        logger?.error("\(message)")
    }

    func logVerbose(_ message: String, environment: Environment) {
        let logger = (environment as? AuthEnvironment)?.logger
        logger?.verbose("\(message)")
    }
}