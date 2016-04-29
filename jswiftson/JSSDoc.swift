//
//  JSSDoc.swift
//  jswiftson
//
//  Created by George Madrid on 4/26/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

func makeObjectDoc(obj: JSSObject) -> Doc {
  return docGroup(docText("{")
    <> docNest(2, docLine() <> makePairsDoc(obj.pairs))
    <> docLine() <> docText("}"))
}

func makePairsDoc(pairs: [JSSPair]) -> Doc {
  if pairs.count == 1 {
    return makePairDoc(pairs.first!)
  }

  return makePairDoc(pairs.first!)
    <> docText(",")
    <> docLine()
    <> makePairsDoc(Array(pairs.dropFirst(1)))
}

func makePairDoc(pair: JSSPair) -> Doc {
  return makeStringDoc(pair.str)
    <> docText(": ")
    <> makeValueDoc(pair.val)
}

func makeStringDoc(str: JSSString) -> Doc {
  return docText("\"") <> docText(str.str) <> docText("\"")
}

func makeValueDoc(val: JSSValue) -> Doc {
  if let str = val as? JSSString {
    return makeStringDoc(str)
  }
  if let num = val as? JSSNumber {
    return makeNumberDoc(num)
  }
  if let obj = val as? JSSObject {
    return makeObjectDoc(obj)
  }
  if let arr = val as? JSSArray {
    return makeArrayDoc(arr)
  }
  if let _ = val as? JSSTrue {
    return docText("true")
  }
  if let _ = val as? JSSFalse {
    return docText("false")
  }
  if let _ = val as? JSSNull {
    return docText("null")
  }
  return docText("UNHANDLED VALUE TYPE")
}

func makeNumberDoc(num: JSSNumber) -> Doc {
  var result = docText(num.digits)
  if let frac = num.frac {
    result = result <> docText(frac)
  }
  if let exp = num.exp {
    result = result <> docText(exp)
  }
  return result
}

func makeArrayDoc(arr: JSSArray) -> Doc {
  if arr.values.isEmpty {
    return docGroup(docText("[") <> docLine() <> docText("]"))
  }

  let valuesDoc = makeValuesDoc(arr.values)
  return docGroup(docText("[")
    <> docNest(2, docLine() <> valuesDoc)
    <> docLine() <> docText("]"))
}

func makeValuesDoc(values: [JSSValue]) -> Doc {
  if values.count == 0 {
    return docNil()
  }

  if values.count == 1 {
    return makeValueDoc(values.first!)
  }

  return makeValueDoc(values.first!)
    <> docText(",")
    <> docLine()
    <> makeValuesDoc(Array(values.dropFirst(1)))
}
