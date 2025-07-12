# Chapter 3: Operating Systems

## Terminology
- **Operating system**: Software and files that allow the system to boot and run programs.
- **Kernel**: Core system program managing memory, CPU, devices, etc.
- **Process**: Executable instance with its own memory and context.
- **Thread**: Lightweight execution context within a process.
- **Task**: A Linux abstraction of a thread or process.
- **BPF Program**: Code running in-kernel using extended BPF.
- **Context Switch**: Switching CPU execution between threads or tasks.
- **Mode Switch**: Transition between user mode and kernel mode.
- **System Call (syscall)**: User space → kernel interface for privileged operations.
- **Trap**: A triggered software interrupt.
- **Hardware Interrupt**: Signals from devices requesting CPU attention.

## Background

### Kernel
- Monolithic kernels manage all OS components (memory, CPU, devices).
- Examples: Linux, BSD.

### Kernel and User Modes
- CPU operates in two modes:
  - **User mode**: Limited privilege.
  - **Kernel mode**: Full hardware access.

### System Calls
- Interface for user programs to request kernel actions.
- Implemented via `int 0x80`, `syscall`, or VDSO (Linux).

### Interrupts
- **Asynchronous**: Triggered by devices (e.g. disk complete, packet arrival).
- **Synchronous**: Triggered by software (traps, exceptions).
- **ISRs**: Interrupt Service Routines; can defer heavy work to bottom halves (tasklets, work queues).
- **Interrupt Masking**: Prevents unsafe reentrancy during critical sections.

### Clock and Idle
- **Clock**: Timer interrupt, used for accounting, scheduling.
- **Idle Thread**: Placeholder when no work exists; may halt CPU for power savings.
- Modern Linux supports **tickless kernel** via `CONFIG_NO_HZ`.

### Processes
- Each process has memory, stacks, file descriptors.
- Linux supports thousands of simultaneous processes via PID.

### Stacks
- Stack stores thread execution state.
- Stack overflows → segmentation faults.

### Virtual Memory
- Each process has an isolated address space.
- Allows overcommit, paging, and protection.

### Schedulers
- Decide which threads run.
- Support for multiple policies (e.g. real-time, fair).

### File Systems
- Organize and store data using a global hierarchy (`/`, `/home`, `/var`, etc.).
- Support mounting, VFS abstraction, namespaces.

### Caching
- Disk I/O is cached at many levels: app, OS, file system, device.
- Linux caches: page cache, buffer cache, inode cache, etc.

### Networking
- Kernel provides TCP/IP stack.
- Applications use sockets to send/receive.

### Device Drivers
- Kernel modules interfacing with hardware (e.g. NICs, block devices).

### Multiprocessor
- Support for SMP (symmetric multiprocessing).
- CPU affinity and scheduling support.

### Preemption
- Kernel supports voluntary and preemptive multitasking.

### Resource Management
- Limits and priorities for CPU, memory, and I/O access.

### Observability
- Metrics, traces, logs for visibility into system internals.

## Kernels

### Unix
- Original system defining kernel principles.

### BSD
- Academic branch of Unix; performance-focused.

### Solaris
- Enterprise Unix with advanced observability (DTrace).

## Linux

### Linux Kernel Developments
- Enhancements in versions 3.1–5.8: `io_uring`, multi-queue I/O, eBPF, etc.
- Performance improvements for NUMA, schedulers, file systems.

### systemd
- Modern Linux init system with service supervision and startup timing:

```bash
systemd-analyze
systemd-analyze critical-chain
