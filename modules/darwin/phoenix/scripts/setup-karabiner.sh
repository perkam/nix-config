#!/usr/bin/env bash
# Setup Karabiner rules for Phoenix
# Required environment variables:
#   RULES_FILE - Path to the karabiner.json rules file
#   JQ - Path to jq binary

set -euo pipefail

KARABINER_CLI="/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"
KARABINER_CONFIG="$HOME/.config/karabiner/karabiner.json"

# Check if Karabiner CLI exists
if [ ! -x "$KARABINER_CLI" ]; then
  echo "Karabiner CLI not found. Please install Karabiner-Elements first."
  exit 0
fi

# Check if karabiner.json exists
if [ ! -f "$KARABINER_CONFIG" ]; then
  echo "Karabiner config not found. Please open Karabiner-Elements first to generate the initial config."
  exit 0
fi

# Add Tab -> Hyper rule if not present
if ! "$JQ" -e '.profiles[0].complex_modifications.rules[] | select(.description | contains("Tab to Hyper"))' "$KARABINER_CONFIG" > /dev/null 2>&1; then
  echo "Adding Tab -> Hyper rule to Karabiner configuration..."
  
  HYPER_RULE=$("$JQ" '.rules[0]' "$RULES_FILE")
  "$JQ" --argjson rule "$HYPER_RULE" \
    '.profiles[0].complex_modifications.rules += [$rule]' \
    "$KARABINER_CONFIG" > "$KARABINER_CONFIG.tmp" && \
    mv "$KARABINER_CONFIG.tmp" "$KARABINER_CONFIG"
  
  echo "Tab -> Hyper rule added successfully!"
else
  echo "Tab -> Hyper rule already exists in Karabiner configuration."
fi

# Add Caps Lock -> F18 rule if not present
if ! "$JQ" -e '.profiles[0].complex_modifications.rules[] | select(.description | contains("Caps Lock to F18"))' "$KARABINER_CONFIG" > /dev/null 2>&1; then
  echo "Adding Caps Lock -> F18 rule to Karabiner configuration..."
  
  F18_RULE=$("$JQ" '.rules[1]' "$RULES_FILE")
  "$JQ" --argjson rule "$F18_RULE" \
    '.profiles[0].complex_modifications.rules += [$rule]' \
    "$KARABINER_CONFIG" > "$KARABINER_CONFIG.tmp" && \
    mv "$KARABINER_CONFIG.tmp" "$KARABINER_CONFIG"
  
  echo "Caps Lock -> F18 rule added successfully!"
else
  echo "Caps Lock -> F18 rule already exists in Karabiner configuration."
fi
