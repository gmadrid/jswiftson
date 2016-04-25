//
//  DocTests.swift
//  jswiftson
//
//  Created by George Madrid on 4/25/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import XCTest

class TreeNode {
  let str: String
  let children: [TreeNode]

  init(str: String, children: [TreeNode]) {
    self.str = str
    self.children = children
  }
}

func showTreeGrouped(node: TreeNode) -> Doc {
  let str = node.str

  return docGroup(docText(str) <> docNest(str.characters.count, showBracketGrouped(node.children)))
}

func showBracketGrouped(children: [TreeNode]) -> Doc {
  if children.isEmpty {
    return docNil()
  }

  return docText("[")
    <> docNest(1, showTreesGrouped(children))
    <> docText("]")
}

// children MUST NEVER be empty
func showTreesGrouped(children: [TreeNode]) -> Doc {
  if children.count < 2 {
    return showTreeGrouped(children.first!)
  }

  return showTreeGrouped(children.first!)
    <> docText(",")
    <> docLine()
    <> showTreesGrouped(Array(children.dropFirst(1)))
}

func showTree(node: TreeNode) -> Doc {
  let str = node.str

  return docText(str) <> docNest(str.characters.count, showBracket(node.children))
}

func showBracket(children: [TreeNode]) -> Doc {
  if children.isEmpty {
    return docNil()
  }

  return docText("[")
    <> docNest(1, showTrees(children))
    <> docText("]")
}

// children MUST NEVER be empty
func showTrees(children: [TreeNode]) -> Doc {
  if children.count < 2 {
    return showTree(children.first!)
  }

  return showTree(children.first!)
    <> docText(",")
    <> docLine()
    <> showTrees(Array(children.dropFirst(1)))
}

func showTreeB(node: TreeNode) -> Doc {
  return docText(node.str) <> showBracketB(node.children)
}

func showBracketB(children: [TreeNode]) -> Doc {
  if children.isEmpty {
    return docNil()
  }

  return docText("[")
    <> docNest(2, docLine() <> showTreesB(children))
    <> docLine() <> docText("]")
}

// children MUST NEVER be empty
func showTreesB(children: [TreeNode]) -> Doc {
  if children.count < 2 {
    return showTreeB(children.first!)
  }

  return showTreeB(children.first!)
    <> docText(",") <> docLine() <> showTreesB(Array(children.dropFirst(1)))
}

func showArray(arr: JSSArray) -> Doc {
  return docText("[")
  <> docNest(2, docLine() <> showValues(arr.values))
  <> docLine() <> docText("]")
}

func showValues(values: [JSSValue]) -> Doc {
  if values.count == 1 {
    return showValue(values.first!)
  }

  return showValue(values.first!)
    <> docText(",")
    <> docLine()
    <> showValues(Array(values.dropFirst(1)))
}

func showObject(obj: JSSObject) -> Doc {
  return docText("{")
    <> docNest(2, docLine() <> showPairs(obj.pairs))
    <> docLine() <> docText("}")
}

func showPairs(pairs: [JSSPair]) -> Doc {
  if pairs.count == 1 {
    return showPair(pairs.first!)
  }

  return showPair(pairs.first!)
    <> docText(",")
    <> docLine()
    <> showPairs(Array(pairs.dropFirst(1)))
}

func showPair(pair: JSSPair) -> Doc {
  return showString(pair.str)
    <> docText(": ")
    <> showValue(pair.val)
}

func showString(str: JSSString) -> Doc {
  return docText("\"") <> docText(str.str) <> docText("\"")
}

func showValue(val: JSSValue) -> Doc {
  if let str = val as? JSSString {
    return showString(str)
  }
  if let num = val as? JSSNumber {
    return showNumber(num)
  }
  if let obj = val as? JSSObject {
    return showObject(obj)
  }
  if let arr = val as? JSSArray {
    return showArray(arr)
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

func showNumber(num: JSSNumber) -> Doc {
  var result = docText(num.digits)
  if let frac = num.frac {
    result = result <> docText(frac)
  }
  if let exp = num.exp {
    result = result <> docText(exp)
  }
  return result
}

class DocTests: XCTestCase {
  func testJSON() {
    do {
      let head = "{ \"foo\": 3, \"bar\": \"quux\", \"frob\": { \"baz\": 3.1415927, \"foo\": "
      let arr = "[ true, false, null, 2.71828, \"textinarray\" ]"
      let tail = " } }"
      print (head + arr + tail)
      let parser = JSSParser(head + arr + tail)
      let jtree = try parser.parse()

      print(docLayout(showObject(jtree)))
    } catch {
      print(error)
      XCTFail()
    }
  }

  func testLayout1() {
    let tree = TreeNode(str: "aaa", children: [
      TreeNode(str: "bbbbb", children: [
        TreeNode(str: "ccc", children: []),
        TreeNode(str: "dd", children: [])
        ]),
      TreeNode(str: "eee", children: []),
      TreeNode(str: "ffff", children: [
        TreeNode(str: "gg", children: []),
        TreeNode(str: "hhh", children: []),
        TreeNode(str: "ii", children: [])
        ])
      ])

    let layout = docLayout(showTree(tree))
    let expectedLayout = [
      "aaa[bbbbb[ccc,",
      "          dd],",
      "    eee,",
      "    ffff[gg,",
      "         hhh,",
      "         ii]]"
      ].joinWithSeparator("\n")
    XCTAssertEqual(layout, expectedLayout)
  }

  func testLayout2() {
    let tree = TreeNode(str: "aaa", children: [
      TreeNode(str: "bbbbb", children: [
        TreeNode(str: "ccc", children: []),
        TreeNode(str: "dd", children: [])
        ]),
      TreeNode(str: "eee", children: []),
      TreeNode(str: "ffff", children: [
        TreeNode(str: "gg", children: []),
        TreeNode(str: "hhh", children: []),
        TreeNode(str: "ii", children: [])
        ])
      ])

    let layout = docLayout(showTreeB(tree))
    let expectedLayout = [
      "aaa[",
      "  bbbbb[",
      "    ccc,",
      "    dd",
      "  ],",
      "  eee,",
      "  ffff[",
      "    gg,",
      "    hhh,",
      "    ii",
      "  ]",
      "]"
    ].joinWithSeparator("\n")
    XCTAssertEqual(layout, expectedLayout)
  }

  func testPretty() {
    let tree = TreeNode(str: "aaa", children: [
      TreeNode(str: "bbbbb", children: [
        TreeNode(str: "ccc", children: []),
        TreeNode(str: "dd", children: [])
        ]),
      TreeNode(str: "eee", children: []),
      TreeNode(str: "ffff", children: [
        TreeNode(str: "gg", children: []),
        TreeNode(str: "hhh", children: []),
        TreeNode(str: "ii", children: [])
        ])
      ])

    print(docPretty(80, doc: showTreeGrouped(tree)))
    print(docPretty(50, doc: showTreeGrouped(tree)))
    print(docPretty(30, doc: showTreeGrouped(tree)))
    print(docPretty(20, doc: showTreeGrouped(tree)))
    print(docPretty(15, doc: showTreeGrouped(tree)))
    print(docPretty(10, doc: showTreeGrouped(tree)))

  }
}
