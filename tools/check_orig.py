import json, subprocess, sys
from pathlib import Path
p = Path(sys.argv[1]).as_posix()
out = subprocess.check_output(['git','show',f'HEAD:{p}'], cwd=Path(__file__).resolve().parent.parent)
d = json.loads(out)
print(json.dumps({k:d.get(k) for k in ['id','name','area','parentBoardId','tier','isSubBoard','isTertiaryBoard','sortOrder']}, indent=2))
