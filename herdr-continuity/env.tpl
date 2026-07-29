# Create a 1Password item named "herdr-continuity" with these fields.
export HERDR_CONTINUITY_DATABASE_URL="{{ op://Private/herdr-continuity/database-url }}"
export HERDR_CONTINUITY_KEY="{{ op://Private/herdr-continuity/encryption-key }}"
# Enable hourly background sync and exact-session Claude Stop-hook sync.
export HERDR_CONTINUITY_AUTO_SYNC=1
