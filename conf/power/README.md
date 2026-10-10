The local `omaconf.power` plugin preserves Omarchy's panel and actions,
but does not infer a charge threshold pause from power or estimated time.
A battery in UPower's `Charging` state keeps its charging icon even during
slow charging. `PendingCharge` and `FullyCharged` below 99% retain the
original panel's threshold handling.

The installer runs through `make setup`, preserves bar position and settings,
and regenerates the clone from the installed Omarchy version.
An incompatible upstream structure stops installation before any changes.
The power module continues to own the 75% charge limit policy.
