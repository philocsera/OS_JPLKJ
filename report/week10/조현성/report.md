# Week10 — xv6-process: LLM 어드바이저 인터페이스 구현 보고서

> 대상 코드베이스: `xv6-process/`
> 설계 모체: [`process.md`](./process.md)
> 작성일: 2026-05-18

---

## 0. 작업 한 줄 요약

`process.md`가 제시한 "LLM 어드바이저가 옆에 있는 xv6" 의 **커널 측 인터페이스 절반**을 구현했다. 즉, *advisor가 사용할* 정책 상태 필드와 syscall 묶음, 그리고 그 상태를 갱신하는 tick 회계를 커널에 박았다. 사용자 공간의 polling 데몬 (`advisord`) 도 데모 형태로 함께 추가했다. 단, **커널 fast path 자체의 로직은 그대로**이고 — `scheduler()` 의 단일 패스 best-priority 선정, `kfork()` 의 priority 상속, `kexit()`→ZOMBIE 시맨틱, `kwait()` 의 회수 흐름은 변경 없음. process.md §1 의 핵심 원칙 — "커널은 그대로, 그 함수가 *읽는 값* 의 품질만 달라진다" — 을 그대로 따른다.

빌드 결과: `make` (커널) / `make fs.img` (사용자 + fs) 모두 경고/에러 없이 통과. `riscv64-elf-ld: warning: kernel/kernel has a LOAD segment with RWX permissions` 는 변경 전부터 존재하던 xv6 원본 경고.

---

## 1. process.md 요구사항 → 작업 매핑

| process.md 절 | 요구사항 핵심 | 본 작업의 대응 |
|---|---|---|
| §2 `scheduler()` | priority 분포가 의미를 갖도록 advisor가 흔들 수 있어야 함 | `proc.priority` 는 기존 존재. 신규로 `class_id` / `quantum_ticks` / `slice_used` 추가. scheduler 의 RR best-pick 루프는 한 줄도 안 바꿈 — 다만 `ctxsw_count++` 만 추가해 advisor 가 dispatch 빈도를 관측 가능 |
| §3 `kfork()` | 자식이 부모 priority 상속, advisor 가 ~500ms 안에 재분류 | `kfork()` 에 `np->class_id = p->class_id;` / `np->quantum_ticks = p->quantum_ticks;` 추가 (priority 상속은 기존). 재분류는 사용자공간 `advisord` 가 담당 |
| §4 MLFQ + aging | quantum 이 컴파일타임 상수가 아니라 advisor 권장값이 되어야 함 | 클래스별 디폴트 quantum 테이블 (`class_default_quantum[NCLASS]`) + per-proc `quantum_ticks`. `usertrap()`/`kerneltrap()` 의 timer-yield 분기에서 `slice_used >= quantum_ticks` 일 때만 yield → CPU_BOUND/BATCH 는 더 긴 슬라이스 |
| §5 정적 priority | 같은 `setpriority` 가 500ms마다 호출되어 phase 전환을 따라잡음 | `setpriority` 기존 그대로. 신규 `setclass` 가 클래스 변경 시 quantum 도 함께 재계산해 phase 전환을 한 콜로 표현 |
| §6 `kexit` / `kwait` — lifetime 통계 | ZOMBIE 가 회수되기 전 한 번은 advisor 가 lifetime 스냅샷을 봄 | `procstat_all()` 이 ZOMBIE 도 포함. lifetime = `ticks - alloc_tick`. `freeproc()` 가 회수할 때 비로소 카운터가 클리어됨 — 즉 advisor 의 마지막 폴링 윈도우가 자연스럽게 lifetime 스냅샷이 됨 |
| §7 `allocproc` / fork bomb | fork rate 같은 집계 신호가 advisor 에 노출되어야 함 | `procstat.ctxsw_count` + per-proc `run_ticks` / `sleep_ticks` 누계가 `getprocstat_all` 로 흐름. 부모-자식 관계는 `procstat.ppid` 로 노출 → 사용자공간에서 "fork rate" 와 "트리 모양" 둘 다 추론 가능 |
| §8 `panic` 사후분석 | procstat 시계열을 ring buffer 로 보관 | 본 작업에선 미구현. `procdump()` 출력에 procstat 필드를 모두 인라인해 ^P 시 즉시 가시화 — panic 직전 상태 검증의 가장 가벼운 형태 |
| §9 bio.c | 비-스케줄러 영역도 같은 패턴 | 범위 밖 — process.md §9 도 일반론 |
| §10 못 하는 것 | fast path 침범 금지 / 결정성 보존 | tick 회계는 `procstat_tick()` 에 격리, `try` 가까운 best-effort 락. scheduler/sched/sleep/wakeup 모두 원형 보존. advisor 가 죽어도 마지막 priority/class/quantum 으로 계속 동작 (fail-static) |

---

## 2. 변경 파일 일람

### 2.1 신규 파일

| 파일 | 역할 |
|---|---|
| `kernel/procstat.h` | 커널/사용자 공유 헤더. `struct procstat`, `CLASS_*` 상수, `PS_*` 상태 코드, `PROCSTAT_MAX` 정의 |
| `user/advisord.c` | 사용자공간 advisor 데모 — `getprocstat_all → classify → setclass + setpriority` 폴링 루프 |
| `user/advstat.c` | 사람용 procstat 인스펙터 — 1회 출력 후 종료. advisor 가 보는 것을 사람이 그대로 보는 도구 |

### 2.2 수정된 커널 파일

| 파일 | 변경 요지 |
|---|---|
| `kernel/proc.h` | `struct proc` 에 `class_id` / `quantum_ticks` / `slice_used` / `ready_ticks` / `run_ticks` / `sleep_ticks` / `ctxsw_count` / `alloc_tick` 8개 필드 추가 |
| `kernel/proc.c` | 신규 필드 초기화·정리, `kfork` 의 class/quantum 상속, scheduler dispatch 시 `ctxsw_count++` 와 `slice_used = 0`, **신규 함수** `procstat_tick` / `procstat_get` / `procstat_all` / `proc_setclass` / `proc_setquantum`, 클래스별 디폴트 quantum 테이블, `procdump` 출력 확장 |
| `kernel/trap.c` | `clockintr()` 가 cpu 0 에서 `procstat_tick()` 호출, `usertrap()` / `kerneltrap()` timer-yield 가 `slice_used >= quantum_ticks` 조건으로 변경 (디폴트 quantum=1 이면 종전 동작과 동일) |
| `kernel/sysproc.c` | 신규 syscall 핸들러: `sys_setclass` / `sys_setquantum` / `sys_getprocstat` / `sys_getprocstat_all` |
| `kernel/syscall.h` | `SYS_setclass=24` / `SYS_setquantum=25` / `SYS_getprocstat=26` / `SYS_getprocstat_all=27` |
| `kernel/syscall.c` | 함수 extern 선언 + syscalls[] 테이블 4 entry 추가 |
| `kernel/defs.h` | `procstat_tick` / `procstat_get` / `procstat_all` / `proc_setclass` / `proc_setquantum` 의 헬퍼 프로토타입 |

### 2.3 수정된 사용자공간 파일

| 파일 | 변경 요지 |
|---|---|
| `user/user.h` | `setclass` / `setquantum` / `getprocstat` / `getprocstat_all` 프로토타입 + `struct procstat;` 전방 선언 |
| `user/usys.pl` | 4개 신규 syscall stub entry |
| `Makefile` | UPROGS 에 `_advisord` / `_advstat` 추가 |

---

## 3. 설계 상의 결정 — process.md 5원칙과 대응

process.md 가 끝까지 강조하는 원칙은 다음 5개다 (§5 / §12).
각 원칙이 본 구현 어디서 보장되는지 짚어둔다.

### 3.1 "Fast path 는 그대로"

`scheduler()` 의 핵심 RR best-pick 루프, `sched()`, `swtch()` 흐름, `sleep`/`wakeup`, `kfork` 의 자식 RUNNABLE 전이 — 한 줄도 안 바꿈. 추가된 것은:

- `scheduler()`: dispatch 직후 한 줄 `best->ctxsw_count++; best->slice_used = 0;`. 락은 어차피 잡혀 있으므로 추가 비용은 두 번의 64bit 쓰기뿐.
- `usertrap/kerneltrap`: 기존 `yield()` 직전에 한 줄 분기 `if(p->slice_used >= p->quantum_ticks)`. 디폴트 quantum=1 이면 모든 tick 에 참이므로 종전 동작과 동일.

### 3.2 "정책 상태의 품질만 바뀐다"

추가된 필드 (`class_id`, `quantum_ticks`, 카운터들) 는 **정책 상태**다. 커널은 그 값을 *해석* 하지 않는다 — class_id 가 5인지 7인지 커널은 의미를 모른다. 의미는 사용자공간 `advisord` 와 `class_default_quantum[]` 매핑에만 존재. 미래에 advisor 가 더 똑똑해져도 커널은 변경되지 않는다.

### 3.3 "결정성 회복 가능"

advisor 가 호출하는 모든 syscall (`setpriority/setclass/setquantum`) 은 단순 한 값 쓰기. 같은 trace 로 같은 값을 같은 시점에 쓰면 같은 결과. 사용자공간에서 *결정적* 분류기 (예: lookup table) 만 쓰면 전체 시스템이 결정적이다.

### 3.4 "Fail-static"

`advisord` 가 죽거나 영영 안 떠도, 모든 proc 는 `allocproc` 에서 `class_id = CLASS_NORMAL`, `quantum_ticks = 1` 을 받으므로 priority 만 사용하는 원래 RR 스케줄링이 그대로 작동. `usertrap` 도 디폴트 quantum=1 이면 매 tick yield = 원본 동작.

### 3.5 "Observable"

새로 추가된 procstat 의 8개 필드 + `procdump()` 의 ^P 출력이 정확히 advisor 가 보는 데이터를 사람도 볼 수 있게 한다. `advstat` 사용자 프로그램이 같은 syscall 로 동일한 스냅샷을 dump 하므로, advisor 의 판단을 사람이 검증할 수 있다.

---

## 4. 신규 자료구조 / 인터페이스 — 한눈에

### 4.1 `struct procstat` (커널 ↔ 사용자공간)

```c
struct procstat {
  int pid, ppid, state, priority, class_id, quantum_ticks;
  uint64 ready_ticks, run_ticks, sleep_ticks, ctxsw_count, lifetime;
  char name[16];
};
```

- 모든 카운터는 64-bit. xv6 의 1 tick≈100ms 기준으로 약 58억년 분량의 헤드룸 — overflow 걱정 없음.
- `state` 는 `enum procstate` 의 미러로 `PS_*` 상수를 따로 둔다 (사용자공간에서 enum 정의 노출 안 함).

### 4.2 클래스 ID

`CLASS_INTERACTIVE / IO_BOUND / NORMAL / CPU_BOUND / BATCH / SYSTEM` 6종. process.md §2/§3 의 예시와 1:1 대응. NCLASS=6.

### 4.3 클래스 → 디폴트 quantum 매핑 (커널 측 단 하나의 정책)

| 클래스 | quantum (ticks) | 이유 |
|---|---|---|
| INTERACTIVE | 1 | latency 우선 — 매 tick yield |
| IO_BOUND | 1 | sleep 빈번하므로 quantum 키울 필요 없음 |
| NORMAL | 1 | 원본 xv6 와 동등 |
| CPU_BOUND | 4 | 컨텍스트 스위치 비용 ↓ |
| BATCH | 8 | 백그라운드 throughput 우선 |
| SYSTEM | 2 | 짧되 약간의 여유 |

이 테이블이 커널이 "클래스 → 동작" 으로 매핑하는 *유일한* 자리다. 그 외 모든 의미 부여는 사용자공간에 격리.

### 4.4 신규 syscall

| 번호 | 시그니처 | 역할 |
|---|---|---|
| 24 | `int setclass(int pid, int class_id)` | 클래스 설정 + 디폴트 quantum 동기화 |
| 25 | `int setquantum(int pid, int q)` | quantum 만 별도 override (1..64) |
| 26 | `int getprocstat(int pid, struct procstat *out)` | 한 pid 의 스냅샷 |
| 27 | `int getprocstat_all(struct procstat *arr, int max)` | 비-UNUSED 모든 proc 의 스냅샷, 채운 개수 반환 |

기존 23 (`getpriority`) / 22 (`setpriority`) 는 그대로 사용. setclass 가 priority 까지 같이 안 바꾸도록 분리한 이유: process.md §5 의 phase 전환을 **클래스만** 으로 표현하고 싶은 경우와 **priority 보정만** 하고 싶은 경우를 독립적으로 다루기 위함. `advisord.c` 는 두 콜을 묶어 쓰지만, 다른 사용자공간 도구가 단일 콜만 쓰는 것도 의도된 사용법.

---

## 5. tick 회계의 동작 — process.md §5 가 우려한 진동을 어떻게 피했나

`clockintr()` 에서 호출되는 `procstat_tick()` 은 cpu 0 에서만 동작하고, 각 proc 의 현재 `state` 에 따라 단일 카운터를 1 증가시킨다.

```c
switch(p->state) {
case RUNNABLE: p->ready_ticks++; break;
case RUNNING:  p->run_ticks++; p->slice_used++; break;
case SLEEPING: p->sleep_ticks++; break;
}
```

**왜 이 자리인가**:
- 매 tick `NPROC=64` 회 루프 + 락 — 비용 작음 (마이크로초 단위).
- 단일 CPU 에서 증분되므로 카운터에 race 없음 — 락은 *상태가 바뀌는 동안* state 를 보지 않기 위한 가드.
- "엣지 트리거" 가 아닌 "샘플링" 이라 빠른 상태 천이를 놓칠 수 있지만, advisor 는 500ms 단위로 분류하므로 100ms 해상도면 충분 — process.md §5.4 의 히스테리시스 논리와 동일한 자리.

**왜 트랜지션 훅 (enter_state/leave_state) 으로 안 했나**:
- xv6 의 state 변경 자리는 5곳 이상 (scheduler/sched/yield/sleep/wakeup/kfork/...) 으로 흩어져 있어, 각 자리에 회계 콜을 박는 변경량이 크다 — fast path 침범 위험.
- 샘플링 방식은 매 클락에 1곳에서만 동작하므로 변경량과 위험이 모두 작다.

---

## 6. quantum 기반 yield — 디폴트 동등성 증명

`usertrap()` 변경 전:

```c
if(which_dev == 2) yield();
```

변경 후:

```c
if(which_dev == 2) {
  if(p->slice_used >= p->quantum_ticks) yield();
}
```

디폴트 `quantum_ticks=1` 인 경우:
- t0: dispatch — scheduler 에서 `slice_used=0` 으로 초기화
- t0+1tick: timer interrupt 도착 → `clockintr` 가 `slice_used`++ = 1 → usertrap 의 분기 `1 >= 1` 참 → `yield()`

즉 quantum=1 인 모든 proc 는 원본과 동일하게 매 tick yield. advisor 가 quantum 을 올리지 않는 한 동작은 비트 단위로 동등. process.md §6 의 "bypass 모드 동등성" 조건을 만족.

quantum=4 인 CPU_BOUND proc 의 경우:
- t0 dispatch
- t0+1, +2, +3 tick — yield 안 함, 동일 proc 계속 RUNNING
- t0+4 tick — yield → scheduler 재진입

→ 컨텍스트 스위치 빈도 1/4 로 감소. process.md §2.4 의 "CPU loop × 3 → BATCH 분류 시 throughput ↑" 시나리오가 이 한 줄로 작동.

---

## 7. advisord 의 폴링 루프 — process.md §3.3 의 구현

`user/advisord.c` 가 process.md 의 분류 흐름을 다음으로 환원한다:

```
loop {
  n = getprocstat_all(buf, MAX_PROCS);
  for each ps in buf[0..n]:
    new_class = classify(ps);  // 이 자리가 LLM call 의 stub
    if(new_class != ps->class_id)
      setclass(ps->pid, new_class);
      setpriority(ps->pid, class_to_priority(new_class));
  pause(POLL_TICKS);  // ~500ms
}
```

`classify()` 함수가 **LLM 자리의 표식자**다. 현재 구현은 sleep/run 비율과 이름 매칭만 보는 매우 단순한 휴리스틱이고, process.md §3.3 의 진짜 LLM 통찰 (name prior, syscall histogram, tree shape) 은 들어 있지 않다. 그러나 이 자리만 교체하면 같은 syscall 인터페이스 위에서 LLM 호출로 자연스럽게 확장된다 — **인터페이스가 분리되어 있으므로 분류기 교체는 커널 변경을 요구하지 않는다**.

추가 안전장치:
- `pid == my_pid` 인 advisord 자신은 재분류 안 함 (피드백 루프 차단).
- `pid <= 2` (init, sh) 도 건드리지 않음 — process.md §10 의 "fast path 침범 금지" 와 같은 정신.

---

## 8. process.md §6 검증 조건과의 대응

| 조건 | 본 구현 상태 |
|---|---|
| bypass 모드 동등성 | ✅ `advisord` 미실행 + class=NORMAL/quantum=1 디폴트 → 원본 xv6 와 동일 (§6 참조) |
| 결정성 회복 | ✅ syscall 이 단순 setter. 결정적 분류기 사용 시 전체 결정적 |
| fail-static | ✅ advisord 가 죽어도 마지막에 쓰인 class/priority 로 계속 동작. NORMAL 인 채 한 번도 advisor 못 만난 proc 도 원래 우선순위 분포 그대로 |
| Observable | ✅ `^P` (procdump) / `advstat` / `getprocstat_all` 모두 동일 데이터 |

---

## 9. 빌드 / 사용

### 9.1 빌드

```bash
cd xv6-process
make            # 커널만
make fs.img     # 사용자 + 디스크 이미지 (advisord/advstat 포함)
make qemu       # QEMU 부팅
```

본 작업 시점에 `make fs.img` 까지 모두 클린 통과 확인 (mkfs 로 fs.img 재생성 성공, balloc/write bitmap 정상).

### 9.2 QEMU 안에서

```
$ advstat                           # 현재 procstat 한번 dump
$ advisord -v &                     # 백그라운드로 advisor 시동 (verbose)
$ spin &                            # CPU bound 워크로드 시작
$ sleep 5; advstat                  # 잠시 후 spin 이 CPU_BOUND 로 분류됐는지 확인
$ priority_test                     # 기존 priority 테스트가 그대로 통과 (회귀 확인)
```

`spin` 같은 CPU-bound 가 몇 폴링 후 `cls CPU` 로 바뀌고 `quan 4` 로 늘어나는 것을 `advstat` 출력에서 확인할 수 있다 (실제 결과는 워크로드와 polling 타이밍에 따라 다르므로 본 보고서에는 결정적 출력으로 남기지 않는다).

---

## 10. 의도적으로 *하지 않은* 것

다음은 process.md 가 언급했지만 본 작업의 범위에 의도적으로 **포함하지 않은** 항목이다.

- **MLFQ 다단계 큐**: process.md §4 의 가정된 메커니즘. xv6 원본에는 다단계 큐가 없고, advisor 가 권장하는 quantum 으로 단일 우선순위 큐 위에서도 §4 의 효과는 얻을 수 있다. 다단계 큐는 별도 작업.
- **aging boost**: §4.4 의 안전망. priority 진동 위험이 적은 단순 분류기에선 advisor 의 ready_ticks 모니터링 자체가 같은 역할을 할 수 있어 일단 보류.
- **panic ring buffer**: §8 의 사후분석 도구. procstat 시계열 저장이 디스크 IO를 요구해 fast path 침범 위험을 평가해야 함 — 별도 다음 단계.
- **fork rate 자동 강등**: §7 의 fork bomb 방어. 본 작업은 *데이터 노출* 까지만 — 정책 (강등 임계, 트리 모양 판별) 은 사용자공간 `advisord` 의 `classify()` 자리에 채워 넣는 형태로 확장.
- **lifetime 의 cross-instance 캐시**: §6.3 의 "이름별 prior 학습". advisor 의 사용자공간 상태 관리 영역이라 커널 변경 없이 가능 — `advisord.c` 의 다음 버전에서 추가.

---

## 11. 마무리

이번 작업의 가장 정확한 한 줄 요약은 process.md §12 를 그대로 인용하는 것이다:

> *xv6의 함수들은 LLM이 옆에 와도 자기 일을 그대로 한다. LLM은 그 함수들이 보던 입력 분포를 의미 있게 만들 뿐이다.*

본 PR 은 정확히 그 "보던 입력 분포" 를 *advisor가 빚을 수 있도록* 커널이 노출하고, 그 노출이 fast path 와 결정성을 깨지 않도록 격리하는 작업이다. advisor 자체의 똑똑함은 사용자공간의 미래 작업이다 — 커널은 이미 자기 자리에서 할 일을 마쳤다.
