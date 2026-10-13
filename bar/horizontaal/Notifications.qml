// bar/horizontaal/Notifications.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    // ---- public state -------------------------------------------------
    // newest first: { key, appName, icon, summary, body, urgency, time, actions: [{identifier, text}] }
    property var history: []
    property alias toasts: toastModel
    property bool dndEnabled: false
    property real now: Date.now()
    property string expandedKey: ""
    readonly property int count: history.length
    readonly property int maxHistory: 100

    // ---- internals ----------------------------------------------------
    property var _live: ({})
    property int _toastSeq: 0
    readonly property string _dir: Quickshell.env("HOME") + "/.local/state/quickshell"
    readonly property string _file: _dir + "/notifications.json"
    readonly property var _toastTimeouts: ({
            "0": 3000,
            "1": 10000,
            "2": 30000
        })

    ListModel {
        id: toastModel
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.now = Date.now()
    }

    Timer {
        id: saveTimer
        interval: 800
        onTriggered: root._writeStore()
    }

    FileView {
        id: store
        path: root._file
        printErrors: false
        onLoaded: root._restore(store.text())
    }

    // ---- helpers ------------------------------------------------------
    function timeAgo(t, ref) {
        const s = Math.max(0, Math.floor((ref - t) / 1000));
        if (s < 60)
            return "now";
        const m = Math.floor(s / 60);
        if (m < 60)
            return m + " min ago";
        const h = Math.floor(m / 60);
        if (h < 24)
            return h + " h ago";
        const d = Math.floor(h / 24);
        return d + (d === 1 ? " day ago" : " days ago");
    }

    function bucketOf(t, ref) {
        const d = new Date(ref);
        d.setHours(0, 0, 0, 0);
        const start = d.getTime();
        if (t >= start)
            return "today";
        if (t >= start - 86400000)
            return "yesterday";
        return "older";
    }

    function _clean(s) {
        return String(s || "").replace(/<br\s*\/?>/gi, "\n").replace(/<[^>]*>/g, "").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"").replace(/&#39;/g, "'").replace(/&amp;/g, "&").trim();
    }

    function _resolveIcon(n) {
        if (n.image && String(n.image) !== "")
            return String(n.image);
        const tries = [n.appIcon, n.desktopEntry, n.appName ? String(n.appName).toLowerCase() : ""];
        for (let i = 0; i < tries.length; i++) {
            const t = tries[i];
            if (!t)
                continue;
            const s = String(t);
            if (s.startsWith("/"))
                return "file://" + s;
            if (s.startsWith("file:") || s.startsWith("image:") || s.startsWith("http"))
                return s;
            const p = Quickshell.iconPath(s, true);
            if (p)
                return p;
        }
        return "";
    }

    function _actionsOf(n) {
        const acts = [];
        const src = n.actions;
        if (!src)
            return acts;
        for (let i = 0; i < src.length; i++)
            acts.push({
                identifier: src[i].identifier,
                text: src[i].text
            });
        return acts;
    }

    // ---- persistence --------------------------------------------------
    function _persist() {
        saveTimer.restart();
    }

    function _writeStore() {
        const out = [];
        for (let i = 0; i < history.length && i < maxHistory; i++) {
            const e = history[i];
            out.push({
                key: e.key,
                appName: e.appName,
                icon: String(e.icon).startsWith("image:") ? "" : e.icon,
                summary: e.summary,
                body: e.body,
                urgency: e.urgency,
                time: e.time
            });
        }
        store.setText(JSON.stringify(out));
    }

    function _restore(text) {
        let arr = [];
        try {
            arr = JSON.parse(text);
        } catch (e) {
            return;
        }
        if (!Array.isArray(arr))
            return;
        const have = {};
        for (let i = 0; i < history.length; i++)
            have[history[i].key] = true;
        const old = [];
        for (let i = 0; i < arr.length; i++) {
            const e = arr[i];
            if (!e || !e.key || have[e.key])
                continue;
            old.push({
                key: e.key,
                appName: e.appName || "",
                icon: e.icon || "",
                summary: e.summary || "",
                body: e.body || "",
                urgency: e.urgency === undefined ? 1 : e.urgency,
                time: e.time || Date.now(),
                actions: []
            });
        }
        history = history.concat(old).sort((a, b) => b.time - a.time).slice(0, maxHistory);
    }

    // ---- history ops --------------------------------------------------
    function _trim(list) {
        for (let i = maxHistory; i < list.length; i++) {
            const l = _live[list[i].key];
            if (l) {
                delete _live[list[i].key];
                l.dismiss();
            }
        }
        return list.slice(0, maxHistory);
    }

    function _add(n) {
        const key = Date.now() + "-" + n.id;
        _live[key] = n;
        const entry = {
            key: key,
            appName: n.appName || "",
            icon: _resolveIcon(n),
            summary: _clean(n.summary),
            body: _clean(n.body),
            urgency: Number(n.urgency),
            time: Date.now(),
            actions: _actionsOf(n)
        };
        history = _trim([entry].concat(history));
        n.closed.connect(() => root._markClosed(key));
        n.summaryChanged.connect(() => root._refresh(n, key));
        n.bodyChanged.connect(() => root._refresh(n, key));
        _persist();
        return key;
    }

    function _refresh(n, key) {
        let found = false;
        const next = history.map(e => {
            if (e.key !== key)
                return e;
            found = true;
            return Object.assign({}, e, {
                summary: root._clean(n.summary),
                body: root._clean(n.body),
                icon: root._resolveIcon(n),
                time: Date.now(),
                actions: root._actionsOf(n)
            });
        });
        if (found) {
            history = next;
            _persist();
        }
    }

    function _markClosed(key) {
        delete _live[key];
        let found = false;
        const next = history.map(e => {
            if (e.key !== key)
                return e;
            found = true;
            return Object.assign({}, e, {
                actions: []
            });
        });
        if (found)
            history = next;
    }

    function remove(key) {
        const n = _live[key];
        delete _live[key];
        history = history.filter(e => e.key !== key);
        if (expandedKey === key)
            expandedKey = "";
        if (n)
            n.dismiss();
        _persist();
    }

    function clearAll() {
        const keys = Object.keys(_live);
        const live = _live;
        _live = ({});
        history = [];
        expandedKey = "";
        for (let i = 0; i < keys.length; i++)
            live[keys[i]].dismiss();
        _persist();
    }

    function invoke(key, identifier) {
        const n = _live[key];
        if (!n)
            return;
        for (let i = 0; i < n.actions.length; i++) {
            if (n.actions[i].identifier === identifier) {
                n.actions[i].invoke();
                break;
            }
        }
        remove(key);
    }

    function invokeDefault(key) {
        const n = _live[key];
        if (!n)
            return;
        for (let i = 0; i < n.actions.length; i++) {
            if (n.actions[i].identifier === "default") {
                invoke(key, "default");
                return;
            }
        }
    }

    function toggleExpand(key) {
        expandedKey = (expandedKey === key) ? "" : key;
    }

    function toggleDnd() {
        dndEnabled = !dndEnabled;
    }

    // ---- toasts -------------------------------------------------------
    function _toast(n, key) {
        if (dndEnabled)
            return;
        const urgency = n.urgency !== undefined ? Number(n.urgency) : 1;
        const timeout = n.expireTimeout > 0 ? Math.round(n.expireTimeout * 1000) : _toastTimeouts[String(urgency)];
        const mergeKey = (n.appName || "") + "|" + n.summary;
        const title = _clean(n.summary);
        const body = _clean(n.body);

        for (let i = 0; i < toastModel.count; i++) {
            const ex = toastModel.get(i);
            if (ex.mergeKey === mergeKey) {
                toastModel.set(i, {
                    title: title,
                    body: body,
                    timeout: timeout,
                    token: ex.token + 1
                });
                return;
            }
        }

        toastModel.append({
            tid: String(++_toastSeq),
            nkey: key,
            appName: n.appName || "",
            icon: _resolveIcon(n),
            title: title,
            body: body,
            timeout: timeout,
            mergeKey: mergeKey,
            token: 0
        });
    }

    function dismissToast(tid) {
        for (let i = 0; i < toastModel.count; i++) {
            if (toastModel.get(i).tid === tid) {
                toastModel.remove(i);
                break;
            }
        }
    }

    function dismissAllToasts() {
        toastModel.clear();
    }

    // ---- server -------------------------------------------------------
    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: n => {
            const app = (n.appName || "").toLowerCase();
            const sum = n.summary || "";

            if (app === "kwrited" || sum === "Volume" || sum === "Brightness" || sum === "Touchpad") {
                n.dismiss();
                return;
            }

            const lsms = "local system message service";
            if (app.includes(lsms) || sum.toLowerCase().includes(lsms)) {
                n.dismiss();
                return;
            }

            if (sum === "Music" && (n.body === "Stopped" || n.body === "Playing")) {
                n.dismiss();
                return;
            }

            if (n.transient) {
                root._toast(n, "");
                return;
            }

            n.tracked = true;
            const key = root._add(n);
            root._toast(n, key);
        }
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", root._dir])
}
