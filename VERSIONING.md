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

### 1. Make Your Changes

Make your changes to the module(s) and commit them to the `main` branch:

```bash
git add .
git commit -m "feat: add support for VPC connector in Cloud Run module"
git push origin main
```

### 2. Determine the Version Number

Based on your changes:

- **Breaking change?** → Increment MAJOR version
- **New feature?** → Increment MINOR version
- **Bug fix?** → Increment PATCH version

### 3. Create and Push a Git Tag

```bash
# Create an annotated tag
git tag -a v1.1.0 -m "Release v1.1.0: Add VPC connector support"

# Push the tag to GitHub
git push origin v1.1.0
```

### 4. Create a GitHub Release (Optional but Recommended)

1. Go to `https://github.com/veridianlab/project-fox-infra/releases/new`
2. Select the tag you just created
3. Add release notes describing the changes
4. Publish the release

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

Here's a complete workflow for releasing a new version:

```bash
# 1. Make changes and commit
git checkout main
git pull origin main
# ... make your changes ...
git add .
git commit -m "feat(cloudrun): add VPC connector support"

# 2. Push changes
git push origin main

# 3. Create and push tag
git tag -a v1.1.0 -m "Release v1.1.0: Add VPC connector support to Cloud Run module"
git push origin v1.1.0

# 4. Create GitHub release (via web UI or gh CLI)
gh release create v1.1.0 --title "v1.1.0" --notes "Added VPC connector support"
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
