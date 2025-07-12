# Chapter 2: Methodologies

## Terminology
- **Latency**: Time taken to complete a request.
- **Throughput**: Number of completed requests per time unit.
- **Utilization**: Percentage of time a resource is actively used.
- **Saturation**: The queue length or backlog of a resource.
- **IOPS**: Disk input/output operations per second.
- **Cache**: Fast-access memory used to reduce slow storage calls.

## Models

### System Under Test (SUT)
- The target system being benchmarked or analyzed.

### Queueing System
- A way to model how operations wait to be serviced (latency + contention).

## Concepts

### Latency
- Core performance metric, measured at multiple layers (network, app, disk).

### Time Scales
- Performance spans nanoseconds to minutes depending on context.

### Trade-Offs
- Improving one metric (e.g., CPU usage) might worsen another (e.g., memory).

### Tuning Efforts
- Adjustments made to configs, code, or architecture to improve performance.

### Level of Appropriateness
- Avoid premature optimization; tune based on realistic goals.

### When to Stop Analysis
- Stop when goals are met or effort outweighs gains.

### Point-in-Time Recommendations
- Optimal tuning may change over time or workload.

### Load vs. Architecture
- Different architectures scale differently under the same load.

### Scalability
- How well a system handles increasing load.

### Metrics
- Quantified data points: latency, QPS, CPU%.

### Utilization
- How busy a resource is over time.

### Saturation
- Queue depth or backpressure indicator.

### Profiling
- Examines CPU usage patterns in code or system.

### Caching
- Reduces latency by storing frequently accessed data.

### Known-Unknowns
- Identify gaps in observability or understanding.

## Perspectives

### Resource Analysis
- Focus on how system resources behave (CPU, memory, disk, etc.).

### Workload Analysis
- View from user/application side: latency, throughput, errors.

## Methodology

### Streetlight Anti-Method
- Looking only where it’s easy, not where problem is.

### Random Change Anti-Method
- Changing system settings without evidence.

### Blame-Someone-Else Anti-Method
- Pushing the issue to other teams without evidence.

### Ad Hoc Checklist Method
- Using informal checklists—quick but not always reliable.

### Problem Statement
- Clearly define what performance issue you're solving.

### Scientific Method
- Hypothesis → Measurement → Analysis → Conclusion → Repeat.

### Diagnosis Cycle
- Iterate: Identify → Measure → Hypothesize → Test → Confirm.

### Tools Method
- Use diagnostic tools across subsystems.

### The USE Method
- For each resource:
  - **Utilization**: Is it busy?
  - **Saturation**: Is it overloaded?
  - **Errors**: Any faults?

### The RED Method
- For services:
  - **Rate**: Throughput (req/sec).
  - **Errors**: Failure count.
  - **Duration**: Latency.

### Workload Characterization
- Define types of requests and frequency.

### Drill-Down Analysis
- From top-level indicators to fine-grained subsystems.

### Latency Analysis
- Break latency into layers (e.g., app, network, disk).

### Method R
- Oracle method focusing on response time.

### Event Tracing
- Record sequence of events to reconstruct root cause.

### Baseline Statistics
- Establish normal operating ranges.

### Static Performance Tuning
- One-time optimization; doesn't adapt to workload.

### Cache Tuning
- Adjust cache sizes, eviction policies.

### Micro-Benchmarking
- Small, focused tests of performance in isolation.

### Performance Mantras
- "Don't do it", "Do it concurrently", "Do it later", etc.

## Modeling

### Enterprise vs. Cloud
- Cloud reduces need for precise capacity planning but introduces variability.

### Visual Identification
- Use plots to see saturation points (e.g., throughput knee).

### Amdahl’s Law
- Parallel speedup is limited by serial portion of workload.

### Universal Scalability Law (USL)
- Adds contention and coherency to scalability model.

### Queueing Theory
- Mathematical modeling of wait times and throughput.

## Capacity Planning

### Resource Limits
- Identify bottlenecks before they cause outages.

### Factor Analysis
- Analyze which resource affects capacity most.

### Scaling Solutions
- Add instances (horizontal) or more powerful ones (vertical).

## Statistics

### Quantifying Performance Gains
- Use percentiles or ratios for before/after.

### Averages
- Easy to compute but often misleading.

### Standard Deviation, Percentiles, Median
- Measure variance and worst-case performance.

### Coefficient of Variation
- Standard deviation ÷ mean: normalized variation.

### Multimodal Distributions
- Multiple peaks in performance histograms.

### Outliers
- Rare but impactful performance events.

## Monitoring

### Time-Based Patterns
- Detect peaks, troughs, diurnal cycles.

### Monitoring Products
- Tools like Prometheus, Datadog, Grafana.

### Summary-Since-Boot
- `vmstat`, `uptime`, `/proc/stat` give long-term stats.

## Visualizations

### Line Chart
- Time series data.

### Scatter Plots
- Show variance and clustering.

### Heat Maps
- Intensity over time and metrics.

### Timeline Charts
- Execution flow per process/thread.

### Surface Plot
- 3D views: e.g., latency vs. load vs. CPU.

### Visualization Tools
- `perf`, `flamegraph`, `bpftrace`, etc.

