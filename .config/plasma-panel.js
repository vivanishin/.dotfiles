// Restore the standard Plasma 6.8 panel and configure its clocks and calendars.
// Run manually after setting up Plasma on a new host, after losing a panel,
// or to reapply these preferences. Requires an active Plasma session; this
// script is not registered for automatic startup.
// Command:
// qdbus6 org.kde.plasmashell /PlasmaShell \
//   org.kde.PlasmaShell.evaluateScript "$(cat ~/.config/plasma-panel.js)"
// Re-running is a no-op when a panel exists and its clocks match the settings.
// Changes made in Plasma's UI must currently be copied into this script by hand.
// See plasma-panel.md for recovery limitations and future options.
//
// Future option: a Git clean filter could keep selected layout settings while
// stripping volatile fields such as popup sizes, screen geometry, and migration
// state. Define the allowlist and checkout/restoration behavior first so that a
// checkout never replaces the live layout with an incomplete filtered file.
// https://git-scm.com/docs/gitattributes#_filter

var panelList = panels();
if (panelList.length === 0) {
    loadTemplate("org.kde.plasma.desktop.defaultPanel");
    panelList = panels();
    if (panelList.length === 0) {
        throw new Error("Could not create the standard Plasma panel");
    }
}

var clockSettings = {
    dateFormat: "isoDate",
    showWeekNumbers: true,
    firstDayOfWeek: 1 // Sunday is 0; Monday is 1.
};
var clockCount = 0;
for (var panelIndex = 0; panelIndex < panelList.length; ++panelIndex) {
    var widgetList = panelList[panelIndex].widgets();
    for (var widgetIndex = 0; widgetIndex < widgetList.length; ++widgetIndex) {
        var clock = widgetList[widgetIndex];
        if (clock.type !== "org.kde.plasma.digitalclock") {
            continue;
        }
        clock.currentConfigGroup = ["Appearance"];
        var needsReload = false;
        for (var settingName in clockSettings) {
            var value = clockSettings[settingName];
            if (String(clock.readConfig(settingName, "")) !== String(value)) {
                clock.writeConfig(settingName, value);
                needsReload = true;
            }
        }
        if (needsReload) {
            clock.reloadConfig();
        }
        ++clockCount;
    }
}
print("Panels: " + panelList.length + "; configured clocks: " + clockCount);
