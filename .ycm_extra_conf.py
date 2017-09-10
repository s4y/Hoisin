import subprocess

def FlagsForFile(filename, **kwargs):
    return {
        'flags': [
            '-isysroot',
            subprocess.check_output(['xcrun', '--show-sdk-path']).strip(),
            '-m',
            'objective-c',
        ] + open('flags.compile.txt').read().strip().split(),
    }
