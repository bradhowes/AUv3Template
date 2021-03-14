#!/bin/env python3

import os
import os.path
import re
import shutil
import subprocess
import sys


def substituteName(content, name, subtype):
    return content.replace('__NAME__', name).replace('__SUBTYPE__', subtype)

def makeDestPath(sourcePath, destDir, name, subtype):
    return substituteName(os.path.join(destDir, sourcePath), name, subtype)

def buildFile(sourcePath, destPath, name, subtype):
    justCopy = ['.py', '.png', '.caf', '.wav', '.xcuserstate', '.opacity']
    os.makedirs(os.path.split(destPath)[0], exist_ok=True)
    if os.path.splitext(destPath)[1] in justCopy:
        shutil.copy2(sourcePath, destPath)
    else:
        open(destPath, 'w').write(substituteName(open(sourcePath, 'r').read(), name, subtype))

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

def build(name, subtype):
    destDir = os.path.join('..', name)
    if os.path.exists(destDir):
        print('** destination', destDir, 'exists')
        sys.exit(1)
    for dirname, dirnames, filenames in os.walk('.'):
        for ignore in ['.~', '.git', 'DerivedData', 'xcuserdata']:
            if ignore in dirnames:
                dirnames.remove(ignore)
        for filename in filenames:
            if filename == '.DS_Store': continue
            sourcePath = os.path.join(dirname, filename)[2:]
            print('--', sourcePath)
            buildFile(sourcePath, makeDestPath(sourcePath, destDir, name, subtype), name, subtype)
    createRepo(destDir)
    runCommand('opening project', 'open', os.path.join(destDir, name + '.xcodeproj'))

if __name__ == '__main__':
    build(sys.argv[1], sys.argv[2])
