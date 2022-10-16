#!/usr/bin/env python3
#
# Generate a set of scripts from the documentation by reading markdown comments to determine target hosts
# and extracting all scripts fenced by ```bash
#
#
# Point it to the docs directory containing the lab documents
# It will create shell scripts in docs/../quick-steps
# THe scripts are ordered by lab number, then a, b, c where a lab requires you to use more than one host,
# and the filename indicates which hosts to run
#
# Hosts and other things are determined from markdown comments.
# For documents containing no markdown comments, scripts are not generated.

import re
import os
import glob
import codecs
import argparse
from enum import Enum
from sys import exit

class State(Enum):
    NONE = 0
    SCRIPT = 1

parser = argparse.ArgumentParser(description="Extract scripts from markdown")
parser.add_argument("--path", '-p', required=True, help='Path to markdown docs')
args = parser.parse_args()

docs_path = os.path.abspath(args.path)

if not os.path.isdir(docs_path):
    print (f'Invalid path: {docs_path}')
    exit(1)

qs_path = os.path.abspath(os.path.join(docs_path, '../quick-steps'))

if not os.path.isdir(qs_path):
    os.makedirs(qs_path)

newline = chr(10)       # In case running on Windows (plus writing files as binary to not convert to \r\n)
file_number_rx = re.compile(r'^(?P<number>\d+)')
comment_rx = re.compile(r'^\[//\]:\s\#\s\((?P<token>\w+):(?P<value>[^\)]+)\)')
choice_rx = re.compile(r'^\s*-+\s+OR\s+-+')
script_begin = '```bash'
script_end = '```'
script_open = ('{' + newline).encode('utf-8')
script_close = '}'.encode('utf-8')
current_host = None

def write_script(filename: str, script: list):
    path = os.path.join(qs_path, filename)
    with open(path, "wb") as f:
        f.write(script_open)
        f.write(newline.join(script).encode('utf-8'))
        f.write(script_close)
    print(f'-> {path}')


for doc in glob.glob(os.path.join(docs_path, '*.md')):
    print(doc)
    script = []
    state = State.NONE
    ignore_next_script = False
    m = file_number_rx.search(os.path.basename(doc))
    if not m:
        continue
    file_no = m['number']
    section = 0
    output_file = None
    with codecs.open(doc, "r", encoding='utf-8') as f:
        for line in f.readlines():
            line = line.rstrip()
            if state == State.NONE:
                m = comment_rx.search(line)
                if m:
                    token = m['token']
                    value = m['value']
                    if token == 'host':
                        if script:
                            write_script(output_file, script)
                            script = []
                        output_file = os.path.join(qs_path, f'{file_no}{chr(97 + section)}-{value}.sh')
                        section += 1
                    elif token == 'sleep':
                        script.extend([
                            f'echo "Sleeping {value}s"',
                            f'sleep {value}',
                            newline
                        ])
                    elif token == 'command':
                        script.extend([
                            value,
                            newline
                        ])
                    elif token == 'comment':
                        script.extend([
                            '#######################################################################',
                            '#',
                            f'# {value}',
                            '#',
                            '#######################################################################',
                            newline
                        ])
                elif line == script_begin:
                    state = State.SCRIPT
                elif choice_rx.match(line):
                    ignore_next_script = True
            elif state == State.SCRIPT:
                if line == script_end:
                    state = State.NONE
                    script.append(newline)
                    ignore_next_script = False
                elif not (ignore_next_script or line == '{' or line == '}'):
                    script.append(line)
        if output_file and script:
            write_script(output_file, script)

