import subprocess
import os
import json
import re

subprocess.run(["make", "clean"])
process = subprocess.run(["make", "all", "-n"], capture_output=True, encoding="utf8")
assert(process.returncode == 0)

out = []
for line in process.stdout.splitlines():
    if re.match(r'^\S+arm-none-eabi-g(cc|\+\+)(?!.*\s(-MM\b|-L))', line):
        out.append({
            "directory": os.getcwd(),
            "command": line,
            "file": line.split(" ")[-1]
        })

with open("compile_commands.json", "w") as f:
    json.dump(out, f)
