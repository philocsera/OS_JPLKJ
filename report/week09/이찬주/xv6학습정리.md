# xv6학습 정리

## 1. 학습목표

다음과 같은 관점에서 xv6를 공부한다.

- xv6의 커널은 어떤 구조로 이루어져 있는가?
- `proc.h`, `proc.c`, `trap.c`, `syscall.c`는 서로 어떻게 연결되는가?
- 프로세스 상태는 어디에 저장되고, 누가 변경하는가?
- 스케줄러가 실행되면 `struct proc` 내부의 어떤 값이 바뀌는가?
- 그 변화가 실제 사용자 프로그램의 실행 결과에 어떻게 반영되는가?
- OS 프로그램을 수정할 때 왜 상태 전이, lock, context switch, interrupt 등을 함께 고려해야 하는가?
- eBPF, Kgent, 심층 점수화 구조를 기반으로 OS 개발 보조 프로그램을 설계하려면 xv6에서 무엇을 관찰하고 평가해야 하는가?

즉, xv6는 단순한 교육용 운영체제가 아니라, OS 구조를 실험하고 분석하기 위한 작은 실험 환경으로 볼 수 있다.

---

## 2. xv6를 공부할 때의 핵심 질문

xv6 코드를 볼 때는 함수 하나만 따로 보는 것이 아니라, 다음 질문을 계속 던지면서 공부해야 한다.

```text
이 구조체는 무엇을 기억하는가?
이 값은 누가 바꾸는가?
이 값이 바뀌면 다음 함수의 동작은 어떻게 달라지는가?
그 결과는 어디에서 관찰되는가?
이 코드를 수정하면 어떤 부작용이 생길 수 있는가?
```

예를 들어 스케줄러를 공부할 때 단순히 다음과 같이 이해하면 부족하다.

```text
scheduler()는 RUNNABLE 상태의 프로세스를 실행한다.
```

더 깊게 이해하려면 다음과 같이 봐야 한다.

```text
프로세스 상태는 proc.h의 struct proc 안에 state로 저장된다.
scheduler()는 proc 배열을 순회하면서 state가 RUNNABLE인 프로세스를 찾는다.
찾은 프로세스의 state를 RUNNING으로 바꾸고,
현재 CPU의 c->proc에 해당 프로세스를 저장한다.
그 후 swtch()를 통해 CPU 실행 흐름을 선택된 프로세스로 넘긴다.
타이머 인터럽트가 발생하면 trap.c에서 yield()가 호출되고,
yield()는 현재 프로세스의 state를 다시 RUNNABLE로 바꾼 뒤
sched()를 통해 scheduler로 돌아간다.
```

따라서 스케줄러를 수정한다는 것은 단순히 `scheduler()` 함수의 for문을 바꾸는 일이 아니다.

스케줄러를 수정하려면 다음 요소를 함께 고려해야 한다.

- 프로세스 상태
- CPU별 현재 실행 프로세스
- context switch
- timer interrupt
- yield 흐름
- lock 보호
- starvation 가능성
- 실험 결과 측정 방식

---

## 3. xv6의 전체 구조

xv6는 크게 사용자 영역과 커널 영역으로 나뉜다.

```text
xv6-riscv/
├── user/        사용자 프로그램 코드
├── kernel/      운영체제 커널 코드
├── mkfs/        파일 시스템 이미지 생성 도구
├── Makefile     빌드 및 실행 설정
└── README
```

가장 중요한 부분은 `kernel/` 디렉터리이다.

```text
kernel/
├── proc.h       프로세스와 CPU 구조체 정의
├── proc.c       프로세스 생성, 종료, 대기, 스케줄링 구현
├── trap.c       시스템 콜, 인터럽트, 예외 처리
├── syscall.c    시스템 콜 번호를 실제 커널 함수로 연결
├── sysproc.c    fork, exit, wait 등 프로세스 관련 시스템 콜 구현
├── sysfile.c    read, write, open 등 파일 관련 시스템 콜 구현
├── vm.c         가상 메모리와 페이지 테이블 관리
├── kalloc.c     물리 메모리 할당과 해제
├── spinlock.c   커널 lock 구현
├── file.c       파일 객체 관리
├── fs.c         파일 시스템 구현
└── main.c       커널 시작 지점
```

xv6를 깊게 공부하려면 파일을 따로 외우는 것이 아니라, 하나의 실행 흐름이 여러 파일을 어떻게 통과하는지 추적해야 한다.

---

## 4. `proc.h`: 프로세스를 표현하는 핵심 구조

운영체제에서 프로세스는 단순히 실행 중인 프로그램이 아니다.

커널 입장에서 프로세스는 다음과 같은 정보를 가진 관리 대상이다.

```c
struct proc {
    struct spinlock lock;
    enum procstate state;
    void *chan;
    int killed;
    int xstate;
    int pid;
    struct proc *parent;

    uint64 kstack;
    uint64 sz;
    pagetable_t pagetable;
    struct trapframe *trapframe;
    struct context context;

    struct file *ofile[NOFILE];
    struct inode *cwd;
    char name[16];
};
```

각 필드의 의미는 다음과 같다.

| 필드 | 의미 |
|---|---|
| `lock` | 해당 프로세스 구조체를 보호하는 lock |
| `state` | 프로세스의 현재 상태 |
| `chan` | sleep/wakeup에서 사용하는 대기 채널 |
| `killed` | 프로세스가 종료 요청을 받았는지 표시 |
| `xstate` | 종료 상태 |
| `pid` | 프로세스 ID |
| `parent` | 부모 프로세스 |
| `kstack` | 커널 모드에서 사용할 커널 스택 |
| `sz` | 프로세스 메모리 크기 |
| `pagetable` | 프로세스의 페이지 테이블 |
| `trapframe` | user mode에서 kernel mode로 넘어올 때 저장되는 레지스터 정보 |
| `context` | context switch 때 저장되는 커널 레지스터 정보 |
| `ofile` | 열린 파일 목록 |
| `cwd` | 현재 작업 디렉터리 |
| `name` | 프로세스 이름 |

여기서 가장 중요한 것은 `state`, `trapframe`, `context`, `pagetable`이다.

```text
state
→ 프로세스가 현재 실행 가능한지, 실행 중인지, 잠들었는지, 종료되었는지를 나타낸다.

trapframe
→ 시스템 콜이나 인터럽트로 user mode에서 kernel mode로 들어올 때 사용자 레지스터를 저장한다.

context
→ 커널 내부에서 context switch가 일어날 때 필요한 레지스터를 저장한다.

pagetable
→ 해당 프로세스의 가상 주소 공간을 관리한다.
```

따라서 프로그램이 실행된다는 것은 단순히 CPU가 명령어를 수행하는 것이 아니다.

커널은 프로세스마다 `state`, `trapframe`, `context`, `pagetable` 등을 관리하면서 어떤 프로세스가 언제 실행될지 결정한다.

---

## 5. 프로세스 상태 전이

xv6의 프로세스 상태는 보통 다음과 같이 이동한다.

```text
UNUSED
아직 사용되지 않는 proc 슬롯

↓ allocproc()

USED
프로세스로 사용하기 위해 준비 중인 상태

↓ userinit() 또는 fork()

RUNNABLE
실행 가능하지만 아직 CPU를 받지 못한 상태

↓ scheduler()

RUNNING
CPU에서 실행 중인 상태

↓ yield(), sleep(), exit()

RUNNABLE / SLEEPING / ZOMBIE
```

각 상태의 의미는 다음과 같다.

| 상태 | 의미 |
|---|---|
| `UNUSED` | 비어 있는 프로세스 슬롯 |
| `USED` | 프로세스 생성 중 |
| `RUNNABLE` | 실행 가능하지만 CPU를 기다림 |
| `RUNNING` | 현재 CPU에서 실행 중 |
| `SLEEPING` | 특정 이벤트를 기다리며 잠든 상태 |
| `ZOMBIE` | 종료되었지만 부모가 아직 회수하지 않은 상태 |

이 상태 전이는 OS 설계에서 매우 중요하다.

예를 들어 다음과 같은 문제가 생길 수 있다.

```text
RUNNABLE로 바꿔야 하는데 SLEEPING으로 남아 있으면
→ 프로세스가 영원히 실행되지 않을 수 있다.

RUNNING 상태인데 scheduler가 또 실행하려고 하면
→ 같은 프로세스를 중복 실행할 위험이 생긴다.

ZOMBIE 상태를 제대로 정리하지 않으면
→ 종료된 프로세스가 proc table에 계속 남는다.

lock 없이 state를 변경하면
→ 여러 CPU가 동시에 같은 프로세스를 수정할 수 있다.
```

따라서 OS 프로그램 설계에서는 단순한 변수 변경 하나도 매우 조심해야 한다.

---

## 6. `proc.c`: 프로세스를 실제로 움직이는 파일

`proc.h`가 프로세스의 설계도라면, `proc.c`는 프로세스를 실제로 생성하고, 실행하고, 재우고, 깨우고, 종료시키는 코드이다.

`proc.c`에서 중요한 함수는 다음과 같다.

| 함수 | 역할 |
|---|---|
| `procinit()` | 프로세스 테이블 초기화 |
| `allocproc()` | 비어 있는 proc 슬롯을 찾아 새 프로세스 준비 |
| `userinit()` | 최초 사용자 프로세스 생성 |
| `fork()` | 부모 프로세스를 복사하여 자식 프로세스 생성 |
| `exit()` | 프로세스 종료 |
| `wait()` | 부모가 자식 프로세스 종료를 기다림 |
| `scheduler()` | 실행 가능한 프로세스를 선택 |
| `yield()` | 현재 프로세스가 CPU를 양보 |
| `sched()` | 현재 프로세스에서 scheduler로 전환 |
| `sleep()` | 프로세스를 잠들게 함 |
| `wakeup()` | 잠든 프로세스를 깨움 |

`proc.c`는 단순히 프로세스 관련 함수가 모여 있는 파일이 아니라, xv6의 실행 흐름을 제어하는 중심 파일이다.

---

## 7. xv6 스케줄러의 기본 흐름

xv6의 기본 스케줄러는 매우 단순하다.

```text
scheduler()
↓
proc 배열을 처음부터 끝까지 검사
↓
각 프로세스 p에 대해 p->lock 획득
↓
p->state == RUNNABLE 인지 확인
↓
RUNNABLE이면 p->state = RUNNING
↓
현재 CPU의 c->proc = p
↓
swtch(&c->context, &p->context)
↓
프로세스 실행
↓
프로세스가 yield/sleep/exit 등으로 다시 scheduler에 복귀
↓
c->proc = 0
↓
다음 RUNNABLE 프로세스 탐색
```

이 과정에서 실제로 움직이는 값은 다음과 같다.

| 값 | 변화 |
|---|---|
| `p->state` | `RUNNABLE → RUNNING → RUNNABLE/SLEEPING/ZOMBIE` |
| `p->context` | 프로세스의 실행 문맥 저장 및 복원 |
| `c->proc` | 현재 CPU가 실행 중인 프로세스를 가리킴 |
| `c->context` | CPU의 scheduler context 저장 |
| `p->lock` | 프로세스 상태 변경 보호 |

따라서 스케줄러는 단순히 프로세스를 고르는 함수가 아니다.

스케줄러는 다음을 모두 수행한다.

```text
프로세스 상태 확인
프로세스 상태 변경
현재 CPU의 실행 대상 변경
context switch 수행
다시 돌아온 후 다음 프로세스 탐색
```

즉, 스케줄러를 수정한다는 것은 OS의 실행 제어 방식을 수정하는 일이다.

---

## 8. 타이머 인터럽트와 `yield()` 흐름

스케줄러만 보면 부족하다.

왜냐하면 실행 중인 프로세스가 언제 CPU를 놓는지도 알아야 하기 때문이다.

xv6에서는 타이머 인터럽트가 발생하면 현재 실행 중인 프로세스가 CPU를 양보할 수 있다.

흐름은 다음과 같다.

```text
사용자 프로그램 실행 중
↓
타이머 인터럽트 발생
↓
trap.c의 usertrap() 또는 kerneltrap() 진입
↓
타이머 인터럽트인지 확인
↓
yield() 호출
↓
현재 프로세스의 p->state = RUNNABLE
↓
sched() 호출
↓
swtch(&p->context, &mycpu()->context)
↓
scheduler()로 복귀
```

여기서 중요한 점은, 스케줄러 정책은 `scheduler()` 함수 안에만 있는 것이 아니라는 것이다.

다음 요소들이 모두 연결되어 있다.

- timer interrupt
- trap 처리
- yield
- sched
- swtch
- process state
- CPU context

따라서 스케줄러를 바꾸려면 다음 질문을 해야 한다.

```text
언제 CPU를 빼앗을 것인가?
yield()가 현재 프로세스를 어떤 상태로 되돌릴 것인가?
sched()는 어떤 조건에서 context switch를 허용할 것인가?
lock은 올바르게 잡혀 있는가?
프로세스가 굶주리지 않는가?
측정 결과는 어디서 확인할 것인가?
```

---

## 9. 예시: 우선순위 스케줄러를 만든다고 할 때

우선순위 스케줄러를 만든다고 하면 처음에는 간단해 보인다.

```text
priority가 높은 프로세스를 먼저 실행하면 되지 않나?
```

하지만 실제 OS 설계에서는 고려해야 할 것이 많다.

### 9.1 `proc.h`에 필드 추가

예를 들어 `struct proc`에 다음 필드를 추가할 수 있다.

```c
int priority;
int sched_count;
uint64 runtime_ticks;
```

각 필드의 의미는 다음과 같다.

| 필드 | 의미 |
|---|---|
| `priority` | 프로세스 우선순위 |
| `sched_count` | 해당 프로세스가 CPU를 받은 횟수 |
| `runtime_ticks` | 해당 프로세스가 실행된 시간 |

하지만 필드를 추가하는 순간 다음 문제가 생긴다.

```text
priority의 기본값은 어디서 정할 것인가?
fork()할 때 부모의 priority를 자식이 물려받을 것인가?
exec()하면 priority를 초기화할 것인가, 유지할 것인가?
사용자 프로그램이 priority를 바꿀 수 있게 할 것인가?
priority 값의 범위는 어떻게 정할 것인가?
```

즉, 단순한 필드 추가가 아니라 OS 정책 설계 문제가 된다.

---

### 9.2 프로세스 생성 시 초기화

필드를 추가했다면 `allocproc()` 또는 `userinit()`에서 초기화해야 한다.

예시는 다음과 같다.

```c
p->priority = 5;
p->sched_count = 0;
p->runtime_ticks = 0;
```

초기화를 하지 않으면 쓰레기 값이 들어갈 수 있다.

그 결과 다음 문제가 발생할 수 있다.

```text
priority가 우연히 매우 큰 값이 됨
→ 특정 프로세스만 계속 실행될 수 있다.

sched_count가 초기화되지 않음
→ 실험 결과를 신뢰할 수 없다.

runtime_ticks가 잘못된 값에서 시작함
→ CPU 사용 시간 측정이 왜곡된다.
```

---

### 9.3 `fork()`에서 필드 복사 여부 결정

자식 프로세스를 만들 때 부모의 priority를 물려줄 수도 있고, 기본값으로 초기화할 수도 있다.

부모의 priority를 물려주는 경우:

```c
np->priority = p->priority;
```

기본 priority를 부여하는 경우:

```c
np->priority = DEFAULT_PRIORITY;
```

각 방식의 장단점은 다음과 같다.

| 방식 | 장점 | 단점 |
|---|---|---|
| 부모 priority 상속 | 부모 작업의 중요도가 자식에게 유지됨 | 높은 priority가 비정상적으로 전파될 수 있음 |
| 기본값 초기화 | 단순하고 안정적 | 부모 작업의 중요도를 잃을 수 있음 |

이처럼 OS 설계에서는 작은 선택 하나가 정책의 의미를 바꾼다.

---

### 9.4 `scheduler()` 선택 기준 변경

기본 xv6 스케줄러는 proc 배열을 순서대로 돌면서 `RUNNABLE` 프로세스를 실행한다.

우선순위 스케줄러는 다음과 같이 바뀔 수 있다.

```text
proc 배열 전체를 순회한다.
RUNNABLE인 프로세스 중 priority가 가장 높은 프로세스를 찾는다.
선택된 프로세스의 state를 RUNNING으로 바꾼다.
swtch()로 실행 흐름을 넘긴다.
```

하지만 여기서도 문제가 생긴다.

```text
priority가 높은 프로세스가 계속 RUNNABLE이면?
→ 낮은 priority 프로세스가 굶을 수 있다.

priority가 같은 프로세스가 여러 개라면?
→ 어떤 기준으로 선택할 것인가?

매번 전체 proc 배열을 검사하면?
→ 스케줄러 오버헤드가 증가한다.

실행 중에 priority를 바꾸면?
→ lock 없이 변경할 경우 race condition이 발생할 수 있다.
```

따라서 스케줄러 설계에서는 다음 기준을 함께 고려해야 한다.

- 공정성
- 성능
- starvation 방지
- lock 보호
- 구현 단순성
- 디버깅 가능성
- 실험 결과 측정 가능성

---

## 10. 커널 수정 결과는 어디에서 관찰되는가?

커널 코드를 수정해도 결과가 바로 눈에 보이지 않을 수 있다.

따라서 수정한 기능이 실제로 영향을 주었는지 관찰할 지점을 정해야 한다.

우선순위 스케줄러를 예로 들면, 관찰 지점은 다음과 같다.

| 관찰 항목 | 의미 |
|---|---|
| 사용자 프로그램 출력 순서 | 어떤 프로세스가 더 자주 실행되는지 확인 |
| `sched_count` | 프로세스별 CPU 할당 횟수 |
| `runtime_ticks` | 프로세스별 실행 시간 |
| turnaround time | 생성부터 종료까지 걸린 시간 |
| response time | 처음 CPU를 받기까지 걸린 시간 |
| starvation 여부 | 낮은 priority 프로세스가 계속 실행되지 못하는지 확인 |

즉, xv6 실험은 다음과 같이 정리해야 한다.

```text
수정 위치:
kernel/proc.h, kernel/proc.c

수정한 값:
priority, sched_count, runtime_ticks

영향받는 함수:
allocproc(), fork(), scheduler(), yield()

커널 내부 변화:
p->state 전이 순서 변경
c->proc에 들어가는 프로세스 변경
swtch 대상 변경

사용자 관찰 결과:
출력 순서 변경
프로세스 완료 시간 변경
CPU 배분 횟수 변경

위험:
starvation
race condition
lock 오류
측정값 왜곡
```

이렇게 정리해야 OS 코드 수정이 실제로 어떤 영향을 주었는지 설명할 수 있다.

---

## 11. 시스템 콜 흐름도 함께 이해해야 한다

OS 개발 보조 프로그램을 만들려면 스케줄러뿐만 아니라 시스템 콜 흐름도 이해해야 한다.

예를 들어 `getpid()` 시스템 콜은 다음 흐름으로 실행된다.

```text
user program에서 getpid() 호출
↓
user/usys.S의 system call stub 실행
↓
ecall 발생
↓
trap.c의 usertrap() 진입
↓
syscall.c의 syscall() 호출
↓
p->trapframe->a7에서 syscall number 확인
↓
syscalls[] 배열에서 sys_getpid 선택
↓
sys_getpid() 실행
↓
반환값을 p->trapframe->a0에 저장
↓
user mode로 복귀
↓
사용자 프로그램은 반환값을 받음
```

여기서 중요한 것은 사용자 프로그램과 커널 함수가 직접 연결되는 것이 아니라는 점이다.

중간에 다음 구조가 있다.

- user stub
- ecall
- trap
- syscall dispatcher
- syscall number
- kernel function
- trapframe return value

따라서 시스템 콜 하나를 추가하려면 여러 파일을 수정해야 한다.

```text
user/user.h
→ 사용자 프로그램에서 호출할 함수 선언 추가

user/usys.pl
→ system call stub 생성 entry 추가

kernel/syscall.h
→ system call 번호 추가

kernel/syscall.c
→ extern 선언과 syscalls[] 배열 등록

kernel/sysproc.c 또는 kernel/sysfile.c
→ 실제 커널 함수 구현

Makefile
→ 테스트용 user program 추가
```

이처럼 시스템 콜 하나도 user 영역, trap 처리, syscall dispatcher, kernel function, 반환 레지스터가 모두 연결되어 있다.

---

## 12. OS 프로그램 설계가 어려운 이유

일반 프로그램은 함수의 입력과 출력만 생각해도 어느 정도 구현할 수 있다.

하지만 OS 프로그램은 다르다.

OS에서는 하나의 기능을 수정할 때 다음 요소를 함께 고려해야 한다.

### 12.1 상태 전이

프로세스는 계속 상태가 바뀐다.

```text
UNUSED → USED → RUNNABLE → RUNNING → SLEEPING/RUNNABLE/ZOMBIE
```

상태 전이가 잘못되면 프로세스가 실행되지 않거나, 중복 실행되거나, 종료되지 않을 수 있다.

---

### 12.2 동시성

커널은 여러 CPU나 인터럽트 상황에서 동시에 실행될 수 있다.

따라서 공유 데이터는 lock으로 보호해야 한다.

```c
acquire(&p->lock);
p->state = RUNNABLE;
release(&p->lock);
```

lock을 잘못 사용하면 다음 문제가 발생한다.

```text
race condition
deadlock
lost wakeup
잘못된 process state
중복 실행
영원히 깨어나지 않는 process
```

---

### 12.3 context switch

프로세스 전환은 단순한 함수 호출이 아니다.

`swtch()`를 통해 현재 실행 문맥을 저장하고, 다른 실행 문맥을 복원한다.

따라서 context switch 흐름을 이해하지 못하면 스케줄러를 안전하게 수정하기 어렵다.

---

### 12.4 interrupt

프로세스는 자기 마음대로만 CPU를 놓는 것이 아니다.

타이머 인터럽트에 의해 강제로 CPU를 양보할 수 있다.

따라서 스케줄러는 interrupt, trap, yield와 함께 이해해야 한다.

---

### 12.5 측정과 평가

커널 코드를 수정했다고 해서 그것이 좋은 개선이라는 보장은 없다.

반드시 다음과 같은 기준으로 평가해야 한다.

- 정확히 동작하는가?
- 기존 기능을 망가뜨리지 않았는가?
- 성능이 좋아졌는가?
- 특정 프로세스가 굶지 않는가?
- lock 문제가 없는가?
- 측정값이 신뢰 가능한가?

---

## 13. xv6 학습 정리

```md
# 주제: xv6 스케줄러 구조 분석

## 1. 관련 파일
- kernel/proc.h
- kernel/proc.c
- kernel/trap.c
- kernel/swtch.S

## 2. 핵심 구조체
- struct proc
- struct cpu
- struct context
- struct trapframe

## 3. 핵심 필드
- p->state
- p->context
- p->trapframe
- p->kstack
- c->proc
- c->context

## 4. 실행 흐름
RUNNABLE 프로세스 발견
→ p->state = RUNNING
→ c->proc = p
→ swtch()
→ 프로세스 실행
→ timer interrupt
→ yield()
→ p->state = RUNNABLE
→ sched()
→ scheduler 복귀

## 5. 현재 구조의 한계
- priority 없음
- 실행 시간 기록 없음
- 프로세스별 CPU 점유율 측정 없음
- starvation 판단 기준 없음
- 정책 평가 지표 없음

## 6. 개선 아이디어
- proc에 priority 추가
- sched_count 추가
- runtime_ticks 추가
- scheduler에서 선택 기준 변경
- 실험용 user program 작성

## 7. 고려해야 할 위험
- lock 누락
- state 전이 오류
- starvation
- 측정 오버헤드
- fork 시 필드 복사 여부
- exec 시 필드 유지 여부
```

이런 형식으로 정리하면 단순한 코드 해석이 아니라, OS 기능이 어떤 구조를 통해 작동하고 어떤 기준으로 개선될 수 있는지 설명할 수 있다.

---

## 14. 학습 순서

```text
1. proc.h 분석
프로세스와 CPU가 어떤 데이터로 표현되는지 이해한다.

2. proc.c 분석
프로세스 생성, 종료, 대기, 스케줄링 흐름을 이해한다.

3. trap.c 분석
시스템 콜과 타이머 인터럽트가 커널로 들어오는 방식을 이해한다.

4. syscall.c 분석
사용자 요청이 실제 커널 함수로 연결되는 방식을 이해한다.

5. scheduler 실험
priority, sched_count, runtime_ticks 같은 필드를 추가해본다.

6. sleep/wakeup 분석
동기화와 lost wakeup 문제를 이해한다.

7. kalloc/vm 분석
메모리 할당과 주소 공간 변화를 이해한다.

8. file/fs 분석
파일 디스크립터와 파일 시스템 흐름을 이해한다.

9. 관찰 지점 설계
어떤 값을 로그로 남기면 OS 동작을 평가할 수 있는지 정리한다.
```

---

## 15. 최종 정리

xv6를 깊게 공부한다는 것은 단순히 커널 코드를 읽는 것이 아니다.

xv6의 커널 구조체와 실행 흐름을 분석하여, 하나의 OS 기능이 어떤 데이터 구조, 상태 전이, lock, interrupt, context switch를 통해 작동하는지 추적하는 것이다.

이를 통해 OS 프로그램 설계가 왜 어려운지 이해할 수 있다.

OS 프로그램 설계에서는 다음을 반드시 고려해야 한다.

```text
어떤 값을 저장할 것인가?
그 값은 누가 변경하는가?
그 값이 바뀌면 어떤 함수의 동작이 바뀌는가?
그 결과는 사용자 프로그램에서 어떻게 관찰되는가?
동시성 문제는 없는가?
lock은 올바르게 사용되는가?
상태 전이는 안전한가?
성능은 실제로 개선되었는가?
실패했을 때 되돌릴 수 있는가?
```
