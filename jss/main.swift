//
//  main.swift
//  jss
//
//  Created by George Madrid on 4/26/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

//let fn = "/Users/gmadrid/Dropbox/jswiftson/samples/rtmresponse.json"
let fn = "/Users/gmadrid/Dropbox/jswiftson/samples/shortresponse-formatted.json"
guard let fh = NSFileHandle(forReadingAtPath: fn) else {
  print("Count not open file")
  exit(1)
}

let data = fh.readDataToEndOfFile()
guard let jsonString = String(data: data, encoding: NSASCIIStringEncoding) else {
  print("Could not encode file to ASCII string.")
  exit(1)
}

let parser = JSSParser(jsonString)
print(parser)

print("starting parse")
//let startTime = NSDate()
let jsObject = try! parser.parse()
//let endTime = NSDate()
//let foo = endTime.timeIntervalSinceDate(startTime)
//print(foo)

print(jsObject)
print("finished parse")


let doc = makeObjectDoc(jsObject)
print("made doc")
//let start2 = NSDate()
//try! NSJSONSerialization.JSONObjectWithData(data, options: [])
//let end2 = NSDate()
//print(end2.timeIntervalSinceDate(start2))

print(docPretty(70, doc: doc))
