// advisord — userspace "LLM advisor" skeleton for xv6.
//
// This is the runtime side of the design in
// report/week10/조현성/process.md. The *real* deployment would shell
// out to an LLM API or to a distilled classifier; in xv6 we only have
// printf, fork, and the new syscalls (getprocstat / setclass /
// setquantum / setpriority), so this binary stands in as a
// demonstration of the polling loop.
//
// Behavior:
//   1. Poll: getprocstat_all(buf, max) every ~500ms (we use pause(50)
//      since xv6's tick is ~100ms).
//   2. Classify each proc with the trivial heuristic below — exactly
//      where a real LLM call would go. The kernel doesn't care which
//      classifier produced the answer; it only sees the resulting
//      class_id / priority / quantum.
//   3. Write back via setclass and setpriority.
//
// Even with this *very* dumb classifier, the architecture is faithful
// to the design: the kernel fast path (scheduler / kfork / kexit) does
// not know advisord exists. If advisord dies, the system keeps running
// with whatever class/priority was last written (fail-static, §process.md).

#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/procstat.h"
#include "user/user.h"

#define POLL_TICKS  5     // xv6 tick is ~100ms → ~500ms cadence
#define MAX_PROCS   PROCSTAT_MAX

// A stand-in for the LLM. Looks at the procstat snapshot and picks a
// class. The thresholds are intentionally crude — a real advisor would
// have a richer feature set (name prior, syscall histogram, tree
// shape). The point is just to show what *kind* of decisions cross
// this boundary.
static int
classify(const struct procstat *ps)
{
  // Bootstrap window: too little data to classify confidently.
  if(ps->lifetime < 3)
    return CLASS_NORMAL;

  uint64 active = ps->run_ticks + ps->sleep_ticks;
  if(active == 0)
    return CLASS_NORMAL;

  // Sleep-heavy → likely IO / interactive.
  if(ps->sleep_ticks * 2 > active) {
    // crude name prior — see process.md §3.3
    if(strcmp(ps->name, "sh") == 0)
      return CLASS_INTERACTIVE;
    return CLASS_IO_BOUND;
  }
  // CPU-heavy → batch.
  if(ps->run_ticks * 4 > active)
    return CLASS_CPU_BOUND;
  return CLASS_NORMAL;
}

// Recommend a priority for a given class. Mirrors the example
// priorities cited in process.md §2.3.
static int
class_to_priority(int class_id)
{
  switch(class_id) {
  case CLASS_INTERACTIVE: return 4;
  case CLASS_IO_BOUND:    return 8;
  case CLASS_NORMAL:      return 10;
  case CLASS_CPU_BOUND:   return 12;
  case CLASS_BATCH:       return 15;
  case CLASS_SYSTEM:      return 6;
  default:                return 10;
  }
}

static const char *
class_name(int class_id)
{
  switch(class_id) {
  case CLASS_INTERACTIVE: return "INTERACTIVE";
  case CLASS_IO_BOUND:    return "IO_BOUND";
  case CLASS_NORMAL:      return "NORMAL";
  case CLASS_CPU_BOUND:   return "CPU_BOUND";
  case CLASS_BATCH:       return "BATCH";
  case CLASS_SYSTEM:      return "SYSTEM";
  default:                return "?";
  }
}

int
main(int argc, char *argv[])
{
  struct procstat buf[MAX_PROCS];
  int verbose = (argc > 1 && strcmp(argv[1], "-v") == 0);
  int my_pid = getpid();

  printf("advisord: starting (pid=%d, poll=%d ticks)\n", my_pid, POLL_TICKS);

  for(;;) {
    int n = getprocstat_all(buf, MAX_PROCS);
    if(n < 0) {
      printf("advisord: getprocstat_all failed\n");
      exit(1);
    }

    for(int i = 0; i < n; i++) {
      struct procstat *ps = &buf[i];
      // Never reclassify advisord itself — would race with the next poll.
      if(ps->pid == my_pid)
        continue;
      // init and the shell are too special to retag automatically.
      if(ps->pid <= 2)
        continue;

      int new_class = classify(ps);
      if(new_class == ps->class_id)
        continue;

      if(setclass(ps->pid, new_class) < 0)
        continue;
      int new_prio = class_to_priority(new_class);
      setpriority(ps->pid, new_prio);

      if(verbose) {
        printf("advisord: pid=%d name=%s %s -> %s (prio %d -> %d)\n",
               ps->pid, ps->name,
               class_name(ps->class_id), class_name(new_class),
               ps->priority, new_prio);
      }
    }

    pause(POLL_TICKS);
  }

  return 0;
}
