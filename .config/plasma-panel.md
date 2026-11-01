# Plasma panel preferences

`plasma-panel.js` records the intended settings separately from Plasma's
generated layout. It creates the standard panel if there are no panels,
then configures the digital clocks in existing panels:

- ISO dates (`yyyy-MM-dd`);
- week numbers in the popup calendar;
- Monday as the first day of the week.

If a panel already exists, the script keeps its layout and configures any
digital clocks it contains. It does not add missing widgets to an existing
panel. With matching values, it skips configuration writes and reloads.

## Manual setup and recovery

Run this command in an active Plasma session on a new host, after losing a
panel, or to reapply the recorded preferences:

```sh
qdbus6 org.kde.plasmashell /PlasmaShell \
  org.kde.PlasmaShell.evaluateScript "$(cat ~/.config/plasma-panel.js)"
```

The script has no automatic startup or monitoring. It has to be run manually
after a reset. Changes made through Plasma's UI must be copied into the
script to preserve them in Git.

Plasma normally saves its live settings in
`~/.config/plasma-org.kde.plasma.desktop-appletsrc`, so ordinary logins do
not require rerunning the script. That file is ignored by Git: it mixes
preferences with widget IDs, screen mappings, popup dimensions, migration
state, and discovered system tray widgets. An accidental reset or overwrite
can therefore lose the live settings without a Git version to restore.
The script preserves a recovery recipe, not a backup of the whole layout.

## Possible future changes

- **Automatic startup:** run the script after Plasma's D-Bus service becomes
  available at login. This would reapply the selected settings and recreate
  a panel if none exists. It would also override later UI edits to those
  settings at the next login; it would not repair resets during the session.
- **Selective export:** export an explicit list of preferences from the live
  layout into a separate tracked file, with a matching restore command.
  This would capture UI changes without tracking unrelated runtime state.
- **Git content filter:** use a `clean` filter to store a normalized layout
  containing selected settings while leaving the full working file for
  Plasma. Define the allowlist, required identifiers, and checkout/restore
  behavior first: checking out a filtered file must produce a usable layout,
  rather than replace the live file with an incomplete configuration.

See the [Git filter documentation](https://git-scm.com/docs/gitattributes#_filter).
