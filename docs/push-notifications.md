# Push notifications

Real APNs requires an Apple Developer membership, an explicit App ID with Push Notifications, matching provisioning, and a physical iPhone for reliable testing. Create an APNs `.p8` key and set `APNS_ENABLED=true`, `APNS_TEAM_ID`, `APNS_KEY_ID`, `APNS_BUNDLE_ID`, `APNS_PRIVATE_KEY_PATH`, and the correct development/production environment. Never commit the key.

In Xcode add **Push Notifications** and **Background Modes → Remote notifications** to the app target, select a team, and ensure the bundle ID matches `APNS_BUNDLE_ID`. Production traffic must use HTTPS/WSS. When APNs is disabled, the backend remains healthy and reports the mock provider; completing provider delivery and invalid-token pruning is the next release task.

