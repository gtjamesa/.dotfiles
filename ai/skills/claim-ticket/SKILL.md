---
name: claim-ticket
description: "Claim a ticket from an Epic, or the next available agent ticket"
disable-model-invocation: true
---

Pick up the next available ticket from epic $ARGUMENTS[1] in the current repository and implement it in a worktree, under `.claude/worktrees`.

1. Find the frontier — unblocked, unclaimed, agent-ready:

   ```
   gh api repos/<repo>/issues/$ARGUMENTS[1]/sub_issues --jq '.[]
     | select(.state=="open")
     | select(any(.labels[].name; .=="ready-for-agent"))
     | select(.issue_dependencies_summary.blocked_by==0)
     | select(.assignee==null)
     | "#\(.number) \(.title)"'
   ```

   Take the FIRST result — they are in dependency order. If the list is empty, stop and tell me which tickets are blocked and by what; do not pick a `ready-for-human` ticket or one with an open blocker.

2. Claim it immediately, before doing anything else, so parallel sessions don't collide:
   gh issue edit <n> --add-assignee @me

3. Read the full ticket: gh issue view <n> --comments
   The body is self-contained — it carries its own evidence, greps and doc quotes.
   Don't go hunting for the audit it came from.

4. Create a worktree off main and work there. Branch: <type>/<short-slug>-<n> (repo convention, e.g. fix/beta-invite-actions-853, feat/app-sitemap-865).

5. Run /implement <n>. Act on findings from the `/code-review` output (ie high-value fixes and hard violations)

6. Check off "Acceptance criteria" in the issue and ensure all requirements are met

7. Before finishing: add a changeset in .changeset/, typecheck (pnpm lint:types), and run the tests you touched — not the whole suite.

8. Open a PR whose body links the ticket with "Closes #<n>" and states which acceptance criteria are met and which (if any) were deliberately deferred, with reasons. If CI does not go green, fix it.

Do not triage the ticket — it came from /to-tickets and is already agent-ready.
