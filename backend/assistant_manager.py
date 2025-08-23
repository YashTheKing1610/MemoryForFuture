# E:\MemoryForFuture\backend\assistant_manager.py

import os
import sys
import subprocess
import threading
from typing import Optional

_process: Optional[subprocess.Popen] = None

def _script_path() -> str:
    here = os.path.dirname(os.path.abspath(__file__))
    return os.path.join(here, "azure_voice_assistant_api.py")  # Correct script name

def print_output(pipe):
    for line in iter(pipe.readline, ''):
        if line:
            print(f"[Assistant Subprocess] {line.strip()}")

def start_assistant():
    global _process
    if _process and _process.poll() is None:
        print(f"[AssistantManager] Assistant already running with PID {_process.pid}")
        return {"status": "already_running", "pid": _process.pid}

    cmd = [sys.executable, _script_path()]
    print(f"[AssistantManager] Starting assistant subprocess with command: {cmd}")
    _process = subprocess.Popen(
        cmd,
        cwd=os.path.dirname(_script_path()),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        creationflags=subprocess.CREATE_NEW_PROCESS_GROUP if os.name == "nt" else 0,
    )
    # Start thread to print assistant output
    threading.Thread(target=print_output, args=(_process.stdout,), daemon=True).start()
    print(f"[AssistantManager] Assistant started with PID {_process.pid}")
    return {"status": "started", "pid": _process.pid}

def stop_assistant():
    global _process
    if not _process or _process.poll() is not None:
        print(f"[AssistantManager] No running assistant found to stop")
        return {"status": "not_running"}

    print(f"[AssistantManager] Terminating assistant with PID {_process.pid}")
    _process.terminate()
    try:
        _process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        print(f"[AssistantManager] Killing assistant with PID {_process.pid} after timeout")
        _process.kill()
    _process = None
    print(f"[AssistantManager] Assistant stopped")
    return {"status": "stopped"}
