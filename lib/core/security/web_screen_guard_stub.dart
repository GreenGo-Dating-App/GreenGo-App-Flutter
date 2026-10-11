/// Non-web builds: there is no browser shim to attach to.
bool attachWebScreenGuard(void Function(String event) onEvent) => false;

/// Non-web builds: nothing to toggle.
void setWebScreenGuardEnabled(bool enabled) {}
