#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"
#include "vm.h"
#include "sysinfo.h"

extern struct proc proc[];

// Maximum proc_info entries returned in one sys_proclist call.
// Sized to NPROC (param.h) so a single snapshot covers the whole table.
#define PROCLIST_MAX NPROC

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

// Set the calling process's syscall trace mask.
// `mask` is a bitmap indexed by SYS_* numbers; bit n set means "log
// every invocation of syscall number n by this proc and its children".
uint64
sys_trace(void)
{
  int mask;
  argint(0, &mask);
  myproc()->trace_mask = mask;
  return 0;
}

// Copy a sysinfo struct (free memory + active proc count) to userspace.
uint64
sys_sysinfo(void)
{
  struct sysinfo info;
  uint64 addr;

  argaddr(0, &addr);
  info.freemem = freemem_count();
  info.nproc = proc_count();
  if(copyout(myproc()->pagetable, addr, (char *)&info, sizeof(info)) < 0)
    return -1;
  return 0;
}

// Snapshot the proc table into a user-supplied array.
//   arg0: user pointer to struct proc_info[]
//   arg1: max number of entries the caller's buffer can hold
// Returns the number of entries written, or -1 on copyout failure.
uint64
sys_proclist(void)
{
  uint64 uaddr;
  int max;
  static struct proc_info buf[PROCLIST_MAX];
  int n;

  argaddr(0, &uaddr);
  argint(1, &max);
  if(max <= 0)
    return 0;
  if(max > PROCLIST_MAX)
    max = PROCLIST_MAX;

  n = proclist_fill(buf, max);
  if(copyout(myproc()->pagetable, uaddr,
             (char *)buf, n * sizeof(struct proc_info)) < 0)
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
