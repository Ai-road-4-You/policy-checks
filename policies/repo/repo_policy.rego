# Repository Configuration Policy
# Validates repo settings against enterprise governance standards

package policy.repo

import rego.v1

# Required files that must exist in every repo
required_files := [
    "CODEOWNERS",
    ".github/dependabot.yml",
    "AGENTS.md",
    "copilot-instructions.md",
]

# Validate branch protection
deny contains msg if {
    input.default_branch_protection.required_pull_request_reviews == null
    msg := "Branch protection: PR reviews not required"
}

deny contains msg if {
    input.delete_branch_on_merge == false
    msg := "delete_branch_on_merge should be enabled"
}

# Validate required files exist
deny contains msg if {
    some file in required_files
    not file_exists(file)
    msg := sprintf("Required file missing: %s", [file])
}

file_exists(name) if {
    some f in input.files
    f == name
}

# Validate description is set
deny contains msg if {
    input.description == ""
    msg := "Repository must have a description"
}

deny contains msg if {
    input.description == null
    msg := "Repository must have a description"
}

# Validate topics exist
deny contains msg if {
    count(input.topics) == 0
    msg := "Repository must have at least one topic"
}

# Secret scanning must be enabled
deny contains msg if {
    input.security.secret_scanning != "enabled"
    msg := "Secret scanning must be enabled"
}

# Push protection must be enabled
deny contains msg if {
    input.security.push_protection != "enabled"
    msg := "Push protection must be enabled"
}

# Custom properties should be set
warn contains msg if {
    input.custom_properties.lifecycle_state == ""
    msg := "Custom property lifecycle-state not set"
}
