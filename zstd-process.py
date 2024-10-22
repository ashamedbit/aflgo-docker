import glob
import linecache
import os
import re
import shlex
import shutil
import subprocess
import threading
import time
from multiprocessing import Pool
from pathlib import Path
import timeout_decorator
from tqdm import tqdm

trig_bugs = {}
reach_bugs = {}
crashes = {}
crash_types = {}

def assign_if_smaller(dictionary, key, value):
    prev_value = -1
    if key in dictionary:
        prev_value = dictionary[key]
    
    if prev_value == -1 or value < prev_value:
        dictionary[key] = value


def confirm_triggers(asan_output, time):
    lines = asan_output.split("\n")
    
    for line in lines:
        if "triggered bug index " in line:
            m = re.findall("triggered bug index ([\d]+)", line)
            key = int(m[0])
            assign_if_smaller(trig_bugs, key, time)
        if "reached bug index " in line:
            m = re.findall("reached bug index ([\d]+)", line)
            key = int(m[0])
            assign_if_smaller(reach_bugs, key, time)


def identify_crash_line(asan_output, file, time):
        lines = asan_output.split("\n")
        file_root = os.path.splitext(os.path.basename(file))[0]
        issue = ""
        issues = []
        crash_lines = []
        crash_detected = 0
        leak_detected = 0
        stacktrace_detected = 0
        is_some_issue_present = 0
        for line in lines:
            m = re.findall("==ERROR: AddressSanitizer: ([\w\s-]+) on", line)
            if m:
                issue = m[0]
                crash_detected = 1
            elif "==AddressSanitizer CHECK failed:" in line:
                issue = "Accessed memory not in memory and shadow"
                crash_detected = 1
            elif "== ERROR: libFuzzer: deadly signal" in line:
                issue = "libFuzzer: deadly signal"
                crash_detected = 1
            elif "==ERROR: LeakSanitizer: detected memory leaks" in line:
                issue = "memory leak"
                leak_detected = 1
            elif "== ERROR: libFuzzer: timeout after" in line:
                issue = "testcase timeout"
                crash_detected = 1

            if line.startswith("    #") and ((file_root + ".c") in line):
                stacktrace_detected = 1

            if (
                ("#" in line)
                and ((".c:") in line or (".cc:" in line))
                and (crash_detected == 1 or leak_detected == 1)
            ):
                crash_line = line.split(" ")[-1]
                is_some_issue_present = 1
                issues.append(issue)
                crash_lines.append(crash_line)
                if crash_detected == 1:
                    crash_detected = 0

                key = crash_line
                assign_if_smaller(crashes, key, time)
                if key not in crash_types:
                    crash_types[key] = set()
                s : set = crash_types[key]
                s.add(issue)
                

            if leak_detected == 1 and "SUMMARY: AddressSanitizer: " in line:
                leak_detected = 0

        if stacktrace_detected == 1 and is_some_issue_present == 0:
            logger.info("Can't identify crash issue")
            logger.info(issues)
            logger.info(crash_lines)
            logger.info(asan_output)
            assert False
        assert len(issues) == len(crash_lines)
        return [issues, crash_lines]


def check_crashes(file, outpath):
    if not os.path.exists(outpath):
        return
    print("Searching following path "+ outpath)
    dir = outpath
    count = 0
    my_env = os.environ
    my_env["ASAN_OPTIONS"] = "halt_on_error=0:detect_leaks=1"
    my_env["FIXREVERTER"] = "off"
    for path in tqdm(os.listdir(dir)):
        if os.path.isfile(os.path.join(dir, path)):
            # print(path)
            time = os.path.getmtime(os.path.join(dir, path)) 
            count = count + 1
            try:
                p = subprocess.run(
                    [file, os.path.join(dir, path), "-timeout=10"],
                    stdin=subprocess.PIPE,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    env = my_env,
                    timeout = 5
                )
            except subprocess.TimeoutExpired:
                continue
            asan_output = p.stderr.decode("utf-8")
            # print(asan_output)
            [issues, crash_lines] = identify_crash_line(asan_output, file, time)
            confirm_triggers(asan_output, time)
            # if count == 1:
            #     break
    # removing count of default.profraw files
    count = count - 2
    print("Processed these many files: " + str(count))

def afl_crash_dir(path):
    dir_list = []
    if not os.path.exists(outpath):
        return dir_list
    for directory in os.listdir(path):
        if os.path.isdir(os.path.join(path,directory)):
            dir_list.append(os.path.join(path,directory))
    return dir_list




bin_file = "./zstd/tests/fuzz/stream_decompress"
outpath = "./aflgo-fuzz-seeds/zstd-fuzz-noseeds-7days"
for directory in afl_crash_dir(outpath):
    print(directory)
    check_crashes(bin_file, directory)

import pickle

# obj0, obj1, obj2 are created here...

# Saving the objects:
with open('zstd-vars.pkl', 'wb') as f:  # Python 3: open(..., 'wb')
    pickle.dump([trig_bugs, reach_bugs, crashes, crash_types], f)

# print(dict(sorted(trig_bugs.items())))
max_value = max(trig_bugs.values())
min_value = min(reach_bugs.values())
print(min_value, max_value)  # Output: 5 30
# print(dict(sorted(reach_bugs.items())))
# print(dict(sorted(crashes.items())))
# print(dict(sorted(crash_types.items())))
print("Found unique crashes overall : " + str(len(crash_types)))