//
//  JSSLexer.swift
//  jswiftson
//
//  Created by George Madrid on 4/21/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

class JSSLexer {
  // The input string as characters. These will be consumed as they are matched.
  var input: String.CharacterView
  var peekedToken: JSSToken?

  init(input: String) {
    self.input = input.characters
  }

  func peekToken() throws -> JSSToken {
    if peekedToken == nil {
      peekedToken = try nextToken()
    }
    return peekedToken!
  }

  func nextToken() throws -> JSSToken {
    var result = peekedToken
    if result != nil {
      peekedToken = nil
      return result!
    }

    result = skipWhite()
    if result != nil { return result! }

    result = matchEOS()
    if result != nil { return result! }

    result = matchSymbol()
    if result != nil { return result! }

    result = matchTrue()
    if result != nil { return result! }

    result = matchFalse()
    if result != nil { return result! }

    result = matchNull()
    if result != nil { return result! }

    result = try matchString()
    if result != nil { return result! }

    result = try matchNumber()
    if result != nil { return result! }

    // Improve this error reporting.
    throw NSError(domain: "jswiftson", code: 1, userInfo: nil)
  }

  func skipWhite() -> JSSToken? {
    // This function always returns nil, but returns JSSToken so that it can be chained with matchers.
    let firstNonWhiteIndex_ = input.indexOf { foo in
      return !" \t\n\r".characters.contains(foo)
    }
    guard let firstNonWhiteIndex = firstNonWhiteIndex_ else {
      // If we find no non-ws chars, then there is nothing left.
      input = JSSLexer.emptyChars
      return nil
    }
    if firstNonWhiteIndex != input.startIndex {
      input = input.suffixFrom(firstNonWhiteIndex)
    }
    return nil
  }

  func matchSymbol() -> JSSToken? {
    guard let ch = input.first else {
      return nil
    }
    let result: JSSToken
    switch ch {
    case "{":
      result = JSSLCurly()
    case "}":
      result = JSSRCurly()
    case "[":
      result = JSSLBrack()
    case "]":
      result = JSSRBrack()
    case ":":
      result = JSSColon()
    case ",":
      result = JSSComma()
    default:
      return nil
    }
    chopFront(1)
    return result
  }

  func matchEOS() -> JSSToken? {
    if input.isEmpty { return JSSEOS() }
    return nil
  }

  private static let emptyChars = "".characters
  private func chopFront(n: Int) {
    input.replaceRange(input.startIndex ..< input.startIndex.advancedBy(n), with: JSSLexer.emptyChars)
  }

  private static let trueChars: String.CharacterView = "true".characters
  func matchTrue() -> JSSToken? {
    let match = JSSLexer.trueChars
    if input.startsWith(match) {
      chopFront(match.count)
      return JSSTrue()
    }
    return nil
  }

  private static let falseChars: String.CharacterView = "false".characters
  func matchFalse() -> JSSToken? {
    if input.startsWith(JSSLexer.falseChars) {
      chopFront(JSSLexer.falseChars.count)
      return JSSFalse()
    }
    return nil
  }

  private static let nullChars: String.CharacterView = "null".characters
  func matchNull() -> JSSToken? {
    if input.startsWith(JSSLexer.nullChars) {
      chopFront(JSSLexer.nullChars.count)
      return JSSNull()
    }
    return nil
  }

  private static let digitChars: String.CharacterView = "0123456789".characters
  func matchNumber() throws -> JSSToken? {
    guard let first = input.first else {
      return nil
    }

    guard JSSLexer.digitChars.contains(first) || first == "-" else {
      return nil
    }

    var intResult = String.CharacterView()
    intResult.append(first)
    chopFront(1)

    // If the first digit is zero, then there can be no more digits before the frac or exp.
    if first != "0" {
      if let digits = grabDigits() {
        intResult.appendContentsOf(digits)
      }
    }

    var fracResult: String.CharacterView?
    if let fracFirst = input.first {
      if fracFirst == "." {
        fracResult = String.CharacterView()
        fracResult!.append(".")
        chopFront(1)

        guard let fracDigits = grabDigits() else {
          // There must be digits.
          throw NSError(domain: "jswiftson", code: -3, userInfo: nil)
        }
        fracResult!.appendContentsOf(fracDigits)
      }
    }

    var expResult: String.CharacterView?
    if let expFirst = input.first {
      if expFirst == "E" || expFirst == "e" {
        expResult = String.CharacterView()
        expResult!.append(expFirst)
        chopFront(1)

        if let sign = grabSign() {
          expResult!.append(sign)
        }

        guard let expDigits = grabDigits() else {
          // There must be digits.
          throw NSError(domain: "jswiftson", code: -4, userInfo: nil)
        }
        expResult!.appendContentsOf(expDigits)
      }
    }

    return JSSNumber(digits: String(intResult),
                     frac: fracResult == nil ? nil : String(fracResult!),
                     exp: expResult == nil ? nil : String(expResult!))
  }

  func grabSign() -> Character? {
    if let signFirst = input.first {
      if signFirst == "+" || signFirst == "-" {
        chopFront(1)
        return signFirst
      }
    }
    return nil
  }

  func grabDigits() -> String.CharacterView? {
    let firstNonDigitIndex_ = input.indexOf { foo in
      return !JSSLexer.digitChars.contains(foo)
    }
    guard let firstNonDigitIndex = firstNonDigitIndex_ else {
      // No non-digits, so everything is a digit.
      let result = input
      input = JSSLexer.emptyChars
      return result
    }

    if firstNonDigitIndex == input.startIndex {
      // No digits
      return nil
    }

    let result = input.prefixUpTo(firstNonDigitIndex)
    input = input.suffixFrom(firstNonDigitIndex)
    return result
  }

  func matchString() throws -> JSSToken? {
    // String always starts with a quote.
    guard input[input.startIndex] == "\"" else {
      return nil
    }
    chopFront(1)  // Remove the leading quote

    var result = String.CharacterView()

    var awaitingEscapeCharacter = false
    inputloop: for ch in input {
      if !awaitingEscapeCharacter {
        switch ch {
        case "\"": break inputloop  // closing quote. End of the string.

        case "\\":
          awaitingEscapeCharacter = true
          result.append(ch)
          
        default: result.append(ch)
        }
      } else {
        // process escape characters
        awaitingEscapeCharacter = false
        switch ch {
        case "b", "f", "n", "r", "t", "u", "/", "\\", "\"":
          result.append(ch)
        // TODO: add code to test validity of \u#### character.
        default:
          throw NSError(domain: "jswiftson", code: 2, userInfo: nil)
        }
      }
    }

    // And string always ends with a quote.
    guard result.count < input.count && input[input.startIndex.advancedBy(result.count)] == "\"" else {
      // We started a string that we could not finish. This is an error!
      throw NSError(domain: "jswiftson", code: 1, userInfo: nil)
    }
    // Because we are not translating or interpreting the characters in the string, the result
    // will always have the same length as the consumed characters.  Add one for the trailing quote.
    chopFront(1 + result.count)

    return JSSString(String(result))
  }
}
