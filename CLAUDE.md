# Claude Code project instructions

See [`AGENT.md`](AGENT.md) for the actual project context, commands, and
conventions - that file is the canonical, tool-agnostic source so it stays
useful for any agent working in this repo, not just Claude Code.

The one Claude-Code-specific thing worth calling out here: the user has
explicitly asked to **never commit without being asked**, even after
finishing a chunk of work, and to **always run the full lint suite**
(`ansible-playbook --syntax-check`, `yamllint`, `ansible-lint`,
`hadolint`) clean before any commit that does happen. Both are stated in
`AGENT.md` too, but given how often this comes up in this repo, they're
worth repeating here.
