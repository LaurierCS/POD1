import 'dart:async'; //Required for recording and waitting.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart'; //
import 'package:audio_waveforms/audio_waveforms.dart'; //for recording and waveforms
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; //Used for date formatting
import 'package:path_provider/path_provider.dart'; //used for getting app directory
import 'package:fluttertoast/fluttertoast.dart'; //Used for making saved pop up
import 'package:voice_journal_app/Emotions_enums.dart';
import 'package:voice_journal_app/home.dart';
import 'package:voice_journal_app/theme.dart'; 
import 'package:http/http.dart' as http;
import 'schema.dart';
// To-do List:
// - Save file (Done)
// - Recording to data base (Done) 
// - Send the audio file to API (Not Done)
// ------Initializing Variables----
RecorderController controller = RecorderController();
String recordapiIp ="http://35.211.11.4:8000/api/recordings/"; //API IP addres
final recordUri = Uri.parse('http://35.211.11.4:8000/api/recordings/');
String path = '';
late DateTime presently; //what day/time is it presently? went with the shortest name I could think of
int secondsCounter = 0;
late Timer _timer;
String message = "Press the record button to start";
bool boxCreated = false;
bool recordingStarted = false;
bool recording = false; //Establish a bool to keep track of button state
bool transcribed = false; //Transcribed bool **just a placeholder for now**
late Directory appDirectory; //late meanning initializing later in code, but deffining it now
bool counting = false; //Counting bool to track if the counter has been started or not. Unsure if I can stop it so this bool is used to prevent double trigger (counting on 2s)
late String formattedDateTime; //Format date and time to work as a valid file name
late String file; //definning title for look up.
late Recording currentRecording;
late var rbox; //openj recording box (rbox)
// ------Done Initializing Variables----
void displaySaved(){ //Create a little pop up letting the user know their reccording has been saved
  Fluttertoast.showToast(
    msg: 'saved',
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,
    backgroundColor: const Color.fromARGB(0, 76, 175, 79),
    textColor: Colors.white,
    fontSize: 16.0,
  );
}
startRecording() async{
  formattedDateTime = DateFormat('yyy-MM-dd-HH-mm-ss').format(presently);
  file = '$formattedDateTime.m4a';
  controller.bitRate = 192000;
  controller.sampleRate = 50000;
  appDirectory = await getApplicationDocumentsDirectory();  //get the apps directory useful later
  //appDirectory = Directory('/storage/emulated/0/Download'); //Set directory for file to go to
  String exactDirectory = appDirectory.path;
  path = '$exactDirectory' '/$file';//Set the path to where it should go + the current date and time formatting with .m4a at the end
  rbox = Hive.box<Recording>('recordings');
  int key = rbox.length;
  currentRecording = Recording(id: '',title: formattedDateTime,audioFile: path,transcriptFile: '',timeStamp: presently,emotion:[],isTranscribed: false,transcriptionId:'', duration: 0,key: key); //create the recording class
  controller.record(path: path); //Actually start the recording
  message = 'Recording'; //change message to show recording
}
stopRecording() async{
  await controller.stop();
  //controller.dispose();
  if(counting){ //if the timer was started
    counting = false;//Don't count anymore
    _timer.cancel();
  }
  if(secondsCounter > 2){ //if something was recorded that's longer than a second then add it to the data base.
    var request = http.MultipartRequest('POST', recordUri);
    final httpRecording = await http.MultipartFile.fromPath('recording', path);
    request.files.add(httpRecording);
    final recordResponse = await request.send();
    String responseBody = await recordResponse.stream.bytesToString();
    Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
    String id = jsonResponse['id'];
    //var transcriptResponce = http.get(Uri.parse('$transcriptURi$id'));
    currentRecording.duration = secondsCounter;
    currentRecording.id = id;
    await rbox.put(currentRecording.key, currentRecording); //Add the recording to the database
  }
  secondsCounter = 0; //reset counter to 0
  message = 'Recording Stopped';
}
pauseRecording(){
  controller.pause(); //pause the recording
  message = 'Recording paused';
  displaySaved();
}
class RecordingPage extends StatefulWidget{
  const RecordingPage({super.key, required this.title, required this.callback}); //takes in call back function to call when this page is closed, this refreashes the widget tree on the homepage to update the recent recordings list.
  final String title;
  final VoidCallback callback;
  @override
  State<RecordingPage> createState() => _RecordingPageState();
}
class _RecordingPageState extends State<RecordingPage>{
    @override
  initState(){ //Page Initialization code, moved frome changed state.
    super.initState();
    presently = DateTime.now();
  }
  void _changeState() async{
    final hasPermission = await controller.checkPermission(); //get permission to use mic
    if(hasPermission){
      if(!recording){ //if currently not recording and the button has been hit`
        //recording = true; //recording is true
        await startRecording(); //wait for function to start the recording
        if(!counting){
          _startCounting(); //Starts the displayed recording counter
        }
      } else if(recording){ //else if we are recording and the button was hit
        //recording = false; //stop recording
        await pauseRecording();
      }
      setState(() { //set state (change button icon)
        recording = !recording;
      });
    } else{
      message = 'permissions denied, no recording allowed';
    }
  }
  void _startCounting(){ //start timer
    counting = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {  //This will repeat the counter+ line every second, increasing the counter.
        setState(() { //visual update
          if(recording){
            secondsCounter++; //if recording increase counter every second
          }
        });
    }
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
        body: Center(
       child: Column(
            //mainAxisAlignment: MainAxisAlignment.center, //center it
            children: <Widget>[
              const SizedBox(height: 40), // Add some spacing
              Container( //Container at the top of the page showing timer and recording status
                alignment: Alignment.center, //center align
                width: 370,
                height: 200,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                color: AppColors.secondaryColor,
                borderRadius: BorderRadius.circular(20),
                ),
                child: 
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:[
                    Text(message, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height:50), //Spacer
                    Text('${(secondsCounter~/60)}' ':' '${((secondsCounter~/10) %6).toStringAsFixed(0)}' '${secondsCounter % 10}', style: Theme.of(context).textTheme.headlineMedium),
                  ]
                ),

              ),
              const SizedBox(height: 30), //spacer
              Container( //This is the lower box which displays the audio waveforms.
                alignment: Alignment.center,
                width: 370,
                height:200,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(20),
                ),
                child: 
                  AudioWaveforms( //Wave form
                    size: Size(MediaQuery.of(context).size.height, 200.0),
                    recorderController: controller,
                    enableGesture: false,//makes it so you cant move around the waves by dragging your finger
                    waveStyle: const WaveStyle( //controls how the wave looks
                      waveColor: AppColors.mutedTeal,
                      showDurationLabel: false,
                      spacing: 4.0, //increase wave resolution/definition/ammount
                      showBottom: true, //Unsure what this does
                      extendWaveform: true,
                      showMiddleLine: false, //adds a red line to the middle of the box
                  ),
                ),
              ),
              PopScope(
                canPop: true,
                onPopInvoked: (bool didPop) async{
                  if(didPop){ //If the page has been closed
                        await stopRecording(); //Then stop the recording
                        widget.callback();
                    return;
                  }
                }, child: const Text(''),
              )
            ],
          ),
        ),
        appBar: AppBar(
          backgroundColor: AppColors.lightGray,
        ),
      floatingActionButton: Container( //Recording button
        margin: const EdgeInsets.only(bottom: 120),
        height: 70,
        width:70,
        // alignment: Alignment.center,
        child: FloatingActionButton(
          onPressed: _changeState,
          tooltip: 'Record',
          backgroundColor: AppColors.accentColor, //button background colour
          splashColor: Colors.red[200],     //button click animation
          child: recording ? const Icon(Icons.pause) : const Icon(Icons.play_arrow),
        ),
      ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, // Centers the button above the bar
    );
  }
}
