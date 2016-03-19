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
        if strings.endIndex - strings.startIndex == 1 {
            unsafes.append(UnsafeMutablePointer())
            return withCStrings(ArraySlice<String>(), unsafes: unsafes, f: f)
        }
        return withCStrings(strings[strings.startIndex+1..<strings.endIndex], unsafes: unsafes, f: f)
    }
}