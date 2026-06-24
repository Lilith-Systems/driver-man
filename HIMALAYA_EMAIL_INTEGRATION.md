# Himalaya Email Integration for Driver Man Co-Op

## Account Setup
```bash
himalaya account add --name "driverman-ops" --email "ops@thedriverman.coop"
himalaya account add --name "driverman-support" --email "support@thedriverman.coop"
himalaya account add --name "driverman-bizdev" --email "bizdev@thedriverman.coop"
himalaya account add --name "driverman-legal" --email "legal@thedriverman.coop"
```

## Automated Workflows
- **Driver Onboarding:** Himalaya watches for applications → Polsia Ambassador agent processes
- **Support Tickets:** Himalaya filters support@ → Polsia Sentinel agent triages
- **Restaurant Leads:** Himalaya watches biz-dev@ → Polsia Ambassador outreaches
- **Legal Notices:** Himalaya filters legal@ → Auto-forwards to legal-evidence repo

## Email Templates (in business-strategy repo)
- `templates/driver_welcome.txt`
- `templates/restaurant_pitch.txt`
- `templates/support_acknowledgment.txt`
- `templates/legal_notice_received.txt`

## Polsia Agent Email Mapping
| Agent | Sephirah | Email Account | Purpose |
|-------|----------|---------------|---------|
| Orchestrator | Keter | driverman-ops | System alerts, dispatch |
| Ambassador | Chokmah | driverman-bizdev | Restaurant outreach |
| Ledger | Binah | driverman-ops | Pool balance reports |
| Sentinel | Chesed | driverman-support | Driver disputes |
| Guardian | Geburah | driverman-legal | Fraud, compliance |
| Harmonizer | Tifereth | driverman-support | Mediation |
| Networker | Netzach | driverman-bizdev | Partnerships |
| Communicator | Hod | driverman-ops | Status reports |
| Foundation | Yesod | driverman-ops | Infrastructure |
| Manifestor | Malkuth | driverman-ops | Deployment confirmations |

## Integration with Polsia Backend
```bash
# Each agent polls their inbox every 5min via cron
*/5 * * * * /usr/bin/himalaya -a driverman-{agent} list -l 10 --format json | jq -r '.[] | select(.flags | contains("unread")) | .uid' | xargs -I {} himalaya -a driverman-{agent} read {}
```

## Ledger Integration
- Driver Man ledger at `/home/tehlappy/Desktop/Lilith/state/coop_pool_state.json`
- Transparent ledger: $4.99 fee → $3.50 driver + $1.49 pool
- 100% tips retained by driver
- $0 restaurant commission + $1.50 flat routing fee
