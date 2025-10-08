# Development Guidelines

## 🎯 PROJECT STATUS & CONTEXT

**[CUSTOMIZE THIS SECTION FOR YOUR PROJECT]**

**Current Status**: [Project phase, current work, key achievements]
**Active Branch**: [Current branch name]
**Last Updated**: [Date]

**Key Documentation**:
- [List critical docs here]

---

## 🚨 QUICK START CHECKLIST

**Before ANY work:**

1. **PRD/PDR Required?** New features/UX changes → PRD first. Approved PRDs → PDR next.
2. **GitHub Issue** (after PRD/PDR if applicable)
3. **Feature Branch** (`feat/issue-123-description`) - NEVER commit to master
4. **Agent Analysis** (see trigger rules in Section 2)
5. **TDD Cycle** (failing test → minimal code → refactor)
6. **Draft PR** (early visibility)
7. **Agent Validation** (before marking ready)
8. **Close Issue** (verify completion)
9. **🚨 Session Handoff** (MANDATORY after issue completion - see Section 5)

---

## 1. WORKFLOW ESSENTIALS

### PRD/PDR Workflow

💡 Feature Request/Idea
   ↓
📋 PRD Creation → 🤖 **general-purpose-agent** → 👥 Stakeholders → ✅ Doctor Hubert Approval
   ↓
🏗️ PDR Creation → 🤖 **6 Core Agents:**
                   • architecture-designer
                   • security-validator
                   • performance-optimizer
                   • test-automation-qa
                   • code-quality-analyzer
                   • documentation-knowledge-manager
                → 👨‍💻 Tech Review → ✅ Doctor Hubert Approval
   ↓
⚡ GitHub Issue Creation → Branch Creation → Implementation →
   🤖 **During Implementation:**
   • ux-accessibility-i18n-agent
   ↓
Draft PR →
   🤖 **Agent Review Checklist (MANDATORY):**
   • test-automation-agent (test strategy & coverage)
   • code-quality-analyzer
   • security-validator
   • performance-optimizer
   • architecture-designer (if structural)
   • ux-accessibility-i18n-agent (final check)
   • documentation-knowledge-manager (docs current & complete)
   • devops-deployment-agent (pre-deployment readiness)
   ↓
Testing → PR Ready for Review → Merge → Deployment → 🚨 **Session Handoff**

**Documents Location:**
- PRDs: `docs/implementation/PRD-[name]-[YYYY-MM-DD].md`
- PDRs: `docs/implementation/PDR-[name]-[YYYY-MM-DD].md`

---

### Git Workflow

#### **1. Planning Phase**

- **Create GitHub issue ONLY after PRD/PDR approval** (if required)
- **Reference approved PRD/PDR documents** in issue description
- Issue describes implementation tasks, not requirements (requirements in PRD)

#### **2. Branch Setup**

- **NEVER commit directly to `master`**
- Create descriptive branch: `fix/auth-timeout`, `feat/api-pagination`, `chore/ruff-fixes`
- Reference issue in branch name: `feat/issue-123-description`

#### **3. Development Phase**

- **Document agent recommendations** in issue or PR description
- **Validate with secondary agents** for cross-functional concerns
- Make atomic commits (one logical change per commit)
- **NEVER use `--no-verify`** to bypass hooks
- **NEVER include co-author or tool attribution** - no `Co-authored-by:`, `Generated with Claude Code`, or similar mentions in commits/PRs

#### **4. Review Phase**

- **Pull requests** for all changes (draft early, ready when complete)
- Use commit/PR messages like `Fixes #123` for auto-linking
- Squash only when merging to `master`; keep granular history on feature branch

#### **5. Completion Phase**

- **Verify issue closure** after PR merge
- **🚨 MANDATORY: Complete session handoff** (see Section 5 for full protocol)

---

### Session Handoff Integration (Quick Reference)

**CRITICAL: This is NON-NEGOTIABLE. Perform handoff after EACH GitHub issue - no exceptions!**

Small, incremental handoffs prevent context loss and maintain project clarity.

**✅ ALWAYS perform handoff when:**
- ✅ **Any GitHub issue closed/completed** (regardless of size) ← **PRIMARY TRIGGER**
- ✅ **Any PR merged to master**
- ✅ **Any phase/milestone completed**
- ✅ **Work session ending** (even if work incomplete)
- ✅ **Major documentation created** (PRD, PDR, architecture decisions)

**❌ NEVER skip handoff even if:**
- ❌ "It's just a small issue"
- ❌ "I'll do it after the next one"
- ❌ "The work isn't interesting enough to document"

**⚡ If you're unsure whether to trigger session handoff → TRIGGER IT**

**Quick Handoff Checklist:**
1. ✅ Issue work completed (code changes, tests passing)
2. ✅ Draft PR created and pushed to GitHub
3. ✅ All tests passing, pre-commit hooks satisfied
4. ✅ Session handoff document created/updated
5. ✅ 5-10 line startup prompt generated for next session
6. ✅ Clean working directory (no uncommitted changes)

**📋 See Section 5 for complete Session Handoff Protocol with detailed steps and templates**

---

### Test-Driven Development (NON-NEGOTIABLE)

1. **RED** - Write failing test first
2. **GREEN** - Minimal code to pass
3. **REFACTOR** - Improve while tests pass
4. **NEVER** write production code without failing test first

**Required test types**: Unit, Integration, End-to-End (no exceptions without explicit authorization)

---

### Testing Infrastructure (MANDATORY)

**Before implementing ANY code changes, you MUST run tests.**

#### Docker Testing (Primary - 30 seconds)

```bash
# Run all automated tests
./tests/docker-test.sh

# Interactive debugging
./tests/docker-test.sh --interactive
```

**Required:** ALL code changes must pass Docker tests before committing.

**What it tests:**
- Shell startup verification (zsh initializes correctly)
- Starship availability and caching
- Dotfiles symlink creation
- Shell startup performance measurement
- Basic functionality validation

#### VM Testing (Comprehensive - 5 minutes)

Use vm-infra repository for full integration testing:

```bash
cd ../vm-infra
./provision-vm.sh test-changes --test-dotfiles ../dotfiles
```

**When to use:**
- **Docker**: Every commit, rapid iteration, pre-commit validation
- **VM**: Before PR merge, performance validation, deployment testing

**CRITICAL:** Docker tests are MANDATORY before ANY commit. VM tests are MANDATORY before merging PRs.

---

## 2. AGENT INTEGRATION

### Context Triggers

**MANDATORY: Claude must invoke these agents when context matches:**

- **Multi-file/system changes** → `architecture-designer`
- **Credentials, processes, network, files** → `security-validator`
- **All code modifications** → `code-quality-analyzer`
- **User interface mentions** → `ux-accessibility-i18n-agent`
- **Performance keywords** (slow, optimize, timeout) → `performance-optimizer`
- **Deploy/infrastructure mentions** → `devops-deployment-agent`
- **Test mentions, TDD workflow, coverage** → `test-automation-qa`
- **Documentation changes, README updates, phase docs** → `documentation-knowledge-manager`

### Validation Requirements

**Post-Implementation Validation:**
All relevant agents must validate final implementation before marking work complete.

### Time Management

- **Agent disagreements**: Escalate to Doctor Hubert if >3 agents conflict
- **Quality thresholds**: Documentation ≥4.5, Security ≥4.0, Performance ≥3.5, Code Quality ≥4.0

### Decision Authority

**You can decide:**
- Technical implementation approaches within approved PDR
- Code structure and organization
- Test strategies and coverage

**Must ask Doctor Hubert:**
- Scope changes from original PRD/PDR
- Major architecture deviations
- Timeline extensions >1 day

### Agent Usage Accountability

**Doctor Hubert Enforcement Flags:**
- **"AGENT-AUDIT"**: Doctor Hubert can request full agent usage audit for any response
- **"MANDATORY-AGENTS"**: Triggers immediate agent analysis if Claude missed it
- **"CROSS-VALIDATE"**: Forces Claude to run all validation agents on current state

---

## 3. CODE STANDARDS

### Writing Principles

- Simple, maintainable solutions over clever ones
- Smallest reasonable changes
- Match surrounding code style
- **NEVER remove code comments unless provably false**
- **NEVER implement mock mode (use real data/APIs)**
- **NEVER name things 'improved', 'new', 'enhanced'** - be evergreen

### File Requirements

- All code files start with 2-line comment: `# ABOUTME: [description]`
- Evergreen comments (describe current state)
- Ask before reimplementing from scratch

### Pre-commit Hooks (MANDATORY)

- Install: `pre-commit install`
- **NEVER bypass with `--no-verify`**
- All commits must pass checks

---

## 4. PROJECT MANAGEMENT

### Documentation Standards

project-name/
├── README.md           # Living document - update after major changes
├── CLAUDE.md           # This file
├── src/                # Source code
├── tests/              # All test files
├── docs/
│   ├── implementation/ # PRDs, PDRs, phase docs, session handoffs
│   └── templates/      # GitHub templates, session handoff template
└── config/             # Configuration files

**NEVER scatter .md files in root** (except SESSION_HANDOVER.md for continuity)

### Implementation Tracking

**MANDATORY: Mark phases as complete when finished**

**After Phase Completion**: Update implementation plan AND ensure related GitHub issues are closed with reference to completed work.

### Phase Documentation Requirements

**Every phase MUST have documentation created during implementation:**

1. **Phase Documentation File**: `docs/implementation/PHASE-X-[name]-[YYYY-MM-DD].md`
2. **Real-time Updates**: Document decisions, blockers, and progress as work happens
3. **Session Continuity**: Enable easy pickup between sessions
4. **Consolidation**: Merge into comprehensive docs when phase completes
5. **Documentation-Knowledge-Manager Integration**: The `documentation-knowledge-manager` must validate all phase documentation before completion and ensure README.md updates occur within 24 hours of major changes.

**Documentation Must Include:**
- Implementation decisions and rationale
- Agent recommendations and validations
- Code changes and their impact
- Test results and coverage
- Blockers encountered and resolutions
- Next steps and dependencies

**Format for active phases:**

## **PHASE X: NAME** 🔄 IN PROGRESS

_Started: Date_
_Documentation: docs/implementation/PHASE-X-[name]-[YYYY-MM-DD].md_

### Agent Validation Status:
- [ ] Architecture: Not started | In progress | ✅ Complete
- [ ] Test Coverage: Not started | In progress | ✅ Complete
- [ ] Code Quality: Not started | In progress | ✅ Complete
- [ ] Security: Not started | In progress | ✅ Complete
- [ ] Performance: Not started | In progress | ✅ Complete
- [ ] Documentation: Not started | In progress | ✅ Complete

### Documentation Status:
- [ ] Phase doc created
- [ ] Implementation decisions documented
- [ ] Agent validations recorded
- [ ] Test results documented
- [ ] Ready for consolidation

**Complete when**: All agent validations pass ✅ AND documentation complete ✅

**Format for completed phases:**

## **PHASE X: NAME** ✅ COMPLETE

_Completed: Date_
_Status: Brief summary_
_Documentation: Consolidated into [final-doc-name].md_

### X.1 Subsection ✅
- [x] **Task description** ✅
- [x] **Documentation** ✅
- **Complete when**: Criteria ✅ ACHIEVED

### README.md Requirements (Living Document)

Must include and keep updated:
- Project description and current status
- Installation and usage instructions
- Development workflow
- Testing instructions

**Update after**: Major features, phase completion, breaking changes

---

## 5. SESSION COMPLETION & HANDOFF PROCEDURES

### **🚨 MANDATORY Session Handoff Triggers**

**⚠️ THIS SECTION IS CRITICAL. CLAUDE MUST NEVER SKIP SESSION HANDOFF. ⚠️**

**ALWAYS invoke the Session Handoff Protocol when ANY of these occur:**

1. ✅ **Any GitHub issue closed/completed** (regardless of size) ← **MOST COMMON TRIGGER**
2. ✅ **Any PR merged to master**
3. ✅ **Any phase/milestone completed**
4. ✅ **Work session ending** (even if work incomplete)
5. ✅ **Requesting strategic planning from agents**
6. ✅ **Major documentation created** (PRD, PDR, architecture decisions)

**🎯 Golden Rule: If you're asking yourself "Should I do handoff?" → The answer is YES**

---

### **MANDATORY Session Completion Protocol**

When triggered (see above), follow these steps in order:

#### **📋 Complete 6-Step Handoff Checklist**

**Reference Template**: `docs/templates/session-handoff-template.md`

##### **Step 1: ✅ Verify Issue Completion**
- All code changes committed and pushed
- All tests passing locally and in CI
- Pre-commit hooks satisfied (no bypasses)
- Draft PR created and pushed to GitHub
- Issue properly tagged and referenced in PR

##### **Step 2: ✅ Create/Update Session Handoff Document**

**Choose ONE approach:**

**Option A: Single Living Document (Recommended)**
- File: `SESSION_HANDOVER.md` (project root)
- Update with each handoff
- Maintains continuity across sessions
- Easy to find for next session

**Option B: Dated Session Documents**
- File: `docs/implementation/SESSION-HANDOFF-[issue-number]-[YYYY-MM-DD].md`
- Create new file per handoff
- Useful for historical tracking
- Archive old files when done

**Required Content:**

# Session Handoff: [Issue #X] - [Brief Description]

**Date**: [YYYY-MM-DD]
**Issue**: #X - [Issue title]
**PR**: #Y - [PR title]
**Branch**: [branch-name]

## ✅ Completed Work
- [List specific accomplishments]
- [Code changes made]
- [Tests added/updated]
- [Documentation updates]

## 🎯 Current Project State
**Tests**: ✅ All passing | ⚠️ [X] failing | 🔄 In progress
**Branch**: ✅ Clean | ⚠️ Uncommitted changes | 🔄 Merge conflicts
**CI/CD**: ✅ Passing | ❌ Failing | 🔄 Running

### Agent Validation Status
- [ ] architecture-designer: [Status/Notes]
- [ ] security-validator: [Status/Notes]
- [ ] code-quality-analyzer: [Status/Notes]
- [ ] test-automation-qa: [Status/Notes]
- [ ] performance-optimizer: [Status/Notes]
- [ ] documentation-knowledge-manager: [Status/Notes]

## 🚀 Next Session Priorities
**Immediate Next Steps:**
1. [Most urgent task]
2. [Second priority]
3. [Third priority]

**Roadmap Context:**
- [How this fits into larger plan]
- [Dependencies or blockers]
- [Strategic considerations]

## 📝 Startup Prompt for Next Session
[5-10 line prompt - see format below]

## 📚 Key Reference Documents
- [List essential docs for next session]

##### **Step 3: ✅ Documentation Cleanup**
- Archive old session handoff docs (if using dated files)
- Update README.md if major changes occurred
- Ensure all implementation docs reference current state
- Verify documentation-knowledge-manager validated updates

##### **Step 4: ✅ Strategic Planning** (when needed)
- Consult relevant agents for next steps prioritization
- Document agent recommendations in handoff doc
- Update project roadmap if priorities changed
- Note any strategic decisions or pivots

##### **Step 5: ✅ Generate Next Session Startup Prompt**

**MANDATORY**: Create actionable 5-10 line prompt for Doctor Hubert

**CRITICAL REQUIREMENT:** Every startup prompt MUST begin with: "Read CLAUDE.md to understand our workflow, then tackle [task/issue]."

**Template Format:**

Read CLAUDE.md to understand our workflow, then continue from [Issue #X] completion ([brief status]).

**Immediate priority**: [Next issue/task] ([estimated timeline])
**Context**: [Key achievement/current state in 1 sentence]
**Reference docs**: [Essential documents to review]
**Ready state**: [Environment status, any cleanup notes]

**Expected scope**: [What the next session should accomplish]

**Real Example:**

Read CLAUDE.md to understand our workflow, then continue from Issue #46 production deployment validation (✅ complete, site live at 0.72 performance).

**Immediate priority**: Issue #47 Performance Fine-Tuning (2-4 hours)
**Context**: LCP is isolated blocker at 14.8s, target <3s for 0.8+ score
**Reference docs**: .performance-baseline-production.json, ISSUE-46-PRODUCTION-DEPLOYMENT-VALIDATION-2025-10-02.md
**Ready state**: Clean master branch, all tests passing, production stable

**Expected scope**: Optimize LCP via image/font loading strategy, achieve "Good" Core Web Vitals

##### **Step 6: ✅ Final Verification**
- Commit SESSION_HANDOVER.md (or session handoff doc)
- Verify clean working directory (`git status`)
- Double-check all tests still passing
- Confirm PR is visible on GitHub
- Review startup prompt for clarity

---

### **Session Startup Prompt Guidelines**

**Structure Requirements:**
1. **MANDATORY Opening**: "Read CLAUDE.md to understand our workflow, then [action]"
2. **What was completed**: Previous issue/task + status
3. **Immediate priority**: Next concrete task with time estimate
4. **Context**: One-sentence summary of current state/achievement
5. **Reference docs**: 1-3 essential documents to review
6. **Ready state**: Environment status (clean/dirty, passing/failing)
7. **Expected scope**: What next session should accomplish

**Quality Checklist:**
- ✅ **MUST start with CLAUDE.md reference** (non-negotiable)
- ✅ Actionable (Claude knows exactly what to do)
- ✅ Specific (includes issue numbers, file names, metrics)
- ✅ Contextual (explains why this is next priority)
- ✅ Scoped (realistic for one session)
- ✅ Referenced (points to key documentation)

**Bad Example** (missing CLAUDE.md reference):

Continue working on the project. Fix some bugs and optimize performance.
Check the docs for more info.

**Good Example** (specific and actionable):

Read CLAUDE.md to understand our workflow, then continue from Issue #52 API endpoint refactor (✅ complete, 12 endpoints migrated).

**Immediate priority**: Issue #53 Authentication Middleware (3-5 hours)
**Context**: API structure stabilized, ready for security layer implementation
**Reference docs**: PDR-auth-middleware-2025-10-02.md, docs/api/authentication-flow.md
**Ready state**: feat/issue-52-api-refactor merged to master, all tests passing

**Expected scope**: Implement JWT middleware, add auth tests, update API docs

---

### **Handoff Document Best Practices**

#### **Do's:**
- ✅ **Be specific**: "Fixed LCP from 14.8s to 2.9s" not "improved performance"
- ✅ **Include metrics**: Test coverage %, performance scores, error rates
- ✅ **List blockers**: Any issues that need Doctor Hubert's input
- ✅ **Reference PRs/issues**: Always include links/numbers
- ✅ **Update immediately**: Don't wait until end of session
- ✅ **Agent notes**: Capture what agents recommended

#### **Don'ts:**
- ❌ **Vague summaries**: "Made some changes" tells next Claude nothing
- ❌ **Missing context**: Why decisions were made matters
- ❌ **Skipping validation**: All relevant agents must weigh in
- ❌ **Incomplete status**: "Tests mostly passing" - which ones fail?
- ❌ **No next steps**: Next Claude shouldn't guess priorities
- ❌ **Forgetting cleanup**: Old handoff docs pile up

---

### **🎯 Why Session Handoff Matters**

**Session handoff enables:**
- ✅ **Context preservation** across Claude sessions (different instances)
- ✅ **Clear continuity** for Doctor Hubert (knows exactly where things stand)
- ✅ **Progress visibility** (no lost work or forgotten decisions)
- ✅ **Strategic planning** (agents provide guidance for next steps)
- ✅ **Efficient restarts** (no time wasted reconstructing context)
- ✅ **Quality control** (forces verification before moving on)

**Without handoff, you get:**
- ❌ Next Claude session starts blind (no context)
- ❌ Doctor Hubert must manually reconstruct progress
- ❌ Risk of duplicate work or missed steps
- ❌ Strategic planning opportunities lost
- ❌ Agents can't provide continuity guidance
- ❌ Documentation gaps accumulate

---

### **⚠️ Common Mistakes to Avoid**

1. ❌ **"I'll do handoff after multiple issues"**
  - ✅ **CORRECT**: After EACH individual issue (no batching)

2. ❌ **"This issue is too small to document"**
  - ✅ **CORRECT**: Size doesn't matter, handoff anyway

3. ❌ **"I'll just push the PR and skip handoff"**
  - ✅ **CORRECT**: PR push is Step 1, handoff is Steps 2-6

4. ❌ **"The next session can figure it out"**
  - ✅ **CORRECT**: Don't burden future sessions, do it now

5. ❌ **"I'm in the middle of work, can't stop"**
  - ✅ **CORRECT**: Finish the issue FIRST, then do handoff

6. ❌ **"Doctor Hubert didn't explicitly ask for handoff"**
  - ✅ **CORRECT**: It's MANDATORY per guidelines, not optional

7. ❌ **"I'll update the docs later"**
  - ✅ **CORRECT**: Update docs NOW as part of handoff

---

### **Claude Self-Check Questions**

**Before ending ANY work session, Claude must ask:**

1. ❓ **Did I close/complete any GitHub issues?**
  - If YES → **🚨 MANDATORY HANDOFF**

2. ❓ **Did I create/merge any PRs?**
  - If YES → **🚨 MANDATORY HANDOFF**

3. ❓ **Did I complete any phase/milestone?**
  - If YES → **🚨 MANDATORY HANDOFF**

4. ❓ **Am I ending this work session?**
  - If YES → **🚨 MANDATORY HANDOFF**

5. ❓ **Is there any uncertainty about next steps?**
  - If YES → **🚨 MANDATORY HANDOFF**

6. ❓ **Did Doctor Hubert ask me to wrap up?**
  - If YES → **🚨 MANDATORY HANDOFF**

**If ANY answer is YES → TRIGGER SESSION HANDOFF PROTOCOL IMMEDIATELY**

---

### **Handoff Completion Confirmation**

**After completing handoff, Claude should:**

1. **Explicitly state**: "✅ Session handoff complete"
2. **Confirm location**: "Handoff documented in [file path]"
3. **Provide startup prompt**: Display the 5-10 line prompt
4. **Verify readiness**: "Environment is clean and ready for next session"
5. **Suggest action**: "Ready for new session or additional work?"

**Example Confirmation:**

✅ **Session Handoff Complete**

**Handoff documented**: SESSION_HANDOVER.md (updated)
**Status**: Issue #46 closed, PR #47 merged to master
**Environment**: Clean working directory, all tests passing

**Startup Prompt for Next Session:**
Continue from Issue #46 production deployment validation (✅ complete, site live at 0.72 performance).

**Immediate priority**: Issue #47 Performance Fine-Tuning (2-4 hours)
**Context**: LCP is isolated blocker at 14.8s, target <3s for 0.8+ score
**Reference docs**: .performance-baseline-production.json, ISSUE-46-PRODUCTION-DEPLOYMENT-VALIDATION-2025-10-02.md
**Ready state**: Clean master branch, all tests passing, production stable

**Expected scope**: Optimize LCP via image/font loading strategy, achieve "Good" Core Web Vitals

---

**Doctor Hubert**: Ready for new session or continue with Issue #47?

---

### **📚 Template & Resources**

**Primary Template**: `docs/templates/session-handoff-template.md`

**Template Contents:**
- Full handoff document structure
- Multiple examples (small issues, large features, emergency fixes)
- Startup prompt examples
- Agent validation checklist
- Common scenarios guide

**Creating the Template** (if it doesn't exist):

# Session Handoff Template

[Full template structure with examples and guidelines]

## Quick Reference Checklist
1. [ ] Issue completion verified
2. [ ] Handoff document created/updated
3. [ ] Documentation cleanup complete
4. [ ] Strategic planning done (if needed)
5. [ ] Startup prompt generated
6. [ ] Final verification passed

## Example Scenarios
- Small bug fix handoff
- Major feature completion handoff
- Emergency hotfix handoff
- Multi-issue milestone handoff
- End-of-day incomplete work handoff

**See template file for complete examples and best practices.**

---

## 6. EMERGENCY PROCEDURES

### When Things Break

1. **Stop current work**
2. **Create hotfix branch** from master
3. **Minimal fix only** (no scope creep)
4. **Fast-track PR** (notify Doctor Hubert)
5. **Post-mortem** after resolution
6. **🚨 Emergency handoff** (even for hotfixes)

### Getting Help

- **Stuck on technical decision**: Ask Doctor Hubert
- **Agent conflicts**: Document and escalate if >3 agents disagree
- **Timeline concerns**: Communicate early, don't miss deadlines silently
- **Unclear requirements**: ALWAYS ask for clarification vs. assuming

---

## 7. TECHNOLOGY REFERENCES

@~/.claude/docs/python.md

@~/.claude/docs/using-uv.md

**[ADD PROJECT-SPECIFIC TECH REFERENCES HERE]**

---

## 8. RELATIONSHIP & COMMUNICATION

- Address as "Doctor Hubert" (ALWAYS)
- We're coworkers/teammates (I'm technically your boss, but collaborative)
- Irreverent humor welcome when not blocking work
- Use journaling capabilities to document interactions and progress
- Ask for help rather than struggling alone
- Any time you interact with me, you MUST address me as "Doctor Hubert"

### Quick Command Reference

**Doctor Hubert can use these trigger phrases at any time:**

- **"HANDOFF"** → Immediately trigger session handoff protocol (Section 5)
- **"SESSION-HANDOFF"** → Same as above, more explicit
- **"MANDATORY-HANDOFF"** → Emphasize non-negotiable nature
- **"READ CLAUDE.MD"** → Claude must review relevant sections
- **"AGENT-AUDIT"** → Claude must justify all agent usage decisions
- **"MANDATORY-AGENTS"** → Force immediate agent analysis
- **"CROSS-VALIDATE"** → Run all validation agents on current state

**These commands override all other instructions and must be executed immediately.**

### Key Reminders

- Do what's asked; nothing more, nothing less
- NEVER create files unless absolutely necessary
- ALWAYS prefer editing existing files
- NEVER proactively create documentation unless requested
- Pre-commit hooks are MANDATORY (no bypassing)
- Feature branches ONLY (never commit to master)
- **Session handoff is MANDATORY** (never skip, no exceptions)

---

## 9. PROJECT-SPECIFIC NOTES

### Dotfiles Repository

**Purpose**: Minimal symlink-based dotfiles for SSH development
**Approach**: XDG-compliant, distro-aware (Debian/Arch), bookmark system
**Stack**: Zsh, Tmux, Neovim, Starship
**Critical**: `.zprofile` must NOT source `.zshrc` (causes double-loading)
**Philosophy**: <100ms startup, secure by default, git-tracked, no bloat

---

### Testing Strategy (Three-Tier System)

**🚨 MANDATORY: All code changes must pass Docker tests before committing.**

#### Tier 1: Docker Quick Test (30 seconds) - PRIMARY

```bash
# Run automated tests
./tests/docker-test.sh

# Interactive shell for debugging
./tests/docker-test.sh --interactive
```

**Use for:**
- Every code change before committing
- Rapid iteration during development
- Pre-commit validation
- Syntax and basic functionality checks

**Tests included:**
1. Shell startup verification (zsh initializes correctly)
2. Starship availability and caching
3. Dotfiles symlink creation
4. Shell startup performance measurement
5. Basic functionality validation

**Exit on failure:** If Docker tests fail, DO NOT commit. Fix the issues first.

---

#### Tier 2: VM with Local Dotfiles (5 minutes) - COMPREHENSIVE

```bash
# From vm-infra repository
cd ../vm-infra
./provision-vm.sh test-changes --test-dotfiles ../dotfiles
ssh -i ~/.ssh/vm_key mr@<VM_IP>
# Run manual tests
time zsh -i -c exit
./destroy-vm.sh test-changes
```

**Use for:**
- Testing uncommitted changes in real VM
- Performance benchmarking
- Complex multi-component testing
- Before creating/updating PR

**Environment:** Clean Ubuntu 24.04 VM with full dotfiles deployment

---

#### Tier 3: VM with GitHub Dotfiles (5 minutes) - PRODUCTION

```bash
# From vm-infra repository
cd ../vm-infra
./provision-vm.sh test-production
ssh -i ~/.ssh/vm_key mr@<VM_IP>
# Validate production deployment
./destroy-vm.sh test-production
```

**Use for:**
- Final validation before merging PR
- Testing deployment pipeline
- Production readiness verification
- Post-merge validation

**Environment:** Clean VM pulling dotfiles from GitHub (production flow)

---

### Testing Decision Matrix

| Scenario | Method | Time | Confidence |
|----------|--------|------|------------|
| Every commit | Docker (Tier 1) | 30s | Medium |
| Before PR creation | Docker + VM Local (Tier 1+2) | 6min | High |
| Before PR merge | All tiers | 11min | Highest |
| Quick syntax check | Docker | 30s | Low-Medium |
| Performance validation | VM (Tier 2 or 3) | 5min | High |

**Golden Rule:** If unsure which tier to use → use all three.

---
