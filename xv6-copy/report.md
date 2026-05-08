# xv6에서 LLM을 활용한 성능 개선 방안 10가지

작성 기준일: 2026-05-06

이 문서는 현재 저장소의 xv6-riscv 구현을 기준으로, "기존에는 이렇게 동작한다"와 "LLM을 활용하면 이렇게 성능 개선을 시도할 수 있다"를 10가지로 정리한 조사 보고서다. 여기서 핵심은 **LLM을 커널 내부에 넣는 것**이 아니라, **LLM을 오프라인 분석기, 자동 튜너, 패치 생성기, 실험 오케스트레이터**로 활용하는 것이다. xv6는 교육용 운영체제이므로, 모든 개선안은 성능과 함께 코드 복잡도 증가라는 대가를 가진다.

## 1. 스케줄러 정책 자동 탐색

현재 방식:
`kernel/proc.c`의 `scheduler()`는 `proc[]` 전체를 선형 탐색하면서 `RUNNABLE` 프로세스 중 가장 높은 우선순위를 고른다. 우선순위가 같으면 사실상 스캔 순서 기반의 round-robin에 가깝다.

LLM 활용 방식:
QEMU에서 수집한 실행 로그와 워크로드별 응답시간 데이터를 LLM에 넣고, "priority aging", "multi-level feedback queue", "interactive bias", "time slice 조정" 같은 후보 정책을 생성하게 한 뒤 자동 벤치마크 루프로 검증한다. LLM은 정책 초안을 만들고, 실제 선택은 측정값으로 한다.

기대 효과:
CPU-bound와 I/O-bound 프로세스가 섞인 경우 평균 대기시간과 문맥 전환 낭비를 줄일 수 있다. 현재처럼 전체 프로세스 테이블을 매번 훑는 단순 정책보다 workload-specific tuning이 가능하다.

주의점:
LLM이 제안한 정책은 직관적으로 그럴듯해도 starvation을 만들 수 있다. `usertests`, `priority_test`, 장시간 stress workload로 반드시 검증해야 한다.

## 2. 프로세스 선택 자료구조 개선

현재 방식:
`scheduler()`는 실행할 프로세스를 찾기 위해 `proc[]`를 끝까지 순회한다. 프로세스 수가 늘수록 선택 비용이 커진다.

LLM 활용 방식:
프로파일링 로그를 바탕으로 LLM이 "우선순위 큐", "per-priority runnable list", "per-CPU run queue" 중 어떤 구조가 현재 xv6 코드와 가장 작은 변경으로 맞는지 제안하게 한다. 이후 LLM이 패치 초안을 만들고 테스트 스크립트로 회귀를 확인한다.

기대 효과:
스케줄러 오버헤드를 `O(NPROC)` 스캔에서 더 낮은 비용 구조로 바꿀 수 있다. 특히 프로세스 수가 많거나 다중 CPU에서 락 경쟁이 커지는 경우 효과가 있다.

주의점:
xv6의 단순성을 해칠 가능성이 높다. 교육 목적을 유지하려면 실험 브랜치와 수업용 브랜치를 분리하는 편이 낫다.

## 3. 물리 페이지 할당기 락 경쟁 완화

현재 방식:
`kernel/kalloc.c`는 단일 `kmem.lock`과 단일 free list를 사용한다. 여러 CPU가 동시에 `kalloc()`/`kfree()`를 호출하면 하나의 스핀락에 병목이 집중된다.

LLM 활용 방식:
락 획득 횟수, 실패 횟수, CPU별 할당 패턴을 로그로 수집한 뒤 LLM에게 "per-CPU freelist", "stealing", "batch refill" 같은 설계를 비교하게 한다. 이후 LLM이 현재 코드 스타일에 맞는 최소 변경 패치를 생성하도록 한다.

기대 효과:
멀티코어에서 페이지 할당 경합을 줄여 `fork`, `exec`, page fault, pipe/file buffer 관련 경로를 전반적으로 빠르게 만들 수 있다.

주의점:
메모리 불균형과 stealing 정책이 필요해져 코드가 복잡해진다. 성능은 좋아질 수 있지만 xv6의 설명 가능성은 나빠진다.

## 4. lazy allocation의 fault-around 튜닝

현재 방식:
`kernel/vm.c`의 `vmfault()`는 page fault가 발생하면 해당 가상 페이지 1장만 할당한다. 연속 접근 workload에서는 fault가 너무 자주 난다.

LLM 활용 방식:
프로세스별 page fault trace를 기반으로 LLM이 "한 번 fault가 나면 인접 2~8페이지를 함께 할당", "프로그램 유형별 prefetch 거리 차등화" 같은 규칙을 제안하게 한다. 이 규칙은 정적이 아니라 벤치마크 결과를 다시 넣어 iterative tuning 한다.

기대 효과:
연속 메모리 접근이 많은 프로그램에서 trap 횟수와 `walk/mappages/kalloc` 호출 수를 줄일 수 있다.

주의점:
너무 공격적으로 prefetch하면 메모리 낭비가 커진다. 작은 메모리 환경에서는 오히려 성능이 나빠질 수 있다.

## 5. `fork()`의 eager copy를 copy-on-write로 전환

현재 방식:
`kernel/proc.c`의 `kfork()`는 `uvmcopy()`를 통해 부모 메모리를 자식에게 즉시 복사한다. `kernel/vm.c`의 `uvmcopy()`는 페이지마다 새 메모리를 할당하고 내용을 복사하므로 `fork()` 비용이 크다.

LLM 활용 방식:
LLM에게 현재 `fork`/`page fault`/PTE 플래그 흐름을 읽히고, copy-on-write 설계와 필요한 trap 처리 변경을 초안으로 작성하게 한다. 그 뒤 사람이 invariants를 검토하고, 자동 테스트로 안정성을 확인한다.

기대 효과:
`fork` 직후 `exec`하는 전형적 Unix 패턴에서 메모리 복사 비용이 크게 줄어든다. 프로세스 생성 지연과 메모리 대역폭 낭비를 함께 줄일 수 있다.

주의점:
정확성 리스크가 가장 큰 항목 중 하나다. 참조 카운트, write fault 처리, `copyout()` 경로까지 함께 손봐야 한다.

## 6. 버퍼 캐시 교체 정책과 해시 구조 최적화

현재 방식:
`kernel/bio.c`는 전역 락 하나와 LRU linked list 하나로 버퍼 캐시를 관리한다. 조회도 선형 탐색이고, 교체도 전역 구조에 의존한다.

LLM 활용 방식:
block access trace를 LLM에 제공해 "hash bucket + per-bucket lock", "sequential read-ahead", "metadata block 우선 유지", "workload별 replacement policy" 후보를 제안하게 한다. LLM은 사람이 놓치기 쉬운 access pattern 차이를 요약하는 데 강점이 있다.

기대 효과:
디스크 블록 탐색 비용과 락 경쟁을 줄일 수 있고, 파일시스템 메타데이터 접근이 잦은 workload에서 캐시 hit rate를 높일 수 있다.

주의점:
LRU를 깨는 순간 디버깅이 어려워진다. 캐시 정책은 좋아 보여도 특정 workload에서는 역효과가 날 수 있으므로 trace 재현이 중요하다.

## 7. 파일시스템 로그 commit batching 자동 튜닝

현재 방식:
`kernel/log.c`는 outstanding FS operation이 0이 되면 commit한다. 구조는 단순하지만 작은 write가 많은 경우 commit 빈도가 높아져 I/O 비용이 커질 수 있다.

LLM 활용 방식:
`logstress` 같은 workload의 commit 간격, block 수, syscall mix를 입력으로 넣고, LLM이 "짧은 지연을 허용한 group commit", "write coalescing", "commit threshold 조정" 같은 정책을 제안하게 한다. 이후 테스트 루프로 내구성과 성능을 함께 본다.

기대 효과:
작은 파일 쓰기 workload에서 디스크 write 횟수와 로그 오버헤드를 줄일 수 있다.

주의점:
내구성 모델이 바뀌므로 crash recovery 테스트가 필수다. `test-xv6.py`의 log recovery 경로를 반드시 유지해야 한다.

## 8. inode/block allocator의 탐색 힌트 자동 도입

현재 방식:
`kernel/fs.c`의 `balloc()`와 `ialloc()`는 비트맵/아이노드 영역을 선형 스캔한다. 디스크가 커지거나 파일 생성이 많아지면 할당 탐색 비용이 커진다.

LLM 활용 방식:
워크로드별 파일 생성/삭제 패턴을 보고 LLM이 "last allocated hint", "free summary cache", "per-cylinder-like locality heuristic" 같은 간단한 힌트 구조를 제안하게 한다. xv6에 맞게 가장 작은 상태값 추가안을 고르게 할 수 있다.

기대 효과:
반복적인 파일 생성/삭제에서 allocation path를 단축할 수 있고, 불필요한 bitmap block read도 줄일 수 있다.

주의점:
힌트는 어디까지나 힌트라서, 일관성보다 성능만 노리면 안 된다. 힌트가 깨져도 correctness는 유지되도록 설계해야 한다.

## 9. 시스템콜 데이터 복사 경로 최적화

현재 방식:
`kernel/vm.c`의 `copyin()`/`copyout()`은 페이지 경계를 넘을 때마다 주소 변환과 복사를 반복한다. 현재 구현은 단순하고 안전하지만 대용량 I/O에서 비효율적일 수 있다.

LLM 활용 방식:
LLM이 syscall trace와 버퍼 크기 분포를 보고 "짧은 복사 경로와 큰 복사 경로 분리", "page-walk 결과 재사용", "빈번한 경로 인라인화", "copyin/copyout 호출 site 재구성" 후보를 제안하게 한다. 여기에 compiler output과 실행 시간을 다시 피드백해 반복 튜닝한다.

기대 효과:
`read`, `write`, `exec`, pathname 처리 같은 경로에서 메모리 복사 오버헤드를 줄일 수 있다.

주의점:
이 영역은 보안과 정확성 민감도가 높다. 속도 때문에 user/kernel 경계 검사를 약화시키면 안 된다.

## 10. 컴파일 옵션과 코드 형태 자동 탐색

현재 방식:
`Makefile`은 전반적으로 보수적인 `-O` 기반 설정을 사용한다. 사람이 직접 `-O2`, `-O3`, 함수 인라인, 분기 힌트, 루프 변환 등을 일일이 비교하지는 않는다.

LLM 활용 방식:
LLM을 실험 오케스트레이터로 두고, `make`, QEMU 실행, 사용자 벤치마크, 코드 크기 비교를 자동 루프로 돌리며 최적화 조합을 탐색한다. 예를 들어 스케줄러/메모리 관리/문자열 함수에 한정해 함수별 인라인 또는 분기 재배치를 제안하게 할 수 있다.

기대 효과:
커널 전체 구조를 바꾸지 않고도 일정 수준의 실행시간 개선을 얻을 수 있다. 특히 hot path가 분명한 교육용 커널에서는 비용 대비 효과가 괜찮을 수 있다.

주의점:
최근 연구는 LLM이 전통적 컴파일러를 완전히 대체하지는 못한다고 본다. 따라서 "LLM이 제안, 컴파일러와 벤치마크가 판정" 구조가 적절하다.

## 우선순위 제안

실제로 해볼 가치가 높은 순서는 다음과 같다.

1. `kalloc`의 per-CPU freelist 실험
2. scheduler 정책 및 runnable queue 구조 실험
3. buffer cache 해시화와 lock 분산
4. log commit batching 실험
5. `fork()`의 copy-on-write 실험

이 다섯 가지는 xv6에서 병목이 비교적 뚜렷하고, QEMU 상에서도 실험 결과를 관찰하기 쉽다.

## 현실적인 적용 방법

가장 현실적인 워크플로는 다음과 같다.

1. `test-xv6.py`와 사용자 프로그램으로 workload를 만든다.
2. 커널에 간단한 tracing counter를 추가해 락 경쟁, page fault, block I/O, scheduler 선택 횟수를 수집한다.
3. 로그를 LLM에 넣어 병목 원인과 후보 패치를 생성하게 한다.
4. 생성된 패치를 별도 브랜치에 적용하고 `usertests`, crash recovery, microbenchmark를 자동 실행한다.
5. 성능과 정확성이 모두 통과한 안만 채택한다.

즉, LLM은 "최적화 결정을 대신 내리는 존재"라기보다, **탐색 공간을 줄이고 패치 초안을 빠르게 만드는 보조 최적화 엔진**으로 쓰는 것이 맞다.