//
//  JSSLexerTests.swift
//  jswiftson
//
//  Created by George Madrid on 4/21/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import XCTest

class JSSLexerTests: XCTestCase {

  override func setUp() {
    super.setUp()
  }

  override func tearDown() {
    super.tearDown()
  }

  // TODO test peek

  func testEOS() {
    XCTAssert(JSSLexer(input: "").matchEOS()! ~= JSSEOS())
    XCTAssert(JSSLexer(input: " ").matchEOS() == nil)

    XCTAssert(try JSSLexer(input: "").nextToken() ~= JSSEOS())
  }

  func testSkipWhite() {
    let lexer = JSSLexer(input: "    true \n  \t false   ");
    XCTAssert(try lexer.nextToken() ~= JSSTrue())
    XCTAssert(try lexer.nextToken() ~= JSSFalse())
    XCTAssert(try lexer.nextToken() ~= JSSEOS())
  }

  func testTrue() {
    XCTAssert(JSSLexer(input: "true").matchTrue()! ~= JSSTrue())
    XCTAssert(JSSLexer(input: "false").matchTrue() == nil)
    XCTAssert(JSSLexer(input: "").matchTrue() == nil)

    let lexer = JSSLexer(input: "true")
    XCTAssert(try lexer.nextToken() ~= JSSTrue())
    XCTAssert(try lexer.nextToken() ~= JSSEOS())
  }

  func testFalse() {
    XCTAssert(JSSLexer(input: "false").matchFalse()! ~= JSSFalse())
    XCTAssert(JSSLexer(input: "true").matchFalse() == nil)
    XCTAssert(JSSLexer(input: "").matchFalse() == nil)

    let lexer = JSSLexer(input: "false")
    XCTAssert(try lexer.nextToken() ~= JSSFalse())
    XCTAssert(try lexer.nextToken() ~= JSSEOS())
  }

  func testNull() {
    XCTAssert(JSSLexer(input: "null").matchNull()! ~= JSSNull())
    XCTAssert(JSSLexer(input: "true").matchNull() == nil)
    XCTAssert(JSSLexer(input: "").matchNull() == nil)

    let lexer = JSSLexer(input: "null")
    XCTAssert(try lexer.nextToken() ~= JSSNull())
    XCTAssert(try lexer.nextToken() ~= JSSEOS())
  }

  func testSymbols() {
    let lexer = JSSLexer(input: "[]{}:,")
    XCTAssert(try lexer.nextToken() ~= JSSLBrack())
    XCTAssert(try lexer.nextToken() ~= JSSRBrack())
    XCTAssert(try lexer.nextToken() ~= JSSLCurly())
    XCTAssert(try lexer.nextToken() ~= JSSRCurly())
    XCTAssert(try lexer.nextToken() ~= JSSColon())
    XCTAssert(try lexer.nextToken() ~= JSSComma())
    XCTAssert(try lexer.nextToken() ~= JSSEOS())
  }

  func testNumbers() {
    // Some basic numbers
    checkNumber("123", token: JSSNumber(digits: "123", frac: nil, exp: nil))
    checkNumber("0", token: JSSNumber(digits: "0", frac: nil, exp: nil))

    checkNumber("123.1415", token: JSSNumber(digits: "123", frac: ".1415", exp: nil))
    checkNumber("123.0333", token: JSSNumber(digits: "123", frac: ".0333", exp: nil))

    checkNumber("123e45", token: JSSNumber(digits: "123", frac: nil, exp: "e45"))
    checkNumber("123E45", token: JSSNumber(digits: "123", frac: nil, exp: "E45"))
    checkNumber("123e+45", token: JSSNumber(digits: "123", frac: nil, exp: "e+45"))
    checkNumber("123E+45", token: JSSNumber(digits: "123", frac: nil, exp: "E+45"))
    checkNumber("123e-45", token: JSSNumber(digits: "123", frac: nil, exp: "e-45"))
    checkNumber("123E-45", token: JSSNumber(digits: "123", frac: nil, exp: "E-45"))

    checkNumber("123.1415e45", token: JSSNumber(digits: "123", frac: ".1415", exp: "e45"))
    checkNumber("123.0333E+22", token: JSSNumber(digits: "123", frac: ".0333", exp: "E+22"))
    checkNumber("123.0333E-22", token: JSSNumber(digits: "123", frac: ".0333", exp: "E-22"))

    // TODO: need some counter-examples, but I'm lazy right now.
  }

  func checkNumber(str: String, token: JSSToken) {
    let lexer = JSSLexer(input: str)
    let tok = try! lexer.nextToken()
    XCTAssert(tok ~= token)
    XCTAssert(try lexer.nextToken() ~= JSSEOS())
  }

  func testString() {
    // Basic
    XCTAssert(try JSSLexer(input: "\"foobar\"").nextToken() ~= JSSString("foobar"))

    // \Unicode
    XCTAssert(try JSSLexer(input: "\"fooπbar\"").nextToken() ~= JSSString("fooπbar"))

    // \quote
    XCTAssert(try JSSLexer(input: "\"foo\\\"bar\"").nextToken() ~= JSSString("foo\\\"bar"))

    // \backslash
    XCTAssert(try JSSLexer(input: "\"foo\\\\bar\"").nextToken() ~= JSSString("foo\\\\bar"))

    // \slash
    XCTAssert(try JSSLexer(input: "\"foo\\/bar\"").nextToken() ~= JSSString("foo\\/bar"))

    // \backspace
    XCTAssert(try JSSLexer(input: "\"foo\\bbar\"").nextToken() ~= JSSString("foo\\bbar"))

    // \formfeed
    XCTAssert(try JSSLexer(input: "\"foo\\fbar\"").nextToken() ~= JSSString("foo\\fbar"))

    // \newline
    XCTAssert(try JSSLexer(input: "\"foo\\nbar\"").nextToken() ~= JSSString("foo\\nbar"))

    // \carraige return
    XCTAssert(try JSSLexer(input: "\"foo\\rbar\"").nextToken() ~= JSSString("foo\\rbar"))

    // \horizontal tab
    XCTAssert(try JSSLexer(input: "\"foo\\tbar\"").nextToken() ~= JSSString("foo\\tbar"))

    // \4hexdigits
    XCTAssert(try JSSLexer(input: "\"foo\\u1234bar\"").nextToken() ~= JSSString("foo\\u1234bar"))
  }

  func testNotStrings() {
    // naked quote in the middle of the string
    XCTAssert(try JSSLexer(input: "\"foo\"bar\"").nextToken() ~= JSSString("foo"))

    // no starting quote
    XCTAssertThrowsError(try JSSLexer(input: "foobar\"").nextToken())

    // no ending quote
    XCTAssertThrowsError(try JSSLexer(input: "\"foobar").nextToken())

    // backslash with bad follower
    XCTAssertThrowsError(try JSSLexer(input: "\"foo\\abar\"").nextToken())

    // trailing naked backslash
    XCTAssertThrowsError(try JSSLexer(input: "\"foobar\\\"").nextToken())
  }

}
