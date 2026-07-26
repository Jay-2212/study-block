#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_BINARY="$PROJECT_ROOT/.build/domain-normalizer-smoke"
POLICY_BINARY="$PROJECT_ROOT/.build/enforcement-policy-smoke"
ESCALATION_BINARY="$PROJECT_ROOT/.build/escalation-smoke"

mkdir -p "$PROJECT_ROOT/.build"
xcrun swiftc \
  "$PROJECT_ROOT/StudyBlock/Services/DomainNormalizer.swift" \
  "$PROJECT_ROOT/script/domain_normalizer_smoke.swift" \
  -o "$TEST_BINARY"
"$TEST_BINARY"

xcrun swiftc \
  "$PROJECT_ROOT/StudyBlock/Services/DomainNormalizer.swift" \
  "$PROJECT_ROOT/StudyBlock/Models/WebEnforcementPolicy.swift" \
  "$PROJECT_ROOT/script/enforcement_policy_smoke.swift" \
  -o "$POLICY_BINARY"
"$POLICY_BINARY"

xcrun swiftc \
  "$PROJECT_ROOT/StudyBlock/Models/AppChoice.swift" \
  "$PROJECT_ROOT/StudyBlock/Models/AppEscalationState.swift" \
  "$PROJECT_ROOT/script/escalation_smoke.swift" \
  -o "$ESCALATION_BINARY"
"$ESCALATION_BINARY"
