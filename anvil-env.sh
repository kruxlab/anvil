# anvil: passthrough env vars from `exe.dev new --env FOO=bar` (which set
# them on PID 1) into every shell, so opencode + MCP servers + CLI tools
# see them without per-session re-export. Add new names to the list below.

ANVIL_PASSTHROUGH="CF_MCP_TOKEN GITHUB_TOKEN OPENCODE_API_KEY"

for _v in $ANVIL_PASSTHROUGH; do
  eval "_cur=\${$_v:-}"
  if [ -z "$_cur" ]; then
    _val=$(tr '\0' '\n' </proc/1/environ 2>/dev/null | sed -n "s/^${_v}=//p")
    [ -n "$_val" ] && export "$_v=$_val"
  fi
done
unset _v _val _cur ANVIL_PASSTHROUGH
