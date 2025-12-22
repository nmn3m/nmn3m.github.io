---
title: "فهم قابلية المراقبة في Kubernetes: المقاييس والمراقبة وأفضل الممارسات"
date: 2025-12-22T10:00:00Z
draft: false
tags: ["kubernetes", "observability", "sre", "monitoring", "metrics"]
author: "Noureldin Abdelmonem"
---

كمهندس موثوقية أنظمة أعمل بشكل مكثف مع Kubernetes، تعلمت أن قابلية المراقبة لا تقتصر فقط على جمع المقاييس - بل تتعلق بفهم سلوك الأنظمة الموزعة واتخاذ قرارات مستنيرة بناءً على هذا الفهم.

<!--more-->

## الركائز الثلاث لقابلية المراقبة

عندما نتحدث عن قابلية المراقبة في Kubernetes، فإننا نتحدث حقاً عن ثلاث ركائز أساسية:

1. **المقاييس (Metrics)**: بيانات رقمية حول أداء النظام واستخدام الموارد
2. **السجلات (Logs)**: سجلات مفصلة للأحداث التي تحدث في تطبيقاتك
3. **التتبعات (Traces)**: مسار الطلبات عبر النظام الموزع

اليوم، أريد التركيز على المقاييس وكيفية مراقبة كتل Kubernetes بشكل فعال.

## لماذا المقاييس مهمة

في بيئة Kubernetes، يمكن أن تفشل الأشياء بطرق معقدة وغير متوقعة. بدون مقاييس مناسبة، أنت تطير بدون رؤية. إليك ما يجب عليك مراقبته:

### مقاييس مستوى الكتلة

```yaml
# المقاييس الرئيسية للتتبع:
- استخدام CPU والذاكرة للعقد
- عدد وحالة البودات
- استخدام الأقراص الدائمة
- إدخال/إخراج الشبكة
- زمن استجابة API server
```

### مقاييس مستوى التطبيق

يجب أن تعرض تطبيقاتك مقاييس مهمة لعملك:

- معدلات الطلبات وأوقات الاستجابة
- معدلات الأخطاء
- استهلاك الموارد
- مقاييس الأعمال المخصصة

## kube-state-metrics: مراسل صحة الكتلة

واحدة من أكثر الأدوات قيمة في مجموعة أدوات قابلية المراقبة هي [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics). على عكس metrics-server الذي يركز على مقاييس الموارد للتوسع التلقائي، يعطيك kube-state-metrics الصورة الكاملة لحالة كتلتك.

إليك مثال بسيط لنشره:

```bash
# استخدام Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install kube-state-metrics prometheus-community/kube-state-metrics
```

## Prometheus + Grafana: المجموعة الكلاسيكية

يظل الجمع بين Prometheus لجمع المقاييس و Grafana للتصور المعيار الذهبي لمراقبة Kubernetes:

```yaml
# مثال على Prometheus ServiceMonitor
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

## أفضل الممارسات التي تعلمتها

بعد العمل مع قابلية المراقبة في Kubernetes لسنوات، إليك توصياتي الرئيسية:

### 1. ابدأ بطريقة USE

- **U**tilization (الاستخدام): ما مدى انشغال المورد؟
- **S**aturation (التشبع): كم من العمل الإضافي في قائمة الانتظار؟
- **E**rrors (الأخطاء): عدد أحداث الخطأ

### 2. نفذ طريقة RED للخدمات

- **R**ate (المعدل): الطلبات في الثانية
- **E**rrors (الأخطاء): الطلبات الفاشلة
- **D**uration (المدة): توزيع زمن استجابة الطلب

### 3. اضبط تنبيهات ذات معنى

لا تنبه على كل شيء. نبه على الأعراض، وليس الأسباب:

```yaml
# تنبيه جيد: قائم على الأعراض
- alert: HighErrorRate
  expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
  annotations:
    summary: "معدل خطأ عالي تم اكتشافه"

# تنبيه سيئ: قائم على الأسباب
- alert: HighCPU
  expr: container_cpu_usage > 80
  # قد لا يؤثر هذا فعلياً على المستخدمين
```

### 4. استخدم التسميات بحكمة

التسميات قوية ولكن يمكن أن تفجر عدد المقاييس:

```go
// جيد: عدد محدود
http_requests_total{method="GET", status="200", endpoint="/api/users"}

// سيئ: عدد غير محدود
http_requests_total{user_id="12345"}  // لا تفعل هذا!
```

## مراقبة مكونات المستوى التحكمي

يحتاج المستوى التحكمي في Kubernetes إلى اهتمام خاص:

```bash
# المقاييس الرئيسية للمراقبة:
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

## مثال واقعي: تصحيح نشر بطيء

مؤخراً، قمت بتصحيح مشكلة نشر بطيء باستخدام المقاييس:

1. **العرض الأولي**: استغرقت البودات أكثر من 5 دقائق لتصبح جاهزة
2. **فحص المقاييس**: `kube_pod_container_status_waiting_reason`
3. **وجدت المشكلة**: سحب الصورة كان بطيئاً
4. **السبب الجذري**: اختناق السجل
5. **الحل**: تنفيذ تخزين مؤقت للصور عبر pull-through cache

بدون مقاييس مناسبة، كان سيستغرق هذا ساعات لتصحيحه بدلاً من دقائق.

## الخلاصة

قابلية المراقبة في Kubernetes ليست اختيارية - إنها أساسية. ابدأ بالأساسيات:

1. انشر kube-state-metrics
2. أعد Prometheus و Grafana
3. نفذ طرق USE و RED
4. أنشئ تنبيهات ذات معنى
5. كرر وحسن باستمرار

تذكر: الهدف ليس جمع جميع المقاييس الممكنة، بل جمع المقاييس *الصحيحة* التي تساعدك على فهم وتحسين أنظمتك.

## الموارد

- [kube-state-metrics GitHub](https://github.com/kubernetes/kube-state-metrics)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [The USE Method](http://www.brendangregg.com/usemethod.html)
- [The RED Method](https://grafana.com/blog/2018/08/02/the-red-method-how-to-instrument-your-services/)

---

*ما هي تجاربك مع قابلية المراقبة في Kubernetes؟ لا تتردد في التواصل على [GitHub](https://github.com/nmn3m) أو [LinkedIn](https://linkedin.com/in/nmn3m) للنقاش!*
