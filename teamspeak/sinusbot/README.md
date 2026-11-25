# SinusBot scripts

Scripts for [SinusBot](https://www.sinusbot.com) on a TeamSpeak server. Copy a script into the `scripts` folder of the bot, restart it and enable the script in the web interface under Settings, Scripts.

## self-groups.js

Lets people join and leave server groups themselves by sending the bot a private message, in English or German. The bot answers in the language of the command.

The same as a standalone ServerQuery bot, without SinusBot: [`../self-groups`](../self-groups).

| English | German | |
|---|---|---|
| `!groups` | `!gruppen` | lists the groups you can join, with a ✓ on the ones you are in |
| `!group <name>` | `!gruppe <name>` | joins the group, or leaves it if you are already in it |
| `!help` | `!hilfe` | shows the commands |

The prefix is the command prefix of the instance, so `!` turns into whatever is set there.

### Settings

Each entry in the web interface is one group people may join:

| Field | |
|---|---|
| Server group ID | the group |
| Name for the command | optional, defaults to the group name in lower case. Set it when the group name is long, e.g. `cs2` for "Counter-Strike 2" |
| Description | optional, shown in the list |
| Only for members of these group IDs | optional, comma separated. Only members of one of these groups can join. Leaving always works, so nobody gets stuck in a group after losing the required one |

Groups that are not in the list can't be touched through the bot, whatever someone types.

Give every group in the list the basic permissions of your default server group (usually Guest). TeamSpeak only gives a client the default group while the client is in no other server group, so a guest who joins a group without them suddenly can't join channels or talk. The easiest way is to create the group as a copy of the default group via ServerQuery (`servergroupcopy ssgid=<default group> tsgid=0 name=<name> type=1`). SinusBot scripts can't create groups, the [query bot](../self-groups) can do it with `!creategroup`.

### TeamSpeak permissions

The bot's server group needs:

- `i_group_member_add_power` and `i_group_member_remove_power` at least as high as `i_group_needed_member_add_power` / `i_group_needed_member_remove_power` of the groups in the list, and lower than those of mod, admin and punishment groups. Then the bot can't hand those out even if something goes wrong.
- `b_virtualserver_servergroup_list` so it can read the group names.
- `i_client_needed_private_textmessage_power` no higher than the `i_client_private_textmessage_power` of normal users, otherwise nobody can message the bot.
