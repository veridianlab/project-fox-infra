# Versioning and Release Guide

This document explains how to manage versions and create releases for the infrastructure modules in this repository.

## Semantic Versioning

We follow [Semantic Versioning 2.0.0](https://semver.org/). Version numbers are structured as `MAJOR.MINOR.PATCH`:

- **MAJOR** (v2.0.0) - Incompatible API changes or breaking changes
- **MINOR** (v1.1.0) - New features that are backward compatible
- **PATCH** (v1.0.1) - Backward compatible bug fixes

### Breaking Changes Examples

- Removing or renaming variables
- Changing variable types
- Removing outputs
- Changing resource names (causes resource recreation)
- Requiring new required variables

### Non-Breaking Changes Examples

- Adding new optional variables with defaults
- Adding new outputs
- Bug fixes that don't change behavior
- Documentation updates
- Internal refactoring

## Creating a New Release

Tagging and releases are **automated** via GitHub Actions (`.github/workflows/merge.yml` + `tag.yml`).

### 1. Make Your Changes

Make your changes to the module(s) and merge a PR to the `main` branch:

```bash
git add .
git commit -m "feat: add support for VPC connector in Cloud Run module"
# Push to a branch, open a PR, and merge
```

### 2. Automated Tagging & Release

When a commit lands on `main`, the CI pipeline automatically:

1. **Creates a semver tag** using `mathieudutour/github-tag-action` — the bump type is derived from the commit message:
   - `feat!:` or `BREAKING CHANGE` → MAJOR
   - `feat:` → MINOR
   - anything else → PATCH
2. **Creates a GitHub Release** with the new tag.

> **Tip:** Use [squash merges](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/about-pull-request-merges#squash-and-merge-your-commits) so the commit title controls the bump type.

### 3. Manual Tagging (Fallback)

If you need to create a tag manually:

```bash
# Create an annotated tag
git tag -a v1.1.0 -m "Release v1.1.0: Add VPC connector support"

# Push the tag to GitHub
git push origin v1.1.0
```

You can also trigger the tag workflow manually via the GitHub Actions UI using the **workflow_dispatch** event on `tag.yml`.

## Git Tag Commands

### Create a Tag

```bash
# Annotated tag (recommended)
git tag -a v1.0.0 -m "Initial release"

# Lightweight tag (not recommended for releases)
git tag v1.0.0
```

### List Tags

```bash
# List all tags
git tag

# List tags matching a pattern
git tag -l "v1.*"
```

### Push Tags

```bash
# Push a specific tag
git push origin v1.0.0

# Push all tags
git push origin --tags
```

### Delete Tags

```bash
# Delete local tag
git tag -d v1.0.0

# Delete remote tag
git push origin --delete v1.0.0
```

## Using Versioned Modules

### In Your Terraform Configuration

Reference modules using Git tags:

```hcl
module "cloud_run" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.0.0"

  # ... module inputs
}
```

### Version Reference Formats

```hcl
# Specific version (RECOMMENDED for production)
source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.0.0"

# Specific branch (useful for development)
source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=main"

# Specific commit (for pinning to exact state)
source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=abc1234"
```

### Upgrading Module Versions

```bash
# 1. Update the ref in your module source
# Before: source = "...?ref=v1.0.0"
# After:  source = "...?ref=v1.1.0"

# 2. Re-initialize Terraform to download the new version
terraform init -upgrade

# 3. Review the changes
terraform plan

# 4. Apply if everything looks good
terraform apply
```

## Version Management Best Practices

### ✅ DO

- Always use semantic versioning
- Create annotated tags with descriptive messages
- Document breaking changes in release notes
- Test modules before creating releases
- Use version tags in production environments
- Keep a CHANGELOG.md for each module (optional but recommended)

### ❌ DON'T

- Don't delete or modify existing tags (they're immutable)
- Don't use branch references in production
- Don't make breaking changes without incrementing MAJOR version
- Don't create tags without testing

## Changelog Example

Consider maintaining a `CHANGELOG.md` file for each module:

```markdown
# Changelog

## [1.1.0] - 2024-01-15

### Added

- VPC connector support for private networking
- Custom domain mapping variable

### Changed

- Default memory limit increased to 1Gi

## [1.0.1] - 2024-01-10

### Fixed

- Fixed IAM policy for public access

## [1.0.0] - 2024-01-01

### Added

- Initial release of Cloud Run module
```

## Pre-release Versions

For pre-release versions, use the following format:

```bash
# Alpha release
git tag -a v2.0.0-alpha.1 -m "Alpha release for v2.0.0"

# Beta release
git tag -a v2.0.0-beta.1 -m "Beta release for v2.0.0"

# Release candidate
git tag -a v2.0.0-rc.1 -m "Release candidate 1 for v2.0.0"
```

## Module-Specific Versioning

Each module can have its own versioning:

```bash
# Tag for a specific module update
git tag -a cloudrun-v1.2.0 -m "Cloud Run module v1.2.0"

# Then reference it
source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=cloudrun-v1.2.0"
```

However, **repository-level versioning is recommended** for simplicity when multiple modules may have dependencies.

## Workflow Example

Releases are created automatically when commits land on `main`. Here's the typical workflow:

```bash
# 1. Make changes on a feature branch
git checkout -b feat/cloudrun-vpc-connector
# ... make your changes ...
git add .
git commit -m "feat(cloudrun): add VPC connector support"

# 2. Push and open a PR
git push -u origin feat/cloudrun-vpc-connector
gh pr create --title "feat(cloudrun): add VPC connector support"

# 3. Merge the PR (use squash merge for clean conventional commit titles)
gh pr merge --squash

# 4. CI automatically tags and creates a GitHub Release
```

## Questions?

If you have questions about versioning:

1. Check [Semantic Versioning documentation](https://semver.org/)
2. Review existing releases and tags
3. Ask in team discussions

## References

- [Semantic Versioning 2.0.0](https://semver.org/)
- [Git Tagging Documentation](https://git-scm.com/book/en/v2/Git-Basics-Tagging)
- [Terraform Module Sources](https://www.terraform.io/language/modules/sources)
- [GitHub Releases Documentation](https://docs.github.com/en/repositories/releasing-projects-on-github)
