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

}
