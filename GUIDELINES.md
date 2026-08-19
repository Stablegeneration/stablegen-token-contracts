# GUIDELINES

These guidelines define the expected practices for maintaining and contributing to the StableGen smart contract repository.

The objective is to preserve the security, traceability, consistency, and auditability of the codebase throughout its lifecycle. All contributors and maintainers are expected to follow these guidelines when proposing, reviewing, approving, or merging changes.

## 1. General Principles

Changes to the StableGold codebase should be:

- Necessary and clearly scoped.
- Easy to understand and review.
- Backward-compatible where reasonably possible.
- Supported by appropriate tests.
- Documented where behavior, configuration, interfaces, or operational assumptions change.
- Implemented with security as a primary consideration.
- Traceable through Git history, pull requests, and release documentation.

Avoid combining unrelated changes into the same pull request.

Security-sensitive or behavioral changes should be isolated from documentation-only, formatting, or maintenance changes whenever practical.

## 2. Branching and Pull Requests

Changes must not be committed directly to `main`.

All work should be performed on a dedicated branch created from the latest version of `main`.

Recommended branch naming conventions include:

- `feature/<description>`
- `fix/<description>`
- `security/<description>`
- `docs/<description>`
- `refactor/<description>`

Before opening a pull request, contributors should ensure that their branch is up to date with `main` and that all relevant tests pass.

Each pull request should:

- Have a clear and descriptive title.
- Explain the purpose of the change.
- Describe any functional or security impact.
- Reference related issues, audit findings, or external requirements where applicable.
- Avoid unrelated changes.
- Clearly identify any change to privileged roles, access controls, token economics, oracle behavior, reserve controls, compliance functionality, or external integrations.

## 3. Peer Review

All changes must be submitted through pull requests and undergo peer review before being merged.

The reviewer should approach the review with a level of diligence comparable to a focused audit of the code being changed.

Reviewers should consider, where applicable:

- Whether the implementation matches the stated intention.
- Whether existing functionality may be unintentionally affected.
- Access-control and privilege implications.
- State-transition and accounting implications.
- External-call and token-interaction risks.
- Oracle, pricing, reserve, and decimal-handling assumptions.
- Reentrancy and callback exposure.
- Pause, freeze, KYC, minting, burning, redemption, and cross-chain behavior.
- Boundary conditions and failure cases.
- Upgrade, deployment, and configuration implications.
- Test coverage.
- Documentation and NatSpec accuracy.
- Compliance with repository and project guidelines.

Reviewers should not approve a change solely because it compiles or passes automated tests.

Any material concern identified during review should be resolved or explicitly documented before approval.

The author of a pull request should not be the sole approver of their own change.

External contributions should be reviewed separately by multiple maintainers before being accepted.

Security-sensitive changes should receive additional scrutiny and, where appropriate, review from more than one maintainer or an external security specialist.

## 4. Commit Practices

Commits should be focused and logically grouped.

Commit messages should clearly describe the purpose of the change. Examples include:

```text
fix: enforce freeze policy on burn operations
security: validate proof-of-reserve feed configuration
docs: improve NatSpec documentation
refactor: separate contract interfaces
```

Where repository rules require signed commits, commits must use verified signatures.

Do not rewrite or amend historical commits that are referenced by:

- Security audit reports.
- Published releases.
- External integrations.
- Regulatory or compliance documentation.

Maintaining stable commit hashes is important for audit traceability.

## 5. Security Audit Traceability

Code that has been independently audited must remain identifiable by an immutable Git tag.

The OpenZeppelin-audited StableGold baseline is:

- **Release:** `v2.17.4`
- **Final remediation merge commit:** `bcd20cb`

Changes made after an audited release must not be represented as part of that audited version unless they were specifically reviewed by the auditor.

If changes are introduced after an audit, the repository must clearly distinguish between:

- The audited baseline.
- Subsequent documentation-only changes.
- Subsequent functional changes.

Material security or functional changes may require additional external review or a new audit.

## 6. Smart Contract Changes

Changes affecting contract behavior require particular care.

This includes changes to:

- Minting and burning.
- Transfers and allowances.
- Freeze and KYC controls.
- Redemption.
- On-chain buyback functionality.
- Supply limits.
- Proof-of-reserve enforcement.
- Oracle configuration or price calculations.
- Stablecoin handling.
- Privileged roles.
- Ownership.
- Pause functionality.
- Cross-chain functionality.
- EIP-3009 authorization flows.
- External contract interactions.

Such changes should include relevant tests and a clear explanation of their intended effect.

Where arithmetic is involved, contributors should explicitly consider:

- Decimal precision.
- Rounding.
- Multiplication/division ordering.
- Minimum and maximum values.
- Overflow or underflow assumptions.
- Token decimal differences.

## 7. Privileged Roles and Access Control

Changes involving privileged roles require explicit review of the resulting authority model.

The StableGold system includes privileged roles such as:

- `owner`
- `admin`
- `authority`
- `custody`
- `minter`
- `tokenBridge`

Contributors must not assume that a role is harmless because it is operational rather than owner-level.

Any change that expands, reduces, or alters the authority of a privileged role should be clearly documented in the pull request.

Production privileged roles should be assigned only to appropriately controlled addresses or contracts, such as approved multisig wallets where required by the operating model.

## 8. External Tokens and Integrations

External assets and contracts should be treated as trust boundaries.

Accepted settlement tokens must be explicitly reviewed before being enabled.

At minimum, maintainers should consider:

- Token decimals.
- Transfer behavior.
- Transfer fees.
- Rebasing or deflationary behavior.
- Callback or hook mechanisms.
- Upgradeability.
- Blacklisting or pausing functionality.
- Compatibility with the ERC-20 interaction mechanisms used by StableGold.

A previously approved token should be reconsidered if its implementation or behavior materially changes.

External bridges, oracle feeds, reserve feeds, and other integrations should similarly be reviewed before configuration changes are made.

## 9. Configuration and Deployment

Deployment and post-deployment configuration form part of the StableGold security model.

Changes to deployment procedures should therefore be reviewed with the same care as contract changes.

Before a production deployment is activated, maintainers should verify relevant configuration, including:

- Ownership and multisig configuration.
- Operational role assignments.
- Supply limits.
- Accepted settlement tokens.
- Price-feed address.
- Oracle heartbeat.
- Proof-of-reserve configuration.
- Reserve-feed address and heartbeat.
- Redemption limits.
- Premiums and fees.
- Buyback configuration.
- Feature toggles.
- Bridge configuration.
- Pause state.
- KYC and compliance controls.

The contract should not be unpaused for production use until the intended configuration has been independently checked.

## 10. Testing

Functional changes should include tests appropriate to the risk and complexity of the modification.

Tests should include, where relevant:

- Expected successful behavior.
- Expected failure behavior.
- Authorization and access-control failures.
- Boundary values.
- Paused-state behavior.
- Frozen-address behavior.
- Oracle staleness.
- Supply-cap enforcement.
- Decimal conversions.
- Cross-chain restrictions.
- Invalid configuration.

Regression tests should be added when fixing a bug or security issue where practical.

## 11. Documentation

Public and external contract interfaces should have clear NatSpec documentation.

Comments should explain intent, assumptions, and non-obvious behavior rather than simply restating the code.

Documentation must be updated whenever a change affects:

- Public behavior.
- Configuration.
- Trust assumptions.
- Operational procedures.
- External integrations.
- Security controls.

Documentation-only changes should generally be separated from functional changes so that reviewers can clearly identify whether contract behavior has changed.

## 12. Changelog and Releases

Material changes must be recorded in `CHANGELOG.md`.

Each release entry should summarize:

- Security fixes.
- Functional changes.
- Significant refactoring.
- Operational changes.
- Relevant audit or review milestones.

Release tags must be treated as immutable references.

Do not move or overwrite a published release tag unless there is an exceptional and documented reason.

Release notes should identify significant security or audit milestones where applicable.

## 13. Audit Reports

Independent security reports should be stored under:

```text
/audits
```

Audit reports should remain unchanged after publication.

Where possible, the repository should identify:

- Auditor.
- Audit date.
- Initial audited commit.
- Final reviewed/remediated commit.
- Corresponding release tag.

## 14. Security-Sensitive Changes After an Audit

An external audit does not permanently cover future versions of the codebase.

After an audited release, maintainers should assess each functional change to determine whether it:

- Is clearly outside the audited functionality.
- Modifies previously audited behavior.
- Introduces new trust assumptions.
- Changes privileged functionality.
- Introduces new external dependencies.
- Changes token economics or accounting.
- Changes oracle, reserve, compliance, or bridge behavior.

Changes with a material security impact should be considered for independent security review before production deployment.

## 15. Final Merge Responsibility

Approval of a pull request means more than accepting the implementation.

The maintainer approving and merging the pull request should be satisfied that:

- The change is understood.
- The scope is appropriate.
- Review comments are resolved.
- Relevant tests have passed.
- Documentation is updated where required.
- Security implications have been considered.
- The change is appropriate for inclusion in the target release.

When uncertainty remains regarding the security impact of a change, the preferred action is to seek additional review before merging.