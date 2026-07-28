# Create a 1Password item named "herdr-continuity" with these fields.
export HERDR_CONTINUITY_DATABASE_URL="{{ op://Private/herdr-continuity/database-url }}"
export HERDR_CONTINUITY_KEY="{{ op://Private/herdr-continuity/encryption-key }}"
# Keep this at 0 until the Neon organization is upgraded beyond its 512 MB
# branch limit, then change to 1 to enable launchd and Claude Stop-hook sync.
export HERDR_CONTINUITY_AUTO_SYNC=0
