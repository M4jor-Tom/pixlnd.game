# Independent combat damage-over-time applications

Status: accepted. Owner decision: 2026-10-17. Exact answer, without amendments:

> 1: Approved; 2: Approved; Handoff, commit, push

Scope: combat hit-derived burning and poison application semantics, not environmental hazards.
Existing damage coefficients, durations, Resistance handling, dodge/status protections and aggro
rules remain. Documentation approval grants no gameplay, live JSON, loader, validator or test
implementation authority.

## Independent burning — item 1

Exact answer: **“1: Approved”**.

Selected original proposal:

> Each successful application creates its **own four-second burn**, without replacing or
> refreshing earlier burns. Each ticks every 0.5 seconds, first at 0.5 seconds and last at
> four seconds.
>
> For example, burns based on 100- and 50-damage hits deal **10 and 5 per tick**, respectively,
> while both remain active.

Context: D21 selected burning's coefficient, duration and cadence, but not repeated-application
behavior. The shared overwriting runtime slot is an implementation approximation, not final
policy. The selected rule permits repeated fire hits, including a multi-hit volley, to leave
several burns; the tradeoff is increased ongoing damage from strong bursts. Replacement or
renewal of earlier burns was not chosen. Further owner reasoning was not supplied.

Dependencies: [D21 burning numbers](class-abilities.md) and the existing
[Resistance inheritance rule](resistance-meaning.md#hit-derived-damage-over-time--item-4).
This selects eight ticks per application; no new coefficient, environmental hazard rule or
additional DOT buff timing is selected.

## Independent poison lifetimes and scheduling — item 2

Exact answer: **“2: Approved”**.

Selected original proposal:

> Every poison application has an **independent lifetime and schedule**. Dagger poison delivers
> its existing five ticks at **one, two, three, four and five seconds after application**.
> New applications neither refresh older stacks nor reset their next tick.
>
> For example, applications two seconds apart finish at seconds **five and seven**, respectively.

Context: poison already stacks and inherits hit damage/crit; [D24](weapon-movesets.md) selects
its dagger total/cadence. The remaining choice was application lifetime and tick phase, not
whether poison stacks. Each application delivers its own scheduled damage, without indefinitely
renewing older stacks; shared renewal/scheduling and an immediate initial dagger tick were not chosen.
Further owner reasoning was not supplied.

Dependencies: existing dagger poison numbers, status identity, dodge exception and Resistance
handling. Burning item 1 concerns a different effect, not a prerequisite. Environmental hazards
and additional DOT buff timing remain outside scope; implementation is still unauthorized.

Canonical: [status effects](../domain/3_Classes.md#status-effect) and
[constraint catalog](../domain/5_Constraints.md#constraint-catalog).
Implementation is [deferred](../../docs/ROADMAP/todo_implement.md#combat-33-slices-457c947--d21--d23),
not authorized by this decision.
