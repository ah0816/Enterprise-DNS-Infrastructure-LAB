/ip firewall filter
add chain=forward action=accept src-address-list=allow_internet out-interface=ether1-WAN comment="allow_internet for normal users"

add chain=input action=accept connection-state=established,related comment="Allow established/related"

add chain=forward action=accept protocol=tcp src-address=192.168.20.10 out-interface=ether1-WAN dst-port=53 comment="allow_dns_dmz /TCP"

add chain=forward action=accept protocol=udp src-address=192.168.20.10 out-interface=ether1-WAN dst-port=53 comment="allow_dns_dmz /UDP"

add chain=forward action=accept protocol=udp src-address=192.168.100.10 dst-address=192.168.20.10 dst-port=53 comment="allow_DC to DMZ UDP/53"

add chain=forward action=accept protocol=tcp src-address=192.168.100.10 dst-address=192.168.20.10 dst-port=53 comment="allow_DC to DMZ TCP/53"

add chain=forward action=accept protocol=icmp src-address=192.168.20.10 out-interface=ether1-WAN comment="Allow_ICMP for DNS-SRV"

add chain=forward action=drop out-interface=ether1-WAN comment="Drop all other traffic (to WAN)"

add chain=forward action=drop in-interface=ether3-DMZ out-interface=ether1-WAN comment="Drop all other traffic (DMZ -> WAN)"

add chain=input action=drop connection-state=invalid comment="Drop invalid connections"

