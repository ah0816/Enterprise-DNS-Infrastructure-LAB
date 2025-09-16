1. Open **DNS Manager** on Domain Controller.
2. Right-click the server name → **Properties** → **Forwarders** tab.
3. Add the IP address of the **Unbound DNS Server** (in my case 192.168.20.10).
4. Apply settings.

## Security Hardening
- Go to **Interfaces** tab → select only the LAN IP (avoid listening on all IPs).
- For **Zone Transfers**:
  - Right-click on your domain zone (e.g., `domain.local`) → Properties → **Zone Transfers**.
  - Disable zone transfers, or allow only to explicitly listed secondary DNS servers.
