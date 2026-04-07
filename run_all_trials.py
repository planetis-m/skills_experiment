#!/usr/bin/env python3
"""Run crush trials for skill comparison."""
import subprocess, os, shutil, sys, time

BASE = "/tmp/skills_experiment"
TASK = """Create a Nim source file called subject_solution.nim implementing a custom String type with Reference Counting and Copy-on-Write (CoW) semantics using raw pointers and manual memory management.

Required types (must match exactly):
  StrPayload* = object
    cap*, counter*: int
    data*: UncheckedArray[char]
  String* = object
    len*: int
    p*: ptr StrPayload

Required exports:
  proc initString*(s: var String; data: string)
  proc getStr*(s: String): string
  proc mutateAt*(s: var String; i: int; c: char)
  proc `=destroy`*(x: String)
  proc `=wasMoved`*(x: var String)  
  proc `=dup`*(b: String): String
  proc `=copy`*(a: var String; b: String)

Read AGENTS.md for the Nim ownership hooks skill. Follow it strictly.
The file must compile with nim c --mm:orc. Only write subject_solution.nim."""

def run_trial(label, trial_num, skill_file):
    trial_dir = os.path.join(BASE, "trials", f"{label}_{trial_num}")
    if os.path.exists(trial_dir):
        shutil.rmtree(trial_dir)
    os.makedirs(trial_dir)
    
    # Inject skill
    shutil.copy(skill_file, os.path.join(trial_dir, "AGENTS.md"))
    
    print(f"\n========== {label} TRIAL {trial_num} ==========")
    sys.stdout.flush()
    
    # Run crush
    result = subprocess.run(
        ["crush", "run", "-c", trial_dir, TASK],
        capture_output=True, text=True, timeout=180, cwd=trial_dir
    )
    
    subj_file = os.path.join(trial_dir, "subject_solution.nim")
    if not os.path.exists(subj_file):
        print(f"  [FAIL] subject_solution.nim NOT created")
        # Check for alt locations
        for f in os.listdir(trial_dir):
            if f.endswith('.nim'):
                print(f"  Found: {f}")
        return {"label": label, "trial": trial_num, "created": False, "compiled": False, "passed": False}
    
    lines = sum(1 for _ in open(subj_file))
    print(f"  [OK] Created subject_solution.nim ({lines} lines)")
    
    # Compile with validator
    val_src = os.path.join(BASE, "validator.nim")
    shutil.copy(val_src, os.path.join(trial_dir, "validator.nim"))
    
    comp = subprocess.run(
        ["nim", "c", "--mm:orc", f"--path:{trial_dir}", 
         "-o", os.path.join(trial_dir, "validator_bin"),
         os.path.join(trial_dir, "validator.nim")],
        capture_output=True, text=True, timeout=60
    )
    
    if comp.returncode != 0:
        errors = [l for l in comp.stderr.split('\n') if 'Error' in l][:5]
        print(f"  [COMPILE FAIL]")
        for e in errors:
            print(f"    {e}")
        return {"label": label, "trial": trial_num, "created": True, "compiled": False, "passed": False}
    
    print(f"  [COMPILE OK]")
    
    # Run validator
    run = subprocess.run(
        [os.path.join(trial_dir, "validator_bin")],
        capture_output=True, text=True, timeout=30
    )
    
    passed = run.returncode == 0
    status = "PASS" if passed else "FAIL"
    print(f"  [RUN {status}]")
    
    # Count results
    output = run.stdout + run.stderr
    pass_count = output.count("[PASS]")
    fail_count = output.count("[FAIL]")
    print(f"  {pass_count} passed, {fail_count} failed")
    
    if not passed:
        print(f"  Output (last 10 lines):")
        for line in output.split('\n')[-10:]:
            if line.strip():
                print(f"    {line}")
    
    return {"label": label, "trial": trial_num, "created": True, "compiled": True, 
            "passed": passed, "pass_count": pass_count, "fail_count": fail_count, "lines": lines}

original_skill = os.path.join(BASE, "trial_original_skill.md")
verified_skill = os.path.join(BASE, "trial_verified_skill.md")

results = []

# Original trials (skip 1-2 already done)
for i in range(1, 4):
    trial_dir = os.path.join(BASE, "trials", f"original_{i}")
    subj_file = os.path.join(trial_dir, "subject_solution.nim")
    if os.path.exists(subj_file):
        # Already completed — just re-validate
        print(f"\n========== original TRIAL {i} (cached) ==========")
        lines = sum(1 for _ in open(subj_file))
        print(f"  [OK] subject_solution.nim exists ({lines} lines)")
        shutil.copy(os.path.join(BASE, "validator.nim"), os.path.join(trial_dir, "validator.nim"))
        comp = subprocess.run(
            ["nim", "c", "--mm:orc", f"--path:{trial_dir}",
             "-o", os.path.join(trial_dir, "validator_bin"),
             os.path.join(trial_dir, "validator.nim")],
            capture_output=True, text=True, timeout=60
        )
        if comp.returncode == 0:
            run = subprocess.run([os.path.join(trial_dir, "validator_bin")], capture_output=True, text=True, timeout=30)
            passed = run.returncode == 0
            pc = run.stdout.count("[PASS]")
            fc = run.stdout.count("[FAIL]")
            print(f"  [RUN {'PASS' if passed else 'FAIL'}] {pc} passed, {fc} failed")
            results.append({"label": "original", "trial": i, "created": True, "compiled": True, "passed": passed, "pass_count": pc, "fail_count": fc, "lines": lines})
        else:
            print(f"  [COMPILE FAIL]")
            results.append({"label": "original", "trial": i, "created": True, "compiled": False, "passed": False, "lines": lines})
    else:
        results.append(run_trial("original", i, original_skill))
        time.sleep(30)

# Verified trials
for i in range(1, 4):
    results.append(run_trial("verified", i, verified_skill))
    if i < 3:
        time.sleep(30)

# Summary
print("\n" + "=" * 60)
print("BENCHMARK SUMMARY")
print("=" * 60)
for r in results:
    status = "PASS" if r.get("passed") else "FAIL"
    created = "created" if r.get("created") else "NOT CREATED"
    print(f"  {r['label']:10s} trial {r['trial']}: {created:12s} | {status:4s} | {r.get('pass_count', '?'):>2s}/{r.get('pass_count', 0) + r.get('fail_count', 0)} tests")

orig_passes = sum(1 for r in results if r['label'] == 'original' and r.get('passed'))
veri_passes = sum(1 for r in results if r['label'] == 'verified' and r.get('passed'))
orig_total = sum(1 for r in results if r['label'] == 'original')
veri_total = sum(1 for r in results if r['label'] == 'verified')

print(f"\n  Original skill: {orig_passes}/{orig_total} trials passed")
print(f"  Verified skill: {veri_passes}/{veri_total} trials passed")
