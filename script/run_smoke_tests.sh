#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_BINARY="$PROJECT_ROOT/.build/domain-normalizer-smoke"
POLICY_BINARY="$PROJECT_ROOT/.build/enforcement-policy-smoke"
ESCALATION_BINARY="$PROJECT_ROOT/.build/escalation-smoke"
SETTINGS_BINARY="$PROJECT_ROOT/.build/settings-store-smoke"
HISTORY_BINARY="$PROJECT_ROOT/.build/session-history-smoke"

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

xcrun swiftc \
  -parse-as-library \
  "$PROJECT_ROOT/StudyBlock/Models/AppChoice.swift" \
  "$PROJECT_ROOT/StudyBlock/Models/AppSettings.swift" \
  "$PROJECT_ROOT/StudyBlock/Services/DomainNormalizer.swift" \
  "$PROJECT_ROOT/StudyBlock/Models/WebEnforcementPolicy.swift" \
  "$PROJECT_ROOT/StudyBlock/Stores/SettingsStore.swift" \
  "$PROJECT_ROOT/script/settings_store_smoke.swift" \
  -o "$SETTINGS_BINARY"
"$SETTINGS_BINARY"

xcrun swiftc \
  -parse-as-library \
  "$PROJECT_ROOT/StudyBlock/Models/SessionPreset.swift" \
  "$PROJECT_ROOT/StudyBlock/Models/StudySessionRecord.swift" \
  "$PROJECT_ROOT/StudyBlock/Stores/SessionHistoryStore.swift" \
  "$PROJECT_ROOT/script/session_history_smoke.swift" \
  -o "$HISTORY_BINARY"
"$HISTORY_BINARY"
