import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
// To-do List:
// - Save file (Done)
// - Recording to data base (Not Done) 
// - Send the audio file to API (Not Done Have not looked into Hive yet)
// ------Initializing Variables----
RecorderController controller = RecorderController();
String path = '';
int secondsCounter = 0;
String message = "Press the record button to start";
Icon rcrdIcon = const Icon(Icons.mic_off_outlined);  
bool recording = false; //Establish a bool to keep track of button state
bool transcribed = false; //Transcribed bool **just a placeholder for now**
late Directory appDirectory; //late meanning initializing later in code, but deffining it now
// ------Done Initializing Variables----
startRecording() async{
  rcrdIcon = const Icon(Icons.pause);
  recording = true;
  final hasPermission = await controller.checkPermission(); //get permission to use mic
  //appDirectory = await getApplicationDocumentsDirectory();  //get the apps directory useful later
  appDirectory = Directory('/storage/emulated/0/Download'); //Set directory for file to go to.
   path = "${appDirectory.path}/recording.m4a";//Set the path to where it should go + the name
   if(hasPermission){ //If we got phone perm
    controller.record(path: path); //Record
   }
  message = 'Recording';
}
stopRecording(){
    recording = false;
    controller.stop(); //Stop the recording controller
    secondsCounter = 0;
    rcrdIcon = const Icon(Icons.mic_off_outlined);  
    message = 'Recording Stopped';
}
pauseRecording(){
  recording = false;
  controller.pause();
  rcrdIcon = const Icon(Icons.play_arrow);
  message = 'Recording paused';
}

void main() {
  runApp(const MainApp());
}
class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'recording page',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const RecordingPage(title: "recordingPage"),
    );
  }
}
class RecordingPage extends StatefulWidget{
  const RecordingPage({super.key, required this.title});
  final String title;
  @override
  State<RecordingPage> createState() => _RecordingPageState();
}
class _RecordingPageState extends State<RecordingPage>{
  late Timer _timer;

  bool counting = false; //Counting bool to track if the counter has been started or not. Unsure if I can stop it so this bool is used to prevent double trigger (counting on 2s)
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
  void _startCounting(){
    counting = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {  //This will repeat the counter+ line every second, increasing the counter.
      setState(() {
        if(recording){
          secondsCounter++;
        }
      });
    }
    );
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording Page'),
        actions:[
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: (){
              if(!recording){ //If not currently recording
                stopRecording(); //Stop the recording (onoce stopped it cannot be started again)
               // message = "Recording Endded"; //Display recording ended
               setState((){
               });
              }else{ //If the recording is running
                showDialog(context: context, builder:(BuildContext context){ //Create a pop up
                  return AlertDialog(
                    title: const Text('uhhh. You sure?'),// Title:
                    content: const Text('Are you sure you want to exit this page and stop recording?'), //Contents of the pop up
                    actions:[
                      TextButton(
                        onPressed:(){
                          Navigator.of(context).pop(); //close the dialog box
                        },
                        child: const Text('No')
                      ),
                      TextButton(
                        onPressed:(){
                          Navigator.of(context).pop(); //close the dialog box
                          stopRecording();
                          setState((){ //Refreshing display after calling function
                          });
                        }, child: const Text('Yes'),
                      ),
                    ],
                  );
                },
              );
                //message = 'Hey!\nPlease pause the recording before trying to close this page';
              }
            },
          )
        ]
      ),
        body: Center(
       child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20), // Add some spacing
              Container(
                alignment: Alignment.center,
                width: 500,
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
                width: 500,
                height:200,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                color: Colors.blue[400],
                borderRadius: BorderRadius.circular(20),
                ),
                child: 
                  AudioWaveforms(
                    size: Size(MediaQuery.of(context).size.height, 200.0),
                    recorderController: controller,
                    enableGesture: false,
                    waveStyle: const WaveStyle(
                      waveColor: Colors.white,
                      showDurationLabel: false,
                      spacing: 4.0,
                      showBottom: true,
                      extendWaveform: false,
                      showMiddleLine: false,
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Container(
        height: 70,
        width:70,
        child: FloatingActionButton(
          onPressed: _changeState,
          tooltip: 'Record',
          backgroundColor: Colors.red[200], //button background colour
          splashColor: Colors.red[500],     //button click animation
          child: rcrdIcon,
        ),
      ),
    );
  }
}
