func withCStrings<Result>(
    strings: ArraySlice<String>,
    unsafes unsafesIn: [UnsafeMutablePointer<CChar>] = [],
    f: ([UnsafeMutablePointer<CChar>]) -> Result
) -> Result {
    if strings.isEmpty {
        return f(unsafesIn)
    }
    return strings[strings.startIndex].withCString {
        var unsafes = unsafesIn
        unsafes.append(UnsafeMutablePointer($0))
        if strings.endIndex - strings.startIndex == 1 {
            unsafes.append(nil)
            return withCStrings(ArraySlice<String>(), unsafes: unsafes, f: f)
        }
        return withCStrings(strings[strings.startIndex+1..<strings.endIndex], unsafes: unsafes, f: f)
    }
}