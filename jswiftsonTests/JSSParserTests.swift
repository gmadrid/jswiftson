//
//  JSSParserTests.swift
//  jswiftson
//
//  Created by George Madrid on 4/22/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import XCTest

class JSSParserTests: XCTestCase {

  func testSimpleParse() {
    let json = "{ \"foo\": 3 }"
    let parser = JSSParser(json)
    XCTAssertNotNil(try parser.parse())
  }
}
