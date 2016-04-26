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

  func testDeeperParse() {
    let json = "{ \"foo\": 3, \"bar\": \"quux\", \"frob\": { \"baz\": 3.1415927, \"foo\": \"\" } }"
    let parser = JSSParser(json)
    XCTAssertNotNil(try parser.parse())
  }

  func testArrayParse() {
    let json = "{ \"foo\": [ true, false, null ] }"
    let parser = JSSParser(json)
    XCTAssertNotNil(try parser.parse())
  }

  func testArrayOfObjects() {
    let json = "{ \"foo\": [ {\"a\":1 }, {\"b\":2}, {\"c\":\"C\"} ] }"
    let parser = JSSParser(json)
    XCTAssertNotNil(try parser.parse())
  }

  func testEmptyArray() {
    let json = "{ \"array\": [], \"bam\": 3 }"
    let parser = JSSParser(json)
    XCTAssertNotNil(try parser.parse())
  }

}
