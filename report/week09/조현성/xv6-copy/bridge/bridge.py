#!/usr/bin/env python3
"""bridge.py — host-side LLM bridge for the xv6 LLM-for-OS project.

Spawns `make qemu` (or any command given on the CLI), then proxies the
QEMU console between the human user and an Upstage Solar Pro 3 model.

Protocol with the xv6-side user programs (llmsh, schedhint, osdoc):

  xv6 → bridge                         bridge → xv6
  --------------------------------     --------------------------------
  <<LLM>> <free text>                  <<EXEC>> argv0 [arg1 ...]
                                       <<DENY>> <reason>

  <<PROCS>> ... <<PROCS_END>>          <<SETPRI>> <pid> <delta>
                                       <<NOOP>>

  <<DOC>> <free text>                  <<TRACE_MASK>> <hex_mask> <ticks>

Anything outside the marker protocol is passed through to the user's
terminal verbatim, so a regular xv6 shell session still works.

The LLM is *required* to return a strict JSON object matching one of
three schemas (see prompts/system.txt). Any reply that is not valid
JSON, or whose `argv[0]` is not in the whitelist, is converted into a
<<DENY>> line — never executed.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import threading
from pathlib import Path
from typing import Optional

# Optional dependency: openai SDK (Solar is OpenAI-API-compatible).
try:
    from openai import OpenAI
except ImportError:
    OpenAI = None

WHITELIST = {
    "ls", "cat", "echo", "grep", "wc", "mkdir", "rm", "ln",
    "sysinfo_test", "trace_test", "priority_test", "schedhint", "osdoc",
}

PROMPT_DIR = Path(__file__).parent / "prompts"


def load_prompt(name: str) -> str:
    return (PROMPT_DIR / name).read_text(encoding="utf-8")


class SolarClient:
    """Thin wrapper around the OpenAI SDK pointed at Upstage's endpoint."""

    def __init__(self, api_key: str, model: str = "solar-pro2"):
        if OpenAI is None:
            raise RuntimeError(
                "openai package not installed. Run: pip install openai"
            )
        self.client = OpenAI(
            api_key=api_key,
            base_url="https://api.upstage.ai/v1",
        )
        self.model = model

    def chat(self, system: str, user: str) -> str:
        resp = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
            temperature=0.0,
            response_format={"type": "json_object"},
        )
        return resp.choices[0].message.content or "{}"


def safe_argv(reply: dict) -> Optional[list[str]]:
    """Validate an LLMSH reply against the whitelist."""
    argv = reply.get("argv")
    if not isinstance(argv, list) or not argv:
        return None
    if not all(isinstance(a, str) for a in argv):
        return None
    if argv[0] not in WHITELIST:
        return None
    # Reject shell metacharacters that xv6 sh.c would mis-handle anyway.
    if any(re.search(r"[;&|<>$`]", a) for a in argv):
        return None
    return argv


def handle_llm(question: str, solar: SolarClient) -> str:
    """Resolve a <<LLM>> question → an EXEC/DENY reply line."""
    try:
        raw = solar.chat(load_prompt("llmsh.txt"), question)
        reply = json.loads(raw)
    except (json.JSONDecodeError, Exception) as e:
        return f"<<DENY>> bridge error: {e}"
    argv = safe_argv(reply)
    if not argv:
        rsn = reply.get("rationale", "rejected by policy")
        return f"<<DENY>> {rsn}"
    return "<<EXEC>> " + " ".join(argv)


def handle_procs(snapshot: list[str], solar: SolarClient) -> str:
    """Resolve a <<PROCS>>...<<PROCS_END>> dump → SETPRI/NOOP reply."""
    try:
        raw = solar.chat(load_prompt("schedhint.txt"), "\n".join(snapshot))
        reply = json.loads(raw)
    except (json.JSONDecodeError, Exception) as e:
        return f"<<NOOP>>  # bridge error: {e}"
    if reply.get("action") != "setpri":
        return "<<NOOP>>"
    pid = int(reply.get("pid", 0))
    delta = int(reply.get("delta", 0))
    if pid <= 0 or abs(delta) > 5:
        return "<<NOOP>>"
    return f"<<SETPRI>> {pid} {delta}"


def handle_doc(question: str, solar: SolarClient) -> str:
    """Resolve a <<DOC>> question → a trace mask + duration."""
    try:
        raw = solar.chat(load_prompt("osdoc.txt"), question)
        reply = json.loads(raw)
    except (json.JSONDecodeError, Exception) as e:
        return f"<<TRACE_MASK>> 0 0  # bridge error: {e}"
    mask = int(reply.get("mask", 0))
    ticks = int(reply.get("ticks", 30))
    if mask <= 0:
        return "<<TRACE_MASK>> 0 0"
    return f"<<TRACE_MASK>> 0x{mask:x} {ticks}"


class Bridge:
    """Glue between QEMU stdio and the LLM."""

    def __init__(self, solar: Optional[SolarClient], qemu_cmd: list[str], cwd: str):
        self.solar = solar
        self.proc = subprocess.Popen(
            qemu_cmd,
            cwd=cwd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,  # line-buffered
        )
        self._procs_buf: list[str] = []
        self._collecting_procs = False

    def write_xv6(self, line: str) -> None:
        if not line.endswith("\n"):
            line += "\n"
        assert self.proc.stdin is not None
        self.proc.stdin.write(line)
        self.proc.stdin.flush()

    def _maybe_intercept(self, line: str) -> bool:
        """Return True if the line was a protocol marker we handled."""
        stripped = line.rstrip("\r\n")
        if stripped == "<<PROCS>>":
            self._procs_buf = []
            self._collecting_procs = True
            return True
        if stripped == "<<PROCS_END>>":
            self._collecting_procs = False
            if self.solar:
                self.write_xv6(handle_procs(self._procs_buf, self.solar))
            else:
                self.write_xv6("<<NOOP>>")
            return True
        if self._collecting_procs:
            self._procs_buf.append(stripped)
            # Still echo so the user sees the snapshot.
            sys.stdout.write(line)
            sys.stdout.flush()
            return True
        if stripped.startswith("<<LLM>>"):
            question = stripped[len("<<LLM>>"):].strip()
            if self.solar:
                self.write_xv6(handle_llm(question, self.solar))
            else:
                self.write_xv6("<<DENY>> bridge offline")
            return True
        if stripped.startswith("<<DOC>>"):
            question = stripped[len("<<DOC>>"):].strip()
            if self.solar:
                self.write_xv6(handle_doc(question, self.solar))
            else:
                self.write_xv6("<<TRACE_MASK>> 0 0")
            return True
        return False

    def read_loop(self) -> None:
        assert self.proc.stdout is not None
        for line in self.proc.stdout:
            if not self._maybe_intercept(line):
                sys.stdout.write(line)
                sys.stdout.flush()

    def stdin_loop(self) -> None:
        # Pass user keystrokes through to QEMU so a normal sh session
        # remains usable alongside llmsh.
        for line in sys.stdin:
            self.write_xv6(line.rstrip("\n"))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--qemu-cmd",
        default="make qemu-nox",
        help="Command to launch QEMU+xv6 (default: 'make qemu-nox').",
    )
    parser.add_argument(
        "--cwd",
        default=str(Path(__file__).resolve().parent.parent),
        help="Directory the qemu command runs in (default: xv6 root).",
    )
    parser.add_argument(
        "--offline",
        action="store_true",
        help="Skip Solar API; reject all LLM requests with <<DENY>>.",
    )
    parser.add_argument(
        "--model",
        default=os.environ.get("UPSTAGE_MODEL", "solar-pro2"),
    )
    args = parser.parse_args()

    solar: Optional[SolarClient] = None
    if not args.offline:
        api_key = os.environ.get("UPSTAGE_API_KEY")
        if not api_key:
            print("warning: UPSTAGE_API_KEY not set, running in --offline mode",
                  file=sys.stderr)
        else:
            try:
                solar = SolarClient(api_key=api_key, model=args.model)
            except Exception as e:
                print(f"warning: cannot init Solar client ({e}); offline mode",
                      file=sys.stderr)

    bridge = Bridge(
        solar=solar,
        qemu_cmd=args.qemu_cmd.split(),
        cwd=args.cwd,
    )

    reader = threading.Thread(target=bridge.read_loop, daemon=True)
    reader.start()
    try:
        bridge.stdin_loop()
    except KeyboardInterrupt:
        pass
    finally:
        bridge.proc.terminate()
        bridge.proc.wait(timeout=5)
    return 0


if __name__ == "__main__":
    sys.exit(main())
