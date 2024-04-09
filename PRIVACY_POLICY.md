## ServeIt: Privacy policy

This is an open source Android app developed by Vignesh Nandakumar. The source code is available on GitHub under the GNU GPLv3 license


### Data collected by the app

I hereby state, to the best of my knowledge and belief, that I have not programmed this app to collect any personally identifiable information. All data (app preferences (like theme) and alarms) created by the you (the user) is stored locally in your device only, and can be simply erased by clearing the app's data or uninstalling it. No analytics software is present in the app either.

### Explanation of permissions requested in the app

The list of permissions required by the app can be found in the `AndroidManifest.xml` file:

https://github.com/many-fac3d-g0d/ServeIt/blob/05aa0b72757520886b3e124ae4d2acc17bad90da/android/app/src/main/AndroidManifest.xml
<br/>

| Permission | Why it is required |
| :---: | --- |
| `android.permission.WRITE_EXTERNAL_STORAGE` | Used to write files uploaded from the http server started by the app to the User specified directory for sharing inside local network. |
| `android.permission.READ_EXTERNAL_STORAGE` | Used to read the files from User specified directory and serve it via the http server started by the app inside local network. |
| `android.permission.MANAGE_EXTERNAL_STORAGE` | Used to read all files from the User specified directory, not just media files. |

 <hr style="border:1px solid gray">

If you find any security vulnerability that has been inadvertently caused by me, or have any question regarding how the app protectes your privacy, please send me an email or post a discussion on GitHub, and I will surely try to fix it/help you.

Vignesh Nandakumar
(vignesh.nandakumar.dev@gmail.com)
