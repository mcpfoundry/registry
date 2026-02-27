# MCP Foundry

**The open registry for Model Context Protocol (MCP) tools.**

MCP Foundry is a curated catalog and submission pipeline for MCP-compatible tool servers. It provides:

- **Verified Tool Registry**: A catalog of security-scanned, community-reviewed MCP servers that agents can trust.
- **Open Submission Pipeline**: Any developer can submit an MCP tool via pull request. Submissions go through automated security scanning and human review before being listed as verified.
- **Searchable Catalog**: Browse and search MCP tools by name, author, capability, or permission scope.
- **Transparent Security Scanning**: Every verified tool includes a scan summary so consumers know exactly what was checked.

## How It Works

1. **Browse** the catalog at [mcpfoundry.org](https://mcpfoundry.org) or query the API.
2. **Install** tools directly into your MCP-compatible agent (e.g., Agent Toolbox, Claude Desktop).
3. **Submit** your own MCP server by opening a PR with a `toolbox.toml` manifest. The CI pipeline will automatically scan your tool and post results for reviewers.

## Repository Structure

```
registry/
  .github/
    workflows/review.yml    # CI pipeline for tool submissions
    CODEOWNERS              # Protected file ownership
    PULL_REQUEST_TEMPLATE.md
  api/
    schema.sql              # Supabase-compatible PostgreSQL schema
  catalog/
    verified.json           # Curated, scanned MCP tool entries
    unverified.json         # Community-submitted, not yet reviewed
  submissions/              # PR-based tool submissions go here
  vercel.json               # Vercel deployment config
```

## Deployment

- **API**: Vercel serves `catalog/*.json` files with CORS headers for Agent Toolbox desktop app access.
- **DNS**: Cloudflare manages `mcpfoundry.org` with proxied records pointing to Vercel.
- **Database**: Supabase PostgreSQL for the full catalog API (schema in `api/schema.sql`).

## Tool Manifest Format

Every tool submission includes a `toolbox.toml` manifest:

```toml
[tool]
name = "my-tool"
version = "1.0.0"
description = "What this tool does"
author = "Your Name"

[binary]
entry = "my-tool-mcp"
platforms = ["darwin-arm64", "darwin-x64", "linux-x64"]

[permissions]
filesystem = ["read:~/Documents"]
network = false
env_vars = ["API_KEY"]

[distribution]
binary_url = "https://github.com/user/repo/releases/download/v1.0.0/my-tool-darwin-arm64.tar.gz"
sha512 = ""  # Set by MCP Foundry during verification

[[mcp.tools]]
name = "example_function"
description = "What this function does"
```

## Contributing

To submit a tool for verification:

1. Fork this repository.
2. Add a `toolbox.toml` in `submissions/<your-tool-id>/`.
3. Open a pull request targeting `main`.
4. The CI pipeline will scan your tool and post results as a PR comment.
5. A maintainer will review and, if approved, merge your tool into `catalog/verified.json`.

See the [pull request template](.github/PULL_REQUEST_TEMPLATE.md) for the required submission format.

## License

MIT
