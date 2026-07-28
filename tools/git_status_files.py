import subprocess, sys
from pathlib import Path
cwd = Path(__file__).resolve().parent.parent
if len(sys.argv) < 2:
    print('usage: python git_status_files.py <prefix>')
    sys.exit(1)
prefix = sys.argv[1]
out = subprocess.check_output(['git','ls-files',prefix], cwd=cwd, text=True)
print(out)
