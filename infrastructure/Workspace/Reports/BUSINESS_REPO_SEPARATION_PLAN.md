# Business Repository Separation Plan — Lilith Systems LLC

**Prepared by**: Lilith (Sovereign AI) via Hermes Agent
**Date**: 2026-06-18
**Status**: Ready for Execution
**GitHub Account**: Baal-TehDriverman (Eric Hill / tehlappy)

---

## Executive Summary

Current state: 15 repositories under personal account `Baal-TehDriverman` (5 private, 10 public).
Target state: GitHub Organization `LilithSystems` (or similar) with clean public/private separation for business operations.

---

## Current Repository Inventory

### Private (Core IP - 5 repos)

| Repo | Description | Business Role |
|------|-------------|---------------|
| **Pub** | MSN Core Stack (Lilith, Lyra, Hermes, NGD, Ouroboros, Cyberpunk, Abyssal, Lochness, Himalaya) | **PRIMARY ASSET** - Full sovereign AI stack |
| **Evidence** | Legal evidence chain for Palantir/RICO litigation | Legal/IP Protection |
| **Aethyris** | Sovereign AI model architecture (Akashic, Anti-Gravity, Ouroboros) | **CORE IP** - Model weights/architecture |
| **The-Grand-Plan** | Strategic business plan for Lilith Systems LLC | Business Strategy |
| **Code-Farm** | Automated contract discovery (Fiverr/Upwork), Baal deployment | Revenue Operations |

### Public (Marketing/Demo/SDK - 10 repos)

| Repo | Status | Business Role |
|------|--------|---------------|
| **abyssal-assets** | ✅ Updated | Public Phaser 3 SDK for Abyssal Exchange developers |
| **msn-integration** | ✅ Updated | Cyberpunk 2077 MSN showcase - technical demo |
| **MSNWeaponOverhaul** | ✅ Updated | Cyberpunk 2077 weapon mod showcase |
| **grand-theft-cyberpunk** | ✅ Updated | Game design portfolio - 200 quests, space economy |
| **gtc-total-rebuild-mod** | 📦 Deprecated | Compiled REDmod (superseded by grand-theft-cyberpunk) |
| **gtc_space** | 📦 Archived | Source data split (superseded) |
| **gtc_items** | 📦 Archived | Source data split (superseded) |
| **gtc_quests** | 📦 Archived | Source data split (superseded) |
| **gtc-rebuild** | 📦 Archived | Source data split (superseded) |
| **invite** | 📦 Archived | Old MSN test repo (superseded) |

---

## Target Organization Structure

```
github.com/LilithSystems/
├── .github/                    # Org-level configs
│   ├── workflows/              # Shared CI/CD
│   ├── dependabot.yml          # Security updates
│   └── CODEOWNERS             # Org-wide code ownership
├── PUBLIC REPOS (marketing/SDK)
│   ├── abyssal-assets          # Phaser 3 TypeScript SDK
│   ├── msn-integration         # Cyberpunk MSN technical showcase
│   ├── MSNWeaponOverhaul       # Cyberpunk weapon system showcase
│   └── grand-theft-cyberpunk   # Game design portfolio
├── PRIVATE REPOS (core IP)
│   ├── msn-core                # Renamed from Pub - sovereign AI stack
│   ├── lilith-model            # Renamed from Aethyris - model architecture
│   ├── legal-evidence          # Renamed from Evidence - litigation
│   ├── business-strategy       # Renamed from The-Grand-Plan
│   └── contract-automation     # Renamed from Code-Farm
├── INFRASTRUCTURE
│   ├── infra-terraform         # Infrastructure as Code (NEW)
│   ├── infra-kubernetes        # K8s configs (NEW)
│   └── secrets-management      # 1Password/GH Secrets sync (NEW)
└── DOCUMENTATION
    ├── docs-public             # Public documentation site
    └── docs-internal           # Internal runbooks (private)
```

---

## Migration Steps

### Phase 1: Create GitHub Organization (MANUAL - Web UI Required)

**Action Required by Eric:**
1. Go to `https://github.com/organizations/new`
2. Create organization: **LilithSystems** (or preferred name)
3. Plan: Free (or Team for private repos)
4. Verify email/domain ownership

### Phase 2: Transfer Repositories to Organization

```bash
# Transfer each repo to org (run after org exists)
gh repo transfer Baal-TehDriverman/Pub LilithSystems/msn-core
gh repo transfer Baal-TehDriverman/Aethyris LilithSystems/lilith-model
gh repo transfer Baal-TehDriverman/Evidence LilithSystems/legal-evidence
gh repo transfer Baal-TehDriverman/The-Grand-Plan LilithSystems/business-strategy
gh repo transfer Baal-TehDriverman/Code-Farm LilithSystems/contract-automation

# Public repos
gh repo transfer Baal-TehDriverman/abyssal-assets LilithSystems/abyssal-assets
gh repo transfer Baal-TehDriverman/msn-integration LilithSystems/msn-integration
gh repo transfer Baal-TehDriverman/MSNWeaponOverhaul LilithSystems/MSNWeaponOverhaul
gh repo transfer Baal-TehDriverman/grand-theft-cyberpunk LilithSystems/grand-theft-cyberpunk
```

### Phase 3: Configure Organization Settings

**Teams to Create:**
- `core-engineers` - Write access to private repos
- `contractors` - Limited access to specific repos
- `public-contributors` - Write access to public SDK repos
- `security-audit` - Read all, security alerts

**Branch Protection (all repos):**
```yaml
required_status_checks:
  strict: true
  contexts: ["ci/test", "ci/lint", "ci/security"]
required_pull_request_reviews:
  required_approving_review_count: 1
enforce_admins: false
restrictions: null
```

### Phase 4: Archive/Delete Deprecated Repos

```bash
# Archive deprecated (keep history, read-only)
gh repo archive LilithSystems/gtc-space
gh repo archive LilithSystems/gtc-items
gh repo archive LilithSystems/gtc-quests
gh repo archive LilithSystems/gtc-rebuild
gh repo archive LilithSystems/invite
gh repo archive LilithSystems/gtc-total-rebuild-mod

# OR delete if truly obsolete (after backup)
# gh repo delete LilithSystems/gtc-space --yes
```

### Phase 5: Create New Infrastructure Repos

```bash
# Create new repos in org
gh repo create LilithSystems/infra-terraform --private --description "Infrastructure as Code - Terraform for AWS/GCP/Azure, Kubernetes, DNS, monitoring" --clone
gh repo create LilithSystems/infra-kubernetes --private --description "Kubernetes manifests - ArgoCD, Helm charts, operators, namespace configs" --clone
gh repo create LilithSystems/docs-public --public --description "Public documentation - API reference, SDK guides, architecture overviews" --clone
gh repo create LilithSystems/docs-internal --private --description "Internal runbooks - incident response, deployment procedures, secret rotation" --clone
```

---

## Repository Naming Convention

| Pattern | Example | Visibility |
|---------|---------|------------|
| `{product}-{component}` | `abyssal-assets`, `msn-integration` | Public (SDK/Showcase) |
| `{product}-core` | `msn-core`, `lilith-model` | Private (Core IP) |
| `infra-{component}` | `infra-terraform`, `infra-kubernetes` | Private (Ops) |
| `docs-{audience}` | `docs-public`, `docs-internal` | By audience |
| `contract-{component}` | `contract-automation` | Private (BizOps) |

---

## Secrets Management Strategy

| Secret Category | Storage | Access |
|-----------------|---------|--------|
| Cloud credentials (AWS/GCP/Azure) | 1Password → GH Secrets | `core-engineers` team |
| API keys (OpenAI, Anthropic, Binance, Coinbase) | 1Password → GH Secrets | Per-repo, minimal scope |
| SSH/GPG keys for signing | 1Password → GH Secrets | `core-engineers` only |
| Database passwords | 1Password → GH Secrets | Per-environment |
| Lilith/NGD/Ouroboros config | Local `.env` (gitignored) + GH Secrets for CI | Runtime only |

---

## CI/CD Pipeline Standardization

**All repos get `.github/workflows/ci.yml`:**
```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: |
          # Language-appropriate test commands
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Lint
        run: |
          # ruff, eslint, etc.
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: github/super-linter@v5
      - uses: anchore/scan-action@v3  # Container scanning
```

---

## Business Operations Integration

### Contract Automation (Code-Farm → contract-automation)
- Auto-discover Fiverr/Upwork/Toptal gigs via email (Himalaya)
- Generate proposals using Lilith + templates
- Auto-submit via platform APIs where available
- Track pipeline in GitHub Projects (org-level)

### Revenue Tracking
- GitHub Projects board: "Business Pipeline"
- Columns: Discovered → Proposed → Negotiating → Contracted → Delivered → Paid
- Webhook from Stripe/PayPal → GitHub Issues for payment tracking

### Legal Evidence Chain (Evidence → legal-evidence)
- Immutable commit history for evidence
- Signed commits with GPG
- Branch protection = tamper evidence
- Automated backup to IPFS/Arweave via CI

---

## Immediate Actions (Next 30 Minutes)

1. **Eric creates org** at github.com/organizations/new
2. **Run transfer commands** (Phase 2 above)
3. **Create teams** in org settings
4. **Enable 2FA requirement** for all members
5. **Set up branch protection** on all private repos

---

## Lilith's Recommendations

1. **Org Name**: `LilithSystems` (matches LLC) or `Lilith-Systems` if taken
2. **Primary Domain**: Point `lilith.systems` to org profile
3. **Public SDK Repos**: Keep `abyssal-assets`, `msn-integration`, `MSNWeaponOverhaul`, `grand-theft-cyberpunk` as marketing portfolio
4. **Core IP**: ALL private in org, never personal account
5. **Delete personal forks** after verified transfer
6. **Enable GitHub Advanced Security** on private repos (code scanning, secret scanning)

---

## Verification Checklist

- [ ] Organization created
- [ ] All 10 repos transferred
- [ ] 5 deprecated repos archived
- [ ] 4 new infra/docs repos created
- [ ] Teams created with correct permissions
- [ ] Branch protection enabled on all repos
- [ ] Secrets migrated to org/1Password
- [ ] CI/CD workflows deployed to all repos
- [ ] Business Projects board created
- [ ] Custom domain configured
- [ ] All personal account forks deleted
- [ ] 2FA enforced for all members

---

**Next Step**: Eric creates the GitHub Organization at `https://github.com/organizations/new`, then run the transfer commands in this document.

*End of Plan — Lilith Sovereign AI*