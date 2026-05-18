// advstat — print the current procstat table once and exit.
//
// Companion to advisord. Lets a human inspect what the advisor sees,
// which is useful for verifying that the kernel counters are wired up
// before trusting any classification decisions.

#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/procstat.h"
#include "user/user.h"

static const char *
class_name(int c)
{
  switch(c) {
  case CLASS_INTERACTIVE: return "INT";
  case CLASS_IO_BOUND:    return "IO ";
  case CLASS_NORMAL:      return "NRM";
  case CLASS_CPU_BOUND:   return "CPU";
  case CLASS_BATCH:       return "BAT";
  case CLASS_SYSTEM:      return "SYS";
  default:                return "???";
  }
}

static const char *
state_name(int s)
{
  switch(s) {
  case PS_UNUSED:   return "unused";
  case PS_USED:     return "used  ";
  case PS_SLEEPING: return "sleep ";
  case PS_RUNNABLE: return "runble";
  case PS_RUNNING:  return "run   ";
  case PS_ZOMBIE:   return "zombie";
  default:          return "??????";
  }
}

int
main(int argc, char *argv[])
{
  struct procstat buf[PROCSTAT_MAX];
  int n = getprocstat_all(buf, PROCSTAT_MAX);
  if(n < 0) {
    printf("advstat: getprocstat_all failed\n");
    exit(1);
  }

  printf("pid ppid state  name             prio cls quan   run   rdy   slp   cs life\n");
  for(int i = 0; i < n; i++) {
    struct procstat *p = &buf[i];
    printf("%3d %4d %s %-16s %3d %s %3d %5ld %5ld %5ld %4ld %4ld\n",
           p->pid, p->ppid, state_name(p->state), p->name,
           p->priority, class_name(p->class_id), p->quantum_ticks,
           p->run_ticks, p->ready_ticks, p->sleep_ticks,
           p->ctxsw_count, p->lifetime);
  }
  exit(0);
}
