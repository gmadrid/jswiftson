//
//  JSSParser.swift
//  jswiftson
//
//  Created by George Madrid on 4/22/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

class JSSParser {
  let lexer: JSSLexer

  init(_ input: String) {
    lexer = JSSLexer(input: input)
  }

  private func parseError() -> NSError {
    return NSError(domain: "jswiftson", code: 10, userInfo: nil)
  }

  func parse() throws -> JSSObject {
    let obj = try matchObject()
    return obj
  }

  func matchObject() throws -> JSSObject {
    guard let _ = try lexer.peekToken() as? JSSLCurly else {
      throw parseError()
    }
    try lexer.nextToken()

    var pairs = [JSSPair]()
    while true {
      // string ':' value [',']
      let key = try lexer.nextToken()
      guard let strKey = key as? JSSString else {
        throw parseError()
      }

      guard let _ = try lexer.nextToken() as? JSSColon else {
        throw parseError()
      }

      let value = try parseValue()

      pairs.append(JSSPair(str: strKey, val: value))

      guard let _ = try lexer.peekToken() as? JSSComma else {
        break
      }
      try lexer.nextToken()
    }


    guard let _ = try lexer.nextToken() as? JSSRCurly else {
      throw parseError()
    }

    return JSSObject(pairs)
  }

  // If the passed token is type T, then consume and return it.
  func checkAndReturn<T>(token: JSSToken) throws -> T? {
    guard let result = token as? T else {
      return nil
    }
    try lexer.nextToken()
    return result
  }

  func parseValue() throws -> JSSValue {
    let peek = try lexer.peekToken();

    // Check the simple tokens.
    if let str: JSSString = try checkAndReturn(peek) { return str }
    if let num: JSSNumber = try checkAndReturn(peek) { return num }
    if let tru: JSSNumber = try checkAndReturn(peek) { return tru }
    if let fals: JSSNumber = try checkAndReturn(peek) { return fals }
    if let nll: JSSNumber = try checkAndReturn(peek) { return nll }

    // Check for subarray
    if let _ = peek as? JSSLBrack {
      return try matchArray()
    }

    if let _ = peek as? JSSLCurly {
      return try matchObject()
    }

    throw parseError()
  }

  func matchArray() throws -> JSSArray {
    guard let _ = try lexer.peekToken() as? JSSLBrack else {
      throw parseError()
    }
    try lexer.nextToken()

    var values = [JSSValue]()
    while true {
      // value [',']
      guard let val = try lexer.nextToken() as? JSSValue else {
        throw parseError()
      }

      values.append(val)

      guard let _ = try lexer.peekToken() as? JSSComma else {
        break
      }
      try lexer.nextToken()
    }

    guard let _ = try lexer.nextToken() as? JSSRBrack else {
      throw parseError()
    }

    return JSSArray(values)
  }

}
