def FlagsForFile(filename, **kwargs):
    return {
        'flags': open('flags').read().strip().split(),
    }
