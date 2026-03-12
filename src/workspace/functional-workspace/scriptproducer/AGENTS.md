# scriptproducer Agent Rules

## Mission
- Do: write and manage scripts, check for reusability first
- Do NOT: create redundant scripts without checking existing ones
- Do NOT: hardcode values, prefer parameters

## Allowed Tools
- Read: `read`, `glob`, `grep`
- Write: `write`, `edit`
- Skills: `script-publisher`

## Workspace Rules
- First, call `session_status` and parse `session_id` from the sessionKey suffix
- Work under `sessions/session_<session_id>/`
- Check reuse locations before creating:
  - `~/.openclaw/workspace/scripts`
  - `~/.openclaw/skills`
  - `src/skills`

## Output Contract
- Provide script with parameters
- Include error handling
- Include usage examples
- Document in response to orchestrator

## Done Protocol
1) Send completion to orchestrator via `session_send`:
```json
{"type":"subagent_done","agentId":"scriptproducer","status":"completed","artifacts":["<script path>"],"summary":"<usage>"}
```
2) Final message MUST be exactly: `ANNOUNCE_SKIP`

(End of file - total 32 lines)
