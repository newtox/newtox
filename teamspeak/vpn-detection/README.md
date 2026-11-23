# TeamSpeak VPN detection

A Compose/Portainer stack with a ServerQuery bot that checks the IP address of every connecting client and reacts when it belongs to a VPN or proxy. The whole bot (a Python script) is embedded in `docker-compose.yml`, so the stack can be pasted into Portainer as it is.

## How it works

1. The bot logs in via the SSH query port, sets its nickname and registers for server events.
2. On every client join it reads the IP with `clientinfo` (`connection_client_ip`).
3. The IP is checked against the selected provider. Results are cached for 6 hours.
4. On a hit, the configured actions run: `log`, `message`, `poke`, `move`, `kick`.

Private and local IPs, query clients and moved clients are ignored. Clients can be whitelisted by unique ID or by server group.

## Requirements

- TeamSpeak 6 server with the SSH query port reachable from the Docker network of this stack
- the Docker network of the TeamSpeak container. The stack expects an external network called `teamspeak-server_default`, set `TS_NETWORK` if yours differs.
- a query login with enough rights (see below)

## Query login

Create a dedicated global login in the query console (`ssh -p 10022 serveradmin@127.0.0.1`):

```
use 0
queryloginadd client_login_name=vpnbot
```

The answer contains the generated password. It is shown only once, so copy it right away. `queryloginlist` shows all logins.

New logins are implicitly members of the default group Guest Server Query, which cannot be assigned manually. If the log shows `register failed: insufficient client permissions`, the bot needs more rights. Either add the login to another query group:

```
use 1
servergroupaddclient sgid=2 cldbid=<cldbid of vpnbot>
```

or grant the missing permissions to a group. The bot needs to register for server events, list clients, read client info including the remote address, and, depending on the actions, send private messages, poke, move or kick.

## Variables

| Variable | Default | Description |
|---|---|---|
| `TS_PASSWORD` | required | password of the query login |
| `TS_USER` | `serveradmin` | query login name |
| `TS_HOST` | `teamspeak6-server` | host of the query port (container name) |
| `TS_NETWORK` | `teamspeak-server_default` | Docker network of the TeamSpeak container |
| `TS_PORT` | `10022` | SSH query port |
| `TS_SID` | `1` | virtual server ID |
| `TS_NICK` | `VPN-Detection` | nickname of the bot |
| `TS_CID` | empty | channel ID to park the bot in |
| `KEEPALIVE` | `60` | seconds between keep-alives |
| `PROVIDER` | `proxycheck` | `proxycheck` or `asn` |
| `PROXYCHECK_KEY` | empty | optional proxycheck.io API key for a higher quota |
| `ASN_DB` | `/data/GeoLite2-ASN.mmdb` | path of the ASN database inside the container |
| `ASN_DIR` | `/opt/ts-vpn` | host folder that contains the ASN database, mounted read-only to `/data` |
| `ASN_KEYWORDS` | built-in list | comma separated provider name fragments that count as a hit |
| `ASN_BLOCKLIST` | empty | comma separated ASN numbers that count as a hit |
| `ACTION` | `log,message` | comma separated list of `log`, `message`, `poke`, `move`, `kick` |
| `MESSAGE` | built-in text | text for `message` and `poke` |
| `KICK_MESSAGE` | built-in text | reason for `kick` |
| `MOVE_CID` | empty | target channel ID for `move` |
| `WHITELIST_UIDS` | empty | comma separated unique IDs that are never checked |
| `WHITELIST_SGIDS` | empty | comma separated server group IDs that are never checked |

## Providers

**proxycheck** asks proxycheck.io whether the IP is a VPN or proxy. It detects single IPs and needs no maintenance. A limited daily quota is free, an API key raises it. The IPs of joining clients are sent to a third party.

**asn** looks the IP up in a local GeoLite2 ASN database. Nothing leaves your server and there is no quota, but only whole networks are detected, and hosting or company networks can cause false positives. Provide the database as follows:

1. Create a free MaxMind account and download `GeoLite2-ASN.mmdb`.
2. Place it in a folder on the host, `/opt/ts-vpn` by default or any path set with `ASN_DIR`. The folder is mounted read-only to `/data`.
3. Set `PROVIDER=asn` and, if needed, `ASN_BLOCKLIST` and `ASN_KEYWORDS`.

Do not commit the database to a repository, the MaxMind license does not allow redistribution.

## Recommended start

Begin with `ACTION=log,message` and watch the logs for a few days. Mobile and company networks are sometimes classified as VPN. Whitelist your bots and trusted users (`WHITELIST_SGIDS`, `WHITELIST_UIDS`) before enabling `move` or `kick`.

## Deploy

In Portainer: Stacks, Add stack, paste `docker-compose.yml`, set the variables under Environment variables (at least `TS_PASSWORD`), then Deploy the stack. Check the result with:

```bash
docker logs --tail 20 ts-vpn-detection
```

`connected, provider=...` means the bot is running. A hit is logged as `VPN/proxy: <nickname> (<uid>) <ip> <type>`.

## Privacy

IP addresses are personal data. If you use an external provider, mention the check in your welcome message or privacy notice.
