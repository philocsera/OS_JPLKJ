#define SBRK_ERROR ((char *)-1)

struct stat;
struct sysinfo;

// Snapshot of one entry from the kernel proc table, returned by proclist().
// Keep in sync with `struct proc_info` in kernel/proc.h.
struct proc_info {
  int pid;
  int state;          // 0=UNUSED 1=USED 2=SLEEPING 3=RUNNABLE 4=RUNNING 5=ZOMBIE
  int priority;
  int _pad;
  unsigned long long run_ticks;
  unsigned long long sleep_ticks;
  char name[16];
};

// system calls
int fork(void);
int exit(int) __attribute__((noreturn));
int wait(int*);
int pipe(int*);
int write(int, const void*, int);
int read(int, void*, int);
int close(int);
int kill(int);
int exec(const char*, char**);
int open(const char*, int);
int mknod(const char*, short, short);
int unlink(const char*);
int fstat(int fd, struct stat*);
int link(const char*, const char*);
int mkdir(const char*);
int chdir(const char*);
int dup(int);
int getpid(void);
char* sys_sbrk(int,int);
int pause(int);
int uptime(void);
int setpriority(int, int);
int getpriority(int);
int trace(int);
int sysinfo(struct sysinfo *);
int proclist(struct proc_info *, int);

// ulib.c
int stat(const char*, struct stat*);
char* strcpy(char*, const char*);
void *memmove(void*, const void*, int);
char* strchr(const char*, char c);
int strcmp(const char*, const char*);
char* gets(char*, int max);
uint strlen(const char*);
void* memset(void*, int, uint);
int atoi(const char*);
int memcmp(const void *, const void *, uint);
void *memcpy(void *, const void *, uint);
char* sbrk(int);
char* sbrklazy(int);

// printf.c
void fprintf(int, const char*, ...) __attribute__ ((format (printf, 2, 3)));
void printf(const char*, ...) __attribute__ ((format (printf, 1, 2)));

// umalloc.c
void* malloc(uint);
void free(void*);
