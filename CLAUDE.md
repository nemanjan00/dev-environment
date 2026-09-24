<!--
Import shim. The real instructions live in AGENTS.md so every agent
(Claude, opencode, kimi, pi) reads one file. This shim stays because Claude
Code reads AGENTS.md only when no CLAUDE.md exists in the cwd *or any parent* —
a stray ~/CLAUDE.md above this repo would otherwise hide AGENTS.md entirely.
The import never double-loads. See AGENTS.md → "One file, two names".
-->
@AGENTS.md
