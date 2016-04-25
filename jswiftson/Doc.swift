//
//  Doc.swift
//  jswiftson
//
//  Created by George Madrid on 4/25/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

indirect enum Doc {
  case Nil
  case Text(str: String, doc: Doc)
  case Line(i: Int, doc: Doc)
//  case Union(x: Doc, y: Doc)
}

func docNil() -> Doc {
  return .Nil
}

func docText(str: String) -> Doc {
  return .Text(str: str, doc: docNil())
}

func docLine() -> Doc {
  return .Line(i: 0, doc: docNil())
}

infix operator <> {
  associativity left
}

func <>(doc1: Doc, doc2: Doc) -> Doc {
  switch doc1 {
  case .Nil:
    return doc2
  case .Text(let str, let ldoc):
    return .Text(str: str, doc: ldoc <> doc2)
  case .Line(let i, let ldoc):
    return .Line(i: i, doc: ldoc <> doc2)
  }
}

func docNest(i: Int, _ doc: Doc) -> Doc {
  switch doc {
  case .Nil:
    return doc
  case .Text(let str, let ldoc):
    return .Text(str: str, doc: docNest(i, ldoc))
  case .Line(let j, let ldoc):
    return .Line(i: i + j, doc: docNest(i, ldoc))
  }
}

func docLayout(doc: Doc) -> String {
  switch doc {
  case .Nil:
    return ""
  case .Text(let str, let ldoc):
    return str + docLayout(ldoc)
  case .Line(let i, let ldoc):
    return "\n" + String(count:i, repeatedValue: Character(" ")) + docLayout(ldoc)
  }
}
