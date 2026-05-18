#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"
#include "procstat.h"
#include "vm.h"

extern struct proc proc[];

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  kexit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return kfork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return kwait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int t;
  int n;

  argint(0, &n);
  argint(1, &t);
  addr = myproc()->sz;

  if(t == SBRK_EAGER || n < 0) {
    if(growproc(n) < 0) {
      return -1;
    }
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    if(addr + n < addr)
      return -1;
    if(addr + n > TRAPFRAME)
      return -1;
    myproc()->sz += n;
  }
  return addr;
}

uint64
sys_pause(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  if(n < 0)
    n = 0;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kkill(pid);
}

uint64
sys_setpriority(void)
{
  int pid, priority;

  argint(0, &pid);
  argint(1, &priority);

  // Validate priority range [0, 20]
  if(priority < 0 || priority > 20)
    return -1;

  // Find the process with the given pid and set its priority
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++) {
    acquire(&p->lock);
    if(p->pid == pid) {
      p->priority = priority;
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;  // pid not found
}

uint64
sys_getpriority(void)
{
  int pid;

  argint(0, &pid);

  // Find the process with the given pid and return its priority
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++) {
    acquire(&p->lock);
    if(p->pid == pid) {
      int prio = p->priority;
      release(&p->lock);
      return prio;
    }
    release(&p->lock);
  }
  return -1;  // pid not found
}

// ---------------------------------------------------------------------------
// LLM advisor syscalls. See report/week10/조현성/process.md.
//
// The kernel never calls the LLM; these syscalls are the *interface*
// that a userspace advisord uses to read procstat and write back
// policy state (class / quantum / priority). All five together form
// the "read snapshot, classify, write classification" loop sketched
// in process.md §3.
// ---------------------------------------------------------------------------

uint64
sys_setclass(void)
{
  int pid, class_id;
  argint(0, &pid);
  argint(1, &class_id);
  return proc_setclass(pid, class_id);
}

uint64
sys_setquantum(void)
{
  int pid, q;
  argint(0, &pid);
  argint(1, &q);
  return proc_setquantum(pid, q);
}

uint64
sys_getprocstat(void)
{
  int pid;
  uint64 uaddr;
  struct procstat ps;

  argint(0, &pid);
  argaddr(1, &uaddr);

  if(procstat_get(pid, &ps) < 0)
    return -1;
  if(copyout(myproc()->pagetable, uaddr, (char *)&ps, sizeof(ps)) < 0)
    return -1;
  return 0;
}

uint64
sys_getprocstat_all(void)
{
  uint64 uaddr;
  int max;
  struct procstat buf[PROCSTAT_MAX];
  int n;

  argaddr(0, &uaddr);
  argint(1, &max);

  if(max <= 0)
    return -1;
  if(max > PROCSTAT_MAX)
    max = PROCSTAT_MAX;

  n = procstat_all(buf, max);
  if(copyout(myproc()->pagetable, uaddr,
             (char *)buf, n * sizeof(struct procstat)) < 0)
    return -1;
  return n;
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}
