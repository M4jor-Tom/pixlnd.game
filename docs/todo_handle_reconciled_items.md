# Approved selections awaiting handling

Owner answer, 2026-10-17:

> 1: Approved; 2: Approved; Handoff, commit, push

Authority: record these two ontology decisions, commit, finalize the pending-only handoff and
push `fix/ontology-reconciliation`, then stop. No gameplay, live JSON, loader, validator or test
implementation is authorized. Existing dormant source continuation remains separately restricted.

## Repeated combat DOT applications — item 1

**Previously selected:** independent burning applications. Exact answer: **“1: Approved”**.

Original proposal:

> Each successful application creates its **own four-second burn**, without replacing or
> refreshing earlier burns. Each ticks every 0.5 seconds, first at 0.5 seconds and last at
> four seconds.
>
> For example, burns based on 100- and 50-damage hits deal **10 and 5 per tick**, respectively,
> while both remain active.

Scope: combat hit-derived burning, not environmental hazards. Existing damage coefficients,
Resistance inheritance, dodge/status protections and aggro rules remain unchanged. Repeated
fire hits accumulate damage; a multi-hit volley may leave several burns.

Status: approved; canonical recording, verification, review and item commit pending.
Dependencies: existing D21 burning numbers and Resistance item 4; source research and broader
DOT buff timing are outside this selection. Runtime enforcement is separate deferred work.

## Repeated combat DOT applications — item 2

**Previously selected:** independent poison-stack lifetimes and tick schedules.
Exact answer: **“2: Approved”**.

Original proposal:

> Every poison application has an **independent lifetime and schedule**. Dagger poison delivers
> its existing five ticks at **one, two, three, four and five seconds after application**.
> New applications neither refresh older stacks nor reset their next tick.
>
> For example, applications two seconds apart finish at seconds **five and seven**, respectively.

Scope: combat hit-derived poison, not environmental hazards. Poison stacking, inherited hit
damage/crit, the existing dagger total/cadence, poison's dodge exception and Resistance handling
remain unchanged. No shared renewal or immediate tick is selected.

Status: approved; canonical recording, verification, review and item commit pending.
Dependencies: existing D24 dagger poison and status identity; item 1 concerns a different effect,
not a prerequisite. Runtime enforcement is separate deferred work.
