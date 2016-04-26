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

  private func parseError(msg: String) -> NSError {
    return NSError(domain: "jswiftson", code: 10, userInfo: [
      NSLocalizedDescriptionKey: msg,
      "JSSNextInput": lexer.nextInput(40)
      ])
  }

  func parse() throws -> JSSObject {
    let obj = try matchObject()
    return obj
  }

  func matchObject() throws -> JSSObject {
    guard let _ = try lexer.peekToken() as? JSSLCurly else {
      throw parseError("Expected '{' but got \(try lexer.peekToken())")
    }
    try lexer.nextToken()

    var pairs = [JSSPair]()
    while true {
      // string ':' value [',']
      let key = try lexer.nextToken()
      guard let strKey = key as? JSSString else {
        throw parseError("Expecting STRING, but found \(key)")
      }

      guard let _ = try lexer.nextToken() as? JSSColon else {
        throw parseError("Expecting ':', but got \(key)")
      }

      let value = try parseValue()

      pairs.append(JSSPair(str: strKey, val: value))

      guard let _ = try lexer.peekToken() as? JSSComma else {
        break
      }
      try lexer.nextToken()
    }


    let token = try lexer.nextToken()
    guard let _ = token as? JSSRCurly else {
      throw parseError("Expecting '}', but got \(token)")
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

    throw parseError("Expecting value type, but found \(peek)")
  }

  func matchArray() throws -> JSSArray {
    guard let _ = try lexer.peekToken() as? JSSLBrack else {
      throw parseError("Expecting '[', but found \(try lexer.peekToken())")
    }
    try lexer.nextToken()

    var values = [JSSValue]()
    while true {
      // value [',']
      let token = try lexer.peekToken()
      let val: JSSValue
      if let v = token as? JSSValue {
        // The token is an Atomic value, so we can return it directly.
        val = v
        try lexer.nextToken()  // consume the token
      } else if let _ = token as? JSSLBrack {
        // It's the start of an array.
        val = try matchArray()
      } else if let _ = token as? JSSLCurly {
        // It's the start of an object.
        val = try matchObject()
      } else if let _ = token as? JSSRBrack {
        // closing the array, break, but leave consuming the token to after the loop.
        break
      }
      else {
        // Doesn't match any expected token.
        throw parseError("Expecting value in array, but found \(token)")
      }

      values.append(val)

      guard let _ = try lexer.peekToken() as? JSSComma else {
        break
      }
      try lexer.nextToken()
    }

    let rbrack = try lexer.nextToken()
    guard let _ = rbrack as? JSSRBrack else {
      throw parseError("Expected ']', but found \(rbrack)")
    }

    return JSSArray(values)
  }

}
