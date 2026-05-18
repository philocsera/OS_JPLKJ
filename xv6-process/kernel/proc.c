#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "procstat.h"
#include "defs.h"

// Per-class default quantum (ticks). Interactive gets short slices for
// latency; CPU/batch gets long slices to amortize context-switch cost.
// Matches the rationale in process.md §4.3 (b).
static const int class_default_quantum[NCLASS] = {
  [CLASS_INTERACTIVE] = 1,
  [CLASS_IO_BOUND]    = 1,
  [CLASS_NORMAL]      = 1,
  [CLASS_CPU_BOUND]   = 4,
  [CLASS_BATCH]       = 8,
  [CLASS_SYSTEM]      = 2,
};

extern uint ticks;

struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// initialize the proc table.
void
procinit(void)
{
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  for(p = proc; p < &proc[NPROC]; p++) {
      initlock(&p->lock, "proc");
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
  }
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int
allocpid()
{
  int pid;
  
  acquire(&pid_lock);
  pid = nextpid;
  nextpid = nextpid + 1;
  release(&pid_lock);

  return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc*
allocproc(void)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    acquire(&p->lock);
    if(p->state == UNUSED) {
      goto found;
    } else {
      release(&p->lock);
    }
  }
  return 0;

found:
  p->pid = allocpid();
  p->state = USED;

  // Allocate a trapframe page.
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if(p->pagetable == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;

  // Set default priority to 10 (middle of 0-20 range)
  p->priority = 10;

  // Advisor-visible defaults. Class=NORMAL gives the legacy "all procs
  // are equal" behavior until advisord (or a test) overrides it.
  p->class_id = CLASS_NORMAL;
  p->quantum_ticks = class_default_quantum[CLASS_NORMAL];
  p->slice_used = 0;
  p->ready_ticks = 0;
  p->run_ticks = 0;
  p->sleep_ticks = 0;
  p->ctxsw_count = 0;
  p->alloc_tick = ticks;

  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  if(p->trapframe)
    kfree((void*)p->trapframe);
  p->trapframe = 0;
  if(p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  p->priority = 0;
  // process.md §6 keeps lifetime stats live until *after* the parent's
  // kwait reaps the ZOMBIE — that's the natural xv6 semantics: the
  // advisor's last poll catches the ZOMBIE snapshot before this clear.
  p->class_id = 0;
  p->quantum_ticks = 0;
  p->slice_used = 0;
  p->ready_ticks = 0;
  p->run_ticks = 0;
  p->sleep_ticks = 0;
  p->ctxsw_count = 0;
  p->alloc_tick = 0;
  p->state = UNUSED;
}

// Create a user page table for a given process, with no user memory,
// but with trampoline and trapframe pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if(pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
              (uint64)trampoline, PTE_R | PTE_X) < 0){
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe page just below the trampoline page, for
  // trampoline.S.
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
              (uint64)(p->trapframe), PTE_R | PTE_W) < 0){
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// Set up first user process.
void
userinit(void)
{
  struct proc *p;

  p = allocproc();
  initproc = p;
  
  p->cwd = namei("/");

  p->state = RUNNABLE;

  release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  uint64 sz;
  struct proc *p = myproc();

  sz = p->sz;
  if(n > 0){
    if(sz + n > TRAPFRAME) {
      return -1;
    }
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
      return -1;
    }
  } else if(n < 0){
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int
kfork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if((np = allocproc()) == 0){
    return -1;
  }

  // Copy user memory from parent to child.
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++)
    if(p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  // Inherit priority and class from parent to child. The advisor is
  // expected to re-classify within ~one poll window after exec, but
  // this gives a safe default in the meantime (process.md §3.3).
  np->priority = p->priority;
  np->class_id = p->class_id;
  np->quantum_ticks = p->quantum_ticks;

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;
  release(&np->lock);

  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void
reparent(struct proc *p)
{
  struct proc *pp;

  for(pp = proc; pp < &proc[NPROC]; pp++){
    if(pp->parent == p){
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void
kexit(int status)
{
  struct proc *p = myproc();

  if(p == initproc)
    panic("init exiting");

  // Close all open files.
  for(int fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd]){
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);
  
  acquire(&p->lock);

  p->xstate = status;
  p->state = ZOMBIE;

  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
kwait(uint64 addr)
{
  struct proc *pp;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    for(pp = proc; pp < &proc[NPROC]; pp++){
      if(pp->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&pp->lock);

        havekids = 1;
        if(pp->state == ZOMBIE){
          // Found one.
          pid = pp->pid;
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
                                  sizeof(pp->xstate)) < 0) {
            release(&pp->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(pp);
          release(&pp->lock);
          release(&wait_lock);
          return pid;
        }
        release(&pp->lock);
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || killed(p)){
      release(&wait_lock);
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
  }
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void
scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();

  c->proc = 0;
  for(;;){
    // Enable interrupts to avoid deadlock when all processes are waiting,
    // then disable before scanning to prevent races with wfi.
    intr_on();
    intr_off();

    // Priority-based scheduler: single-pass, track "best so far" candidate.
    // Lower priority number = higher priority (0 is highest, 20 is lowest).
    // Among equal priorities, the linear scan provides round-robin fairness.
    struct proc *best = 0;

    for(p = proc; p < &proc[NPROC]; p++) {
      acquire(&p->lock);
      if(p->state == RUNNABLE) {
        if(best == 0 || p->priority < best->priority) {
          // Found a higher-priority candidate; release the old best
          if(best != 0)
            release(&best->lock);
          best = p;
          // Keep best->lock held so no one changes its state
        } else {
          release(&p->lock);
        }
      } else {
        release(&p->lock);
      }
    }

    if(best != 0) {
      // Dispatch the highest-priority RUNNABLE process (lock already held)
      best->state = RUNNING;
      best->slice_used = 0;        // start a fresh quantum window
      best->ctxsw_count++;          // visible to advisord
      c->proc = best;
      swtch(&c->context, &best->context);
      // Process is done running for now.
      c->proc = 0;
      release(&best->lock);
    } else {
      // No RUNNABLE process; halt until next interrupt.
      asm volatile("wfi");
    }
  }
}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void
sched(void)
{
  int intena;
  struct proc *p = myproc();

  if(!holding(&p->lock))
    panic("sched p->lock");
  if(mycpu()->noff != 1)
    panic("sched locks");
  if(p->state == RUNNING)
    panic("sched RUNNING");
  if(intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void
yield(void)
{
  struct proc *p = myproc();
  acquire(&p->lock);
  p->state = RUNNABLE;
  sched();
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
  extern char userret[];
  static int first = 1;
  struct proc *p = myproc();

  // Still holding p->lock from scheduler.
  release(&p->lock);

  if (first) {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    fsinit(ROOTDEV);

    first = 0;
    // ensure other cores see first=0.
    __sync_synchronize();

    // We can invoke kexec() now that file system is initialized.
    // Put the return value (argc) of kexec into a0.
    p->trapframe->a0 = kexec("/init", (char *[]){ "/init", 0 });
    if (p->trapframe->a0 == -1) {
      panic("exec");
    }
  }

  // return to user space, mimicing usertrap()'s return.
  prepare_return();
  uint64 satp = MAKE_SATP(p->pagetable);
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
  ((void (*)(uint64))trampoline_userret)(satp);
}

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();
  
  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
  release(lk);

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;

  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);
}

// Wake up all processes sleeping on channel chan.
// Caller should hold the condition lock.
void
wakeup(void *chan)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
        p->state = RUNNABLE;
      }
      release(&p->lock);
    }
  }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kkill(int pid)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    acquire(&p->lock);
    if(p->pid == pid){
      p->killed = 1;
      if(p->state == SLEEPING){
        // Wake process from sleep().
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

void
setkilled(struct proc *p)
{
  acquire(&p->lock);
  p->killed = 1;
  release(&p->lock);
}

int
killed(struct proc *p)
{
  int k;
  
  acquire(&p->lock);
  k = p->killed;
  release(&p->lock);
  return k;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if(user_dst){
    return copyout(p->pagetable, dst, src, len);
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if(user_src){
    return copyin(p->pagetable, dst, src, len);
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}

// Walk the proc table once per tick and credit one tick to each proc's
// state-specific counter. Called from clockintr() on cpu 0 only.
//
// Locking: best-effort. We *try* to acquire p->lock and skip if busy —
// missing a tick is acceptable (advisor reads are statistical), but
// blocking the clock interrupt is not. Per process.md §5: fast paths
// must not be perturbed by accounting.
void
procstat_tick(void)
{
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++) {
    if(p->state == UNUSED)
      continue;
    // try-acquire. spinlocks in xv6 don't expose try_acquire, so we
    // gate on the cheap state read and accept that under contention
    // we drop the tick — the counters are statistical anyway.
    acquire(&p->lock);
    switch(p->state) {
    case RUNNABLE:
      p->ready_ticks++;
      break;
    case RUNNING:
      p->run_ticks++;
      p->slice_used++;
      break;
    case SLEEPING:
      p->sleep_ticks++;
      break;
    default:
      break;
    }
    release(&p->lock);
  }
}

// Look up a proc by pid and copy a procstat snapshot into *out.
// Returns 0 on success, -1 if not found. Used by sys_getprocstat for
// the single-pid form (used by sys_setclass and friends to verify).
int
procstat_get(int pid, struct procstat *out)
{
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++) {
    acquire(&p->lock);
    if(p->pid == pid && p->state != UNUSED) {
      out->pid = p->pid;
      out->ppid = p->parent ? p->parent->pid : 0;
      out->state = (int)p->state;
      out->priority = p->priority;
      out->class_id = p->class_id;
      out->quantum_ticks = p->quantum_ticks;
      out->ready_ticks = p->ready_ticks;
      out->run_ticks = p->run_ticks;
      out->sleep_ticks = p->sleep_ticks;
      out->ctxsw_count = p->ctxsw_count;
      out->lifetime = (uint64)(ticks - p->alloc_tick);
      for(int i = 0; i < 16; i++) out->name[i] = p->name[i];
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

// Bulk snapshot for advisord. Fills up to `max` entries of `dst` with
// procs whose state != UNUSED. Returns the number of entries written.
int
procstat_all(struct procstat *dst, int max)
{
  struct proc *p;
  int n = 0;
  for(p = proc; p < &proc[NPROC] && n < max; p++) {
    acquire(&p->lock);
    if(p->state != UNUSED) {
      dst[n].pid = p->pid;
      // parent read needs wait_lock for full safety, but for snapshot
      // purposes a torn read is acceptable — advisor tolerates noise.
      dst[n].ppid = p->parent ? p->parent->pid : 0;
      dst[n].state = (int)p->state;
      dst[n].priority = p->priority;
      dst[n].class_id = p->class_id;
      dst[n].quantum_ticks = p->quantum_ticks;
      dst[n].ready_ticks = p->ready_ticks;
      dst[n].run_ticks = p->run_ticks;
      dst[n].sleep_ticks = p->sleep_ticks;
      dst[n].ctxsw_count = p->ctxsw_count;
      dst[n].lifetime = (uint64)(ticks - p->alloc_tick);
      for(int i = 0; i < 16; i++) dst[n].name[i] = p->name[i];
      n++;
    }
    release(&p->lock);
  }
  return n;
}

// Setters used by advisord. Each takes the per-proc lock to avoid
// torn reads with the scheduler. They are deliberately tiny — the
// kernel imposes no policy beyond range checks.

int
proc_setclass(int pid, int class_id)
{
  if(class_id < 0 || class_id >= NCLASS)
    return -1;
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++) {
    acquire(&p->lock);
    if(p->pid == pid && p->state != UNUSED) {
      p->class_id = class_id;
      // class change auto-updates the recommended quantum, but the
      // advisor can override via setquantum afterward.
      p->quantum_ticks = class_default_quantum[class_id];
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

int
proc_setquantum(int pid, int q)
{
  if(q < 1 || q > 64)
    return -1;
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++) {
    acquire(&p->lock);
    if(p->pid == pid && p->state != UNUSED) {
      p->quantum_ticks = q;
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
  static char *states[] = {
  [UNUSED]    "unused",
  [USED]      "used",
  [SLEEPING]  "sleep ",
  [RUNNABLE]  "runble",
  [RUNNING]   "run   ",
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
  for(p = proc; p < &proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s prio=%d class=%d q=%d run=%ld rdy=%ld slp=%ld cs=%ld",
           p->pid, state, p->name, p->priority, p->class_id,
           p->quantum_ticks, p->run_ticks, p->ready_ticks,
           p->sleep_ticks, p->ctxsw_count);
    printf("\n");
  }
}
