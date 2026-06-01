---
name: config-audit
description: "Audit Claude Code configuration for security: check permissions, hooks, MCP servers, and settings"
effort: medium
---

# Config Audit

When asked to audit configuration, check security settings, or verify Claude Code setup:

## Process

1. **Read settings** — Check `~/.claude/settings.json` for:
   - Permission rules (deny/allow lists)
   - Whether dangerous bypasses are enabled (`dangerouslySkipPermissions`, `bypassPermissions`)
   - Hook configuration (are security hooks active?)
   - Telemetry settings
   - Auth configuration

2. **Check MCP servers** — Read `~/.claude/.mcp.json` for:
   - Which servers are enabled
   - Whether any have `autoApprove` for sensitive tools
   - Whether servers use secure transport (stdio vs SSE with auth)
   - Whether any servers have hardcoded credentials in env vars

3. **Check hooks** — Verify security hooks are active:
   - `block-destructive-commands` (PreToolUse:Bash)
   - `pre-write-security-scan` (PreToolUse:Write|Edit)
   - Any hook for blocking sensitive file reads (e.g., `.env`, `.ssh`)

4. **Check CLAUDE.md** — Verify expected behavioral guidelines are loaded.

5. **Generate audit report**

## Output Format

```
# Claude Code Security Audit

## Settings
- ✓ Destructive commands denied (rm -rf, sudo, git push)
- ✓ Sensitive file reads denied (.env, .ssh)
- ✗ bypassPermissions is enabled — DISABLE THIS
- ✓ Telemetry disabled

## Hooks (X/Y active)
- ✓ block-destructive-commands
- ✗ pre-write-security-scan — NOT INSTALLED

## MCP Servers
- ✓ servername: no autoApprove
- ⚠ custom-server: autoApprove includes write tools

## CLAUDE.md
- ✓ Behavioral guidelines loaded

## Recommendations
1. Disable bypassPermissions
2. Install pre-write-security-scan hook
3. Remove autoApprove from custom-server write tools
```
