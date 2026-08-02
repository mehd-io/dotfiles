# Public repository safety

When these instructions are loaded from the dotfiles repository itself, that repository is public. In any other public repository, treat every tracked file and proposed diff as publicly visible.

- Never commit credentials, API keys, access tokens, cookies, private keys, signed URLs, connection strings, account identifiers, or secret-bearing environment files.
- Never commit concrete `op://` references. Commit placeholder `.example` templates and keep real vault, item, field, and account identifiers in machine-local files.
- Never commit machine-local trust or authorization state, including approval hashes, hook trust caches, generated auth files, or one-off command approvals.
- Keep portable defaults separate from mutable runtime configuration. Prefer sanitized templates or base files over symlinking stateful application configs.
- Avoid absolute home-directory paths and private infrastructure details unless they are intentionally public and required by the configuration.
- Before committing or pushing, inspect the exact staged diff and scan it for likely secrets and sensitive paths.
- Stage explicit paths or hunks. Do not use broad staging such as `git add -A` when unrelated changes are present.
- If a value may be sensitive or its purpose is unclear, leave it untracked and ask before including it.
- Before staging, committing, pushing, or creating/updating a pull request, prepare and validate the complete local diff and present it to the user for review.
- Do not take any of those actions until the user explicitly approves that local diff.
- After approval, verify that the staged diff contains only the reviewed paths and hunks.

# Pull-request safety

- Never merge a pull request on the user's behalf, even when explicitly asked.
- Never enable auto-merge or add a pull request to a merge queue.
- Stop at green and merge-ready, provide the pull-request URL, and leave the final UI review and merge exclusively to the user.

# Local diff review

- When Lumen is available, prefer `lumen diff` as the interactive agent-to-human review surface. Use `lumen diff --watch` while changes are still being iterated.
- Launch Lumen so its stdout is captured by the agent. Treat annotations returned with Lumen's `s` action as user feedback to address.
- Lumen annotations, marking files viewed, closing Lumen, or returning no annotations do not constitute approval to stage, commit, push, or create/update a pull request. Require the user's explicit approval in the conversation.
- Do not configure Lumen AI providers or store API keys unless the user explicitly requests it. The diff viewer and annotation workflow do not require AI credentials.
