
import 'package:flutter/material.dart';
//import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';

Widget MyAppIcon(){
  return Image.asset('assets/icon/icon.PNG', width: 50, height: 50);
}
void main(){
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
      )
    );
}

class PortRangeFormatter extends TextInputFormatter {
  final double min;
  final double max;

  PortRangeFormatter({required this.min, required this.max}): assert(
          min < max,
        );

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue,TextEditingValue newValue,) { 
    if(newValue.text == '')
      return TextEditingValue();
    else if(int.parse(newValue.text) < min)
      return TextEditingValue().copyWith(text: '1024');

    return int.parse(newValue.text) > max ? TextEditingValue().copyWith(text: '65535') : newValue;
  }
}

class Home extends StatefulWidget{
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home>{
  String statusText = "Server not started";
  String? wifiName, wifiIPv4;
  String baseDir = "/sdcard/Download";
  //default port to 8888
  int portNo = 8888;
  String serverUrl = "http://";
  bool canStartServer = true;
  var _myLogFileName = "ServeIt.log";
  var _tag = "ServeIt";
  var myserver;
  

  final dirController = TextEditingController();
  final portController = TextEditingController();
  //File handler

  @override
    void dispose() {
      // Clean up the controller when the widget is disposed.
      dirController.dispose();
      portController.dispose();
      super.dispose();
    }


  File getFile(fileName){
    File getFile = new File(fileName);
    return getFile;
  }

  // Directory handler
  List getDir(dirName){
    Directory thisDir = new Directory(dirName);
    List dirFiles = thisDir.listSync();
    return dirFiles;
  }

  @override
  void initState(){
    super.initState();
    setUpLogs();
  }

  void getWifiIP() async{
    wifiIPv4 = null;
    //Handling Wifi IP Address
    debugPrint("Interfaces Detected ${NetworkInterface.list()}");
    for (var interface in await NetworkInterface.list()) {
      debugPrint('Interface Detected : ${interface.name}');
      if(interface.name == 'wlan0'){
          for (var addr in interface.addresses){
            debugPrint('IP Type : ${addr.type.name}');
            if(addr.type.name == 'IPv4'){
              wifiIPv4 = addr.address;
              debugPrint('IP Type : ${addr.address}');
              break;
            }
          }
          break;
      }
    }
  }

  void _selectFolder() async {
    try {
      String? path = await FilePicker.platform.getDirectoryPath();
      if(path != null){
        baseDir = path;
        dirController.text = baseDir;
      }
    } catch (e) {
      debugPrint(e.toString());
      FlutterLogs.logError(_tag, "_selectFolder()", "Error choosing dir ${e.toString()}");
    }
  }

  void setUpLogs() async {
    await FlutterLogs.initLogs(
        logLevelsEnabled: [
          LogLevel.INFO,
          LogLevel.WARNING,
          LogLevel.ERROR,
          LogLevel.SEVERE
        ],
        timeStampFormat: TimeStampFormat.TIME_FORMAT_READABLE,
        directoryStructure: DirectoryStructure.FOR_DATE,
        logTypesEnabled: [_myLogFileName],
        logFileExtension: LogFileExtension.LOG,
        logsWriteDirectoryName: "MyLogs",
        logsExportDirectoryName: "MyLogs/Exported",
        debugFileOperations: true,
        isDebuggable: true);

    // [IMPORTANT] The first log line must never be called before 'FlutterLogs.initLogs'
    FlutterLogs.logInfo(_tag, "setUpLogs()", "setUpLogs: Setting up logs..");
  }

  startServer() async{
    
    getWifiIP();

    debugPrint("User inputted dir ${dirController.text}");
    debugPrint("User inputted port ${portController.text}");
    FlutterLogs.logInfo(_tag, "startServer()", "User inputted dir ${dirController.text}");
    FlutterLogs.logInfo(_tag, "startServer()", "User inputted port ${portController.text}");

    //Assign user inputted dir and port
    if(dirController.text != '')
      baseDir = dirController.text;
    if(portController.text != '')
      portNo = int.parse(portController.text);


   /* setState((){
      //statusText = "Starting server on port : "+portNo.toString();
      debugPrint('Inside startServer()');
    });*/
  if (await Permission.manageExternalStorage.request().isGranted || await Permission.storage.request().isGranted) {
      debugPrint('is wifiName there ? : $wifiName');
      debugPrint('wifiIPv4 : ${wifiIPv4.toString()}');
      FlutterLogs.logInfo(_tag, "startServer()", 'is wifiName there ? : $wifiName');
      FlutterLogs.logInfo(_tag, "startServer()", 'wifiIPv4 : ${wifiIPv4.toString()}');
    
      if(wifiIPv4 == null){ // wifiName can be null sometimes, hence using 127.0.0.1 when no ip address has been assigned 
        wifiIPv4 = "127.0.0.1";
      }
      HttpServer
      .bind(InternetAddress.anyIPv4, portNo)
      .then((server) {
        setState(() {
            myserver = server;// server instance will be required for stopServer()
            statusText = "Server started on http://"+wifiIPv4.toString()+":"+portNo.toString();
            serverUrl = serverUrl+wifiIPv4.toString()+":"+portNo.toString();
            canStartServer = false;
        });
        server.listen((HttpRequest request) async{
          debugPrint('Received request ${request.method}: ${request.uri.path}');
          FlutterLogs.logInfo(_tag, "server.listen()", 'Received request ${request.method}: ${request.uri.path}');
          switch(request.method){
            case 'GET':
              String currDir = Uri.decodeFull(request.uri.path);
              if(request.uri.path == '/')//For first GET add base url to '/'
                currDir = baseDir + Uri.decodeFull(request.uri.path);
              if (File(currDir + "index.html").existsSync()) {
                debugPrint("Served Index File index.html from $currDir ");
                currDir += "index.html";
                File indexFile = getFile(currDir);
                var sink = indexFile.openRead();
                request.response.headers.contentType =new ContentType('text','html',charset : 'utf-8');
                await request.response.addStream(sink);
                request.response.flush();
                request.response.close();

                
                FlutterLogs.logInfo(_tag, "server.listen()", "Served Index File: $currDir");
                break;
              }
              
              //If request is for a file, send the file in response to client
              if(File(currDir).existsSync()){
                File downloadFile = getFile(currDir);
                var sink = downloadFile.openRead();
                String fileName = Uri.decodeFull(request.uri.path);

                List filePath = fileName.split('/');//Get filename from request path
                fileName = filePath.last;

                fileName = fileName.replaceAll(new RegExp(r'[^a-zA-Z0-9.]'), '_');//Sanitize filename to send in response

                request.response.headers.add("Content-Disposition", "attachment;  filename=$fileName");
                await request.response.addStream(sink);
                request.response.flush();
                request.response.close();
                
                debugPrint("File download: $downloadFile");
                FlutterLogs.logInfo(_tag, "server.listen()", "File download: $downloadFile");
          
              }

              //If request is for a directory, add a link so that user can access the directory
              else if(Directory(currDir).existsSync()){
                String baseResponse = "<html><head><h1><p>Directory listing</p></h1></head><body>";
                List dirFiles = getDir(currDir);
                for(var i=0; i<dirFiles.length; i++){
                  List fileNamePath = dirFiles[i].toString().split('/');
                  String fileName = fileNamePath.last.toString();
                  String fileOrDir = fileNamePath.first.toString();
                  fileName = fileName.substring(0,fileName.length - 1);

                  if(fileOrDir.contains('File')) //Current item is a File
                    baseResponse = baseResponse + '<li>📄<a href="${currDir+fileName}">$fileName</a>';
                  else //Current item is a directory
                    baseResponse = baseResponse + '<li>📂<a href="${currDir+fileName+'/'}">$fileName</a>';
                }
                baseResponse = baseResponse + '</body><footer>Copyright &copy; Viki Inc 2021</footer></html>';
                request.response.headers.contentType =new ContentType('text','html',charset : 'utf-8');
                request.response.write(baseResponse);
                request.response.close();
                debugPrint("Directory download: $dirFiles");
                FlutterLogs.logInfo(_tag, "server.listen()", "Directory download: $dirFiles");
          
              }
              // Not a file or directory can be read from filesystem throw error
              else{
                debugPrint("Error reading File/Directory");
                FlutterLogs.logInfo(_tag, "server.listen()", 'Error reading File/Directory ${request.method}: $currDir ');

                request.response.write('Error reading File/Directory ${request.method}: $currDir ');
                request.response.close();
              }
              
              break;
            default:
              request.response.write('Cannot ${request.method}: ${request.uri.path} ');
              request.response.close();
              break;

            }
        });
      });
      
    }else{
      setState(() {
        statusText = "Need file storage permissions to serve files";
        FlutterLogs.logInfo(_tag, "Permission.storage.request() not Granted", "Need file storage permissions to serve files");
      });
    }

  }

  stopServer(){
    myserver.close(force : true);
    setState(() {// invoke widget build and change setState()
      canStartServer = true;
      statusText = "Server stopped";
    });
  }

  @override
    Widget build(BuildContext context){
      return Scaffold(
        appBar: AppBar(
          title: const Text('ServeIt')
         ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  'ServeIt',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                onTap: () async{
                  debugPrint("About Page clicked");
                  PackageInfo packageInfo = await PackageInfo.fromPlatform();
                  showAboutDialog(
                    context: context,
                    applicationName: packageInfo.appName,
                    applicationVersion: packageInfo.version,
                    applicationIcon: MyAppIcon(),
                    children: [
                        Text(
                        "Created by Viki Inc",
                        textAlign: TextAlign.left
                      )
                    ]
                  );
                },
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(),
            child: Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(55.0),
                  child: Container(
                    width: 300.0,
                    child: TextField(
                      controller: dirController,
                      decoration: InputDecoration(
                      border: new OutlineInputBorder(
                          borderRadius: new BorderRadius.circular(25.0),
                          borderSide: new BorderSide(
                          ),
                        ),
                      hintText: "Directory path",
                    )
                  )
                  ),
                ),
                ElevatedButton(
                          onPressed: () => _selectFolder(),
                          child: const Text('Choose directory'),
                        )
                ,
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Container(
                      width: 80.0,
                      height: 40.0,
                      child: TextField(
                      controller: portController,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(5),
                        PortRangeFormatter(min: 1, max: 65535) //Accept only possible port no range
                      ],
                      decoration: InputDecoration(
                      border: new OutlineInputBorder(
                            borderRadius: new BorderRadius.circular(15.0),
                            borderSide: new BorderSide(
                            ),
                          ),
                      hintText: "Port",

                      contentPadding: EdgeInsets.all(10.0),
                      ),
                    )
                  )
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children : <Widget> [ ElevatedButton(
                      onPressed: !canStartServer ? null : (){ // Disable Start Server button based on flag
                        startServer();
                      },
                      child: Text("Start Server")
                    ),
                    ElevatedButton(
                      onPressed: canStartServer ? null : (){
                        stopServer();
                      },
                       child: Text("Stop Server"))
                  ]
                ),
                AnimatedTextKit(
                  key: UniqueKey(),
                  animatedTexts: [
                    TypewriterAnimatedText(statusText)
                  ],
                  onTap: () async{
                    if (statusText.contains('started')){
                      final statusArray = statusText.split(' ');
                      var _url = statusArray[statusArray.length-1];
                      if (!await launch(_url)) {
                        throw Exception('Could not launch $_url');
                      }
                    }
                    
                  },
                ),
                QrImage(data: serverUrl, size: 300.0,),
              ],
            ),
            
          ),
        ),)
      );
    }
}