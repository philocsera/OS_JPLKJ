// osdoc — natural-language diagnostic helper.
//
// Usage:
//   osdoc <natural language question>
//
// Flow:
//   1. Forward the question to the host bridge as "<<DOC>> <question>".
//   2. Bridge resolves it to a trace bitmask and an observation duration,
//      replies with "<<TRACE_MASK>> <hex_mask> <ticks>".
//   3. osdoc enables tracing, pauses for that many ticks, disables it.
//   4. The kernel printf trace lines (prefixed `<<TRACE>>`) appear on
//      stdout during the observation window; bridge collects them and
//      prints a natural-language summary back to the user.
//
// Without an attached bridge, you can pass `--mask <hex>` directly to
// exercise the same code path.

#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/syscall.h"
#include "user/user.h"

#define LINEBUF 256

static int
parse_hex(const char *s)
{
  int v = 0;
  if(s[0] == '0' && (s[1] == 'x' || s[1] == 'X'))
    s += 2;
  while(*s){
    char c = *s++;
    int d;
    if(c >= '0' && c <= '9') d = c - '0';
    else if(c >= 'a' && c <= 'f') d = 10 + c - 'a';
    else if(c >= 'A' && c <= 'F') d = 10 + c - 'A';
    else break;
    v = (v << 4) | d;
  }
  return v;
}

static void
observe(int mask, int ticks)
{
  printf("osdoc: enabling trace mask 0x%x for %d ticks\n", mask, ticks);
  if(trace(mask) < 0){
    fprintf(2, "osdoc: trace() failed\n");
    exit(1);
  }
  if(ticks > 0)
    pause(ticks);
  trace(0);
  printf("<<DOC_END>>\n");
}

int
main(int argc, char *argv[])
{
  // Direct mode: `osdoc --mask 0x42 --ticks 50`.
  if(argc >= 3 && strcmp(argv[1], "--mask") == 0){
    int mask = parse_hex(argv[2]);
    int ticks = (argc >= 5 && strcmp(argv[3], "--ticks") == 0)
                  ? atoi(argv[4]) : 30;
    observe(mask, ticks);
    exit(0);
  }

  if(argc < 2){
    fprintf(2, "usage: osdoc <question>\n");
    fprintf(2, "       osdoc --mask <hex> [--ticks N]\n");
    exit(1);
  }

  // Send question to bridge.
  printf("<<DOC>>");
  for(int i = 1; i < argc; i++)
    printf(" %s", argv[i]);
  printf("\n");

  // Wait for "<<TRACE_MASK>> <hex> <ticks>".
  char line[LINEBUF];
  if(gets(line, LINEBUF) == 0){
    fprintf(2, "osdoc: no reply from bridge\n");
    exit(1);
  }
  int len = strlen(line);
  while(len > 0 && (line[len-1] == '\n' || line[len-1] == '\r'))
    line[--len] = 0;

  // Hand-rolled parse so we don't pull in libc strtok.
  char *p = line;
  while(*p && *p != ' ') p++;        // skip tag
  while(*p == ' ') p++;
  char *mask_s = p;
  while(*p && *p != ' ') p++;
  if(*p) *p++ = 0;
  while(*p == ' ') p++;
  int ticks = (*p) ? atoi(p) : 30;
  int mask = parse_hex(mask_s);
  if(mask == 0){
    fprintf(2, "osdoc: bridge returned empty mask, aborting\n");
    exit(1);
  }
  observe(mask, ticks);
  exit(0);
}
