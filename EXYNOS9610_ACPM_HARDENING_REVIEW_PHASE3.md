# Exynos9610 ACPM IPC Hardening Review — Phase 3

Audit date: 2026-11-18
Repository: crypto143007-ship-it/SOVR-Kernel-A50
Branch: migration/linux-5.1-assessment
Reference implementation: current branch `drivers/soc/samsung/acpm/acpm_ipc.c`
Scope: source review of the Phase 8 ACPM hardening patch
Evidence boundary: static source inspection only; no compile, runtime, or hardware validation

## Summary

The Phase 8 patch improves allocation and input error handling, but it is not yet safe to treat as complete ACPM hardening. This review found two definite validation gaps and one important channel-index invariant that is not proven by the current source.

## Findings

### 1. Channel ID is shifted before its range check

In `channel_init()`, the code calculates:

```c
acpm_ipc->channel[i].id = ipc_ch[i].id;
mask |= acpm_ipc->channel[i].polling << acpm_ipc->channel[i].id;
...
if (!acpm_ipc->channel[i].tx_ch.size ||
        !acpm_ipc->channel[i].tx_ch.len ||
        acpm_ipc->channel[i].id >= 32)
        return -EINVAL;
```

The interrupt-mask shift occurs before the `id >= 32` validation. A firmware-provided ID of 32 or greater therefore reaches an invalid-width shift before the function rejects it.

Required correction:
- Validate the ID range before any shift or bit-mask operation.
- Reject duplicate channel IDs.
- Validate the channel ID/index relationship before publishing the channel table.

### 2. Public channel request can dereference uninitialized global state

`acpm_ipc_request_channel()` checks `np`, then immediately reads `acpm_ipc->num_channels` and `acpm_ipc->channel[i]`. Unlike `acpm_ipc_set_ch_mode()` and `acpm_ipc_send_data()`, it does not first reject a NULL/uninitialized `acpm_ipc` or channel array.

Required correction:
- Return a defined error (normally `-EPROBE_DEFER`) if IPC/channel initialization has not completed.
- Validate output pointers `id` and `size` before writing through them.
- Validate the property length before `be32_to_cpup()`, as the set-channel-mode path already does.

### 3. Channel ID is used as an array index without proving IDs are dense

`acpm_ipc_request_channel()` searches the array for a matching firmware channel ID and returns that ID to the caller. However, `acpm_ipc_send_data()` and `acpm_ipc_release_channel()` subsequently use the returned `channel_id` directly as `&acpm_ipc->channel[channel_id]`.

That is correct only if the firmware guarantees channel IDs are unique, contiguous, and exactly equal to array indices in the range `0..num_channels-1`. The current `channel_init()` checks only the upper bound (and does so too late for the mask shift); it does not establish uniqueness or contiguity.

Required correction:
- Verify the firmware ABI's channel-ID invariant from the ACPM framework definition/firmware contract.
- If IDs are guaranteed dense, explicitly validate `ipc_ch[i].id == i` (or the documented equivalent) and reject duplicates.
- Otherwise, resolve IDs to array indices with a checked lookup in request/send/release paths. Do not silently assume identity mapping.

## Previously identified blockers that remain

- The IRQ is requested before interrupt MMIO, SRAM mappings, framework state, and channel state are initialized. Handler-visible state must be ready and the interrupt source safely masked/acknowledged before IRQ delivery is enabled; the exact ordering must follow the firmware protocol.
- The firmware `initdata-base`, framework header, channel descriptor table, queue bases/front/rear pointers, queue lengths, element sizes, indirection buffers, log buffers, timestamp arrays, and dump ranges are not all range-validated against the mapped SRAM resource.
- Partial-probe unwind, singleton global-state lifetime, workqueue teardown, and remove-path cleanup remain incomplete.
- The current checks do not prove the ACPM firmware ABI, channel numbering, interrupt ordering, or runtime DVFS behavior.

## Recommended next patch order

1. Establish the ACPM framework structure sizes and SRAM layout from the matching firmware ABI / known-good vendor definitions.
2. Add overflow-safe range validation for the framework header, channel table, all ring buffers, indirect buffers, log buffers, timestamps, and dump ranges.
3. Validate channel IDs before bit operations; prove dense identity mapping or add an ID-to-index lookup.
4. Add missing request-channel state/output/property guards.
5. Design IRQ masking, acknowledgement, and registration ordering using the actual mailbox protocol.
6. Implement complete failure unwind and remove lifecycle.
7. Compile the exact A50 vendor configuration, then test on recoverable A50 hardware.

## Build and safety status

- The separate pinned upstream Linux v5.1 ARM64 defconfig + Image + DTBs baseline workflow has passed.
- That workflow does not compile this vendor 4.14 ACPM code.
- The migration branch's ACPM implementation remains vendor 4.14 code and is not a Linux 5.1 port.
- No Exynos9610 Linux 5.1 kernel build or A505F boot is claimed.
- Do not flash the intermediate ACPM hardening patch as a replacement for the known-good kernel.
- Original `SOVR-Technologies/SOVR-Kernel-A50` and `Vothcito/android_kernel_samsung_exynos9610_a50` remain read-only.
- `crypto143007-ship-it:linux-5.1-exynos9610-integration` remains excluded from the main SOVR project.
