# Week 09 Comprehensive Report

## Overview

Each member independently studied xv6, and based on the findings, we explored the feasibility of an LLM-based OS development assistance system.

---

## 1. Current Limitations of xv6

| Area | Limitations |
|------|-------------|
| Scheduler | No priority support, no runtime tracking, no starvation detection |
| Memory | No swap, no OOM handling, no memory fairness |
| System Calls | Only 21 calls; no network or thread-related calls |
| Filesystem | No journaling, no performance optimization |

---

## 2. Contribution Summary by Member

| Member | Key Contributions |
|--------|-------------------|
| Kim Gyeongseon | Studied and summarized xv6 fundamentals (processes, system calls, scheduler, sleep/wakeup) |
| Park Gyutae | Analyzed the overall xv6 structure (pros/cons across 4 major areas, LLM applicability analysis) |
| Jo Seungchan | Summarized xv6 core concepts (overall flow, focus on interrupts and traps) |
| Jo Hyeonseong | Analyzed xv6 using Claude/Codex; derived ideas for a natural-language shell and AI-based scheduler |
| Lee Chanju | In-depth xv6 study (proc.h/c, priority scheduler design); proposed a deep verification architecture based on the Kgent paper |
