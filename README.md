# policy-checks

Policy-as-code validation for the iAiFy enterprise.

## Structure

```
policies/
  repo/           # Repository configuration policies
  workflow/        # Workflow and CI/CD policies  
  docker/          # Docker/container policies
  terraform/       # Terraform/IaC policies
scripts/
  check-repo.sh   # Validate a repo against policies
  check-all.sh    # Validate all repos
```

## Usage

### Check a single repo
```bash
./scripts/check-repo.sh AiFeatures/openclaw
```

### Check all repos
```bash
./scripts/check-all.sh
```

## Policy Categories

| Category | What it checks |
|---|---|
| `repo/` | Branch protection, required files, environment config |
| `workflow/` | SHA pinning, permissions, shared workflow usage |
| `docker/` | Dockerfile best practices, image signing |
| `terraform/` | State backend, provider pinning, required tags |

## Adding a Policy

1. Create a `.rego` file in the appropriate `policies/` subdirectory
2. Add test cases in `policies/*_test.rego`  
3. Run `opa test policies/`
4. Submit PR for review
