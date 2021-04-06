#!/bin/bash

npmIps="$(dig +short *.npmjs.org npmjs.org registry.npmjs.org *.nodejs.org nodejs.org) $(curl https://www.cloudflare.com/ips-v4)";
githubIps=$(curl "https://api.github.com/meta" | jq -r '.web[], .api[], .pages[], .git[]');

# adapted from https://networklessons.com/uncategorized/iptables-example-configuration

# IPv6

##
## set default policies to let everything in
ip6tables --policy INPUT   ACCEPT
ip6tables --policy OUTPUT  ACCEPT
ip6tables --policy FORWARD ACCEPT

##
## start fresh
ip6tables -Z # zero counters
ip6tables -F # flush (delete) rules
ip6tables -X # delete all extra chains

# IPv4

## 
## set default policies to let everything in
iptables --policy INPUT   ACCEPT
iptables --policy OUTPUT  ACCEPT
iptables --policy FORWARD ACCEPT

##
## start fresh
iptables -Z # zero counters
iptables -F # flush (delete) rules
iptables -X # delete all extra chains


# Drop everything
iptables -P OUTPUT  DROP
iptables -P INPUT   DROP
iptables -P FORWARD DROP

# Drop everything IPv6
ip6tables -P OUTPUT  DROP
ip6tables -P INPUT   DROP
ip6tables -P FORWARD DROP

# drop TCP sessions opened prior firewall restart
iptables -A INPUT -p tcp -m tcp ! --tcp-flags SYN,RST,ACK SYN -m state --state NEW -j REJECT
iptables -A OUTPUT  -p tcp -m tcp ! --tcp-flags SYN,RST,ACK SYN -m state --state NEW -j REJECT

# drop packets that do not match any valid state
iptables -N drop_invalid
iptables -A OUTPUT   -m state --state INVALID  -j drop_invalid 
iptables -A INPUT    -m state --state INVALID  -j drop_invalid 
iptables -A INPUT -p tcp -m tcp --sport 1:65535 --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j drop_invalid 
iptables -A drop_invalid -j REJECT

# ESTABLISHED,RELATED
iptables -A INPUT  -m state --state ESTABLISHED,RELATED  -j ACCEPT

# allow all on loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A FORWARD -o lo -j ACCEPT

#(INVALID OUT)
iptables -A OUTPUT -p tcp -m tcp ! --tcp-flags SYN,RST,ACK SYN -m state --state NEW -j REJECT

# ESTABLISHED,RELATED (OUT)
iptables -A OUTPUT  -m state --state ESTABLISHED,RELATED  -j ACCEPT

iptables -A OUTPUT -p udp --dport 53 --sport 1024:65535 -j ACCEPT
iptables -A INPUT -p udp --dport 53 --sport 1024:65535 -j ACCEPT

## repeat this section for multiple IPs
for SERVER_IP in $npmIps; do
  iptables -A INPUT  -p tcp -s $SERVER_IP -m tcp -j ACCEPT
  iptables -A OUTPUT -p tcp -d $SERVER_IP -m tcp -j ACCEPT
done;

for SERVER_IP in $githubIps; do
  iptables -A INPUT  -p tcp -s $SERVER_IP -m tcp -j ACCEPT
  iptables -A OUTPUT -p tcp -d $SERVER_IP -m tcp -j ACCEPT
done;
