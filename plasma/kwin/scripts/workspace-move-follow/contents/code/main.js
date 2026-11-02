for (let index = 0; index < 10; index++) {
    const number = index + 1;
    registerShortcut("Move and follow desktop " + number,
        "Move window and follow to desktop " + number, "", function () {
            const window = workspace.activeWindow;
            const desktop = workspace.desktops[index];
            if (!window || !desktop || !window.normalWindow)
                return;
            window.desktops = [desktop];
            workspace.currentDesktop = desktop;
            workspace.activeWindow = window;
        });
}

registerShortcut("Minimize desktop windows", "Minimize desktop windows", "", function () {
    const desktop = workspace.currentDesktop;
    const windows = workspace.stackingOrder;
    for (const window of windows) {
        if (window.normalWindow && window.minimizable && !window.minimized &&
            (window.desktops.length === 0 || window.desktops.indexOf(desktop) !== -1))
            window.minimized = true;
    }
});
