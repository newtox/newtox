registerPlugin({
    name: 'Self Groups',
    version: '1.3.0',
    description: 'Lets clients join and leave whitelisted server groups by private message, in English or German, e.g. !group cs2 or !gruppe cs2.',
    author: 'newtox <futzy261@gmail.com>',
    backends: ['ts3'],
    engine: '>= 1.0.0',
    vars: [
        {
            name: 'groups',
            title: 'Server groups people may add themselves to',
            type: 'array',
            vars: [
                {
                    name: 'groupId',
                    title: 'Server group ID',
                    type: 'number'
                },
                {
                    name: 'keyword',
                    title: 'Name for the command (optional, default: name of the group)',
                    type: 'string'
                },
                {
                    name: 'description',
                    title: 'Description (optional)',
                    type: 'string'
                },
                {
                    name: 'requiredGroups',
                    title: 'Only for members of these group IDs, comma separated (optional, default: everyone)',
                    type: 'string'
                }
            ]
        }
    ]
}, (_, config) => {
    const engine = require('engine');
    const event = require('event');
    const backend = require('backend');

    const COOLDOWN_MS = 2000;
    const CONFIRM_MS = 1500;
    const COMMANDS = {
        groups: { cmd: 'groups', lang: 'en' },
        group: { cmd: 'group', lang: 'en' },
        help: { cmd: 'help', lang: 'en' },
        gruppen: { cmd: 'groups', lang: 'de' },
        gruppe: { cmd: 'group', lang: 'de' },
        hilfe: { cmd: 'help', lang: 'de' }
    };
    const lastUse = {};

    const allowed = (config.groups || [])
        .map(g => ({
            groupId: String(g.groupId || '').trim(),
            keyword: String(g.keyword || '').trim().toLowerCase(),
            description: String(g.description || '').trim(),
            requiredGroups: String(g.requiredGroups || '').split(',').map(id => id.trim()).filter(id => id)
        }))
        .filter(g => g.groupId);

    function groupName(entry) {
        const group = backend.getServerGroupByID(entry.groupId);
        return group ? group.name() : 'Group ' + entry.groupId;
    }

    function keywordOf(entry) {
        return entry.keyword || groupName(entry).toLowerCase();
    }

    function hasGroup(client, groupId) {
        return client.getServerGroups().some(group => String(group.id()) === groupId);
    }

    function mayUse(client, entry) {
        return entry.requiredGroups.length === 0 || entry.requiredGroups.some(id => hasGroup(client, id));
    }

    function prefix() {
        return engine.getCommandPrefix() || '!';
    }

    const TEXT = {
        en: {
            none: () => 'There are no groups you can join right now.',
            listTitle: () => 'Groups:',
            listHint: p => `[b]${p}group <name>[/b] adds you or takes you out again.`,
            unknown: (k, p) => `There is no group called "${k}". [b]${p}groups[/b] shows which ones there are.`,
            left: n => `You left [b]${n}[/b].`,
            denied: n => `You're not allowed to join [b]${n}[/b].`,
            joined: n => `You joined [b]${n}[/b].`,
            failed: () => "That didn't work, please try again later.",
            help: p => [
                `[b]${p}groups[/b] – shows all groups you can join yourself`,
                `[b]${p}group <name>[/b] – adds you or takes you out again`,
                `Auf Deutsch: [b]${p}gruppen[/b], [b]${p}gruppe <name>[/b]`
            ].join('\n')
        },
        de: {
            none: () => 'Es gibt gerade keine Gruppen, denen du beitreten kannst.',
            listTitle: () => 'Gruppen:',
            listHint: p => `[b]${p}gruppe <name>[/b] trägt dich ein oder wieder aus.`,
            unknown: (k, p) => `Die Gruppe „${k}“ gibt es nicht. [b]${p}gruppen[/b] zeigt, welche es gibt.`,
            left: n => `Du bist aus [b]${n}[/b] ausgetreten.`,
            denied: n => `Du darfst [b]${n}[/b] nicht beitreten.`,
            joined: n => `Du bist jetzt in [b]${n}[/b].`,
            failed: () => 'Das hat nicht geklappt, versuch es später nochmal.',
            help: p => [
                `[b]${p}gruppen[/b] – zeigt alle Gruppen, denen du selbst beitreten kannst`,
                `[b]${p}gruppe <name>[/b] – trägt dich ein oder wieder aus`,
                `In English: [b]${p}groups[/b], [b]${p}group <name>[/b]`
            ].join('\n')
        }
    };

    function list(client, t) {
        const usable = allowed.filter(entry => mayUse(client, entry) || hasGroup(client, entry.groupId));
        if (usable.length === 0) {
            client.chat(t.none());
            return;
        }
        const lines = usable.map(entry => {
            const mark = hasGroup(client, entry.groupId) ? '[b]✓[/b]' : '–';
            const desc = entry.description ? ` – ${entry.description}` : '';
            return `${mark} [b]${keywordOf(entry)}[/b]${desc}`;
        });
        client.chat([t.listTitle()].concat(lines, [t.listHint(prefix())]).join('\n'));
    }

    function confirm(client, entry, shouldHave, done, t) {
        const uid = client.uid();
        const nick = client.name();
        const name = groupName(entry);
        setTimeout(() => {
            const fresh = backend.getClientByUID(uid);
            if (!fresh) return;
            if (hasGroup(fresh, entry.groupId) === shouldHave) {
                fresh.chat(done(name));
                engine.log(`${nick} ${shouldHave ? 'joined' : 'left'} ${name} (${entry.groupId})`);
            } else {
                fresh.chat(t.failed());
                engine.log(`${nick} ${shouldHave ? 'joining' : 'leaving'} ${name} (${entry.groupId}) failed, check the bot's group member add/remove power`);
            }
        }, CONFIRM_MS);
    }

    function toggle(client, keyword, t) {
        const entry = allowed.find(e => keywordOf(e) === keyword);
        if (!entry) {
            client.chat(t.unknown(keyword, prefix()));
            return;
        }
        const name = groupName(entry);
        if (hasGroup(client, entry.groupId)) {
            client.removeFromServerGroup(entry.groupId);
            confirm(client, entry, false, t.left, t);
        } else if (!mayUse(client, entry)) {
            client.chat(t.denied(name));
        } else {
            client.addToServerGroup(entry.groupId);
            confirm(client, entry, true, t.joined, t);
        }
    }

    event.on('chat', msg => {
        if (msg.mode !== 1 || !msg.client || msg.client.isSelf()) return;

        const text = msg.text.trim();
        const p = prefix();
        if (!text.startsWith(p)) return;

        const parts = text.slice(p.length).trim().split(/\s+/);
        const command = COMMANDS[parts.shift().toLowerCase()];
        if (!command) return;

        const client = msg.client;
        const id = client.uid();
        const now = Date.now();
        if (lastUse[id] && now - lastUse[id] < COOLDOWN_MS) return;
        lastUse[id] = now;

        const t = TEXT[command.lang];
        if (command.cmd === 'groups') {
            list(client, t);
        } else if (command.cmd === 'group') {
            const keyword = parts.join(' ').toLowerCase();
            if (keyword) toggle(client, keyword, t);
            else list(client, t);
        } else {
            client.chat(t.help(prefix()));
        }
    });

    engine.log(`Self Groups loaded with ${allowed.length} group(s)`);
});
