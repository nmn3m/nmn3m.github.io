---
title: "Understanding Kubernetes Observability: Metrics, Monitoring, and Best Practices"
date: 2025-12-22T10:00:00Z
draft: false
tags: ["kubernetes", "observability", "sre", "monitoring", "metrics"]
author: "Noureldin Abdelmonem"
---

As a Site Reliability Engineer working extensively with Kubernetes, I've learned that observability is not just about collecting metrics—it's about understanding the behavior of your distributed systems and making informed decisions based on that understanding.

<!--more-->

## The Three Pillars of Observability

When we talk about observability in Kubernetes, we're really talking about three fundamental pillars:

1. **Metrics**: Numerical data about system performance and resource usage
2. **Logs**: Detailed records of events happening in your applications
3. **Traces**: The path of requests through your distributed system

Today, I want to focus on metrics and how to effectively monitor your Kubernetes clusters.

## Why Metrics Matter

In a Kubernetes environment, things can fail in complex and unexpected ways. Without proper metrics, you're flying blind. Here's what you should be monitoring:

### Cluster-Level Metrics

```yaml
# Key metrics to track:
- Node CPU and memory usage
- Pod count and status
- Persistent volume usage
- Network I/O
- API server latency
```

### Application-Level Metrics

Your applications should expose metrics that matter to your business:

- Request rates and latencies
- Error rates
- Resource consumption
- Custom business metrics

## kube-state-metrics: Your Cluster's Health Reporter

One of the most valuable tools in your observability toolkit is [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics). Unlike metrics-server which focuses on resource metrics for autoscaling, kube-state-metrics gives you the full picture of your cluster's state.

Here's a simple example of deploying it:

```bash
# Using Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install kube-state-metrics prometheus-community/kube-state-metrics
```

## Prometheus + Grafana: The Classic Stack

The combination of Prometheus for metrics collection and Grafana for visualization remains the gold standard for Kubernetes monitoring:

```yaml
# Example Prometheus ServiceMonitor
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-app
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: my-app
  endpoints:
  - port: metrics
    interval: 30s
```

## Best Practices I've Learned

After working with Kubernetes observability for years, here are my key recommendations:

### 1. Start with the USE Method

- **U**tilization: How busy is the resource?
- **S**aturation: How much extra work is queued?
- **E**rrors: Count of error events

### 2. Implement the RED Method for Services

- **R**ate: Requests per second
- **E**rrors: Failed requests
- **D**uration: Distribution of request latency

### 3. Set Meaningful Alerts

Don't alert on everything. Alert on symptoms, not causes:

```yaml
# Good alert: symptom-based
- alert: HighErrorRate
  expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
  annotations:
    summary: "High error rate detected"

# Bad alert: cause-based
- alert: HighCPU
  expr: container_cpu_usage > 80
  # This might not actually impact users
```

### 4. Use Labels Wisely

Labels are powerful but can explode your cardinality:

```go
// Good: bounded cardinality
http_requests_total{method="GET", status="200", endpoint="/api/users"}

// Bad: unbounded cardinality
http_requests_total{user_id="12345"}  // Don't do this!
```

## Monitoring Control Plane Components

The Kubernetes control plane needs special attention:

```bash
# Key metrics to monitor:
# API Server
apiserver_request_duration_seconds
apiserver_request_total

# etcd
etcd_disk_wal_fsync_duration_seconds
etcd_server_has_leader

# Scheduler
scheduler_scheduling_duration_seconds
scheduler_queue_incoming_pods_total
```

## Real-World Example: Debugging a Slow Deployment

Recently, I debugged a slow deployment issue using metrics:

1. **Initial symptom**: Pods taking 5+ minutes to become ready
2. **Checked metrics**: `kube_pod_container_status_waiting_reason`
3. **Found issue**: Image pull was slow
4. **Root cause**: Registry throttling
5. **Solution**: Implemented image caching via pull-through cache

Without proper metrics, this would have taken hours to debug instead of minutes.

## Conclusion

Observability in Kubernetes is not optional—it's essential. Start with the basics:

1. Deploy kube-state-metrics
2. Set up Prometheus and Grafana
3. Implement the USE and RED methods
4. Create meaningful alerts
5. Continuously iterate and improve

Remember: the goal isn't to collect all possible metrics, but to collect the *right* metrics that help you understand and improve your systems.

## Resources

- [kube-state-metrics GitHub](https://github.com/kubernetes/kube-state-metrics)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [The USE Method](http://www.brendangregg.com/usemethod.html)
- [The RED Method](https://grafana.com/blog/2018/08/02/the-red-method-how-to-instrument-your-services/)

---

*What are your experiences with Kubernetes observability? Feel free to reach out on [GitHub](https://github.com/nmn3m) or [LinkedIn](https://linkedin.com/in/nmn3m) to discuss!*
