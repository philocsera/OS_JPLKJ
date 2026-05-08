// schedhint — proc-table observer + LLM-driven priority adjuster.
//
// Single-shot mode: dump a proc table snapshot to stdout, ask the bridge
// for a priority hint, and apply it (with safety clamps).
//
// Output format (parsed by bridge.py):
//   <<PROCS>>
//   pid name state priority run_ticks sleep_ticks
//   ...
//   <<PROCS_END>>
//
// Expected reply (one of):
//   <<SETPRI>> <pid> <delta>      # delta in [-5, +5]
//   <<NOOP>>                      # bridge declined to act
//
// Safety guards (kernel-level setpriority already validates [0,20]):
//   * delta is clamped to +/- 5 to limit how much the LLM can move a proc
//   * pid 1 (init) and pid 2 (sh, in xv6's normal boot order) cannot have
//     their priority raised above 5 — keeps the system shell responsive
//     and prevents the LLM from starving the only login channel
//   * setpriority below 1 is rejected client-side as an extra layer

#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#define MAX_PROCS 64
#define LINEBUF 128

static const char *state_name(int s) {
  switch(s){
  case 0: return "UNUSED";
  case 1: return "USED";
  case 2: return "SLEEP";
  case 3: return "RUNBL";
  case 4: return "RUN";
  case 5: return "ZOMB";
  default: return "?";
  }
}

// Parse a non-negative int from *pp; advance *pp past it. Returns -1 if
// no digit found. Skips leading spaces.
static int
parse_int(char **pp)
{
  char *p = *pp;
  while(*p == ' ') p++;
  int sign = 1;
  if(*p == '-'){ sign = -1; p++; }
  if(*p < '0' || *p > '9'){ *pp = p; return -1; }
  int v = 0;
  while(*p >= '0' && *p <= '9'){
    v = v * 10 + (*p - '0');
    p++;
  }
  *pp = p;
  return sign * v;
}

// Apply a priority delta with safety clamps. Returns 0 on success.
static int
apply_hint(int pid, int delta)
{
  if(delta > 5) delta = 5;
  if(delta < -5) delta = -5;

  int cur = getpriority(pid);
  if(cur < 0){
    fprintf(2, "schedhint: pid %d not found\n", pid);
    return -1;
  }
  int new_prio = cur + delta;
  if(new_prio < 0) new_prio = 0;
  if(new_prio > 20) new_prio = 20;

  // Critical procs (init=1, sh=2) cannot be sent below priority 5.
  if((pid == 1 || pid == 2) && new_prio < 5)
    new_prio = 5;
  // Belt-and-suspenders: forbid the strict highest priority for any
  // LLM-driven adjustment.
  if(new_prio < 1)
    new_prio = 1;

  if(setpriority(pid, new_prio) < 0){
    fprintf(2, "schedhint: setpriority(%d, %d) failed\n", pid, new_prio);
    return -1;
  }
  printf("schedhint: pid=%d priority %d -> %d\n", pid, cur, new_prio);
  return 0;
}

int
main(int argc, char *argv[])
{
  static struct proc_info procs[MAX_PROCS];
  int n = proclist(procs, MAX_PROCS);
  if(n < 0){
    fprintf(2, "schedhint: proclist syscall failed\n");
    exit(1);
  }

  printf("<<PROCS>>\n");
  for(int i = 0; i < n; i++){
    printf("%d %s %s %d %ld %ld\n",
           procs[i].pid,
           procs[i].name,
           state_name(procs[i].state),
           procs[i].priority,
           (long)procs[i].run_ticks,
           (long)procs[i].sleep_ticks);
  }
  printf("<<PROCS_END>>\n");

  // If invoked with explicit args (`schedhint <pid> <delta>`), skip
  // the bridge round-trip — useful for unit testing.
  if(argc == 3){
    int pid = atoi(argv[1]);
    int delta = atoi(argv[2]);
    return apply_hint(pid, delta) ? 1 : 0;
  }

  // Otherwise read one line from stdin, expecting an <<SETPRI>> reply.
  char line[LINEBUF];
  if(gets(line, LINEBUF) == 0){
    fprintf(2, "schedhint: no reply from bridge\n");
    exit(1);
  }
  int len = strlen(line);
  while(len > 0 && (line[len-1] == '\n' || line[len-1] == '\r'))
    line[--len] = 0;

  if(strcmp(line, "<<NOOP>>") == 0){
    printf("schedhint: bridge says NOOP\n");
    exit(0);
  }

  // Expect "<<SETPRI>> <pid> <delta>".
  char *p = line;
  if(strcmp(line, "") == 0 || line[0] != '<'){
    fprintf(2, "schedhint: unexpected reply: %s\n", line);
    exit(1);
  }
  // Skip the tag.
  while(*p && *p != ' ') p++;
  int pid = parse_int(&p);
  int delta = parse_int(&p);
  if(pid <= 0){
    fprintf(2, "schedhint: bad pid in reply: %s\n", line);
    exit(1);
  }
  exit(apply_hint(pid, delta) ? 1 : 0);
}
