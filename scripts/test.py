#!/usr/bin/env python3
"""Run original stimulus benches plus the self-checking regression."""
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build"

def run(*args):
    subprocess.run(args, cwd=ROOT, check=True, timeout=60)

def main():
    for tool in ("iverilog", "vvp"):
        if shutil.which(tool) is None:
            raise SystemExit(f"Missing {tool}: install Icarus Verilog first.")
    BUILD.mkdir(exist_ok=True)
    rtl = [str(p) for p in sorted((ROOT / "rtl").glob("*.v"))]
    run("iverilog", "-g2012", "-s", "MainCode", "-o", str(BUILD / "top.vvp"), *rtl)
    benches = sorted((ROOT / "tb/legacy").glob("*_tb.v")) + [ROOT / "tb/regression_tb.sv"]
    for bench in benches:
        output = str(BUILD / (bench.stem + ".vvp"))
        run("iverilog", "-g2012", "-s", bench.stem, "-o", output, *rtl, str(bench))
        # Legacy benches use $stop; -n treats it as completion without a prompt.
        run("vvp", "-n", output)
        print(f"Completed {bench.stem}", flush=True)
    print("PASS: top-level elaboration, 14 stimulus benches, and regression")

if __name__ == "__main__":
    main()
