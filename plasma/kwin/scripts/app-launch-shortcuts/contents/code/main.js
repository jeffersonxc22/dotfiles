function launch(unit) {
    callDBus("org.freedesktop.systemd1", "/org/freedesktop/systemd1",
        "org.freedesktop.systemd1.Manager", "StartUnit", unit, "replace");
}

registerShortcut("Open Kitty window", "Open Kitty window", "", function () {
    launch("shortcut-kitty.service");
});

registerShortcut("Open browser window", "Open browser window", "", function () {
    launch("shortcut-browser.service");
});

registerShortcut("Open Claude", "Open Claude", "", function () {
    launch("shortcut-claude.service");
});
