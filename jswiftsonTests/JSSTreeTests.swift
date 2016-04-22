//
//  JSSTreeTests.swift
//  jswiftson
//
//  Created by George Madrid on 4/22/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import XCTest

class JSSTreeTests: XCTestCase {

  func testTokenEquality() {
    // Basically, ensure that tokens compare equal to themselves. Without this, we cannot trust
    // our other unit tests.
    XCTAssert(JSSEOS() ~= JSSEOS())
    XCTAssert(JSSTrue() ~= JSSTrue())
    XCTAssert(JSSFalse() ~= JSSFalse())
    XCTAssert(JSSNull() ~= JSSNull())
    XCTAssert(JSSLBrack() ~= JSSLBrack())
    XCTAssert(JSSRBrack() ~= JSSRBrack())
    XCTAssert(JSSLCurly() ~= JSSLCurly())
    XCTAssert(JSSRCurly() ~= JSSRCurly())
    XCTAssert(JSSComma() ~= JSSComma())
    XCTAssert(JSSColon() ~= JSSColon())

    XCTAssert(JSSNumber(digits: "123", frac: nil, exp: nil) ~= JSSNumber(digits: "123", frac: nil, exp: nil))
    XCTAssert(JSSNumber(digits: "123", frac: ".456", exp: nil) ~= JSSNumber(digits: "123", frac: ".456", exp: nil))
    XCTAssert(JSSNumber(digits: "123", frac: nil, exp: "e789") ~= JSSNumber(digits: "123", frac: nil, exp: "e789"))
    XCTAssert(JSSNumber(digits: "123", frac: ".456", exp: "e789") ~= JSSNumber(digits: "123", frac: ".456", exp: "e789"))

    XCTAssert(JSSString("quux") ~= JSSString("quux"))
  }

  func testTokenInequality() {
    let unequalTokens: [JSSToken] = [
      JSSEOS(),
      JSSTrue(),
      JSSFalse(),
      JSSNull(),
      JSSLBrack(),
      JSSRBrack(),
      JSSLCurly(),
      JSSRCurly(),
      JSSComma(),
      JSSColon(),

      JSSString("quux"),
      JSSString("foo"),

      JSSNumber(digits: "123", frac: nil, exp: nil),
      JSSNumber(digits: "123", frac: ".456", exp: nil),
      JSSNumber(digits: "123", frac: nil, exp: "e789"),
      JSSNumber(digits: "123", frac: ".456", exp: "e789"),
      JSSNumber(digits: "13", frac: nil, exp: nil),
      JSSNumber(digits: "13", frac: ".46", exp: nil),
      JSSNumber(digits: "13", frac: nil, exp: "e79"),
      JSSNumber(digits: "13", frac: ".46", exp: "e79")
    ]

    // Keep a count of comparisons to make sure we don't miss any.
    for i in 0..<unequalTokens.count {
      for j in 0..<unequalTokens.count {
        if i != j {
          XCTAssert(!(unequalTokens[i] ~= unequalTokens[j]))
        } else {
          XCTAssert(unequalTokens[i] ~= unequalTokens[j])
        }
      }
    }
  }

}
