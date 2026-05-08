// llmsh — natural-language shell for xv6.
//
// Protocol with the host-side bridge.py (see bridge/bridge.py):
//   user types a line of natural language
//      |
//      v
//   llmsh writes:  "<<LLM>> <text>\n" on stdout
//      |  (host bridge captures, calls Solar API, returns JSON)
//      v
//   bridge writes: "<<EXEC>> <argv0> [arg1] [arg2] ...\n" to stdin
//      |
//      v
//   llmsh validates argv0 against an allow-list, fork()/exec()s it.
//
// If the bridge is not attached, the user can prefix a line with `!` to
// run the rest of it as a literal command (escape hatch for offline use).
//
// Whitelist is hard-coded so a misbehaving LLM cannot reach destructive
// or unimplemented syscalls. Any argv0 outside the list is rejected.

#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/fcntl.h"
#include "user/user.h"

#define LINEBUF 256
#define MAXARGS 16

static char *whitelist[] = {
  "ls", "cat", "echo", "grep", "wc", "mkdir", "rm", "ln",
  "sysinfo_test", "trace_test", "priority_test", "schedhint", "osdoc",
  0
};

static int
allowed(const char *cmd)
{
  for(int i = 0; whitelist[i]; i++)
    if(strcmp(cmd, whitelist[i]) == 0)
      return 1;
  return 0;
}

// Split `line` on spaces in place; fill argv[] with up to MAXARGS-1
// pointers, terminated by a 0. Returns argc.
static int
split(char *line, char **argv)
{
  int argc = 0;
  char *p = line;

  while(*p && argc < MAXARGS - 1){
    while(*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r')
      *p++ = 0;
    if(*p == 0)
      break;
    argv[argc++] = p;
    while(*p && *p != ' ' && *p != '\t' && *p != '\n' && *p != '\r')
      p++;
  }
  argv[argc] = 0;
  return argc;
}

static int
starts_with(const char *s, const char *prefix)
{
  while(*prefix){
    if(*s++ != *prefix++)
      return 0;
  }
  return 1;
}

// Run a command described by argv. Forks a child; parent waits.
static void
run_argv(char **argv)
{
  if(!allowed(argv[0])){
    fprintf(2, "llmsh: %s not in whitelist, refusing\n", argv[0]);
    return;
  }
  int pid = fork();
  if(pid < 0){
    fprintf(2, "llmsh: fork failed\n");
    return;
  }
  if(pid == 0){
    exec(argv[0], argv);
    fprintf(2, "llmsh: exec %s failed\n", argv[0]);
    exit(1);
  }
  wait(0);
}

int
main(void)
{
  char line[LINEBUF];
  char *argv[MAXARGS];

  printf("llmsh: natural-language shell, prefix `!` for literal exec.\n");
  printf("       type `exit` to quit.\n");

  for(;;){
    printf("nl> ");
    if(gets(line, LINEBUF) == 0 || line[0] == 0)
      break;

    // Strip trailing newline so prefix checks behave.
    int n = strlen(line);
    while(n > 0 && (line[n-1] == '\n' || line[n-1] == '\r'))
      line[--n] = 0;
    if(n == 0)
      continue;

    if(strcmp(line, "exit") == 0)
      break;

    // `!cmd args...` — direct execution, bypassing the LLM.
    if(line[0] == '!'){
      if(split(line + 1, argv) > 0)
        run_argv(argv);
      continue;
    }

    // EXEC reply directly typed by a user (mostly for testing).
    if(starts_with(line, "<<EXEC>>")){
      char *rest = line + 8;
      while(*rest == ' ') rest++;
      if(split(rest, argv) > 0)
        run_argv(argv);
      continue;
    }

    // Default path: hand the line to the bridge as an LLM request,
    // then wait for an <<EXEC>> reply on the next stdin line.
    printf("<<LLM>> %s\n", line);

    if(gets(line, LINEBUF) == 0)
      break;
    n = strlen(line);
    while(n > 0 && (line[n-1] == '\n' || line[n-1] == '\r'))
      line[--n] = 0;

    if(starts_with(line, "<<EXEC>>")){
      char *rest = line + 8;
      while(*rest == ' ') rest++;
      if(split(rest, argv) > 0)
        run_argv(argv);
    } else if(starts_with(line, "<<DENY>>")){
      // Bridge refused the request (policy or schema violation).
      fprintf(2, "llmsh: bridge denied request: %s\n", line + 8);
    } else {
      fprintf(2, "llmsh: unexpected reply, expected <<EXEC>>: %s\n", line);
    }
  }

  exit(0);
}
