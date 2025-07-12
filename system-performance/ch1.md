# Chapter 1: Introduction to Systems Performance

## Systems Performance
- Study of system behavior across stack: application -> kernel -> hardware.
- Goals: minimize latency, maximize throughput, improve scalability.
- Activities: monitoring, tuning, benchmarking, capacity planning.

## Roles
- Involves multiple functions:
  - **SREs**: Maintain SLAs, debug infrastructure.
  - **Developers**: Optimize application logic and system usage.
  - **System Administrators**: Maintain OS and server performance.
  - **DBAs**: Optimize data access and query performance.

## Activities
- Set performance objectives.
- Model system behavior.
- Benchmark and test under expected loads.
- Tune configurations and application code.
- Troubleshoot production issues.
- Conduct postmortems and performance reviews.

## Perspectives
- **Workload Analysis**: Application-level behavior (e.g., request latency).
- **Resource Analysis**: System-level metrics (e.g., CPU, memory, I/O usage).

## Performance Is Challenging

### Subjectivity
- Performance is context-specific. “Fast” varies by workload and user.

### Complexity
- Involves multiple interacting layers—application, kernel, hardware.

### Multiple Causes
- Problems often caused by a combination of small inefficiencies.

### Multiple Performance Issues
- Systems often suffer from several simultaneous performance problems.

## Latency
- Time taken to complete a task (e.g., syscall, HTTP request).
- Can be broken down: connection, processing, transmission.
- Core metric for performance and user satisfaction.

## Observability
- Ability to infer internal state from external outputs.
- Three pillars:
  - Metrics
  - Profiling
  - Tracing

### Counters, Statistics, and Metrics
- System-wide counters from kernel, apps (`/proc`, `vmstat`, `iostat`).
- Good for trends, alerts, dashboards.

### Profiling
- Identifies CPU usage by functions or code paths.
- Tools: `perf top`, `perf record`, `gprof`, flame graphs.

### Tracing
- Records detailed event flow: syscalls, context switches, I/O delays.
- Tools: `ftrace`, `bpftrace`, `SystemTap`, `strace`.

## Experimentation
- Involves controlled load testing, synthetic benchmarks, chaos engineering.
- Helps discover how systems behave under stress.

## Cloud Computing
- Benefits:
  - Elastic scaling.
  - Easier benchmarking with virtual machines.
- Challenges:
  - Noisy neighbors.
  - Shared tenancy.
  - Limited access to hardware-level metrics.

## Methodologies
- Using systematic methods avoids trial-and-error debugging.
- Includes:
  - **USE Method** (Utilization, Saturation, Errors)
  - **RED Method** (Rate, Errors, Duration)
  - **Scientific Method**

### Linux Perf Analysis in 60 Seconds

```bash
uptime               # Load average
dmesg | tail         # Recent kernel logs
vmstat 1             # CPU, memory, swap
mpstat -P ALL 1      # Per-core CPU usage
pidstat 1            # Per-process stats
iostat -xz 1         # Disk I/O stats
free -m              # Memory usage
sar -n DEV 1         # Network usage
sar -n TCP,ETCP 1    # TCP errors, retransmits
top                  # Interactive overview
