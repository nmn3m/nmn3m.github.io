+++
date = '2026-04-25'
draft = false
title = 'DRA Resource Pool Status Request: Alpha in Kubernetes 1.36'
author = 'Noureldin Abdelmonem'
tags = ['kubernetes', 'dra', 'sig-node', 'kep-5677']
categories = ['kubernetes']
description = "Why a DRA pod can stay Pending forever with no useful signal, and how KEP-5677 introduces a CSR-style API to ask the scheduler what's actually in a resource pool."
+++

When you run a workload on Dynamic Resource Allocation (DRA) and the pod stays `Pending`, there is no good way to ask Kubernetes *why*. `ResourceClaim` events tell you the claim couldn't be allocated, but they don't tell you whether the pool is full, the slices are invalid, or the devices are tainted. You're left grepping scheduler logs.

[KEP-5677 — DRA Resource Availability Visibility](https://github.com/kubernetes/enhancements/tree/master/keps/sig-node/5677-dra-resource-availability-visibility) is the proposal I authored to fix that gap. It shipped as **Alpha in Kubernetes 1.36** behind the `DRAResourcePoolStatus` feature gate, and is now headed to **Beta in 1.37** as `resource.k8s.io/v1beta2`.

This post walks through what we built in Alpha and what's coming in Beta.

<!--more-->

## The problem

A `ResourceSlice` describes the devices a DRA driver is publishing into a pool. The scheduler reads slices, picks devices for each `ResourceClaim`, and writes the allocation back. From the *user's* perspective, all of that is opaque: there is no `kubectl` command that answers "of the 8 GPUs in pool `node-a/gpu`, how many are free right now?" or "are any of them tainted out?"

A few things make this awkward to expose with a normal status field:

- **Pools are sharded across many slices.** A single pool can be made up of dozens of `ResourceSlice` objects from one driver. Aggregation has to happen somewhere.
- **The truth is owned by the scheduler.** Only the controller plane that runs the allocator knows which devices are currently bound to claims.
- **You don't want to write this on hot path.** Writing per-pool counts back into every slice on every allocation would be a write-amplification disaster.

So we needed a *pull* API: the user (or a dashboard, or a driver) asks "tell me about pool X right now," and the controller answers once.

## The shape of the API

The model we landed on is a **request/response object** modeled directly on `CertificateSigningRequest`:

- The user creates a `ResourcePoolStatusRequest` naming a DRA driver and (optionally) a single pool name.
- A controller in `kube-controller-manager` watches for new requests, computes the answer from the live `ResourceSlice` and `ResourceClaim` informers, and writes the result into `.status`.
- The object self-cleans via TTL: 1 hour after `status` is populated (whether the controller answered with `Complete=True` or `Failed=True`), 24 hours if `status` never gets written at all.

That gives users an explicit, RBAC-controllable verb (`create resourcepoolstatusrequests`) without ever mutating slices, and lets the controller serve answers from in-memory informer caches.

The full request/response cycle looks like this:

<div class="mermaid">
sequenceDiagram
    autonumber
    actor User
    participant API as kube-apiserver
    participant Ctrl as RPSR controller
    participant Slices as ResourceSlice cache
    participant Claims as ResourceClaim cache

    User->>API: CREATE ResourcePoolStatusRequest (spec.driver=gpu.example.com, spec.limit=100)
    API-->>User: 201 Created (status empty)
    API->>Ctrl: watch event ADD
    Ctrl->>Slices: list slices for driver gpu.example.com
    Slices-->>Ctrl: slices grouped by pool + generation
    Ctrl->>Claims: list claims allocated to those devices
    Claims-->>Ctrl: allocations
    Note over Ctrl: aggregate per pool: totalDevices, allocatedDevices, availableDevices, unavailableDevices, validationError
    Ctrl->>API: UPDATE .status (condition Complete=True)
    User->>API: GET resourcepoolstatusrequests/my-check
    API-->>User: poolCount + per-pool counts + conditions
    Note over API: 1h later, TTL controller deletes the request
</div>

## What ships in Alpha (1.36)

The Alpha release lands the full read path end-to-end, plus the controller machinery to keep it honest:

### The API surface

- `ResourcePoolStatusRequest` lives in `resource.k8s.io/v1alpha3` next to `DeviceClass`, `ResourceClaim`, and `ResourceSlice`.
- `spec` is **immutable** after creation, and once `status` is populated the entire object is immutable. You can't edit a request to ask about a different driver — you create a new one. This keeps the controller stateless and the audit trail clean.
- `spec` is filter-shaped, not list-shaped:
  - `spec.driver` — required; the DRA driver name to query (e.g. `gpu.example.com`).
  - `spec.poolName` — optional; restricts the response to a single pool. Omit to get every pool the driver publishes.
  - `spec.limit` — optional; caps the number of pools returned (default `100`, min `1`, max `1000`). When more pools match than fit, `status.poolCount` reports the total and `status.pools` is truncated.

### Per-pool reporting

Each matching pool produces an entry in `status.pools` with `driver`, `poolName`, `generation`, `resourceSliceCount`, and the device counts (`totalDevices`, `allocatedDevices`, `availableDevices`, `unavailableDevices`). The invariant the controller maintains is `availableDevices = totalDevices − allocatedDevices − unavailableDevices`.

Critically, **a partially-valid pool doesn't fail the whole request** — it gets a per-pool `validationError` string (e.g. mid-rollout when not all slices are at the latest generation), and the device-count fields are simply omitted for that pool while the rest still report their counts. A pool with a stale generation shouldn't blackhole a 100-pool query.

The request itself reports a single condition: `Complete=True` when the controller answered, `Failed=True` when it couldn't.

### TTL & lifecycle

The same controller runs a sweep every 10 minutes:

- `status` populated (Complete or Failed) for ≥ 1h → delete
- `status` still unset and request ≥ 24h old → delete (something is wrong)
- transient API errors during the answer write → up to 5 retries on the workqueue

### Metrics

Three controller metrics land with the alpha, each labeled by `driver_name`:

- `resourcepoolstatusrequest_controller_requests_processed_total` — counter, total requests processed (success + failure).
- `resourcepoolstatusrequest_controller_request_processing_errors_total` — counter, errors during processing.
- `resourcepoolstatusrequest_controller_request_processing_duration_seconds` — histogram, exponential buckets starting at 1 ms.

### What's intentionally missing in Alpha

Two limits we documented up front:

1. **`unavailableDevices` is hard-coded to `0`.** The controller doesn't yet read device taints. This is the headline Beta item.
2. **TTL deletes are serial.** One `DELETE` API call per expired request inside the sweep loop. Fine at small scale, problematic at thousands.

The Alpha bets on landing the contract first, then hardening the implementation. The [KEP](https://github.com/kubernetes/enhancements/pull/5749) and the [implementation PR](https://github.com/kubernetes/kubernetes/pull/137028) shipped with the user-facing shape intact.

## What's coming in Beta (1.37)

Beta is targeting `resource.k8s.io/v1beta2`, **skipping v1beta1**, matching the precedent that `DeviceTaintRule` set in 1.36 (alpha → v1alpha3, beta → v1beta2). The `v1alpha3` version stays served for one release as the deprecation window.

Beyond the version bump, the Beta work splits into three buckets:

### 1. Wire up real `unavailableDevices`

This is the biggest functional change. A device is "unavailable" iff it has at least one taint with effect `NoSchedule` or `NoExecute`, *and* it isn't already allocated to a claim. Taints can come from two places:

- inline on the slice: `slice.Spec.Devices[i].Taints`
- via cluster-scoped `DeviceTaintRule` objects whose selector matches the device

The Beta controller adds a third aggregation pass over the same slice/claim data it already reads, gated on the `DRADeviceTaintRules` feature so that clusters without taint rules fall back to inline-only:

<div class="mermaid">
flowchart TD
    A["spec.driver (+ optional spec.poolName)"] --> B["List ResourceSlices for driver, group by pool"]
    B --> C["Pass 1: totalDevices = sum of slice.Spec.Devices"]
    B --> D["Pass 2: allocatedDevices = join with ResourceClaims"]
    B --> E["Pass 3: unavailableDevices"]
    E --> E1["Device has inline taint (NoSchedule or NoExecute)"]
    E --> E2["DeviceTaintRule selector matches device"]
    E1 --> F["AND device not currently allocated"]
    E2 --> F
    F --> G["status.pools[i]: totalDevices, allocatedDevices, availableDevices, unavailableDevices, validationError"]
    C --> G
    D --> G
</div>

<style>
.article-body .mermaid { text-align: center; margin: 1.5em 0; }
.article-body .mermaid svg { max-width: 100%; height: auto; }
</style>

Two edge cases worth flagging:

- **`NoExecute` on an allocated device.** The `device-taint-eviction` controller will already be tearing the claim down, so reporting it as "allocated" briefly and "unavailable" the next sweep is self-healing. We're not adding special handling.
- **Partitionable devices.** Today the algorithm counts physical devices, not partitions. Documented as a known limitation; out of scope for Beta.

### 2. Harden the implementation

A handful of things the Alpha left as "good enough for the contract, fix at Beta":

- **Batched TTL deletes.** The current sweep walks expired requests serially — one `DELETE` API call per object inside a for-loop. At thousands of expired requests, that bursts apiserver QPS. Beta replaces it with either a chunked loop with pacing or a rate-limited workqueue.
- **Deterministic metrics tests.** The Alpha metrics tests compare against a stringified `# HELP …` dump, which is brittle. Beta wraps the tests in a `synctest.Test` bubble so histogram bucket counts become deterministic, then asserts exact values per metric and label.
- **Tighter e2e assertions.** The Alpha e2e uses `gstruct.MatchFields(IgnoreExtras, …)` on the returned `PoolStatus`. Beta either switches to `MatchAllFields` or moves the field-by-field checks into unit tests, so we don't silently miss a regression in a status field.
- **Fold the integration tests** into the main DRA integration suite so the apiserver boots once across all DRA tests instead of once per file.

### 3. Validation at scale and with real drivers

Two non-code items:

- Run with at least one production out-of-tree DRA driver and record the results on the Beta KEP PR.
- A scale integration test seeding ≥ 100 pools and ≥ 1000 expired requests, asserting the sweep completes inside the 10-min interval without sustained QPS spikes against the apiserver. This is the test that gates whether the batched-delete change actually pays off.

## How to try the Alpha

In a 1.36 cluster with `--feature-gates=DRAResourcePoolStatus=true` on `kube-apiserver` and `kube-controller-manager`, query every pool a driver publishes:

```yaml
apiVersion: resource.k8s.io/v1alpha3
kind: ResourcePoolStatusRequest
metadata:
  name: gpu-check
spec:
  driver: gpu.example.com
  # poolName: node-a   # optional: omit to get all pools from this driver
  # limit: 100         # optional: default 100, max 1000
```

```sh
kubectl create -f gpu-check.yaml
kubectl wait --for=condition=Complete resourcepoolstatusrequest/gpu-check --timeout=30s
kubectl get resourcepoolstatusrequest/gpu-check -o yaml
```

You should see `status.poolCount` plus a `status.pools[]` array with per-pool counts and (in Alpha) `unavailableDevices: 0` everywhere. The object will delete itself an hour later.

## Where to follow along

- KEP: [kubernetes/enhancements#5749](https://github.com/kubernetes/enhancements/pull/5749)
- Alpha implementation: [kubernetes/kubernetes#137028](https://github.com/kubernetes/kubernetes/pull/137028)
- Feature gate: `DRAResourcePoolStatus`
- SIG: sig-node, with API review from sig-api-machinery and sig-auth

The Beta KEP changes are being prepared on the `kep-5677-beta` branch; the in-tree wire-up will follow once 1.37 opens for enhancements. Feedback — especially from anyone running DRA in production — is the single most useful thing right now.

<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs';

  const blocks = Array.from(document.querySelectorAll('.mermaid'));
  blocks.forEach((el) => { el.dataset.source = el.textContent; });

  const darkVars = {
    background: '#0f172a',
    primaryColor: '#1f2937',
    primaryTextColor: '#f3f4f6',
    primaryBorderColor: '#94a3b8',
    secondaryColor: '#374151',
    tertiaryColor: '#4b5563',
    lineColor: '#e5e7eb',
    textColor: '#f3f4f6',
    actorBkg: '#1f2937',
    actorBorder: '#94a3b8',
    actorTextColor: '#f3f4f6',
    actorLineColor: '#cbd5e1',
    signalColor: '#f3f4f6',
    signalTextColor: '#f3f4f6',
    labelBoxBkgColor: '#fbbf24',
    labelBoxBorderColor: '#f59e0b',
    labelTextColor: '#111827',
    loopTextColor: '#f3f4f6',
    noteBkgColor: '#fbbf24',
    noteBorderColor: '#f59e0b',
    noteTextColor: '#111827',
    activationBorderColor: '#cbd5e1',
    activationBkgColor: '#374151',
    sequenceNumberColor: '#111827',
    nodeBkg: '#1f2937',
    nodeBorder: '#94a3b8',
    nodeTextColor: '#f3f4f6',
    edgeLabelBackground: '#0f172a',
    clusterBkg: '#1f2937',
    clusterBorder: '#94a3b8'
  };

  const render = async () => {
    const isDark = document.documentElement.dataset.theme === 'dark';
    blocks.forEach((el) => {
      el.removeAttribute('data-processed');
      el.innerHTML = el.dataset.source;
    });
    mermaid.initialize({
      startOnLoad: false,
      securityLevel: 'loose',
      theme: 'base',
      themeVariables: isDark ? darkVars : {}
    });
    await mermaid.run({ nodes: blocks });
  };

  await render();

  new MutationObserver((muts) => {
    if (muts.some((m) => m.attributeName === 'data-theme')) render();
  }).observe(document.documentElement, { attributes: true });

  const overlay = document.createElement('div');
  overlay.className = 'lightbox-backdrop';
  overlay.innerHTML = '<img alt="">';
  document.body.appendChild(overlay);
  const view = overlay.querySelector('img');
  const close = () => overlay.classList.remove('is-open');
  overlay.addEventListener('click', close);
  document.addEventListener('keydown', (e) => { if (e.key === 'Escape') close(); });

  blocks.forEach((el) => {
    el.style.cursor = 'zoom-in';
    el.addEventListener('click', () => {
      const svg = el.querySelector('svg');
      if (!svg) return;
      const clone = svg.cloneNode(true);
      const vb = svg.viewBox && svg.viewBox.baseVal;
      if (vb && vb.width && vb.height) {
        clone.setAttribute('width', vb.width);
        clone.setAttribute('height', vb.height);
      }
      clone.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
      const xml = new XMLSerializer().serializeToString(clone);
      view.src = 'data:image/svg+xml;utf8,' + encodeURIComponent(xml);
      overlay.classList.add('is-open');
    });
  });
</script>
