# Push notifications

Real APNs requires an Apple Developer membership, an explicit App ID with Push Notifications, matching provisioning, and a physical iPhone for reliable testing. Create an APNs `.p8` key and set `APNS_ENABLED=true`, `APNS_TEAM_ID`, `APNS_KEY_ID`, `APNS_BUNDLE_ID`, `APNS_PRIVATE_KEY_PATH`, and the correct development/production environment. Never commit the key.

The full iOS push implementation is retained behind the `PUSH_NOTIFICATIONS` Swift compilation condition, but it is excluded from default builds for compatibility with free Apple developer accounts. The default target has no APNs entitlement or background notification mode. To restore it with a paid account, define `PUSH_NOTIFICATIONS`, set `CODE_SIGN_ENTITLEMENTS` to `Nas Hub/Nas Hub.entitlements`, add `remote-notification` to `UIBackgroundModes`, and enable Push Notifications for the App ID. Ensure the bundle ID exactly matches `APNS_BUNDLE_ID`.
