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
    guard let obj = try matchObject() else {
      throw parseError()
    }
    return obj
  }

  func matchObject() throws -> JSSObject? {
    guard let _ = try lexer.peekToken() as? JSSLCurly else {
      return nil
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

      guard let value = try lexer.nextToken() as? JSSValue else {
        throw parseError()
      }

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

  func matchArray() throws -> JSSArray? {
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
