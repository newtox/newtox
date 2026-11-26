# TeamSpeak ServerQuery keep-alive

A small Compose/Portainer stack that keeps a ServerQuery session logged in permanently. The query client shows up in the channel tree under a nickname of your choice and can be parked in a specific channel. If the connection drops, it reconnects automatically.

## How it works

The container (Alpine) installs `openssh-client` and `sshpass`, connects to the SSH query port of the TeamSpeak server and then:

1. selects the virtual server (`use sid=...`)
2. sets the nickname (`clientupdate client_nickname=...`), only if `TS_NICK` is set
3. optionally moves itself into a channel (`clientmove`)
4. sends `whoami` every `KEEPALIVE` seconds so the query idle timeout never closes the session
5. reconnects after 60 seconds if the connection is lost

## Requirements

- TeamSpeak 6 server with the SSH query port reachable from the Docker network of this stack (default `10022`)
- a query login (`serveradmin` or a dedicated login)
- the Docker network of the TeamSpeak container. The stack expects an external network called `teamspeak-server_default`, set `TS_NETWORK` if yours is named differently.

## Variables

| Variable | Default | Description |
|---|---|---|
| `TS_PASSWORD` | required | password of the query login |
| `TS_USER` | `serveradmin` | query login name |
| `TS_HOST` | `teamspeak6-server` | host of the query port (container name) |
| `TS_NETWORK` | `teamspeak-server_default` | Docker network of the TeamSpeak container |
| `TS_PORT` | `10022` | SSH query port |
| `TS_SID` | `1` | virtual server ID |
| `TS_NICK` | empty | nickname shown in the channel tree, empty keeps the login name (for example `serveradmin`) |
| `TS_CID` | empty | channel ID to park in, empty keeps the default channel |
| `KEEPALIVE` | `60` | seconds between keep-alives, must stay below the query idle timeout |

## Deploy

In Portainer: Stacks, Add stack, paste `docker-compose.yml`, set the variables under Environment variables (at least `TS_PASSWORD`), then Deploy the stack.

With the Docker CLI:

```bash
TS_PASSWORD=yourpassword docker compose up -d
```

Check the connection with:

```bash
docker logs --tail 20 ts-query
```

## Notes

- The password is never stored in the file. The stack refuses to start without `TS_PASSWORD`.
- SSH host key checking is disabled, because the connection stays inside the Docker network.
- Run several instances by changing `container_name`. Set a different `TS_NICK` for each one to tell them apart. If a nickname is already taken, the server answers `nickname is already in use` and the session keeps the login name.
