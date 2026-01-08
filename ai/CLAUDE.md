- In all interactions and commit messages, be extremely concise and sacrifice grammar for the sake of concision.

## PR Comments

<pr-comment-rule>
When I say to add a comment to a PR with a TODO on it, use the GitHub 'checkbox' markdown format to add the TODO. For instance:

<example>
- [ ] A description of the todo goes here
</example>
</pr-comment-rule>

- When tagging Claude in GitHub issues, use '@claude'

## Changesets

To add a changeset, write a new file to the `changeset` directory.

The file should be named `0000-your-change.md`. Decide yourself whether to make it a patch, minor, or major change.

The format of the file should be`:

```md
---
'packagename': patch
---

Description of the change

```

`packagename` should be the name of the package contained within the project's `package.json` file.

## GitHub

- Your primary method of interacting with GitHub should be the GitHub CLI (`gh`)

## Plans

- At the end of each plan, give me a list of unresolved questions to answer, if any. Make the questions extremely concise. Sacrifice grammar for the sake of concision.

## TDD

- When a bug can't be reproduced in the test environment (e.g., Hermes-specific issues that don't manifest in Node.js/V8), acknowledge honestly: "Can't reproduce in Node.js — this is a targeted fix based on Sentry stacktrace" rather than pretending it's TDD. 
