# Historical sleep and clock evidence

## Claim, authority and current-rule impact

This is one deduplicated source finding for **items 10/11/23/26/29/80**, not a major gameplay decision or one record per approval/run. It concerns the historical **100×** sleep reference, qualitative healing/time-flow reports and unresolved original Alpha/Steam activation/rate/baseline histories. **Current-rule impact: NONE.** [Hybrid game-clock (locator=game-clock)](../../ontology/domain/3_Classes.dsl) remains 10× real time with free inn recovery and separately paid, consensual next-07:00 sleep/reset/payment rules; no furniture controls, rates or new debt are chosen. [Current constraints (locator=constraint-catalog)](../../ontology/domain/5_Constraints.dsl) and live JSON/design values are unchanged.

## Provenance and limits of this migration

The source passages below are retained from the allowed domain/ledger/README inputs, **not freshly retrieved or tested sources**. “Freshly inspected”, “here” and “this writer” inside retained passages refer to their historical recording, not this migration. No historical digest is promoted to a freshly measured raw-source digest. Exact fields unavailable in the allowed records remain **unknown**: individual community authors, missing raw digests and source-scout completion times. Revision/edit/capture timing is not feature-introduction timing; source identifiers are not proof of shipped behavior.

Historical approvals: items 10/11/23/26/29 were owner-approved 2026-10-04; item 80 used standing sourcing-only approval and was recorded 2026-10-10. Exact selection/approval/execution receipts remain in [the original ledger](../ROADMAP/todo_decide.md#e-ontology-reconciliation-2026-09-13); they grant no new mechanic/label/publication authority. Item 29's exact approval token was **“2ç: Approved”**; parent explicitly interpreted “2ç” as **29**, not approval of then-unanswered 32–35. The complete original answer and workflow limits remain in its existing ledger receipt. No removed history is reconstructed.

## Shared Darkmega source identity (item 70, inherited by item 80)

[Steam guide 1871398574](https://steamcommunity.com/sharedfiles/filedetails/?id=1871398574), Darkmega, **How to not have a bad time: Darkmega's Ultimate Cubeworld Guide [updated 4/10]**. Retained raw `/tmp/pixlnd-presentation-world.I1sm3d/guide.body`: title/author at 610/825; displayed Posted **25 Sep, 2019 @ 2:24am** and Updated **3 Oct, 2019 @ 10:14am** at 846–847, timezone unspecified. Title **updated 4/10** is distinct, not normalized to that update date. Capture **2026-10-04T21:01:17Z**, no immutable revision; HTMLParser/guide.text inspection derivatives are not byte-equal raw HTML. The existing item111 ledger provenance records raw SHA-256 `316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611` and separate derivative SHA-256 `a605a2e3ec320177cc58d951300d0285894f115a4ccdff9e96e4db6e4ef10a90`, not raw-equal. These are inherited recorded identities of the shared guide, **not hashes freshly checked against raw bytes by this migration**. Steam-era community testimony, not primary developer authority, demonstrated original-build behavior, release/introduction dating, Alpha equivalence or absence proof.

## Separately identifiable retained evidence

### Item 10: Historical sleep-speed wording

`static-entities.json#behaviour` says sleeping advances the clock “100x”. Retained
`research/research_systems.md §7` cites cuwo `NORMAL_TIME_SPEED = 10`, `SLEEP_TIME_SPEED = 100`
and approximately two game minutes per real second. These reports do not clearly establish
whether “100x” compares against real time or normal gameplay time. **The historical multiplier's
baseline/units remain unresolved pending source-code verification**, including actual stepping;
100 absolute and 10 normal could be compatible, so this is not a proven numerical contradiction.
This is retained research, not freshly inspected code; no replacement number or source tag is selected.

Hybrid normal time remains **10× real time**, and approved paid/consensual inn sleep still skips
to the **next 07:00** (23:00 → 07:00), with the existing midnight-reset rules, not fast-forwarded
combat/status effects/cooldowns (§3.1). This qualifies history, not hybrid clock policy or furniture
gameplay. `generators.json#time` and all other live JSON remain unchanged.

### Item 11: Verified cuwo clock code and its limits

Freshly inspected cuwo revision **`240bb61ec42abb10a73d750ce72f243e04e55509`** is an
open server reimplementation, not the original Alpha or Steam binary. Its
[`constants.py:23–26`](https://github.com/matpow2/cuwo/blob/240bb61ec42abb10a73d750ce72f243e04e55509/cuwo/constants.py#L23-L26)
defines `MAX_TIME = 86,400,000` game milliseconds, `NORMAL_TIME_SPEED = 10.0` and
`SLEEP_TIME_SPEED = 100.0`.

[`server.py:867–876`](https://github.com/matpow2/cuwo/blob/240bb61ec42abb10a73d750ce72f243e04e55509/cuwo/server.py#L867-L876)
calculates elapsed clock time from the loop-time difference × `time_modifier` ×
`NORMAL_TIME_SPEED` × 1000, plus a clock offset. With the
[default modifier 1.0](https://github.com/matpow2/cuwo/blob/240bb61ec42abb10a73d750ce72f243e04e55509/config/base.py#L10-L11),
this is **10,000 game milliseconds per real second**: six real seconds per game minute,
144 real minutes per day. This establishes that revision's normal calculation, not original-game behavior.

An exact-symbol search of its tracked source finds `SLEEP_TIME_SPEED` **only at its definition**,
not in the clock calculation. This revision therefore does not establish historical sleep selection,
speed or baseline, or justify the retained “approximately two game minutes per real second” report.
The code was inspected, not executed; original Alpha/Steam sleeping units remain unresolved under item 10.
No replacement sleep rate or source label is selected. Hybrid normal time, approved inn skip/reset/
consent/payment rules and all live JSON remain unchanged; this is documentation only.

### Item 23: Furniture-sleep reports, not a selected rate

[Sleep revision 17998](https://cubeworld.fandom.com/wiki/Sleep?oldid=17998), edited
**2024-01-04T06:55:34Z**, reports interacting with a **bed or bedroll** using **R in Alpha /
E in Steam**, regenerating HP **without restoration items**, and being unable to do so
**in combat stance**. It also reports approximately **two game minutes per second** while
asleep; that speed sentence has no individually identified Alpha/Steam build scope.
[Bedroll revision 11769](https://cubeworld.fandom.com/wiki/Bedroll?oldid=11769), edited
**2019-04-23T19:59:38Z**, estimates **10 health per second**, explicitly **“Requires Testing”**.
Its **“does not pass time like an Inn”** wording does not clearly distinguish clock acceleration
from an inn skip. Neither page demonstrates either rate in an identified original build or
resolves historical sleep baseline/units (items 10–11); no numerical contradiction is proven.

Saved raw revision bodies/metadata and extracted passages were inspected here, from source-scout
captures retrieved **2026-10-04**, not externally re-fetched or original behavior tested by this
writer. Edit/capture dates do not date feature introductions. These community reports select
no furniture controls, healing numbers or sleep mechanics, and do not extend bed/bedroll claims
to bench/stool IDs. Free inn recovery and separate paid, consensual sleep to the **next 07:00**,
with the approved reset/payment rules, remain unchanged (§3.1). No rate, source label or live
furniture/clock declaration changes; original activation/healing/rate histories remain research.

### Item 26: Archived camp-bed sleep report

The archived [Camp Bed article, reached through Bedroll](https://web.archive.org/web/20130711002813id_/http://cubeworldwiki.net:80/index.php/Bedroll),
revision **6155**, says sleeping **“simultaneously speeds up time and replenishes health.”**
Wayback snapshot **20130711002813** and header Memento-Datetime **2013-07-11T00:28:13Z**
establish documentary timing, not feature introduction or demonstrated original-build behavior.
The body says last modified **10 July 2013 at 05:23**, timezone unspecified.

Saved body/headers/metadata were inspected here; capture timestamp **2026-10-04T21:01:27Z**
was recorded before the response (HTTP 200 / curl exit 0), not its completion time. No external
re-fetch, image inspection or original-build execution. This community report selects no rate,
controls, combat restriction, Steam scope, bench/stool effect or inn-like skip. Free inn recovery
and separate paid, consensual sleep to the **next 07:00**, with approved reset/payment rules,
remain unchanged (§3.1); original sleep histories and baseline/units remain research (items 10–11/23).
No furniture/clock declaration, source label or gameplay change follows.

### Item 29: Early sleep instructions and clock estimates

[Sleep revision 4042](https://cubeworld.fandom.com/wiki/Sleep?oldid=4042), edited
**2013-07-12T06:25:26Z**, instructs approaching the **head of a bed and hitting R** and
reports sleep's main use as **refilling HP**. It estimates **one game minute per about six
real seconds normally**, versus **one game minute per about half a real second sleeping
at camp**, separately describing an **inn-at-night jump straight to morning**.

The saved raw revision body/metadata and capture sidecars were inspected here, not externally
re-fetched or original-build tested. Source-scout request-start **2026-10-04T22:31:55Z** is not
response completion; the edit date is documentary timing, not feature introduction. These are
paired community estimates, not verified original Alpha/Steam rates or a resolution/replacement
of the qualified **100×** reference (items 10–11/23/26). No ratio, furniture
controls, numeric healing, combat restriction or bench/stool extension is selected. Free inn
recovery and separate paid, consensual sleep to the **next 07:00**, with approved reset/payment
rules (§3.1), remain unchanged. No clock/furniture declaration, source label or gameplay change;
original sleep activation/healing/rate/baseline histories remain research.

### Item 80: Sleeping-bag healing and time-flow corroboration

[Darkmega's Steam guide 1871398574](https://steamcommunity.com/sharedfiles/filedetails/?id=1871398574),
identified in item 70, reports in **Day, Night, monster respawn and camps**:
“Alternatively if you don't want to do that sleeping in a sleeping bag that usually spawn near
and around camps will regenerate your health gradually and speed up time flow.” This is separate
named community corroboration of the qualitative sleep/healing/time combination in items 23/26/29,
not another rate selection. **“Usually” is not a guaranteed campsite furnishing.** The report
establishes no healing rate, time multiplier/baseline/units, activation control, combat restriction,
bench/stool effect or verified original-build behavior. Items 10–11's historical units remain
unresolved. Hybrid normal time, free inn recovery and separate paid, consensual sleep to the
**next 07:00**, with approved reset/payment rules (§3.1), remain unchanged.

Retained public `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1056`, identity and URL/capture
sidecars were inspected without re-fetching; capture **2026-10-04T21:01:17Z**. Item 70's
shared title/author/displayed-date limits apply; title **updated 4/10** remains distinct.
No immutable revision is established. Derived inspection text is not byte-equal raw HTML. This Steam-era community report
is not primary developer documentation, original-build demonstration, release/introduction dating
or Alpha equivalence. No source labels, live JSON, checker/code/tests or gameplay change;
original sleep activation/healing/rate histories remain research, not new implementation debt.

## Qualified conclusion and uncertainty

The cuwo revision establishes its **normal** calculation (10,000 game ms per real second with modifier 1.0), not original-game sleep. Its sleep constant is definition-only. The approximately-two-minutes report, the approximately-half-second camp minute, 100×'s unspecified baseline and Bedroll's “does not pass time like an Inn” wording remain separately qualified; do not manufacture a contradiction or reconcile them into a chosen rate. Qualitative community corroboration of sleep/healing/accelerated time proves no tested original-build implementation. Uncertainty remains research, not new implementation debt or proof of absence.

All six original [§5 headings (locator=validation-contract-mapping-owner-approved-2026-09-28)](../../ontology/domain/5_Constraints.dsl) remain as legacy source-item anchors, retaining current interpretive qualifications. Routine approvals/refusals and unique verification/commit receipts are not findings and remain where they were.
