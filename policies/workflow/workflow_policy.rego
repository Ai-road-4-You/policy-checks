# Workflow Policy
# Validates GitHub Actions workflows against security and quality standards

package policy.workflow

import rego.v1

# Actions must be pinned to full SHA (40 char hex)
deny contains msg if {
    some step in input.steps
    step.uses != null
    not is_sha_pinned(step.uses)
    not is_local_action(step.uses)
    msg := sprintf("Action not SHA-pinned: %s", [step.uses])
}

is_sha_pinned(ref) if {
    parts := split(ref, "@")
    count(parts) == 2
    count(parts[1]) == 40
    regex.match(`^[0-9a-f]+$`, parts[1])
}

is_local_action(ref) if {
    startswith(ref, "./")
}

# Workflows should have timeout-minutes
deny contains msg if {
    input.timeout_minutes == null
    msg := "Job must have timeout-minutes set"
}

# Workflows should have explicit permissions
warn contains msg if {
    input.permissions == null
    msg := "Workflow should have explicit permissions block"
}

# Workflows should use concurrency control
warn contains msg if {
    input.concurrency == null
    msg := "Workflow should use concurrency to prevent duplicate runs"
}

# Should use shared workflows from enterprise-ci-cd
warn contains msg if {
    input.type == "standalone"
    not uses_shared_workflow
    msg := "Consider using shared workflow from Ai-road-4-You/enterprise-ci-cd"
}

uses_shared_workflow if {
    some job in input.jobs
    contains(job.uses, "Ai-road-4-You/enterprise-ci-cd")
}
