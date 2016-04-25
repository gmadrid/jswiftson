//
//  JSSTree.swift
//  jswiftson
//
//  Created by George Madrid on 4/22/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

// MARK: - JSSToken

/** A JSSToken is any non-decomposible parsing unit defined by the JSON spec.
 *  Basically, anything that can come out of the lexer and be matched by a regex.
 */
protocol JSSToken {
  // This is mostly here to allow the creation of the ~= operator for testing.
  func tokenEquals(rhs: JSSToken) -> Bool
}

extension JSSToken where Self: Equatable {
  func tokenEquals(rhs: JSSToken) -> Bool {
    if let other = rhs as? Self { return self == other }
    return false
  }
}

/** Use ~= to test the equality of two arbitrary JSSToken objects.
 *  I think this is probably primarily useful for unit tests.
 */
func ~=(lhs: JSSToken, rhs: JSSToken) -> Bool {
  return lhs.tokenEquals(rhs)
}

// MARK: - JSSValue

/** A JSSValue is anything that can either be named in an object or contained in an array.
 *  It corresponds directly with 'value' in the JSON spec.
 */
protocol JSSValue {}

// MARK: -

class JSSObject : JSSValue {
  let pairs: [ JSSPair ]

  init(_ pairs: [ JSSPair ]) {
    self.pairs = pairs
  }
}

class JSSPair : JSSValue {
  let str: JSSString
  let val: JSSValue

  init(str: JSSString, val: JSSValue) {
    self.str = str
    self.val = val
  }
}

class JSSArray : JSSValue {
  var values: [ JSSValue ]

  init(_ values: [ JSSValue ]) {
    self.values = values
  }
}

class JSSString : JSSToken, JSSValue, Equatable {
  let str: String

  init(_ str: String) {
    self.str = str
  }
}
func ==(lhs: JSSString, rhs: JSSString) -> Bool {
  return lhs.str == rhs.str
}

class JSSNumber : JSSToken, JSSValue, Equatable {
  let digits: String
  let frac: String?
  let exp: String?

  init(digits: String, frac: String?, exp: String?) {
    self.digits = digits
    self.frac = frac
    self.exp = exp
  }
}
func ==(lhs: JSSNumber, rhs: JSSNumber) -> Bool {
  return lhs.digits == rhs.digits
    && lhs.frac == rhs.frac
    && lhs.exp == rhs.exp
}

// MARK: - Atomic 

/** Atomic tokens have no contents which can differ. E.g., one 'true' is equal to any other, so
 *  two JSSTrue objects are equal. This allows Atomic objects to be compared entirely on the basis
 *  of their classes.
 */
protocol Atomic {}

/** Compare two Atomic objects by comparing their classes */
func ==<T,U where T : Atomic, U : Atomic>(lhs: T, rhs: U) -> Bool {
  if let _ = rhs as? T {
    return true
  }
  return false
}

class JSSEOS : JSSToken, Equatable, Atomic {}
class JSSTrue : JSSToken, Equatable, Atomic {}
class JSSFalse : JSSToken, Equatable, Atomic {}
class JSSNull : JSSToken, Equatable, Atomic {}
class JSSLBrack : JSSToken, Equatable, Atomic {}
class JSSRBrack : JSSToken, Equatable, Atomic {}
class JSSLCurly : JSSToken, Equatable, Atomic {}
class JSSRCurly : JSSToken, Equatable, Atomic {}
class JSSComma : JSSToken, Equatable, Atomic {}
class JSSColon : JSSToken, Equatable, Atomic {}
