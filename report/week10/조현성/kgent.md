# Kgent 학습 정리

> 본 문서는 디렉토리 내 `OS_development(kgent).md`, `kgent요약.md` 파일의 내용과 웹에서 추가로 수집한 정보(Kgent 논문, KEN GitHub, Eunomia 블로그, KEN arXiv 등)를 통합하여 **Kgent가 어떤 시스템이며 어떤 영역(메모리, 스케줄링, 시스템콜 등)을 다루는지** 정리한 학습용 자료이다.

---

## 1. Kgent 한 줄 정의

**Kgent**는 사용자가 **자연어**로 표현한 운영체제(커널) 관찰·확장 요구사항을, **LLM**을 이용해 **eBPF 프로그램**으로 자동 생성하고, **Symbolic Verifier + eBPF Verifier**로 검증하는 **커널 확장용 LLM 에이전트(Kernel Extensions Large Language Model Agent)** 이다.

- 논문: Yusheng Zheng, Yiwei Yang, Maolin Chen, Andrew Quinn, **"Kgent: Kernel Extensions Large Language Model Agent"**, ACM SIGCOMM 2024 Workshop on eBPF and Kernel Extensions (eBPF '24), pp. 30–36.
- DOI: `10.1145/3672197.3673434`
- 코드: [eunomia-bpf/KEN](https://github.com/eunomia-bpf/KEN) (이전 arXiv 명칭: **KEN — Kernel Extensions using Natural Language**, arXiv:2312.05531)
- 소속: UC Santa Cruz (SSRC / CRSS) — Eunomia 그룹 협력
- 라이선스: MIT

---

## 2. Kgent가 다루는 영역 (한눈에 보기)

Kgent는 **eBPF가 닿을 수 있는 커널 관찰·확장 도메인**을 모두 잠재 대상으로 한다. 다만 논문/구현에서 실제로 검증된 영역은 다음과 같이 정리할 수 있다.

| 카테고리 | Kgent가 다루는 부분 | 비고 |
|---|---|---|
| **시스템 콜(Syscall)** | execve, ptrace 등 syscall 진입/종료 추적 | 보안 모니터링 사례 다수 |
| **프로세스 / 스케줄링 관찰** | 프로세스 fork, 실행, 종료 이벤트 추적, 스케줄러 hook 관찰 | OS_development(kgent) 제안서에서 강조 |
| **메모리 관찰** | 메모리 할당/접근 지점 추적, map 사용량 관찰 | 안전성 영역과 직접 연관 |
| **네트워크** | TCP 연결(`tcp_connect_init` 등) IPv4/IPv6 추적, 포트별 패킷 카운트/차단 | 논문 대표 사례 |
| **보안 모니터링** | fork bomb 탐지, ptrace 감시 등 침입 탐지 | 사례 연구에 포함 |
| **성능 / Tracing** | bpftrace 형식의 latency, throughput, 이벤트 카운팅 | bpftrace 지원이 가장 성숙 |

> Kgent의 다루는 "영역"은 본질적으로 **eBPF 프로그램이 attach할 수 있는 모든 hook point** 이다. 즉 "메모리/스케줄링/시스템콜"은 Kgent의 *고정 기능 모듈* 이 아니라 **사용자가 자연어 요구사항으로 지시한 도메인에 따라 동적으로 생성되는 eBPF 코드의 대상 영역**이다.

### 2.1 지원되는 Attach Point
- `kprobe` / `kretprobe`
- `tracepoint`
- `perf event`
- (네트워크) `XDP`, `socket` 계열 — 언급되나 bpftrace 위주
- 시스템콜 hook

### 2.2 지원되는 eBPF 작성 방식
- **bpftrace** — Kgent에서 가장 정확도가 높은 형식 (성공률 ~60%)
- **libbpf** (C 기반) — 지원은 되나 symbolic verifier에서 상태 폭발로 인해 정확도가 낮음 (~37.5%)

---

## 3. Kgent의 동기: 왜 만들었는가

eBPF는 커널을 직접 수정하지 않고 안전하게 커널 확장 코드를 동작시키는 강력한 도구이지만, 다음 이유로 진입 장벽이 높다.

- **커널 내부 지식 필요**: hook point, helper function, 컨텍스트 구조 이해 필요
- **eBPF Verifier 제약**: 무한 루프 금지, 메모리 접근 제한, 포인터 연산 제한 등
- **디버깅 난이도**: verifier 실패 시 메시지가 난해함
- **숙련된 커널 개발자만 다룰 수 있음** → junior sysadmin, DevOps에게 사실상 닫혀있음

→ **Kgent는 "자연어 → eBPF 코드 → 검증"의 완전 자동 파이프라인**으로 이 장벽을 낮추는 것을 목표로 한다.

---

## 4. Kgent의 시스템 아키텍처

Kgent는 크게 **3개의 상위 컴포넌트**, 그 안에 **세부 엔진들**로 구성된다.

### 4.1 상위 3대 컴포넌트 (Eunomia 블로그 기준)

| 컴포넌트 | 역할 |
|---|---|
| **Plan** | Prompter → Synthesis → Comprehension → Symbolic Verifier로 이어지는 핵심 생성·검증 파이프라인 |
| **Tools** | `clang`(컴파일), **SeaHorn**(symbolic execution), **Z3**(SMT solver), **bpftrace**(실행/검증) |
| **Memory** | 과거 행동, 오류, 결정사항을 단기 메모리로 보관 → feedback loop 성공률 향상 |

### 4.2 Plan 내부의 4개 엔진

#### (1) Prompter
- 사용자 자연어 요구사항을 LLM에 전달할 prompt로 가공
- 이전 반복의 verifier 실패 메시지, semantic 오류, 예제, 지시문을 **누적**해서 prompt에 포함
- 단순 입력창이 아니라 **feedback loop의 중심 모듈**

#### (2) Synthesis Engine
- LLM(기본 **ChatGPT-4**)을 호출하여 eBPF 후보 코드 생성
- **VectorDB + eBPFNLDataset** 활용 (retrieval-augmented generation)
  - `eBPFNLDataset`: 자연어 ↔ eBPF 코드 쌍 약 **145개** (블로그 수집 65 + 수작업 80)
  - bpftrace, libbpf 두 형식 모두 포함
- 출력: 검증 전 후보 코드(`eBPF Candidate`)

#### (3) Comprehension Engine — Kgent의 핵심 차별점
- 후보 코드가 호출하는 커널 함수에 대해 **Hoare logic 기반 전제조건/사후조건**을 생성
- `assume` / `assert` 어노테이션 형태로 코드에 삽입
- `KernelCompDataset`: 커널 함수별 기초 contract 데이터셋 (자동 생성, sound/complete 보장은 없음)
- **자연어 요구사항 ↔ 코드 사이의 의미를 검증 가능한 형식 조건으로 변환**

**예시 — `tcp_connect` 추적:**
```c
// assume: $sk != 0                                  // 포인터 유효성
// assume: sizeof($skp->__sk_common.skc_v6_daddr) == 4
//         || sizeof(...) == 16                       // IPv4 또는 IPv6
// ...
// assert: $dport == bswap($sk->__sk_common.skc_dport) // 바이트 순서 변환 검증
```

#### (4) Symbolic Verifier
- **SeaHorn + Z3**로 symbolic execution 수행
- assume/assert가 모든 경로에서 만족되는지 확인
- 통과 시 → assume/assert 제거 → eBPF Verifier로 전달
- 실패/Timeout 시 → 오류 메시지를 Prompter로 feedback

#### (5) (커널의) eBPF Verifier
- Linux 커널 내장 verifier — Kgent의 마지막 검증 단계
- 검사 항목:
  - 무한 루프 / 종료 비보장 루프
  - 허용되지 않은 메모리 접근, 미초기화 값
  - 잘못된 포인터 연산
  - helper function 호출 위반
  - 프로그램 타입과 맞지 않는 context 접근

### 4.3 전체 파이프라인 흐름

```
[자연어 요구사항]
       │
       ▼
   Prompter ◀──────────── (feedback: 이전 오류 메시지)
       │
       ▼
 Synthesis Engine ─── VectorDB(eBPFNLDataset)
       │
       ▼
 Comprehension Engine ─── KernelCompDataset
       │ (assume/assert 삽입)
       ▼
 Symbolic Verifier (SeaHorn + Z3)
       │       │
   pass│       │fail / timeout ──► Prompter (재생성)
       │
       ▼ (assume/assert 제거)
 eBPF Verifier (커널)
       │       │
   pass│       │fail ──► Prompter (재생성)
       │
       ▼
   [최종 eBPF 프로그램]
```

---

## 5. 평가 결과 (논문/arXiv 기준)

| 시스템 | 정확도 (Accuracy) | False Positive | False Negative |
|---|---:|---:|---:|
| ChatGPT-4 단독 baseline | 30% | 2.5% | 67.5% |
| **Kgent (KEN)** | **80%** | **2.5%** | **17.5%** |

- GPT-4 단독 대비 **2.67배** 정확도 향상
- 40개 테스트 중 37개에서 baseline 초과, 11개는 9배 이상 향상
- False positive(verifier 통과했지만 의미적으로 틀린 코드)가 매우 적음 → Comprehension Engine + Symbolic Verifier 결합 덕

### 5.1 LLM 모델 비교
- **ChatGPT-4** (기본) — 가장 성능 우수
- CodeLLaMA-7B / 13B, WizardLM-7B / 13B — 로컬 배포 비교
- ChatGPT-4가 로컬 모델 대비 약 **5.3배** 우수

### 5.2 형식별 정확도
- bpftrace: ~60%
- libbpf: ~37.5% (symbolic execution의 state explosion 문제)

---

## 6. 리포지토리 구조 (eunomia-bpf/KEN)

```
KEN/
├── dataset/
│   ├── libbpf/output.json        # libbpf 예제 DB
│   ├── bpftrace/output.json      # bpftrace 예제 DB
│   └── spec/
│       ├── helper_spec.json      # helper 함수 Z3 사양
│       └── kprobe_spec.json      # kprobe 함수 Z3 사양
├── evaluation/                   # 평가 코드
├── examples/                     # 예제
├── ken/                          # 핵심 모듈
└── bpftrace/                     # bpftrace 서브모듈
```

언어 비율: C 68.9%, SMT 1.5%, Python 1.1%

---

## 7. Kgent의 의의 (논문이 보여주는 것)

1. **자연어 ↔ 커널 코드** 간극을 LLM으로 자동화
2. **LLM 두 번 활용**: 코드 생성(Synthesis) + 코드 이해(Comprehension)
   → 한 모델이 만든 코드를 같은 모델이 의미 조건으로 변환 → symbolic verifier가 검사
3. **Symbolic Verifier + eBPF Verifier 이중 검증**으로 false positive를 강력히 억제
4. **Feedback loop**로 단발 실패를 학습하며 재시도

---

## 8. Kgent의 한계 (논문 + 디렉토리 제안서 시각)

### 8.1 논문이 자인하는 한계
- **libbpf 지원 미흡** — symbolic execution의 상태 폭발 문제
- **데이터셋 규모 작음** — 145개 (블로그 65 + 수작업 80)
- **Windows 미지원** — 현재 Linux만
- **KernelCompDataset의 sound/complete 보장 없음** — 자동 생성 contract라 false positive 위험 잔존
- **100줄 이하 소규모 프로그램에 집중** — 대규모/복잡 작업은 향후 과제

### 8.2 본 디렉토리 제안서가 추가로 지적하는 한계
- **"verifier-safe" ≠ "optimal"** — verifier 통과해도 성능이 최적이라는 보장은 없음
- **명시적 성능 평가 단계 부재** — 오버헤드/처리량/메모리 효율 등을 핵심 루프에 포함하지 않음
- **유형별 평가 기준 부재** — tracing, network filtering, security monitoring은 평가 축이 다름에도 동일 기준 적용

---

## 9. 본 디렉토리(`UNIV_Playground/kagent/`)의 제안 — 확장 구조

`OS_development(kgent).md`는 위 한계를 해결하기 위해 **검증 이후의 평가·최적화 루프**를 추가한 8단계 확장 파이프라인을 제안한다.

```
1. Generate   — 자연어 → eBPF 후보 생성  (기존 Synthesis)
2. Verify     — Symbolic Verifier + eBPF Verifier  (기존)
3. Checkpoint — 검증 통과 코드를 안전 후보로 저장  (신규)
4. Classify   — Tracing / Network / Security / Scheduling / Memory 등 유형 분류  (신규)
5. Score      — 유형별 가중치로 성능·메모리·품질·목적적합성 평가  (신규)
6. Optimize   — 낮은 점수 항목 중심 제한 수정  (신규)
7. Re-verify  — 수정 코드 재검증  (신규)
8. Accept / Rollback — 성공 시 새 checkpoint, 실패 시 마지막 checkpoint 복귀  (신규)
```

핵심 원칙:
- verifier는 **hard constraint**, 성능·메모리·품질은 **soft objective**
- 최적화는 **checkpoint 이후의 안전 후보만** 대상으로
- 최적화 후 **반드시 재검증**, 실패 시 **rollback**

### 9.1 Tag 기반 분류 체계 (제안서)
| Tag 종류 | 예시 |
|---|---|
| 목적 tag | tracing, filtering, monitoring, profiling, security |
| attach point tag | kprobe, tracepoint, xdp, socket, syscall |
| verifier tag | passed, memory_error, loop_error, pointer_error |
| 성능 tag | high_overhead, low_overhead, frequent_event |
| 자원 tag | map_heavy, stack_sensitive, helper_heavy |
| 최적화 tag | reduce_map_access, simplify_condition, reduce_output |

### 9.2 유형별 가중치 (Tracing 프로그램 예시)
| 평가 항목 | 가중치 |
|---|---:|
| 목적 적합성 | 0.30 |
| 성능 오버헤드 | 0.25 |
| 안전성 | 0.20 |
| 메모리 효율 | 0.15 |
| 코드 품질 | 0.10 |

### 9.3 xv6 환경에서의 축소 실험
- xv6는 실제 eBPF/verifier가 없으므로 **eBPF-like 관찰 코드 + 정적 검사기**로 대체
- "생성 → 검증 → 평가 → 개선 → 재검증"이라는 **구조적 가능성**을 작은 OS에서 검증하는 실험 환경

---

## 10. 핵심 용어 정리 (학습용 치트시트)

| 용어 | 의미 |
|---|---|
| **eBPF** | extended Berkeley Packet Filter. 커널을 수정하지 않고 sandbox 안에서 커널 hook에 코드를 attach하는 메커니즘 |
| **eBPF Verifier** | Linux 커널 내장 안전성 검증기. 메모리 접근, 루프, 포인터, helper 호출을 정적 분석 |
| **bpftrace** | DTrace-like 고수준 eBPF 추적 언어. Kgent에서 가장 성공률 높음 |
| **libbpf** | C 기반 저수준 eBPF 작성 라이브러리. Kgent의 symbolic verifier에 부담 큼 |
| **kprobe** | 커널 함수 진입점에 동적으로 hook을 거는 메커니즘 |
| **tracepoint** | 커널 코드 내 명시적으로 정의된 정적 hook point |
| **Hoare logic** | `{P} S {Q}` — 사전조건 P에서 S 실행 후 사후조건 Q 보장 |
| **Symbolic execution** | 입력값을 기호로 두고 모든 가능한 경로를 분석하는 기법 |
| **SeaHorn / Z3** | Kgent가 symbolic verification에 사용하는 도구. SeaHorn은 LLVM 기반 모델 체커, Z3는 Microsoft SMT solver |
| **Helper function** | eBPF 프로그램이 호출 가능한 커널 측 함수(예: `bpf_get_current_pid_tgid`) |
| **VectorDB** | 임베딩 기반 유사 예제 검색 DB. eBPFNLDataset을 인덱싱 |
| **eBPFNLDataset** | 자연어 ↔ eBPF 코드 쌍 데이터셋 (145개) |
| **KernelCompDataset** | 커널 함수별 Hoare-logic contract 데이터셋 |

---

## 12. 참고 자료

1. Zheng, Yang, Chen, Quinn — **"Kgent: Kernel Extensions Large Language Model Agent"**, ACM SIGCOMM 2024 Workshop on eBPF and Kernel Extensions. DOI: [10.1145/3672197.3673434](https://doi.org/10.1145/3672197.3673434)
2. **eunomia-bpf/KEN** GitHub Repository — https://github.com/eunomia-bpf/KEN
3. KEN arXiv 초기본 (KEN: Kernel Extensions using Natural Language) — https://arxiv.org/abs/2312.05531
4. Eunomia 블로그, **"Simplifying Kernel Programming: The LLM-Powered eBPF Tool"** — https://eunomia.dev/blogs/kgent/
5. SSRC 공식 페이지 — https://ssrc.us/pub/kgent-ebpf24.html
6. Linux Kernel Documentation, **eBPF verifier** — https://docs.kernel.org/bpf/verifier.html
7. 본 디렉토리 내부 자료
   - `OS_development(kgent).md` — Kgent 기반 검증 심층구조 설계 제안서
   - `kgent요약.md` — 위 제안서의 요약 및 xv6 연결점
