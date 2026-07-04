---
name: sap-fiori-apps-reference
description: Generate SAP Fiori Launchpad URLs from app names. Searches the SAP Fiori apps reference library via whichever MCP server your environment exposes for it, extracts Semantic Object and Action, and constructs proper FLP URLs with required parameters like sap-client and sap-language.
license: MIT
---

# SAP Fiori URL Generator Skill

This skill enables you to generate SAP Fiori Launchpad (FLP) URLs based on app names using the `mcp-sap-docs-local` MCP tools.

## References & Tools

When you need to look up SAP Fiori app information, search and fetch from the SAP Fiori apps reference library using whichever MCP server/tool your environment exposes for it (`sap-dev-rule.md` §9). You need two lookups: (1) search by app name/keywords to get a list of candidate apps, (2) fetch full details for a specific App ID (e.g., F1511A) to get its Semantic Object and Action. In Claude Code specifically, a not-yet-loaded MCP tool appears as a deferred stub — use the `ToolSearch` tool with a relevant query to find and load its schema before calling it.

## Overview

When a user provides:
1. A base SAP Fiori URL (e.g., `https://myserver.com:44300`)
2. An app name (e.g., "Create Maintenance Request")

You will:
1. Search the Fiori Library using the MCP tool.
2. Fetch the app details to extract the "Semantic Object" and "Action".
3. Construct the complete FLP URL with proper parameters.

## URL Structure

The complete SAP Fiori Launchpad URL follows this pattern:

```
{BASE_URL}/sap/bc/ui2/flp?sap-client={CLIENT}&sap-language={LANGUAGE}#{SEMANTIC_OBJECT}-{ACTION}
```

### Required Parameters (MUST be provided by user)

- **BASE_URL**: The SAP system base URL (e.g., `https://myserver.com:44300`)
  - MUST be provided by user
  - No default value
  
- **sap-client**: The SAP client number (e.g., `100`)
  - MUST be provided by user
  - No default value
  - Required for all SAP Fiori Launchpad URLs

### Optional Parameters

- **sap-language**: Language code (e.g., `EN`, `DE`, `FR`)
  - Default: `EN` if not specified by user
  
### Auto-Generated Parameters

- **SEMANTIC_OBJECT-ACTION**: Extracted from the app details returned by the MCP fetch tool.

## Implementation Steps for the Agent

1. **Search for the App**: search the Fiori apps reference library (query: app name/keywords, e.g. "Create Maintenance Request").
2. **Fetch App Details**: from the search results, find the matching App ID (e.g., "F1511A") and fetch its full details.
3. **Extract Semantic Object-Action**
   Look for the `SemanticObject` and `Action` fields in the returned data. If they are missing, report that the app cannot be launched via URL intent.
4. **Construct the URL**
   Combine the user-provided `BASE_URL` and `sap-client` with the `SemanticObject-Action` to generate the URL.

## Example Interaction

**User:** "Generate URL for Create Maintenance Request app with base URL https://myserver.com:44300 and client 100"

**Agent:**
1. Searches the Fiori apps reference library for "Create Maintenance Request".
2. Identifies App ID: F1511A.
3. Fetches full details for F1511A.
4. Finds Semantic Object: `MaintenanceWorkRequest` and Action: `create`.
5. Responds to user:
```
App Found: Create Maintenance Request (F1511A)
Semantic Object-Action: MaintenanceWorkRequest-create

Generated URL:
https://myserver.com:44300/sap/bc/ui2/flp?sap-client=100&sap-language=EN#MaintenanceWorkRequest-create
```
