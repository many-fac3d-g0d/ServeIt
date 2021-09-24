# ServeIt

A simple http-server on android using flutter.

## Getting Started

One app to serve them all

This app can start a http-server from an android/ios device binding to the port specified by the user (default 8888) and expose a directory from the device specified by the user (default dir /sdcard/Downloads).

Any device connected to the same wifi network and with a web browser, can navigate to the server url or scan the QR code to access the directory exposed

## Authentication

Currently there is no authentication from app end. The app assumes anyone connected to the same wifi network as the user is already authenticated. Do not use the app in a public wifi.

## License

This project and its contents are open source under the [MIT License](https://github.com/darekkay/dashboard/blob/master/LICENSE)
