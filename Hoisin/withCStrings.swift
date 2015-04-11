
//
//  withCStrings.swift
//  Hoisin
//
//  Created by Sidney San Martín on 8/22/14.
//  Copyright (c) 2014 s4y. All rights reserved.
//

func withCStrings<Result>(
    strings: ArraySlice<String>,
    var unsafes: [UnsafeMutablePointer<CChar>] = [],
    f: ([UnsafeMutablePointer<CChar>]) -> Result
    ) -> Result {
        if strings.isEmpty {
            return f(unsafes)
        }
        return strings[0].withCString {
            unsafes.append(UnsafeMutablePointer($0))
            if strings.endIndex == 1 {
                unsafes.append(UnsafeMutablePointer())
                return withCStrings(ArraySlice<String>(), unsafes: unsafes, f)
            }
            return withCStrings(strings[1...(strings.endIndex-1)], unsafes: unsafes, f)
        }
}

