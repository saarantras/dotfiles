import sys, re
lines = []
for line in sys.stdin:
    m = re.search(r'@ (\d+(\.\d+)?)', line)
    if m:
        lines.append( (float(m.group(1)), line.strip()) )
    else:
        lines.append( (float(-1), line.strip()) )

#very simple doublet checking
previous_line=""

for _, line in sorted(lines):
    if line != previous_line:
        print(line)
    previous_line=line
