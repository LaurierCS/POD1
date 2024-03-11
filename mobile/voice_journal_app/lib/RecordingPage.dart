import 'dart:async'; //Required for recording and waitting.
import 'dart:io';
import 'package:flutter/material.dart'; //
import 'package:audio_waveforms/audio_waveforms.dart'; //for recording and waveforms
import 'package:intl/intl.dart'; //Used for date formatting
import 'package:path_provider/path_provider.dart'; //used for getting app directory
import 'package:fluttertoast/fluttertoast.dart';
import 'package:voice_journal_app/main.dart'; //Used for making saved pop up
// To-do List:
// - Save file (Done)
// - Recording to data base (Not Done) 
// - Send the audio file to API (Not Done Have not looked into Hive yet)
// ------Initializing Variables----
RecorderController controller = RecorderController();
String path = '';
late DateTime presently; //what day/time is it presently? went with the shortest name I could think of
int secondsCounter = 0;
late Timer _timer;
String message = "Press the record button to start";
Icon rcrdIcon = const Icon(Icons.mic_off_outlined);  
bool recording = false; //Establish a bool to keep track of button state
bool transcribed = false; //Transcribed bool **just a placeholder for now**
late Directory appDirectory; //late meanning initializing later in code, but deffining it now
bool counting = false; //Counting bool to track if the counter has been started or not. Unsure if I can stop it so this bool is used to prevent double trigger (counting on 2s)
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
  rcrdIcon = const Icon(Icons.pause);
  recording = true;
  final hasPermission = await controller.checkPermission(); //get permission to use mic
  //appDirectory = await getApplicationDocumentsDirectory();  //get the apps directory useful later
  appDirectory = Directory('/storage/emulated/0/Download'); //Set directory for file to go to
  String exactDirectory = appDirectory.path;
  presently = DateTime.now(); //Set presently string to date and time
  String formattedDateTime = DateFormat('yyy-MM-dd-HH-mm-ss').format(presently); //Format date and time to work as a valid file name
  path = '$exactDirectory' +'/$formattedDateTime.m4a';//Set the path to where it should go + the current date and time
  if(hasPermission){ //If we got phone permissions
    controller.record(path: path); //Record
  }
  message = 'Recording'; //change message to show recording
}
stopRecording(){
  if(counting){
    counting = false;//Don't count anymore
    _timer.cancel();
  }
    recording = false; //No longer recording
    controller.stop(); //Stop the recording controller
    secondsCounter = 0; //reset counter to 0
    rcrdIcon = const Icon(Icons.mic_off_outlined);  
    message = 'Recording Stopped';
}
pauseRecording(){
  recording = false; //not recording
  controller.pause(); //pause the recording
  rcrdIcon = const Icon(Icons.play_arrow);
  message = 'Recording paused';
  displaySaved();
}
class RecordingPage extends StatefulWidget{
  const RecordingPage({super.key, required this.title});
  final String title;
  @override
  State<RecordingPage> createState() => _RecordingPageState();
}
class _RecordingPageState extends State<RecordingPage>{
  void _changeState() async{
    if(!recording){ //if currently not recording and the button has been hit`
      recording = true; //recording is true
      await startRecording(); //wait for function to start the recording
      if(!counting){
        _startCounting(); //Starts the displayed recording counter
      }
      setState(() { //change state (icon of the button should change)
      });
    } else if(recording){ //else if we are recording and the button was hit
      recording = false; //stop recording
      await pauseRecording();
      setState(() { //set state (change button icon)
      });
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
              const SizedBox(height: 20), // Add some spacing
              const SizedBox(height: 20), // Add some spacing
              Container( //Container at the top of the page showing timer and recording status
                alignment: Alignment.center, //center align
                width: 370,
                height: 200,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                color: Colors.orange[100],
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
                width: 370,
                height:200,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                color: Colors.blue[400],
                borderRadius: BorderRadius.circular(20),
                ),
                child: 
                  AudioWaveforms( //Wave form
                    size: Size(MediaQuery.of(context).size.height, 200.0),
                    recorderController: controller,
                    enableGesture: false,//makes it so you cant move around the waves by dragging your finger
                    waveStyle: const WaveStyle( //controls how the wave looks
                      waveColor: Colors.white,
                      showDurationLabel: false,
                      spacing: 4.0, //increase wave resolution/definition/ammount
                      showBottom: true, //Unsure what this does
                      extendWaveform: true,
                      showMiddleLine: false, //adds a red line to the middle of the box
                  ),
                ),
              ),
            ],
          ),
        ),
        appBar: AppBar(

          
        ),
      floatingActionButton: Container( //Recording button
        margin: const EdgeInsets.only(bottom: 120),
        height: 70,
        width:70,
        // alignment: Alignment.center,
        child: FloatingActionButton(
          onPressed: _changeState,
          tooltip: 'Record',
          backgroundColor: Colors.red[200], //button background colour
          splashColor: Colors.red[500],     //button click animation
          child: rcrdIcon,
        ),
      ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, // Centers the button above the bar
    );
  }
}
