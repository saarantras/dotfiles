import sys, re
lines = []
for line in sys.stdin:
    m = re.search(r'@ (\d+(\.\d+)?)', line)
    if m:
        lines.append( (float(m.group(1)), line.strip()) )
    else:
        lines.append( (float(-1), line.strip()) )
for _, line in sorted(lines):
    print(line)
