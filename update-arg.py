#!/usr/bin/env python3
import argparse
import re


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('pairs', nargs='+', type=str, help='key=value pairs')
    parser.add_argument('--file', type=str, help='Dockerfile path', default='Dockerfile')
    parser.add_argument('--write', action='store_true', help='write to file')

    args = parser.parse_args()
    pairs: dict[str, str] = dict(pair.split('=', 1) for pair in args.pairs)

    lines = []
    with open(args.file, 'r') as f:
        replacers = []
        for key, value in pairs.items():
            replacers.append((re.compile(r'^(\s*ARG\s+' + re.escape(key) + ")=" + r'(.+)$'), value))
        for line in f:
            line = line.rstrip('\n')
            new_line = line
            for replacer in replacers:
                new_line = replacer[0].sub(r'\1=' + replacer[1], line)
                if new_line != line:
                    break
            if new_line != line:
                print(f'replaced "{line}" => "{new_line}"')
            lines.append(new_line)

    if args.write:
        with open(args.file, 'w') as f:
            for line in lines:
                f.write(line + '\n')


if __name__ == '__main__':
    main()
