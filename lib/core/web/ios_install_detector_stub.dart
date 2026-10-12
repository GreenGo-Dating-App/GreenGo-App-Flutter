/// Non-web builds: native apps are installed by definition.
bool isIosBrowserNotInstalled() => false;

/// Non-web builds: never an iOS browser / home-screen web app.
bool isIosWebDevice() => false;
