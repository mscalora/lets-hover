#!/usr/bin/env python

from codecs import open as copen
from tempfile import mkstemp
from shutil import move
from os import remove
from sys import argv, exit
from re import sub

def replace(source_file_path, pattern, substring, is_regexp):
    _, target_file_path = mkstemp()

    with copen(target_file_path, 'w', 'utf-8') as target_file:
        with copen(source_file_path, 'r', 'utf-8') as source_file:
            for line in source_file:
                if is_regexp:
                  target_file.write(sub(pattern, substring, line))
                else:
                  target_file.write(line.replace(pattern, substring))
    remove(source_file_path)
    move(target_file_path, source_file_path)

if __name__ == "__main__":
    args = argv[1:]
    regexp_flag = len(argv) > 1 and argv[1] == '-r'
    if regexp_flag:
        args = args[1:]
    if len(argv) < 4:
        print("\nUsage %s [ -r ] <file-path> <pattern> <replacement>\n" % argv[0])
        print("  -r    <patern> is a regular expression\n ")
        exit(1)
    else:
        replace(args[0], args[1], args[2], regexp_flag)
