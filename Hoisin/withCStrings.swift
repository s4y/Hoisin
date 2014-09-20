//
//  withCStrings.swift
//  Hoisin
//
//  Created by Sidney San Martín on 8/22/14.
//  Copyright (c) 2014 s4y. All rights reserved.
//

func withCStrings<Result>(
    strings: Slice<String>,
    f: ([UnsafeMutablePointer<CChar>]) -> Result,
    var unsafes: [UnsafeMutablePointer<CChar>] = []
    ) -> Result {
        if strings.isEmpty {
            return f(unsafes)
        }
        return strings[0].withCString {
            unsafes.append(UnsafeMutablePointer($0))
            if strings.endIndex == 1 {
                unsafes.append(UnsafeMutablePointer())
                return withCStrings(Slice<String>(), f, unsafes: unsafes)
            }
            return withCStrings(strings[1...(strings.endIndex-1)], f, unsafes: unsafes)
        }
}

