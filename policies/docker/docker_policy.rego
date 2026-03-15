# Docker Policy
# Validates Dockerfiles against security and efficiency standards

package policy.docker

import rego.v1

# Must run as non-root user
deny contains msg if {
    not has_user_instruction
    msg := "Dockerfile must have USER instruction (non-root)"
}

has_user_instruction if {
    some instruction in input.instructions
    instruction.cmd == "USER"
    instruction.value != "root"
    instruction.value != "0"
}

# Must have HEALTHCHECK
warn contains msg if {
    not has_healthcheck
    msg := "Dockerfile should have HEALTHCHECK instruction"
}

has_healthcheck if {
    some instruction in input.instructions
    instruction.cmd == "HEALTHCHECK"
}

# Should use multi-stage build
warn contains msg if {
    count(input.stages) < 2
    msg := "Consider using multi-stage build to reduce image size"
}

# Should not use ADD for remote URLs
deny contains msg if {
    some instruction in input.instructions
    instruction.cmd == "ADD"
    startswith(instruction.value, "http")
    msg := "Use COPY instead of ADD for local files, or curl/wget for remote"
}

# Should not expose secrets in build args
deny contains msg if {
    some instruction in input.instructions
    instruction.cmd == "ARG"
    contains(lower(instruction.value), "password")
    msg := sprintf("Potential secret in ARG: %s", [instruction.value])
}

deny contains msg if {
    some instruction in input.instructions
    instruction.cmd == "ARG"
    contains(lower(instruction.value), "token")
    msg := sprintf("Potential secret in ARG: %s", [instruction.value])
}

deny contains msg if {
    some instruction in input.instructions
    instruction.cmd == "ARG"
    contains(lower(instruction.value), "secret")
    msg := sprintf("Potential secret in ARG: %s", [instruction.value])
}
