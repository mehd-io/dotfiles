# Create a 1Password item named "herdr-continuity" with these fields.
export HERDR_CONTINUITY_DATABASE_URL="{{ op://Private/herdr-continuity/database-url }}"
export HERDR_CONTINUITY_KEY="{{ op://Private/herdr-continuity/encryption-key }}"
# Enable hourly background sync and exact-session Claude Stop-hook sync.
export HERDR_CONTINUITY_AUTO_SYNC=1
# Scheduled fallback sync runs only during local working hours. Explicit
# push/sync commands and handoffs are never restricted by this window.
export HERDR_CONTINUITY_SYNC_START_HOUR=7
export HERDR_CONTINUITY_SYNC_END_HOUR=23
