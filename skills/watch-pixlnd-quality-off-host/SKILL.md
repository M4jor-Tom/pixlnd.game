---
name: "watch-pixlnd-quality-off-host"
description: "Run the pixlnd Quality gate on GitHub instead of locally when the owner approves a one-time local background/pre-push hook skip and a temporary CI branch, then watch and classify the exact GitHub run."
version: 3
created: "2026-11-21"
updated: "2026-11-22"
---
## When to Use
Use only after explicit approval of the temporary remote ref, source scope, and the two named local hook skips. This is not a normal local receipt or permission to retry, merge, or update other refs.

## Procedure
1. In an isolated checkout verify the entire candidate Git tree against reviewed evidence. Keep the primary index untouched. Verify the unchanged Quality workflow is triggered by branch push and that release-only branch triggers do not match.
2. Commit on the temporary branch with only SKIP=gate-background scoped to the commit. Read the short hook results and recheck that the committed tree is byte-identical to the approved tree.
3. Verify the remote target before pushing. Push only the approved commit/ref with SKIP=gate-receipt scoped to that command. Verify the exact remote SHA and protected branch refs afterward; do not disable hooks globally, use force, or fabricate receipts.
4. Use gh run list filtered by workflow, branch, push event and commit SHA to obtain a run ID. Watch that ID until it stops; save gh run view JSON and the complete job log in the evidence directory.

## Pitfalls
- A terminated pre-commit command may print only the start of a hook and discard buffered unittest detail. Exit 143 alone does not identify an OOM, a timeout, or a failing test. Keep only explicitly observed passes and distinguish missing test results from assertions.
- After separate approval, use a branch-only replacement of the Quality workflow on the diagnostic branch so the original broad push trigger does not launch a duplicate full job. Do not carry the diagnostic commit into a feature or release branch. Keep test and lockfile bytes intact; use one step per exact unfinished batch with the existing test limits and unbuffered verbose output. Verify selector membership from raw logs as well as step results.
- On a non-default branch GitHub may display the default-branch workflow name in the CLI listing even after the pushed workflow name changes. Verify by exact head SHA, branch, run name, job and step names; do not infer that the normal gate ran from workflowName alone.
## Verification
1. Short hook output shows actual passes or normal no-matching-files skips, plus only the intended policy skips. Independently verify the published commit/tree, unchanged protected refs, and (for focused runs) that the baseline candidate differs only by the diagnostic workflow.
2. Before a focused push, reconcile the exact unfinished module or selector inventory against the candidate and accepted prior receipts. Keep independent suites from cancelling one another, preserve original discovery and runner commands, and smoke-test the wrapper with stub commands to prove that a failing candidate does not get masked by a baseline pass.
3. From the raw logs verify every selected check's terminal result, not just workflow status. For a claimed pre-existing failure, rerun the failed check on the pinned pre-change tree with the same toolchain and compare test IDs and diagnostic messages; matching counts alone do not suffice. Normalize only ephemeral paths. Distinguish the focused comparison from a full gate pass.