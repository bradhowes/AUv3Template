#!/bin/env python3

import os
import os.path
import re
import shutil
import subprocess
import sys


def substituteName(content, name):
    return content.replace('__NAME__', name)

def makeDestPath(sourcePath, destDir, name):
    return substituteName(os.path.join(destDir, sourcePath), name)

def buildFile(sourcePath, destPath, name):
    skip = ['.py', '.png', '.caf', '.wav', '.xcuserstate', '.opacity']
    os.makedirs(os.path.split(destPath)[0], exist_ok=True)
    if os.path.splitext(destPath)[1] in skip:
        shutil.copy2(sourcePath, destPath)
    else:
        open(destPath, 'w').write(substituteName(open(sourcePath, 'r').read(), name))

def runCommand(step, *args):
    print('--', step)
    process = subprocess.run(args, stdout=subprocess.PIPE, universal_newlines=True)
    if process.returncode != 0:
        print(process.stdout)
        print(process.stderr)
        sys.exit(1)

def createRepo(destDir):
    os.chdir(destDir)
    runCommand('creating repo', 'git', 'init')
    runCommand('stagiing files', 'git', 'add', '-A')
    runCommand('committing to repo', 'git', 'commit', '-m', 'Yeah! Initial commit')

def build(name):
    destDir = os.path.join('..', name)
    if os.path.exists(destDir):
        print('** destination', destDir, 'exists')
        sys.exit(1)
    for dirname, dirnames, filenames in os.walk('.'):
        for ignore in ['.~', '.git']:
            if ignore in dirnames:
                dirnames.remove(ignore)
        for filename in filenames:
            sourcePath = os.path.join(dirname, filename)[2:]
            print('--', sourcePath)
            buildFile(sourcePath, makeDestPath(sourcePath, destDir, name), name)
    createRepo(destDir)

if __name__ == '__main__':
    build(sys.argv[1])
