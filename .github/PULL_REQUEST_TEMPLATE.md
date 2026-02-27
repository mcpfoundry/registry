## Tool Submission

### Tool Information

- **Tool ID**: <!-- e.g. my-tool -->
- **Tool Name**: <!-- e.g. My Tool Server -->
- **Version**: <!-- e.g. 1.0.0 -->
- **Author**: <!-- your name or org -->
- **Homepage**: <!-- link to repo or website -->

### Description

<!-- Brief description of what this tool does (1-2 sentences) -->

### MCP Functions Exposed

<!-- List each function name and what it does -->

- `function_name` - description

### Permissions Justification

<!-- For each permission your tool requests, explain WHY it needs it -->

| Permission | Value | Reason |
|-----------|-------|--------|
| filesystem | `read:~/Documents` | Needs to read user files for conversion |
| network | `false` | No network access needed |
| allow_exec | `false` | No child processes needed |

### Checklist

- [ ] `toolbox.toml` is in `submissions/<tool-id>/`
- [ ] Binary entry name matches an actual binary
- [ ] All permissions are justified above
- [ ] Tool description is accurate and does not contain hidden instructions
- [ ] I have tested this tool locally with Agent Toolbox or another MCP client
