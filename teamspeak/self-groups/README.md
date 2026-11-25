# TeamSpeak self-service groups

A Compose/Portainer stack with a ServerQuery bot that lets people join and leave server groups themselves, for example one group per game. They send the bot a private message or write the command in the chat of the bot's channel, in English or German. The bot answers by private message, in the language of the command. The whole bot (a Python script) is embedded in `docker-compose.yml`, so the stack can be pasted into Portainer as it is.

The bot is a query client, so it shows up without microphone or speaker and doesn't need SinusBot. The TeamSpeak 6 client doesn't show query clients at all, so people using it can't double-click the bot. They write the commands in the chat of the channel the bot sits in (`TS_CID`) instead, and get the answer as a private message. If you'd rather run it inside SinusBot, use [`../sinusbot/self-groups.js`](../sinusbot/self-groups.js), which does the same.

## Commands

| English | German | |
|---|---|---|
| `!groups` | `!gruppen` | lists the groups you can join, with a ✓ on the ones you are in |
| `!group <name>` | `!gruppe <name>` | joins the group, or leaves it if you are already in it |
| `!help` | `!hilfe` | shows the commands |

`<name>` is the group name in lower case, or the keyword set in `GROUP_KEYWORDS`.

Members of `ADMIN_GROUPS` also get:

| English | German | |
|---|---|---|
| `!creategroup <name>` | `!gruppeanlegen <name>` | creates a group people can join right away |
| `!deletegroup <name>` | `!gruppeloeschen <name>` | deletes a group that was created with `!creategroup` |

## Creating groups

TeamSpeak only gives a client the default server group (usually Guest) while the client is in no other server group. When a guest joins a group without the basic permissions, they suddenly can't join channels or talk any more. `!creategroup` avoids that: the new group starts as a copy of the default server group, so it has all of its permissions, and its needed member add/remove power is set to `NEW_GROUP_POWER`. Add icons or extra permissions afterwards as usual.

The bot finds the default group itself (`serverinfo`) and copies it with `servergroupcopy`. If the server doesn't know that command, it creates the group and copies the permissions one by one.

Created groups are remembered in `groups.json` in `DATA_DIR` and can be joined without touching `SELF_GROUPS`. `!deletegroup` only deletes groups from that file, so groups made by hand can't be deleted through the bot. If the file gets lost, the groups stay in TeamSpeak but can't be joined through the bot any more until you add them to `SELF_GROUPS`.

## How it works

1. The bot logs in via the SSH query port, sets its nickname, moves into `TS_CID` and registers for private messages and the chat of that channel.
2. On a command it reads the sender's server groups with `clientinfo`.
3. `!group` adds or removes the group with `servergroupaddclient` / `servergroupdelclient` and answers by private message.

Only the groups in `SELF_GROUPS` can be touched, whatever someone types. A group with an entry in `GROUP_REQUIRED` can only be joined by members of one of the listed groups. Leaving always works, so nobody gets stuck in a group after losing the required one. Each person can send one command every 2 seconds.

## Requirements

- TeamSpeak 6 server with the SSH query port reachable from the Docker network of this stack
- the Docker network of the TeamSpeak container. The stack expects an external network called `teamspeak-server_default`, set `TS_NETWORK` if yours differs.
- a query login in a server group with the right permissions (see below)

## Query login and permissions

Create a dedicated login in the query console (`ssh -p 10022 serveradmin@127.0.0.1`):

```
use 0
queryloginadd client_login_name=groupbot
```

The answer contains the generated password. It is shown only once, so copy it right away.

Create a server group for the bot, for example "Groups bot", and put the login into it. The `client_database_id` comes from `whoami` while logged in as the bot:

```
use 1
servergroupaddclient sgid=<ID of the bot group> cldbid=<client_database_id of groupbot>
```

The group needs:

| Permission | Why |
|---|---|
| `b_virtualserver_notify_register` | receive private messages |
| `b_virtualserver_servergroup_list` | read the group names |
| `b_client_info_view` | read the sender's groups |
| `i_client_private_textmessage_power` | answer, at least the needed power of your users |
| `i_client_needed_private_textmessage_power` | no higher than the private message power of your users, otherwise nobody can message the bot |
| `i_group_member_add_power`, `i_group_member_remove_power` | at least the needed add/remove power of the groups in `SELF_GROUPS`, and lower than that of mod, admin and punishment groups. Then the bot can't hand those out even if something goes wrong |
| `i_client_needed_serverquery_view_power` | no higher than the `i_client_serverquery_view_power` of your users, so TeamSpeak 3 clients see the bot and can double-click it. Keep it high on the groups of your other query clients and only they stay hidden |
| `b_serverquery_login`, `b_virtualserver_select` | log in and select the server, needed when the login isn't in Guest Server Query anymore |
| `b_channel_join_permanent`, `i_channel_join_power` | move into `TS_CID` |

For `!creategroup` and `!deletegroup` it additionally needs:

| Permission | Why |
|---|---|
| `b_virtualserver_info_view` | find the default group |
| `b_virtualserver_servergroup_create`, `b_virtualserver_servergroup_delete` | create and delete groups |
| `b_virtualserver_servergroup_permission_list` | read the default group's permissions |
| `i_group_modify_power` | at least the `i_group_needed_modify_power` of the default group |
| `i_permission_modify_power` | high enough to set the copied permissions |

That is a lot of power, often as much as your server admins have. The bot only ever changes groups it created itself, and only members of `ADMIN_GROUPS` can trigger it. If you don't need it, leave `ADMIN_GROUPS` empty and skip these permissions.

## Variables

| Variable | Default | Description |
|---|---|---|
| `TS_PASSWORD` | required | password of the query login |
| `SELF_GROUPS` | empty | existing server group IDs people may join, comma separated |
| `TS_USER` | `serveradmin` | query login name |
| `TS_HOST` | `teamspeak6-server` | host of the query port (container name) |
| `TS_NETWORK` | `teamspeak-server_default` | Docker network of the TeamSpeak container |
| `TS_PORT` | `10022` | SSH query port |
| `TS_SID` | `1` | virtual server ID |
| `TS_NICK` | `Groups` | nickname of the bot |
| `TS_CID` | empty | channel ID to park the bot in. People write their commands in this channel's chat |
| `KEEPALIVE` | `60` | seconds between keep-alives |
| `PREFIX` | `!` | command prefix |
| `CHANNEL_COMMANDS` | `1` | also answer commands written in the chat of the bot's channel, `0` turns it off |
| `GROUP_KEYWORDS` | group name in lower case | command names, e.g. `12=cs2,14=modcs` |
| `GROUP_DESCRIPTIONS` | empty | descriptions shown in the list, separated by `;` so they can contain commas, e.g. `12=Counter-Strike;13=Palworld, Koop` |
| `GROUP_REQUIRED` | everyone may join | groups needed to join, `+` between several, e.g. `14=10+11` |
| `ADMIN_GROUPS` | nobody | server group IDs allowed to use `!creategroup` and `!deletegroup`, comma separated |
| `NEW_GROUP_POWER` | `30` | needed member add/remove power of created groups, at most the bot's own add/remove power |
| `DATA_DIR` | `/opt/ts-self-groups` | host folder where created groups are remembered |

## Deploy

In Portainer: Stacks, Add stack, paste `docker-compose.yml`, set the variables under Environment variables (at least `TS_PASSWORD`, `TS_USER` and `SELF_GROUPS` or `ADMIN_GROUPS`), then Deploy the stack. Check the result with:

```bash
docker logs --tail 20 ts-self-groups
```

`connected as Groups, 2 group(s): cs2, palworld` means the bot is running and found the group names. Every join and leave is logged as `<nickname> joined <group> (<id>)`.
