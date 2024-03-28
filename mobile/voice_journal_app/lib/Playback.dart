import 'package:audio_waveforms/audio_waveforms.dart'; //for recording and waveforms
import 'package:hive/hive.dart';
import 'theme.dart';
import 'package:flutter/material.dart';
import 'schema.dart';
//----Initializing vairables----
String title ='';
String audioFile ='';
bool playing = false;
late PlayerController controller;
int duration = 0;
//----Done Initializing variables----

displayRecording(Recording givenRecording) async{ //function to get information out of the recording being shown
  title = givenRecording.title;
  audioFile = givenRecording.audioFile;
  duration = givenRecording.duration;
  if(givenRecording.isTranscribed){
    //get transcription file here.
  }
  controller = PlayerController();
  audioPlayerPrep(); //Initialize the audio player
}
playbackRecording()async { //play the playback
  await controller.startPlayer(finishMode: FinishMode.loop); //start playback, loop recording when we get to the end of it.
}
pauseRecording()async { //pause the playback
  await controller.pausePlayer(); //pause recording
}
audioPlayerPrep()async{ //initialize the audio player
  await controller.preparePlayer( //prepare it
    path: audioFile, //fetch the given file
    shouldExtractWaveform: true, //Get the sound wave
    noOfSamples: 50, //how big the sound wave is
    volume: 10, //how loud it is
  );
  controller.updateFrequency = UpdateFrequency.medium; //controller visual update speed
}
class PlaybackPage extends StatefulWidget{
  const PlaybackPage({super.key, required this.title});
  final String title;
  @override
  State<PlaybackPage> createState() => _PlaybackPageState();
}
class _PlaybackPageState extends State<PlaybackPage>{
  @override
  initState(){ //Page Initialization code, moved frome changed state.
    super.initState();
    controller.onCompletion.listen((event){ pauseRecording(); setState((){playing = !playing;});}); //add a listener so that when the file ends it pauses. This allows the user to loop their recording as many times as they want, but they just have to hit the play button to do so
  }
  changeState(){
    if(playing){ //If the recording is playing
      pauseRecording(); //pause it
    } else{ //if the recording is not playing
      playbackRecording(); //play it
    }
    setState(() { //visual update for the pause and play button
      playing = !playing;
    });
  }
  @override
  Widget build(BuildContext context) {
    //audioPlayerPrep();
    return Scaffold(
      body: Center(
        child: Column(
          children: <Widget>[
            AppBar(
              backgroundColor: AppColors.lightGray,
              title: Text(title),
            ), //Creating an app bar to have the back button on the top of the page
            const SizedBox(height: 40),
            Container(
              alignment: Alignment.center,
              width: 370,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.secondaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[ 
                  if(duration > 1)
                  AudioFileWaveforms(
                    size: Size(MediaQuery.of(context).size.width, 200.00),
                    playerController: controller,
                    waveformType: WaveformType.long,
                    playerWaveStyle: const PlayerWaveStyle(
                      fixedWaveColor: AppColors.accentColor,
                      liveWaveColor: AppColors.pastelYellow,
                      spacing: 4,
                    ),
                  ),
                  if(duration < 1)
                  const Text('File is too small to display waveform')
                ],
              ),
            ),  
            const SizedBox(height: 30),
            Container( //Will be used to display how far in the recording we've played so far.
              alignment: Alignment.center,
              width: 370,
              height: 350,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
                child: 
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:[
                    Text('Transcript will go here'),
                  ]
                ),
            ),
            PopScope(
              canPop:true,
              onPopInvoked: (bool didPop){
                if(didPop){
                  controller.stopAllPlayers();
                  controller.dispose();
                  playing = false;
                }
              }, child: const Text(' '),
            )
          ],
        ),
      ),
      floatingActionButton: Container( //Recording button
        alignment: Alignment.bottomCenter,
        margin: const EdgeInsets.only(bottom: 120),
        height: 70,
        width:70,
        // alignment: Alignment.center,
        child: FloatingActionButton(
          onPressed: changeState,
          tooltip: 'Record',
          backgroundColor: AppColors.accentColor, //button background colour
          splashColor: Colors.red[200],     //button click animation
          child: playing ? const Icon(Icons.pause) : const Icon(Icons.play_arrow),
        ),
      ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, // Centers the button above the bar
    );
  }

}
