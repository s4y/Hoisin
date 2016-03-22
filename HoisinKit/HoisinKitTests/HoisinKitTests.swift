//
//  HoisinKitTests.swift
//  HoisinKitTests
//
//  Created by Sidney San Martín on 3/21/16.
//  Copyright © 2016 Coordinated Hackers. All rights reserved.
//

import XCTest
@testable import HoisinKit

class HoisinKitTests: XCTestCase {
    
    func testStartAgent() {
        let agent = HoisinKit.Agent()
        print("AGENT OUTPUT: \(agent.readToCompletion())")
    }
}
