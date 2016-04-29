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
  case Union(x: Doc, y: Doc)
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
    let concat = ldoc <> doc2
    if case .Text(let cstr, let cldoc) = concat {
      return .Text(str: str + cstr, doc: cldoc)
    }
    return .Text(str: str, doc: concat)
  case .Line(let i, let ldoc):
    return .Line(i: i, doc: ldoc <> doc2)
  case .Union(let x, let y):
    return .Union(x: x <> doc2, y: y <> doc2)
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
  case .Union(let x, let y):
    return .Union(x: docNest(i, x), y: docNest(i, y))
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
  case .Union(_, let y):
    return docLayout(y)  // Choose the non-flattened rep.
  }
}

func docGroup(doc: Doc) -> Doc {
  switch doc {
  case .Nil:
    return doc
  case .Line(let i, let x):
    return .Union(x: .Text(str: " ", doc: docFlatten(x)), y: .Line(i: i, doc: x))
  case .Text(let str, let doc):
    return .Text(str: str, doc: docGroup(doc))
  case .Union(let x, let y):
    return .Union(x: docGroup(x), y: y)
  }
}

func docFlatten(doc: Doc) -> Doc {
  switch doc {
  case .Nil:
    return doc
  case .Line(_, let x):
    return .Text(str: " ", doc: docFlatten(x))
  case .Text(let str, let doc):
    return .Text(str: str, doc: docFlatten(doc))
  case .Union(let x, _):
    return docFlatten(x)
  }
}

typealias DocThunk = Doc -> Doc

func docBest(width: Int, used: Int, doc: Doc) -> Doc {
  switch doc {
  case .Nil:
    return doc
  case .Line(let i, let doc):
    return .Line(i: i, doc: docBest(width, used: i, doc: doc))
  case .Text(let str, let doc):
    return .Text(str: str, doc: docBest(width, used: used + str.characters.count, doc: doc))
  case .Union(let x, let y):
    return docBetter(width, used: used, x: docBest(width, used: used, doc: x), y: docBest(width, used: used, doc: y))
  }
}

func docBetter(width: Int, used: Int, x: Doc, y: Doc) -> Doc {
  if docFits(width - used, doc: x) {
    return x
  } else {
    return y
  }
}

func docFits(width: Int, doc: Doc) -> Bool {
  if width < 0 { return false }

  switch doc {
  case .Nil:
    return true
  case .Text(let str, let doc):
    return docFits(width - str.characters.count, doc: doc)
  case .Line:
    return true
  default:
    print("NEVER HAPPENS?!?!?!?!?!?")
    return false  // never happens
  }
}

func docPretty(width: Int, doc: Doc) -> String {
  return docLayout(docBest(width, used: 0, doc: doc))
}
