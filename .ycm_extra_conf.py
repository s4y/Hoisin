import subprocess

def FlagsForFile(filename, **kwargs):
    return {
        'flags': [
            '-isysroot',
            subprocess.check_output(['xcrun', '--show-sdk-path']).strip()
        ] + open('flags').read().strip().split(),
    }
