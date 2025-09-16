# Enterprise-DNS-Infrastructure-LAB
This lab simulates a **real-world enterprise DNS architecture** by separating internal domain DNS (Active Directory) from external recursive DNS (Unbound in DMZ), secured with Mikrotik firewall rules.

## Architecture

**Components:**
- **Windows Server (Domain Controller + DNS)**  
  - Provides internal name resolution for domain-joined clients.  
  - Forwards external queries to Unbound DNS.
  - **IP**: 192.168.100.10/24
  - **DG**: 192.168.100.250
  - **DNS**: 192.168.100.10 or 127.0.0.1

- **Linux Server (Unbound DNS in DMZ)** 
  - Acts as recursive/caching DNS resolver.  
  - Accessible from the Internet for public DNS queries.  
  - Hardened with ACLs and logging.
  - **IP**: 192.168.20.10/24
  - **DG**: 192.168.20.250

- **Mikrotik Router/Firewall**  
  - Provides routing between LAN, DMZ, and WAN.  
  - Enforces firewall rules to isolate zones.
  - **Interface IPs**:
    - **DMZ**: 192.168.20.250/24
    - **LAN**: 192.168.100.250/24
    - **WAN**: DHCP

- **Clients (Windows Workstations, for testing)**  
  - Joined to AD Domain. 
  - Use Domain DNS for resolution.
  - **IP**: 192.168.100.100/24
  - **DG**: 192.168.100.250
  - **DNS**" 192.168.100.10

---

## DNS Query Flow
1. **LAN Client** queries `internal.domain.local` → resolved directly by **AD DNS**.  
2. **LAN Client** queries `google.com` → AD DNS forwards request → **Unbound DNS** → Internet root servers → returns result.  
3. **Internet User** queries → only allowed to **Unbound DNS (DMZ)**.  
4. **Isolation** ensures AD DNS never exposed directly to the Internet.

---
## Security Best Practices
    
- **Unbound**: enable `access-control`, rate-limiting, and DNSSEC.
    
- **Zone Transfers**: disabled unless explicitly required.
    
- **Mikrotik Management**: restrict admin access to management VLAN, use SSH key-based login.
    
- **Logging & Monitoring**: forward Unbound + AD DNS logs to centralized system (ELK/Graylog/Wazuh).
    
- **Limit Interfaces**: configure Unbound to listen only on specific interfaces (e.g., `192.168.100.10` and `127.0.0.1`) instead of `0.0.0.0`.

---

## Notes & Observations

- **DNSSEC is enabled by default**  
    On most modern Linux distributions, Unbound ships with a pre-configured **Root Trust Anchor**.  
    This means DNSSEC validation works out-of-the-box without manually adding:
    
    ```yaml
    auto-trust-anchor-file: "/var/lib/unbound/root.key"
    ```
    
    The trust anchor file is usually located in `/var/lib/unbound/root.key` and you can update it by `unbound-anchor`.
    
- **No pidfile under systemd**  
    **systemd** manages process tracking internally and does not require a separate `pidfile`.  
    This is why `/var/run/unbound/unbound.pid` may not exist by default.  
    If required (e.g., for external scripts), you can explicitly enable it in `unbound.conf`:
    
    ```yaml
    server:
        pidfile: "/var/run/unbound/unbound.pid"
    ```

---

## Troubleshooting

### 1. Port 53 already in use (systemd-resolved conflict)

On some Linux distributions (especially Ubuntu), `systemd-resolved` binds to port 53, which prevents Unbound from starting.

**Check if port 53 is already in use:**

```bash
sudo lsof -i :53
```

**Solution:**

1. Edit `/etc/systemd/resolved.conf`:
    
    ```ini
    [Resolve]
    DNSStubListener=no
    ```
    
2. Restart the service:
    
    ```bash
    sudo systemctl restart systemd-resolved
    ```
    
3. Link resolv.conf:
    
    ```bash
    sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
    ```
    
4. Restart your System:

---

### 2. Unbound service not starting after config change

Always check your config file before restarting:

```bash
unbound-checkconf
```

This ensures no syntax errors exist in `/etc/unbound/unbound.conf`.

---

### 3. DNSSEC validation failures

If DNSSEC is enabled but queries fail:

- Ensure the trust anchor file exists:
    
    ```bash
    ls -l /var/lib/unbound/root.key
    ```
    
- Update trust anchor if needed:
    
    ```bash
    sudo unbound-anchor -a "/var/lib/unbound/root.key"
    ```
    

Test DNSSEC validation:

```bash
dig sigok.verteiltesysteme.net @127.0.0.1
dig sigfail.verteiltesysteme.net @127.0.0.1
```

-  `sigok` should succeed.
    
-  `sigfail` should fail (tampered response).
    
