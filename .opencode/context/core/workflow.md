# Development Workflow & Process

## Standard Workflow

1.  **Understand:**
    *   Read user request.
    *   **Grepping/Globbing:** Search related code and docs.
    *   **Align with PRD:** Confirm features match `docs/PRD.md`.

2.  **Plan:**
    *   List tasks in `TodoWrite`.
    *   **Checklist:** Include i18n, UI adaptation, test verification steps.

3.  **Execute:**
    *   Write code.
    *   **Maintain Consistency:** Mimic existing code naming and structure.

4.  **Verify:**
    *   **Compile Check:** Ensure `flutter build` passes.
    *   **Self Review:** Check for missed i18n? Exception handling?

## Role Separation (Thinking Hats)

To balance features, stability, and speed, explicitly "wear different hats" using Skills.

### 🎩 Product Hat / Architect Hat (Global View)
*   **Role:** Requirements, User Stories, PRD updates, Tech Stack, Security, Design. Focus on Value, Stability/Security.
*   **Recommended Model:** **Google Gemini 2.0 Pro/Flash** (Best for massive context & reasoning).
*   **Action:**
    1.  End current session.
    2.  Start new session with Gemini: `opencode --model google/gemini-2.0-pro-exp-02-05 "Review the entire codebase and update PRD/Architecture doc"`
    3.  Load Skills: `expert-prd-writer` / `expert-arch-architect`.
    4.  Update `docs/PRD.md`, `docs/Architecture_Design.md`, perform Security Audit.

### 🎩 Engineer Hat (Local View)
*   **Role:** Execution, Coding. Focus on Quality/Compliance.
*   **Recommended Model:** **Claude 3.5 Sonnet** (SOTA Coding, Best for precise implementation).
*   **Action:**
    1.  Start session with Sonnet (Default).
    2.  Load Skills: `ios-development`, `test-driven-development`.
    3.  Focus on single file/module changes.
    4.  Write code, Unit Tests, Build.

## Superpowers
This project integrates the Superpowers skill library. **MUST** invoke these skills for specific tasks:

*   **New Features:** `brainstorming` -> `writing-plans` -> `executing-plans`
*   **Bug Fixes:** `systematic-debugging` (No Trial & Error!)
*   **Pre-Commit:** `verification-before-completion`
