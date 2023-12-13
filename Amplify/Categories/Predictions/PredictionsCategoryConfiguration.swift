//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct PredictionsCategoryConfiguration: CategoryConfiguration {
    public var plugins: [String: JSONValue]

    /// Initialize `plugins` map
    public init(plugins: [String: JSONValue] = [:]) {
        self.plugins = plugins
    }
}
