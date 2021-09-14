
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';


void main(){
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
      )
    );
}

class Home extends StatefulWidget{
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home>{
  String statusText = "😎";
  String? wifiName, wifiIPv4;
  String baseDir = "/sdcard/Download";
  //default port to 8888
  int portNo = 8888;
  String serverUrl = "http://";

  final NetworkInfo _networkInfo = NetworkInfo();
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
    _initNetworkInfo();
  }

  //Handling Wifi network connection
  Future<void> _initNetworkInfo() async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        var status = await _networkInfo.getLocationServiceAuthorization();
        if (status == LocationAuthorizationStatus.notDetermined) {
          status = await _networkInfo.requestLocationServiceAuthorization();
        }
        if (status == LocationAuthorizationStatus.authorizedAlways ||
            status == LocationAuthorizationStatus.authorizedWhenInUse) {
          wifiName = await _networkInfo.getWifiName();
        } else {
          wifiName = await _networkInfo.getWifiName();
        }
      } else {
        wifiName = await _networkInfo.getWifiName();
      }
      debugPrint('android device wifi name : $wifiName');
    } on Exception catch (e) {
      print(e.toString());
    }

    try {
      wifiIPv4 = await _networkInfo.getWifiIP();
    } on Exception catch (e) {
      print(e.toString());
    }
  }

  startServer() async{

    debugPrint("User inputted dir ${dirController.text}");
    debugPrint("User inputted port ${portController.text}");

    //Assign user inputted dir and port
    if(dirController.text != '')
      baseDir = dirController.text;
    if(portController.text != '')
      portNo = int.parse(portController.text);


    setState((){
      statusText = "Starting server on port : "+portNo.toString();
      debugPrint('Inside startServer()');
    });
if (await Permission.storage.request().isGranted) {
    debugPrint('is wifiName there ? : $wifiName');
    if(wifiName != null){ // wifiName detected start the server 
      HttpServer
      .bind(wifiIPv4.toString(), portNo)
      .then((server) {
        setState(() {
            statusText = "Server successfully started on "+wifiIPv4.toString()+":"+portNo.toString();
            serverUrl = serverUrl+wifiIPv4.toString()+":"+portNo.toString();
        });
        server.listen((HttpRequest request) async{
          debugPrint('Received request ${request.method}: ${request.uri.path}');
          switch(request.method){
            case 'GET':
              String currDir = '';
              if(request.uri.path == '/')//For first GET add base url to '/'
                currDir = baseDir + Uri.decodeFull(request.uri.path);
              else
                currDir = Uri.decodeFull(request.uri.path);
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
                    baseResponse = baseResponse + '<li><a href="${currDir+fileName}">$fileName</a>';
                  else //Current item is a directory
                    baseResponse = baseResponse + '<li><a href="${currDir+fileName+'/'}">$fileName</a>';
                }
                baseResponse = baseResponse + '</body></html>';
                request.response.headers.contentType =new ContentType('text','html',charset : 'utf-8');
                request.response.write(baseResponse);
                request.response.close();
                debugPrint("Directory download: $dirFiles");
              }
              // Not a file or directory can be read from filesystem throw error
              else{
                debugPrint("Error reading File/Directory");
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
    }
    else// No wifi connection detected no point in server start 
        statusText = "No wifi connection detected, please connect to a wifi network to start server";

  }else{
    setState(() {
      statusText = "Need file storage permissions to serve files";
    });
  }

  }
  @override
    Widget build(BuildContext context){
      return Scaffold(
        body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(),
            child: Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                TextField(
                  controller: dirController,
                  decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Enter the directory path'
                  )
                ),
                TextField(
                  controller: portController,
                  decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Enter the port no'
                  )
                ),
                ElevatedButton(
                  onPressed: (){
                    startServer();
                  },
                  child: Text("Start Server"),
                ),
                Text(statusText),
                QrImage(data: serverUrl)
              ],
            ),
            
          ),
        ),)
      );
    }
}