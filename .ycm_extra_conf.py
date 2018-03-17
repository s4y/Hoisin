import subprocess

def filetype_flags(filename):
    if filename.endswith('.hpp') or filename.endswith('.cpp'):
        return ['--std=c++14', '-x', 'c++']
    if filename.endswith('.h'):
        return ['-x', 'objective-c++']
    return []


def FlagsForFile(filename, **kwargs):
    base_flags = [
        '-isysroot',
        subprocess.check_output(['xcrun', '--show-sdk-path']).strip(),
    ]
    flags_txt = open('flags.compile.txt').read().strip().split()

    return {
        'flags': base_flags + filetype_flags(filename) + flags_txt,
    }
