# LLM 어드바이저가 들어왔을 때, xv6의 기존 기능이 어떻게 *더 잘* 동작하는가

> 모체 문서: [`process.md`](./process.md), 구현 디테일: [`process_2.md`](./process_2.md)
> 현재 동작 레퍼런스: [`analyze_proc.md`](./analyze_proc.md)
> 대상 코드베이스: `xv6-riscv/kernel/{proc.c, proc.h, sysproc.c, trap.c}`

---

## 0. 이 문서의 관점

`process_2.md`가 "어떻게 만드는가(구조체·시스템콜·자료구조)"를 다뤘다면, 이 문서는 **"무엇이 달라지는가"** 만 본다. 같은 `kfork`, 같은 `scheduler()`, 같은 `kwait`의 동작이 LLM 어드바이저가 옆에 있는 상태에서 **어떤 입력에서 어떤 결과가 바뀌는지** 를 펼친다.

원칙은 process.md와 동일:

- 커널 fast path 코드의 **로직 자체는 바뀌지 않는다**. RR 루프는 그대로 RR 루프다.
- 바뀌는 것은 그 fast path가 *읽는 값* — `priority`, `class_id`, `quantum_ticks` 같은 **정책 상태** — 의 품질이다.
- 즉, LLM은 **새 기능을 추가하지 않는다.** 기존 기능이 보던 입력을 더 의미 있는 분포로 만들어 줄 뿐이다.

이 관점을 끝까지 유지하면 "왜 LLM이 필요한가?" 라는 질문에 매번 같은 형태로 답할 수 있다 — *기존 휴리스틱이 못 보던 입력 조합을 LLM이 보고, 그 통찰을 priority라는 한 채널로 압축해서 흘려보낸다*.

---

## 1. 한눈에 — 기능별 개선 매핑

### 1.1 검토에서 제외된 후보 — 현대 OS가 LLM 없이 더 잘 푸는 영역

처음 후보였지만, **Windows/Linux의 기존 메커니즘과 비교**했을 때 LLM 추가의 비용 대비 이득이 명확하지 않아 본 문서에서 제외한다. (xv6 입장에서는 의미 있는 개선이지만, "현대 OS 대비 LLM의 가치"라는 관점에서는 약함.)

- **aging**: Linux CFS는 `vruntime` 기반 공정성으로 starvation을 *알고리즘적으로* 차단한다 — RB-tree에서 항상 vruntime이 가장 작은 태스크를 선택하므로 임의의 ready 시간이 곧 우선순위 상승이 된다. Windows도 32단계 우선순위에서 long-wait 스레드를 자동 boost(`KiQuantumEnd` / starvation boost). 즉, "이상하게 오래 ready 상태인 프로세스를 식별" 하는 일은 이미 결정적 메커니즘이 처리한다. 표준편차 기반 이상치 탐지가 더 필요하다 해도 그건 단순 통계지 LLM 추론이 필요한 영역이 아니다.
- **`bio.c` LRU / 페이지 교체**: Linux 6.1+ 의 **MGLRU(Multi-Generation LRU)** 가 이미 세대 기반 적응형 교체이고, 별도로 **DAMON**(Data Access Monitor) 가 적응형 워킹셋 추적을 담당한다. ML 기반 cache prediction이 hit rate를 더 끌어올릴 수는 있으나 — 교체 결정은 매 페이지 접근마다 hot path에 끼는 결정이라 predictor lookup의 추가 cost와 모델 유지 비용이 한계적 hit rate 향상을 정당화하는지 불명확. 연구 영역이지 "현대 OS보다 명백히 낫다"고 주장하기 어렵다.

### 1.2 기능별 개선 매핑 (xv6 기존 동작 → LLM 어드바이저 추가 후)

| 기존 xv6 기능 | 현재의 한계 | LLM 어드바이저가 바꾸는 것 | 측정 가능한 개선 |
|---|---|---|---|
| `scheduler()` RR 루프 | 같은 priority면 발견 순서대로 디스패치 | priority 분포가 워크로드 의미를 반영 | interactive 응답 지연 ↓ |
| 정적 priority + fork 상속 (`kfork`) | 자식이 부모와 다른 성격이어도 같은 priority | 자식의 초기 syscall 패턴 보고 빠른 재분류 | mis-classification 지속 시간 ↓ |
| MLFQ 강등/승급 (가정된 메커니즘) | quantum/threshold가 고정 상수 | 워크로드 분포에 맞춰 quantum 권장 | CPU bound throughput ↑, IO bound latency ↓ |
| `kexit` / ZOMBIE | 종료 사실만 기록 | 프로세스 lifetime 통계로 분류 정확도 보강 | 짧은 생애 프로세스 mis-class ↓ |
| `kwait` / parent 관계 | 트리 구조의 *의미* 미사용 | 부모-자식 그래프 → "빌드 트리", "쉘 트리" 묶음 정책 | 셸·빌드 혼합 워크로드 응답성 ↑ |
| `allocproc` / NPROC 한도 | 폭주 시 한도 도달까지 무방어 | 비정상 fork 패턴 감지 → 부모 강등 | fork bomb 회복 시간 ↓ |
| `panic()` 로그 | 사람이 읽기 어려움 | 사후 분석 + 자연어 진단 | MTTR (mean time to repair) ↓ |

### 1.3 현대 OS와의 정면 비교 — "Windows/Linux를 두고도 LLM이 가치를 주는 이유"

위 7개 기능 각각에 대해, **xv6의 기존 방식 / Windows가 같은 문제를 푸는 방식 / Linux가 같은 문제를 푸는 방식 / LLM 어드바이저가 이들보다 더 잘할 수 있는 이유** 를 정리한다.

| 기능 | xv6 방식 | Windows 방식 | Linux 방식 | LLM이 더 잘할 수 있는 이유 |
|---|---|---|---|---|
| **스케줄러 선택** | 전 RUNNABLE 중 발견 순서대로 RR. priority 미사용. | 32단계 우선순위 큐 + foreground/IO boost (`PsBoostThreadIo` 류). 사용자 입력·IO 완료에 자동 일시 부스트. | CFS: vruntime 기반 RB-tree에서 최소 vruntime 선택. 6.6+ EEVDF. | *프로세스 이름·의도* 같은 의미 신호를 *관찰 전*에 prior로 사용. CFS/Windows boost는 sleep/wake 패턴이 누적된 *후*에야 분류가 가능 — "방금 fork된 `make`" 는 행동이 쌓이기 전에 잘못된 priority로 도는 구간이 있음. |
| **fork 시 자식 분류** | 부모 priority를 정적 상속. | priority class 상속, 자식이 `SetPriorityClass` 로 즉시 조정 가능하나 자동 분류는 없음. | `clone()` 으로 nice 상속, CFS의 vruntime 흐름으로 빠르게 적응. | `exec` 된 새 `name`(`make`, `cc`, `ld`) 을 보고 *첫 syscall 전*에 분류. 현대 OS는 실행 후 행동 관찰을 거쳐야 함 → mis-class 윈도우 존재. |
| **quantum / time slice** | `param.h` 컴파일 타임 상수. | 워크스테이션 기본 ~30ms FG / ~10ms BG (`Win32PrioritySeparation`). 서버는 길게. | `sched_min_granularity_ns` (기본 0.75ms), `sched_latency_ns` (6ms) 의 동적 계산. **단, 이 sysctl 값 자체는 사람이 튜닝.** | 운영 중 누적된 procstat 트레이스에서 *이 서버 워크로드*에 최적인 sysctl 권장값을 추론. Linux/Windows의 기본값은 워크로드 무관한 *평균적* 값. |
| **종료 프로세스 통계** | `kwait` 회수 시 휘발 — 어디에도 안 남음. | ETW, Performance Counters, WMI — 매우 풍부하게 *수집*. | `/proc/[pid]/stat`, `getrusage`, `taskstats`, cgroup accounting. | 이름 기반 cross-instance prior 학습. 현대 OS는 데이터를 **수집**하지만 "이 시스템에서 `make` 는 평균 N tick CPU, M개 fork" 식의 분류 prior로 **사용**하지 않음 — 다음 `make` 인스턴스에 그 통계가 자동 반영되지 않는다. |
| **프로세스 트리 의미** | 단순 ppid 포인터 + `kwait` 시맨틱. | Job Objects (운영자가 수동 구성, `AssignProcessToJobObject`). | autogroup (TTY 세션 기준 자동 그룹화, `kernel.sched_autogroup_enabled`), cgroups (수동/systemd). | "빌드 트리", "셸 자식 트리" 같은 *의미적* 그룹 인식. Linux autogroup은 **세션 단위**지 워크로드 의미 단위가 아님 — `make` 가 어느 셸에서 돌든 같은 그룹이고, 같은 세션 안의 `vim` 과 `make` 가 한 그룹이 되어 정작 분리되어야 할 워크로드가 묶인다. |
| **fork 폭주 방어** | `NPROC` 한도 도달 시 fork 실패. 그 전엔 무방어. | Job object 의 `ActiveProcessLimit`, `JOB_OBJECT_LIMIT_ACTIVE_PROCESS`. | `RLIMIT_NPROC` (`ulimit -u`), cgroups v2 `pids.max`. | **이름 기반 신뢰** — `sh` 의 빈번한 fork는 정상, 알 수 없는 바이너리의 빈번한 fork는 의심. 양적 한도(rlimit/pids.max)는 정상 빌드와 fork bomb 을 구분 못 함 → 결국 운영자가 *사후*에 한도를 조정. LLM은 *사전* 의미 구분이 가능. |
| **panic / 사후 분석** | 짧은 문자열 + 레지스터 덤프, 거기서 멈춤. | BSOD bug check code + minidump + WinDbg `!analyze -v`. | kdump + crash + ftrace + ebpf + journalctl. | 직전 procstat 시계열 + panic 메시지 + 코드 컨텍스트를 *자연어로 종합*한 진단. 현대 도구들은 매우 강력하지만 분석에 운영자 숙련도를 요구 — 동일 사고에서 MTTR 차이가 크게 벌어진다. LLM은 *제안* 만 하므로 fail-static 도 깨지 않는다. |

핵심 패턴: 현대 OS의 메커니즘은 대부분 **행동 관찰 기반**(sleep/wake 패턴, vruntime 누적, 자원 사용량 카운터) 이거나 **수동 구성 기반**(job objects, cgroups, sysctl). LLM 어드바이저가 추가하는 새 차원은 두 가지 — (1) **의미적 prior** (프로세스 이름, exec된 바이너리, 트리 모양 → 분류), (2) **cross-instance 학습** (이전에 본 `make` 의 프로파일을 다음 `make` 에 자동 적용). 이 두 차원이 현대 OS의 행동 관찰·수동 구성을 **대체**하지는 않고 *앞단에서* 보강한다.

---

이 표들이 이 문서의 목차다. 이하 각 절에서 한 줄씩 풀어 쓴다. (4절의 aging 부분, 9절의 bio.c 부분은 위 1.1에서 제외 판단을 했으므로, 그 절들의 내용은 "xv6 단독 관점에서의 보강 아이디어" 로만 읽으면 된다 — 현대 OS 대비 강한 주장은 아님.)

---

## 2. `scheduler()` — RR 루프는 그대로, 입력 분포가 달라진다

### 2.1 현재 동작 (analyze_proc.md §4 요약)

```
for(;;) {
    proc 테이블 순회:
        if RUNNABLE:
            p->state = RUNNING
            swtch(...)
}
```

`scheduler()`는 **priority를 보지 않는다**. 모든 RUNNABLE 프로세스를 발견 순서대로 디스패치한다. priority 필드가 있다 하더라도, 이 RR 루프 안에는 "priority가 낮은 걸 먼저 본다"는 코드가 없다 — 이미 정책이 fast path 코드에 박혀 있는 셈이다.

### 2.2 한계

1. **공평하지만 멍청하다.** 셸이 키 입력 한 줄 받고 깨어나도, CPU bound 무한 루프 3개와 동등하게 대기 큐 끝에 줄을 선다.
2. **분류 신호가 없다.** "이 프로세스가 IO bound인지 CPU bound인지" 를 RR 루프 안에서 판단할 입력 자체가 없다 — `state == RUNNABLE` 만 보기 때문.
3. **재현은 잘 된다.** 단점이 아니라 강점이다. LLM이 들어와도 이걸 깨면 안 된다.

### 2.3 LLM 어드바이저가 바꾸는 것

`scheduler()` **코드는 한 줄도 안 바뀐다**. 대신 다음 변화가 일어난다:

- RR 루프가 보는 RUNNABLE 집합 안에서, advisor가 priority를 미리 흔들어 두었다. 셸은 priority=4, CPU loop은 priority=12, 백그라운드 batch는 priority=17.
- `scheduler()` 자체는 여전히 RR이지만, **priority가 디스패치 시점의 가중치로 사용되는 부분** (예: MLFQ 큐 레벨 선택, aging boost 대상 선정) 에서 자연스럽게 셸이 먼저 뽑힌다.
- 결과적으로 `scheduler()`는 자기가 *항상 해 왔던 일* (RUNNABLE 중 하나를 고른다) 만 하지만, 그 선택의 분포가 워크로드 의미를 반영한다.

### 2.4 입력 → 결과의 before/after

| 입력 워크로드 | LLM 없는 RR | LLM advisor on |
|---|---|---|
| CPU loop × 3 + 셸 1 | 셸의 키 입력 응답 = O(N × quantum) | 셸이 priority 4로 끌어올려져 거의 즉시 |
| make -j8 (CPU bound batch) | 8개가 priority 10에서 균등하게 RR | 모두 BATCH로 분류, priority 15. 다른 작업(셸)이 묻히지 않음 |
| 셸 + `cat largefile` (IO bound) | 둘 다 priority 10, IO bound가 sleep 자주 들어가 결과적으로 셸이 손해는 안 봄 | `cat`이 IO_BOUND로 분류, priority 8. 셸 우선 보장 |

핵심: **LLM advisor가 가장 큰 가치를 주는 입력은 첫 번째 시나리오**. RR이 가장 못하는 케이스 (혼합 워크로드에서 interactive가 묻히는 상황) 가 LLM advisor가 가장 잘 푸는 케이스.

---

## 3. `kfork()` — priority 상속의 정확성이 올라간다

### 3.1 현재 동작

`kfork()`는 새 proc 슬롯을 잡고 부모의 priority 필드를 그대로 상속한다 (xv6 원본에는 priority가 없지만, process.md가 가정하는 확장본 기준).

### 3.2 한계

부모-자식이 성격이 다른 흔한 시나리오:

- **셸이 `make`를 fork**: 셸은 INTERACTIVE, `make`는 BATCH. 그러나 priority는 상속 → `make`가 셸과 동급으로 CPU를 먹어 셸 응답성을 해친다.
- **셸이 `cat`을 fork**: 셸은 INTERACTIVE, `cat`은 IO_BOUND. 비슷.
- **DB 서버가 워커 fork**: 부모는 SYSTEM, 자식은 워크로드별로 다양.

상속은 *대부분의 경우* 합리적인 디폴트지만, **어떤 자식은 부모와 명확히 다른 종이다**. 휴리스틱으로는 fork 시점에 자식의 성격을 알 수 없다 — 자식이 아직 한 줄도 실행 안 했기 때문.

### 3.3 LLM 어드바이저가 바꾸는 것

`kfork()` 안에서 즉시 분류하지 않는다 (fast path 영향). 대신:

1. 자식은 부모 priority로 일단 시작한다 (안전한 디폴트).
2. advisor가 다음 500ms 폴링에서 자식의 **첫 N개 syscall 히스토그램과 이름 (`exec`로 바뀐 새 `name`)** 을 본다.
3. `name == "make"`, 첫 syscall이 `exec` 후 `fork` 폭증 → BATCH로 즉시 재분류.

이 패턴이 어떤 기존 정보를 활용하는지가 중요하다:

- **프로세스 이름**: xv6의 `struct proc.name[16]` 은 `exec` 시 바뀐다. 휴리스틱은 이 이름을 "분류에 쓸 만한 의미 신호" 로 못 본다. LLM은 "make/cc/ld → BATCH" 같은 매핑을 자연어 지식에서 가져온다.
- **초기 syscall 분포**: `exec` 직후 무엇을 호출하는가는 그 프로세스의 성격을 강하게 암시한다. `mmap/read` 폭주 → IO_BOUND, `getpid/sched_yield` → INTERACTIVE 가능성.

### 3.4 의미 있는 개선 지표

**오분류 지속 시간 (mis-classification window)**: fork 직후 자식이 잘못된 priority로 도는 시간.

- LLM 없음: 자식이 죽을 때까지 부모 priority 상속 → 무한대일 수 있음.
- LLM advisor: 최대 1 폴링 주기 (~500ms). 짧은 셸 명령(`ls`)은 그 안에 끝나버려서 실제론 잘못된 priority로 도는 게 문제 없는 시간만큼만 도는 셈.

이 점이 advisor 설계의 깔끔한 성질이다: **분류 지연이 워크로드 길이에 자연스럽게 비례**. 빨리 끝나는 건 분류 정확도가 낮아도 영향이 없고, 길게 도는 건 분류 시간이 충분히 주어진다.

---

## 4. MLFQ + aging — 고정 상수가 워크로드-aware 권장값으로 바뀐다

### 4.1 현재 동작 (가정된 확장 메커니즘)

MLFQ 패밀리의 흔한 형태:
- 큐 레벨 N개 (예: 0=최상위 5개)
- 각 레벨마다 quantum (예: L0=1tick, L1=2tick, L2=4tick, L3=8tick, L4=16tick)
- quantum 다 쓰면 한 레벨 강등
- 일정 기간(`BOOST_PERIOD`)마다 전원 L0로 부스트 (aging)

### 4.2 한계

- `QUANTUM_LX`, `BOOST_PERIOD`, 강등 임계값은 **컴파일 타임 상수**. xv6의 `param.h` 같은 매크로.
- 어떤 워크로드에서는 boost가 너무 자주 와서 (예: BOOST_PERIOD=100ms) CPU bound가 매번 L0로 끌려 올라가 IO bound를 방해한다.
- 다른 워크로드에서는 boost가 너무 늦어 (예: BOOST_PERIOD=5s) 진짜 starvation이 발생한다.
- **사람이 손으로 튜닝**: 워크로드마다 베스트 셋이 다르므로 결국 "평균적인 값"으로 타협.

### 4.3 LLM 어드바이저가 바꾸는 것

`scheduler()` 안의 MLFQ 코드는 그대로다. 다음 두 가지가 새로 들어온다:

**(a) Trace-driven 파라미터 튜닝 (process.md §3.3 시나리오 C)**

- 부팅 후 N분 트레이스 누적 → LLM이 시뮬레이션·추론으로 quantum/boost 권장값 산출 → 다음 부팅 시 적용.
- "한 번에 한 값" 도 가능: 운영자가 `QUANTUM_L2 = 3` 같은 권장만 수락.
- 결과: 같은 MLFQ 알고리즘이, 이 서버의 워크로드 분포에 맞춰 튜닝된 상수 위에서 도는 것.

**(b) 런타임 동적 quantum (시나리오 A의 부분집합)**

- per-proc `quantum_ticks` 필드를 advisor가 설정.
- CPU bound로 분류된 프로세스에는 큰 quantum(컨텍스트 스위치 비용 ↓), interactive는 작은 quantum(latency ↓).
- MLFQ는 여전히 큐 레벨로 동작하되, **각 프로세스의 quantum이 동일하지 않다** — 이게 작은 변화처럼 보이지만, 컴파일 타임 튜닝의 한계를 깨는 핵심.

### 4.4 aging이 LLM advisor와 결합되는 자리

aging은 "오래 기다린 놈을 boost" 하는 안전망이다. 그러나 *얼마나* 오래가 너무 길면 starvation을 못 막고, 너무 짧으면 분류 노력이 무의미해진다 (boost가 다 평준화).

advisor가 보강하는 것:

- per-proc `ready_ticks` delta를 매 폴링 시 검사.
- 평균보다 N 시그마 이상 떨어진 프로세스(= "이상하게 오래 ready") → advisor가 자체적으로 priority 1 감소 (= 우선순위 상승).
- 이건 aging이 *덮는 영역의 부분집합* 을 더 세밀히 처리하는 것. aging 자체는 그대로 둔다 (안전망 보장).

요지: **aging은 그대로 작동하는 안전망, advisor는 그 안전망 위에서 더 빨리 starvation 후보를 잡는 layer**. 둘이 충돌하지 않는다. 충돌하더라도 fail-static — advisor 죽으면 aging만 남는다.

---

## 5. 정적 priority — "한 값으로 한 프로세스의 전 생애" 가 깨진다

### 5.1 현재 동작

`proc.priority` 는 한 번 설정되면 명시적인 `setpriority` 가 부르기 전까지 그대로다 (xv6 확장본 기준). 즉, 한 프로세스는 자기 priority를 평생 유지한다.

### 5.2 한계 — 프로세스의 *국면 변화*

많은 실제 프로그램은 **여러 국면(phase)** 을 갖는다:

- **컴파일러**: 초반 (소스 읽기) IO_BOUND → 중반 (코드 생성) CPU_BOUND → 후반 (링크) IO_BOUND.
- **DB 서버**: 평소 IO_BOUND → 인덱스 빌드 시 CPU_BOUND.
- **셸 스크립트**: 자식 스폰 시 부모는 SLEEPING (kwait), 자식이 끝나면 다시 active.

정적 priority는 이 전환을 흡수할 수 없다. 한 가지 priority를 골라야 하므로 어느 국면에선 손해 본다.

### 5.3 LLM 어드바이저가 바꾸는 것

advisor의 500ms delta 분류가 자연스럽게 국면 전환을 따라간다:

- 어떤 윈도우에서 `sleep_ticks` 비중이 ↑ → IO_BOUND로 재분류 → priority 8.
- 다음 윈도우에서 `run_ticks` 비중이 ↑ → CPU_BOUND로 재분류 → priority 12.
- 전환 latency = 최대 1 폴링 (500ms).

여기서 의미 있는 점: **국면 전환을 잡기 위해 코드 단 한 줄 추가하지 않았다**. 같은 `setpriority` 호출이 500ms마다 일어나는 것뿐. 기존 `setpriority` 시스템콜의 동작은 정확히 같다 — advisor가 그저 자주 호출할 뿐이다.

### 5.4 위험 한 가지: 잦은 전환의 진동

advisor가 분류 경계 근처에서 매 폴링마다 priority를 흔들면 캐시 친화성이 망가질 수 있다. 이 위험은 advisor 내부의 **히스테리시스** (분류 경계에 ±10% 데드존) 로 막는다 — 이건 advisor 안의 일이라 커널 변경 없음.

---

## 6. `kexit` / `kwait` — 프로세스 lifetime 정보가 분류 신호로 쓰인다

### 6.1 현재 동작

- `kexit(status)`: ZOMBIE 상태 + 부모 깨움. 종료 시각이나 lifetime은 **어디에도 저장되지 않는다**.
- `kwait`: 부모가 ZOMBIE 자식을 회수, `freeproc` 후 슬롯 반환. 자식의 통계는 같이 사라진다.

### 6.2 한계

xv6는 "이 프로세스가 50ms 살았다" vs "이 프로세스가 30분 살았다" 를 **사후에 어디서도 볼 수 없다**. 통계가 ZOMBIE→UNUSED 전환에서 휘발한다.

이 정보는 분류기에게 매우 가치 있다:

- 50ms 생애 프로세스가 1초에 100개 → fork bomb 또는 빌드 스크립트.
- 항상 30분+ 사는 프로세스 → 서버 데몬, SYSTEM 클래스 후보.
- "이 이름의 프로세스는 평균 1.2초 산다" → 같은 이름의 새 인스턴스에 미리 그 priority를 줄 수 있다.

### 6.3 LLM 어드바이저가 바꾸는 것

advisor가 procstat을 폴링할 때 ZOMBIE 상태도 한 번은 본다 — `kwait` 으로 회수되기 *전* 의 마지막 스냅샷. 그 시점에 다음을 흡수한다:

- 종료 직전의 `run_ticks` / `ready_ticks` / `sleep_ticks` 누계 → 이 프로세스의 전체 생애 프로파일.
- `name` 별 통계: "make → 평균 N tick CPU, M개 fork".

이 데이터는 advisor의 user-space 캐시로 누적되고, **다음에 같은 이름의 프로세스가 등장하면 첫 분류부터 더 정확한 priority** 가 적용된다. 즉, advisor가 "이 시스템에서 본 적 있는 프로그램" 에 대해 학습한다.

### 6.4 `kwait` — parent 관계 그래프의 의미

`kwait`의 "부모 PID 추적" 은 트리 구조를 만든다. 휴리스틱은 이 트리를 priority 상속 외엔 쓰지 않는다. LLM은 이걸 **묶음 정책(group policy)** 으로 쓸 수 있다:

- `sh` 가 `make` 를 fork, `make` 가 `cc` 들을 fork → 트리 전체가 "빌드 트리".
- advisor: 트리 root가 BATCH로 분류되면, 자식 트리 전체를 한 번에 priority 15로 끌어내림.
- 셸이 `vim` 을 fork → 트리는 "셸 자식 트리", 일부 INTERACTIVE.

이 묶음 정책이 의미 있는 이유: **유닉스 프로세스 트리는 의미를 담는 자연스러운 단위**. 휴리스틱은 트리를 "그저 부모-자식 포인터" 로 본다. LLM은 트리를 "함께 다뤄야 하는 워크로드 단위" 로 본다.

---

## 7. `allocproc` / NPROC 한도 — 폭주 방어가 정량적이 된다

### 7.1 현재 동작

`allocproc`은 UNUSED 슬롯을 선형 탐색해 잡는다. NPROC=64에 도달하면 fork 실패. 방어는 거기까지.

### 7.2 한계

64에 도달하기 전에는 **무방어**. 1초에 50개씩 fork 하는 폭주 프로세스가 있어도, 한도에 닿기 전까지는 정상 fork와 구분되지 않는다.

### 7.3 LLM 어드바이저가 바꾸는 것

advisor의 ZOMBIE/active 통계가 fork rate를 자연스럽게 계산할 수 있다:

- 한 부모의 `ctxsw_count` 비례 `kfork` 호출 빈도가 분포 상위 N% → 폭주 후보.
- "1초간 fork → exit → fork → exit" 사이클이 반복 → fork bomb 패턴.

advisor의 대응:

1. 부모 priority 강등 (예: 4 → 15). fork bomb이 BATCH로 강등되면 정상 셸이 살아남는다.
2. 정도가 심하면 운영자에게 경고 (diag 도구).

이 대응이 가능한 이유: **휴리스틱은 "지난 1초간 fork 빈도" 같은 *집계 신호* 를 보는 자리가 없다**. 커널 내부에 그런 카운터를 박을 수도 있지만, 그건 fast path 비용. advisor는 user-space에서 이미 누적된 procstat 시계열을 본다 — fast path 비용 0.

### 7.4 LLM이 *더* 잘하는 부분

휴리스틱 대비 LLM이 강한 점:

- **이름 기반 신뢰**: `sh` 의 fork rate가 높은 건 정상. `mystery_binary` 의 fork rate가 높으면 의심. 이 차이를 매핑하려면 자연어 지식이 필요하다.
- **트리 모양**: 정상 빌드는 sh → make → cc 의 얕은 트리. fork bomb은 자기 자신을 재귀 fork 하는 깊거나 넓은 트리. 트리 모양으로 분류는 LLM이 자연스럽게 한다.

---

## 8. `panic()` / 디버깅 — 사후 분석이 사람 친화적이 된다

### 8.1 현재 동작

`panic("kerneltrap")`, `panic("freeproc: invariant")`. xv6는 패닉 시 짧은 문자열 + 레지스터 덤프 정도를 출력하고 멈춘다.

### 8.2 한계

- "어떤 시퀀스가 이 panic을 유발했나?" — 직전 procstat 스냅샷 없이는 알 길이 없다.
- "왜 이 invariant가 깨졌나?" — 코드를 보고 추론해야 함.
- xv6 학습자에게는 이 진단 자체가 학습 곡선의 큰 부분.

### 8.3 LLM 어드바이저가 바꾸는 것

운영 시 advisor (또는 별도 diag 데몬) 가 procstat 스냅샷을 ring buffer에 보관하다가, panic 또는 anomaly 이벤트 발생 시:

1. 직전 N개 스냅샷을 덤프.
2. 사람이 읽기 어려운 panic 메시지 + 카운터 시계열을 LLM에 전달.
3. LLM이 자연어 진단을 반환: "PID 17이 `kwait` 에서 5초간 깨지 못함, 자식 PID 21이 ZOMBIE인데 부모 슬롯이 회수 안 됨 — wait_lock 누락 가능성."

이건 **runtime에 들어가지 않는다.** 사고 발생 후에만 작동. latency 제약이 거의 없다.

### 8.4 어디까지가 LLM의 역할인가

LLM은 *제안* 만 한다. 실제 디버깅 결정 (수정, 재현, 머지) 은 운영자/개발자. process.md §5의 fail-static + observable 원칙이 그대로 적용:

- LLM 진단은 *읽을거리*. 자동 액션 없음.
- 진단의 근거가 된 procstat 스냅샷은 같이 출력 → 운영자가 LLM을 검증 가능.

---

## 9. `bio.c` 등 비-스케줄러 영역 — 같은 패턴의 일반화

### 9.1 buffer cache

`bio.c` 의 LRU 교체:
- 한계: "가까운 미래에 다시 쓰일 블록" 을 LRU만으로는 못 본다.
- LLM 개선: 오프라인 trace에서 distill한 작은 예측기 (블록 해시 → "다음 재사용까지 거리") 를 교체 결정에 합산. LLM은 런타임에 호출 안 됨.

### 9.2 swap / page replacement (xv6에는 없지만 일반화)

- 한계: 워킹셋 추정이 마지막 N tick 만으로는 부정확.
- LLM 개선: 페이지 접근 패턴을 trace로 보고 priority 키를 distill. 동일하게 런타임은 lookup만.

### 9.3 이 절의 요지

스케줄링 외에도 **"fast path에 박혀 있는 작은 정책 객체" 가 있는 곳** 이면 같은 분리가 적용된다:

> fast path 코드는 그대로 — LLM은 fast path가 *참조하는* 정책 객체를 빚는다.

이게 OS-LLM 결합의 일반 패턴이라는 점이 이 문서의 마지막 메시지다.

---

## 10. LLM advisor가 *못 하는* 것 — 솔직한 한계

기존 기능이 더 잘 작동하는 영역이 있는 만큼, **여전히 못 하는 영역도** 명시해야 균형 잡힌 논의다.

| 영역 | 왜 LLM이 못 하는가 |
|---|---|
| 컨텍스트 스위치 대상 선정 | latency가 1–10μs. LLM 추론 100만 배 느림. |
| 인터럽트 핸들러 분기 | 동일 — fast path 침범 금지. |
| 락 획득 순서 | 결정성 필수. LLM은 비결정. |
| 페이지 폴트 즉시 처리 | latency. 단, distilled predictor는 가능. |
| 새로운 자료구조 발명 | LLM은 정책 빚기지, 코드 생성기가 아님 (이 글의 범위 안에서는). |

이 한계는 process.md §4와 같다. 이 문서가 "기능 개선" 관점이라고 해서 이 경계가 옮겨지진 않는다.

---

## 11. "정말 개선됐는가?" 를 어떻게 측정하나

각 절의 개선 주장은 다음 지표로 검증 가능해야 한다.

| 절 | 지표 | 측정 방법 |
|---|---|---|
| §2 scheduler | interactive p50/p99 응답 지연 | `user/bench_mix.c` — CPU loop 3 + interactive 1 |
| §3 kfork | 자식의 mis-class 지속 시간 (priority 변경까지 ticks) | advisord 로그 |
| §4 MLFQ + aging | CPU bound throughput 동시에 max ready-wait time | 같은 bench_mix, longer window |
| §5 정적 priority | 국면 전환 추적 latency (재분류까지의 윈도우 수) | 단일 프로세스를 phase 시켜 트레이스 |
| §6 kexit/kwait | "이름이 같은 새 인스턴스" 의 첫 분류 정확도 | 같은 명령 N번 실행, 첫 윈도우 분류 비교 |
| §7 allocproc | fork bomb 발생 시 정상 셸의 응답성 회복 시간 | bomb 시나리오 + 셸 latency |
| §8 panic | MTTR (mean time to repair) — 운영자 시간 | 운영자 user study 또는 시뮬레이션 |
| §9 bio | hit rate ↑ | 표준 trace replay |

검증의 공통 원칙 (process.md §6의 재진술):

- **bypass 모드 동등성**: advisor off 상태에서 모든 동작이 원본 xv6와 비트 단위 동일.
- **결정성 회복**: advisor 분류 결과를 trace로 고정 → 같은 입력 → 같은 스케줄.
- **fail-static**: advisor 죽이고도 시스템 정상.

이 세 조건을 깨지 않는 한, 위 지표의 개선은 *진짜 개선* 으로 받아들일 수 있다.

---

## 12. 한 줄 요약

> *xv6의 함수들은 LLM이 옆에 와도 자기 일을 그대로 한다. LLM은 그 함수들이 보던 입력 분포를 의미 있게 만들 뿐이다 — 그리고 그 작은 차이가 혼합 워크로드에서 가장 큰 사용자 가치를 만든다.*

---

## 참고

- `process.md` — 전체 그림과 5원칙
- `process_2.md` — 구현 디테일 (syscall, 구조체, advisord 코드)
- `analyze_proc.md` — `kfork`/`kexit`/`kwait`/`scheduler` 의 현재 동작
- `xv6-riscv/kernel/proc.c:425` — `scheduler()` (개선 효과가 관측되는 자리)
- `xv6-riscv/kernel/proc.c:260` — `kfork()` (priority 상속 자리)
- `xv6-riscv/kernel/proc.c:327` — `kexit()` (lifetime 통계 휘발 자리)
- `xv6-riscv/kernel/proc.c:371` — `kwait()` (트리 그래프 의미 자리)
