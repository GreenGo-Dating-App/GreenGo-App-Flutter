#!/bin/bash
# usage: bash cycle.sh <finished-job> [n-new]  -> frees the job, imports its topic, prints n new jobs
cd "$(dirname "$0")"
job="$1"; n="${2:-1}"
python jobs.py done "$job" >/dev/null
topic=$(echo "$job" | cut -d: -f2)
case "$job" in plan:*) for t in $(echo "$topic" | tr ',' ' '); do python import_firestore.py "$t"; done;; *) python import_firestore.py "$topic";; esac
for i in $(seq 1 "$n"); do python jobs.py balanced; done
