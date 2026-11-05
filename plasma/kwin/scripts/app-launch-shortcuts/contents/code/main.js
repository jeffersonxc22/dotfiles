function launch(unit) {
    callDBus("org.freedesktop.systemd1", "/org/freedesktop/systemd1",
        "org.freedesktop.systemd1.Manager", "StartUnit", unit, "replace");
}

registerShortcut("Open Kitty window", "Open Kitty window", "", function () {
    launch("shortcut-kitty.service");
});

registerShortcut("Open Chrome window", "Open Chrome window", "", function () {
    launch("shortcut-chrome.service");
});

registerShortcut("Open Claude", "Open Claude", "", function () {
    launch("shortcut-claude.service");
});
