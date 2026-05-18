// procstat.h — shared layout between kernel and the userspace LLM advisor.
//
// Reflects the design in report/week10/조현성/process.md:
//   - The kernel exposes per-process "policy state" (priority, class_id,
//     quantum_ticks) plus accumulated counters (ready_ticks, run_ticks,
//     sleep_ticks, ctxsw_count, lifetime_ticks).
//   - A userspace advisord polls these snapshots, classifies workloads,
//     and writes back priority/class/quantum.
//   - Kernel fast paths (scheduler RR loop, kfork/kexit/kwait) are not
//     restructured: only the values they read are now meaningful.
//
// The struct is also defined for user programs via user.h indirection.

#ifndef _PROCSTAT_H_
#define _PROCSTAT_H_

// Classification IDs used by the advisor. The kernel only stores the
// number; semantics live in userspace. Quantum mapping is in proc.c.
#define CLASS_INTERACTIVE 0
#define CLASS_IO_BOUND    1
#define CLASS_NORMAL      2   // default for new procs
#define CLASS_CPU_BOUND   3
#define CLASS_BATCH       4
#define CLASS_SYSTEM      5
#define NCLASS            6

#define PROCSTAT_MAX 64       // == NPROC; mirrored here for user code

// State codes, mirrored from enum procstate for user-space readability.
#define PS_UNUSED   0
#define PS_USED     1
#define PS_SLEEPING 2
#define PS_RUNNABLE 3
#define PS_RUNNING  4
#define PS_ZOMBIE   5

// Snapshot of a single process. Designed to be cheap to copy.
struct procstat {
  int pid;
  int ppid;
  int state;          // PS_* code (mirror of enum procstate)
  int priority;       // 0=highest .. 20=lowest (xv6 convention)
  int class_id;       // CLASS_*
  int quantum_ticks;  // dispatcher slice length advisor recommends
  uint64 ready_ticks; // ticks spent in RUNNABLE since allocproc
  uint64 run_ticks;   // ticks spent in RUNNING since allocproc
  uint64 sleep_ticks; // ticks spent in SLEEPING since allocproc
  uint64 ctxsw_count; // total context switches into this proc
  uint64 lifetime;    // ticks since allocproc (ready+run+sleep+used)
  char name[16];      // process name (set by exec)
};

#endif // _PROCSTAT_H_
