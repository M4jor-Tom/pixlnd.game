# Handoff — pending continuation

## Ontology DSL rebase — native browser acceptance pending

Branch: `feat/ontology-dsl`. Reviewed implementation HEAD:
`c7dc40c994de8cdd06426c0bc5cccf7c9a345760`; introducing migration commit:
`80c3c2515bd4fd4650393559d774a1c707fb655c`, rebased onto baseline
`175e0c59b6a05ead62d29bd851085cd5a3818378` (not necessarily current master).
No rebase is active. Recovery branch:
`backup/ontology-dsl-before-master-rebase-20261019-173651`.

Scoped independent correctness and ponytail review found no blocking issue in the two-file
Android alias fix. Fresh exact-HEAD engine/tool gates, metadata/two-commit history and upstream
policy/runtime/data preservation checks pass. All ten alias targets, all seven actual generated
reference addresses, 54 row anchors and separate `block` identities are independently checked.
Final native-browser acceptance is **not established**; do not repeat completed review or
implementation unless HEAD/source changes. No further implementation is selected.

Remaining continuation:
1. Read `/tmp/pixlnd-dsl-resume-review.VoKtUB/review-summary.md` for current reviews, exact-ref
   gates, preservation proof and the non-blocking generated-locator regression-coverage note.
   Earlier `/tmp/pixlnd-ontology-dsl-rebase.ZTZpBZ/review-evidence.md` describes superseded
   `e89b5ea`; its `replay-<full-SHA>/` directories retain the current per-commit evidence.
2. Complete the native viewer browser gate against the reviewed implementation using the
   manual checklist below. Use IPv4 `127.0.0.1:8080`:
   `localhost` selected an unreachable IPv6 loopback in the attempted check. Even over IPv4,
   native JSP/WAR classloading exceeded the bounded viewer window; no rendered-page assertions
   or new screenshot passed. Diagnostics and the reusable Playwright check are in the current
   evidence packet. Owned viewer/browser processes are stopped; evidence is retained.
3. Reconfirm exact HEAD/source/index identity, synthesize the rendered locator/navigation
   result and only then establish final acceptance. If temporary evidence is unavailable,
   reconstruct from Git and rerun the necessary checks; never substitute stale browser evidence.

Publication of this handoff and removal of only the DSL worktree after a verified push are
selected; neither completes browser acceptance. A non-fast-forward update requires explicit
force-with-lease approval; this note alone grants none. No merge, further implementation or
unrelated cleanup is authorized. Do not restore, stash, reset or edit the primary checkout at
`/home/theta/repos/pixlnd`. Whole-primary-checkout before/after equality is unproven.

### Manual browser acceptance

From the repository root with `feat/ontology-dsl` checked out:

```sh
git branch --show-current   # must print feat/ontology-dsl
nix run .#ontology-view
```

Leave the terminal running. This command has no ten-minute timeout; the automated check imposed
that limit. Initial page loading may be slow while the native viewer compiles its web pages.

1. Open <http://127.0.0.1:8080>, choose **Entities definitions**, and confirm the graph appears.
2. Open <http://127.0.0.1:8080/workspace/1/documentation>.
3. Confirm **Controls** and **Controller profiles** appear in the contents and navigation works;
   Controls tables render normally; **Controller profiles → Android** contains all ten rule
   subsections, from layout through Android Back.
4. Find these `locator=…` labels and check their displayed source addresses against the table.
   Paths depend on the checkout location; the following suffixes match the reviewed implementation.

| Locator | Expected source-address suffix |
|---|---|
| `android-interruption` | `controller-profiles.dsl:582; id=c-intentional-release-versus-interruption` |
| `android-request-order` | `controller-profiles.dsl:743; id=c-requests-arriving-together` |
| `android-panels` | `controller-profiles.dsl:637; id=c-inventory-skills-and-shop-touch-interaction` |
| `android-device-scope` | `controller-profiles.dsl:821; id=c-device-switching-and-customization-in-this-slice` |

Source addresses are intentionally text, not clickable links. Save screenshots of the relevant
documentation to support acceptance. If a page hangs, retain the terminal output and report the
URL and elapsed time instead of marking it passed. Press **Ctrl-C** in the terminal to stop the
viewer when finished. No gameplay or Android device test is required for this browser check.

## Android touch — characterization and publication follow-up

Current hardware-test status and its evidence limits live in the
[Android profile (locator=android)](../ontology/domain/controller-profiles.dsl). Further device/checklist
characterization and overlay render-cost measurement remain optional separately selected work,
not a device-access prerequisite for the authorized combat slice. Do not infer individual
checklist passes or install an Android SDK/ADB/export environment.

Android push, publication and changelog backfill remain unauthorized; the separately authorized
combat DOT documentation and feature-branch push do not extend to this follow-up.
Remaining controls scope stays in the
[backlog](ROADMAP/todo_implement.md#device-independent-controls-documentation-only).

## Dormant source continuation — separate owner request required

The earlier finite 108–111 source-pass audit, parent native acceptance/acknowledgment and
publication outcome remain unestablished by this gameplay checkpoint. Inspect existing native
evidence and the prior checkpoint at
`9b63e6e11c8c52b38183624c4fd1c43e9f09a870:docs/HANDOFF.md` before any separately authorized
continuation. Source-status maintenance already exists in `f801166`; do not recreate it or
restore the old §E history. Publishing gameplay documentation renews no earlier conditional
source-pass grant and does not establish its acceptance/publication outcome.

No selected source item is pending; research is not exhausted. Existing remaining evidence gaps
stay at [§7 (locator=7-open-points-for-validation)](../ontology/domain/7_Open_points_for_validation.dsl) and
the [validation-contract backlog](ROADMAP/todo_implement.md#validation-contract-documentation-approved-implementation-unauthorized).
Silk/Spinning Wheel quantities remain **HOLD**. Retained/withdrawn source leads stay **UNAPPROVED**;
do not reopen handled class/weapon/lore attributions. Any future sourcing must follow
[lessons](lessons.md) and the current reconciliation contract: only inspected public article
extracts are public-safe; private authenticated DOM/account/token material is prohibited.
This continuation note authorizes no source research, inventory, selection or publication.
