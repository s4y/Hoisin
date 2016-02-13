/// Swift Migrator:
///
/// This file contains one or more places using either an index
/// or a range with ArraySlice. While in Swift 1.2 ArraySlice
/// indices were 0-based, in Swift 2.0 they changed to match the
/// the indices of the original array.
///
/// The Migrator wrapped the places it found in a call to the
/// following function, please review all call sites and fix
/// incides if necessary.
@available(*, deprecated=2.0, message="Swift 2.0 migration: Review possible 0-based index")
private func __reviewIndex__<T>(value: T) -> T {
    return value
}


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
        return strings[strings.startIndex].withCString {
            unsafes.append(UnsafeMutablePointer($0))
            if __reviewIndex__(strings.endIndex) == 1 {
                unsafes.append(UnsafeMutablePointer())
                return withCStrings(ArraySlice<String>(), unsafes: unsafes, f: f)
            }
            return withCStrings(strings[__reviewIndex__(1...(__reviewIndex__(strings.endIndex)-1))], unsafes: unsafes, f: f)
        }
}

