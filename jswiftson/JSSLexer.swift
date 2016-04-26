//
//  JSSLexer.swift
//  jswiftson
//
//  Created by George Madrid on 4/21/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

/** Allows efficient character-by-character input on a String.CharacterView with peeking */
class CharacterInput {
  var input: String.CharacterView
  var currIndex: String.CharacterView.Index

  var first: Character? {
    guard !isEmpty else { return nil }
    return input[currIndex]
  }
  var startIndex: String.CharacterView.Index {
    return currIndex
  }
  var isEmpty: Bool {
    return !(currIndex < input.endIndex)
  }
  var currInputToEnd: String.CharacterView {
    return self.input[self.currIndex..<input.endIndex]
  }

  init(_ input: String) {
    self.input = input.characters
    self.currIndex = self.input.startIndex
  }

  func nextInput(num: Int) -> String {
    let nIndex = currIndex.advancedBy(num)
    let index = min(nIndex, input.endIndex)
    return String(input[currIndex..<index])
  }

  func prefixToIndex(index: String.CharacterView.Index) -> String.CharacterView {
    return input[currIndex..<index]
  }

  func indexOf(@noescape predicate: (ch: Character) -> Bool) -> String.CharacterView.Index? {
    var index = currIndex
    let end = input.endIndex
    while index < end {
      if predicate(ch: input[index]) {
        return index
      }
      index = index.advancedBy(1)
    }
    return nil
  }

  func startsWith(prefix: String.CharacterView) -> Bool {
    return currInputToEnd.startsWith(prefix)
  }

  func eat(n: Int = 1) {
    eatToIndex(currIndex.advancedBy(n))
  }

  func eatToIndex(index: String.CharacterView.Index) {
    self.currIndex = index
  }

  func eatToEnd() {
    eatToIndex(input.endIndex)
  }
}

class JSSLexer {
  // The input string as characters. These will be consumed as they are matched.
//  var inputt: String.CharacterView
  var cInput: CharacterInput
  var peekedToken: JSSToken?

  init(input: String) {
    self.cInput = CharacterInput(input)
  }

  func nextInput(num: Int) -> String {
    return cInput.nextInput(num)
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

    skipWhite()

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

  func skipWhite() {
    // This function always returns nil, but returns JSSToken so that it can be chained with matchers.
    let firstNonWhiteIndex_ = cInput.indexOf { foo in
      return !" \t\n\r".characters.contains(foo)
    }
    guard let firstNonWhiteIndex = firstNonWhiteIndex_ else {
      // If we find no non-ws chars, then there is nothing left.
      cInput.eatToEnd()
      return
    }
    cInput.eatToIndex(firstNonWhiteIndex)
    return
  }

  func matchSymbol() -> JSSToken? {
    guard let ch = cInput.first else {
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
    cInput.eat()
    return result
  }

  func matchEOS() -> JSSToken? {
    if cInput.isEmpty { return JSSEOS() }
    return nil
  }

  private static let trueChars: String.CharacterView = "true".characters
  private static let trueCount = JSSLexer.trueChars.count
  func matchTrue() -> JSSToken? {
    if cInput.startsWith(JSSLexer.trueChars) {
      cInput.eat(JSSLexer.trueCount)
      return JSSTrue()
    }
    return nil
  }

  private static let falseChars: String.CharacterView = "false".characters
  private static let falseCount = JSSLexer.falseChars.count
  func matchFalse() -> JSSToken? {
    if cInput.startsWith(JSSLexer.falseChars) {
      cInput.eat(JSSLexer.falseCount)
      return JSSFalse()
    }
    return nil
  }

  private static let nullChars: String.CharacterView = "null".characters
  private static let nullCount = JSSLexer.nullChars.count
  func matchNull() -> JSSToken? {
    if cInput.startsWith(JSSLexer.nullChars) {
      cInput.eat(JSSLexer.nullCount)
      return JSSNull()
    }
    return nil
  }

  private static let digitChars: String.CharacterView = "0123456789".characters
  func matchNumber() throws -> JSSToken? {
    guard let first = cInput.first else {
      return nil
    }

    guard JSSLexer.digitChars.contains(first) || first == "-" else {
      return nil
    }

    var intResult = String.CharacterView()
    intResult.append(first)
    cInput.eat()

    // If the first digit is zero, then there can be no more digits before the frac or exp.
    if first != "0" {
      if let digits = grabDigits() {
        intResult.appendContentsOf(digits)
      }
    }

    var fracResult: String.CharacterView?
    if let fracFirst = cInput.first {
      if fracFirst == "." {
        fracResult = String.CharacterView()
        fracResult!.append(".")
        cInput.eat()

        guard let fracDigits = grabDigits() else {
          // There must be digits.
          throw NSError(domain: "jswiftson", code: -3, userInfo: nil)
        }
        fracResult!.appendContentsOf(fracDigits)
      }
    }

    var expResult: String.CharacterView?
    if let expFirst = cInput.first {
      if expFirst == "E" || expFirst == "e" {
        expResult = String.CharacterView()
        expResult!.append(expFirst)
        cInput.eat()

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
    if let signFirst = cInput.first {
      if signFirst == "+" || signFirst == "-" {
        cInput.eat()
        return signFirst
      }
    }
    return nil
  }

  func grabDigits() -> String.CharacterView? {
    let firstNonDigitIndex_ = cInput.indexOf { foo in
      return !JSSLexer.digitChars.contains(foo)
    }
    guard let firstNonDigitIndex = firstNonDigitIndex_ else {
      // No non-digits, so everything is a digit.
      let result = cInput.currInputToEnd
      cInput.eatToEnd()
      return result
    }

    if firstNonDigitIndex == cInput.startIndex {
      // No digits
      return nil
    }

    let result = cInput.prefixToIndex(firstNonDigitIndex)
    cInput.eatToIndex(firstNonDigitIndex)
    return result
  }

  /** We match String by looking for valid characters and escape sequences between two (unescaped)
   *  quotes. This code is simpler than a real JSON parser would be since we are not _interpreting_
   *  the escape codes. We are just ingesting them so that we can print them out verbatim.
   */
  func matchString() throws -> JSSToken? {
    // String always starts with a quote.
    guard cInput.first == "\"" else {
      return nil
    }
    cInput.eat()

    var result = String.CharacterView()
    // TODO: don't append to result. Instead create the result from a range of 'input'
    result.reserveCapacity(25)  // long enough for most ids, I guess.

    var awaitingEscapeCharacter = false
    var closeQuoteFound = false
    inputLoop: while let ch = cInput.first {
      cInput.eat()

      if !awaitingEscapeCharacter {
        switch ch {
        case "\"":
          closeQuoteFound = true
          break inputLoop  // closing quote. End of the string.

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
    guard closeQuoteFound else {
      // We started a string that we could not finish. This is an error!
      throw NSError(domain: "jswiftson", code: 1, userInfo: nil)
    }

    return JSSString(String(result))
  }
}
