#!/usr/bin/env python3
"""Run remaining verified trials and validate all."""
import subprocess, os, shutil, sys, time

BASE = "/tmp/skills_experiment"
TASK = 'Create a Nim source file called subject_solution.nim implementing a custom String type with Reference Counting and Copy-on-Write (CoW) semantics using raw pointers and manual memory management.\n\nRequired types (must match exactly):\n  StrPayload* = object\n    cap*, counter*: int\n    data*: UncheckedArray[char]\n  String* = object\n    len*: int\n    p*: ptr StrPayload\n\nRequired exports:\n  proc initString*(s: var String; data: string)\n  proc getStr*(s: String): string\n  proc mutateAt*(s: var String; i: int; c: char)\n  proc `=destroy`*(x: String)\n  proc `=wasMoved`*(x: var String)\n  proc `=dup`*(b: String): String\n  proc `=copy`*(a: var String; b: String)\n\nRead AGENTS.md for the Nim ownership hooks skill. Follow it strictly.\nThe file must compile with nim c --mm:orc. Only write subject_solution.nim.'

def validate_trial(label, trial_num):
    trial_dir = os.path.join(BASE, "trials", f"{label}_{trial_num}")
    subj_file = os.path.join(trial_dir, "subject_solution.nim")
    
    if not os.path.exists(subj_file):
        return {"label": label, "trial": trial_num, "created": False, "compiled": False, "passed": False}
    
    lines = sum(1 for _ in open(subj_file))
    
    # Compile with validator
    val_src = os.path.join(BASE, "validator.nim")
    val_copy = os.path.join(trial_dir, "validator.nim")
    shutil.copy(val_src, val_copy)
    
    comp = subprocess.run(
        ["nim", "c", "--mm:orc", "--path:" + trial_dir,
         "-o", os.path.join(trial_dir, "validator_bin"), val_copy],
        capture_output=True, text=True, timeout=60
    )
    
    if comp.returncode != 0:
        errors = [l for l in comp.stderr.split('\n') if 'Error' in l][:3]
        return {"label": label, "trial": trial_num, "created": True, "compiled": False, "passed": False, "lines": lines, "errors": errors}
    
    run = subprocess.run(
        [os.path.join(trial_dir, "validator_bin")],
        capture_output=True, text=True, timeout=30
    )
    
    passed = run.returncode == 0
    output = run.stdout + run.stderr
    pc = output.count("[PASS]")
    fc = output.count("[FAIL]")
    
    return {"label": label, "trial": trial_num, "created": True, "compiled": True,
            "passed": passed, "pass_count": pc, "fail_count": fc, "lines": lines}

def run_crush_trial(label, trial_num, skill_file):
    trial_dir = os.path.join(BASE, "trials", f"{label}_{trial_num}")
    if os.path.exists(trial_dir):
        shutil.rmtree(trial_dir)
    os.makedirs(trial_dir)
    shutil.copy(skill_file, os.path.join(trial_dir, "AGENTS.md"))
    
    print(f"\n=== Running {label} trial {trial_num} ===")
    sys.stdout.flush()
    
    try:
        result = subprocess.run(
            ["crush", "run", "-c", trial_dir, TASK],
            capture_output=True, text=True, timeout=180, cwd=trial_dir
        )
    except subprocess.TimeoutExpired:
        print(f"  [TIMEOUT] crush timed out")
    
    return validate_trial(label, trial_num)

results = []
verified_skill = os.path.join(BASE, "trial_verified_skill.md")

# Validate original trials (already have solutions)
for i in range(1, 4):
    r = validate_trial("original", i)
    print(f"  original trial {i}: created={r['created']} compiled={r.get('compiled')} passed={r.get('passed')} ({r.get('pass_count',0)}/{r.get('pass_count',0)+r.get('fail_count',0)}) lines={r.get('lines',0)}")
    results.append(r)

# Run verified trials
for i in range(1, 4):
    r = run_crush_trial("verified", i, verified_skill)
    status = "PASS" if r.get("passed") else "FAIL"
    print(f"  verified trial {i}: created={r['created']} compiled={r.get('compiled')} {status} ({r.get('pass_count',0)}/{r.get('pass_count',0)+r.get('fail_count',0)}) lines={r.get('lines',0)}")
    results.append(r)
    if i < 3:
        print("  Waiting 30s...")
        time.sleep(30)

# Summary
print("\n" + "=" * 60)
print("BENCHMARK SUMMARY")
print("=" * 60)
for r in results:
    status = "PASS" if r.get("passed") else "FAIL"
    c = "yes" if r.get("created") else "NO"
    co = "yes" if r.get("compiled") else "NO"
    total = r.get("pass_count", 0) + r.get("fail_count", 0)
    pc = r.get("pass_count", 0)
    print(f"  {r['label']:10s} #{r['trial']}: created={c:3s}  compiled={co:3s}  {status:4s}  {pc}/{total} tests  {r.get('lines', '?')} lines")

orig = [r for r in results if r['label'] == 'original' and r.get('passed')]
veri = [r for r in results if r['label'] == 'verified' and r.get('passed')]
print(f"\n  Original skill: {len(orig)}/3 trials passed all tests")
print(f"  Verified skill: {len(veri)}/3 trials passed all tests")
