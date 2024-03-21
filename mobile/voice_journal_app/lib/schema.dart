import 'package:hive/hive.dart'; //Importing the local database
import 'package:voice_journal_app/Emotions_enums.dart';
 //----Start Of Database Setup----
@HiveType(typeId:0)
class Recording extends HiveObject{ //creating object class for database
    @HiveField(0) //declaring fields
    String id;
    @HiveField(1)
    String title;
    @HiveField(2)
    String audioFile;
    @HiveField(3)
    String transcriptFile;
    @HiveField(4)
    DateTime timeStamp;
    @HiveField(5)
    List<Emotions> emotion = []; //List of emotions
    @HiveField(6)
    bool isTranscribed;
    @HiveField(7)
    String transcriptionId;
    @HiveField(8)
    int duration;
    Recording({ //Declaring the actual recording class.
      required this.id, 
      required this.title, 
      required this.audioFile, 
      required this.transcriptFile, 
      required this.timeStamp, 
      required this.emotion, 
      required this.isTranscribed, 
      required this.transcriptionId,
      required this.duration
  });
}
class RecordingAdapter extends TypeAdapter<Recording>{ //create custom recording adapter, allows our database to interpret Recording class data.
  @override
  final typeId = 0;
  @override
  Recording read(BinaryReader reader){ //custom read function for the data base to allow it to read our specific class
    return Recording(
      id: reader.readString(),
      title: reader.readString(),
      audioFile: reader.readString(),
      transcriptFile: reader.readString(),
      timeStamp: reader.read(),
      emotion: _readEmotionsList(reader),
      isTranscribed: reader.readBool(),
      transcriptionId: reader.readString(),
      duration: reader.readInt(),

    );
  }
  @override
  void write(BinaryWriter writer, Recording obj) { //specific write class to allow hive to write recording class data
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.audioFile);
    writer.writeString(obj.transcriptFile);
    writer.write(obj.timeStamp);
    _writeEmotionsList(writer, obj.emotion);
    writer.writeBool(obj.isTranscribed);
    writer.writeString(obj.transcriptionId);
    writer.writeInt(obj.duration);
  }
    void _writeEmotionsList(BinaryWriter writer, List<Emotions> emotionsList) {
    writer.writeByte(emotionsList.length); // Write the list length

    for (final emotion in emotionsList) {
      writer.writeInt(emotion.index); // Store value of the integer
    }
  }
_readEmotionsList(BinaryReader reader) {
    final length = reader.readByte();
    final emotionsList = <Emotions>[];

    for (var i = 0; i < length; i++) {
      final emotionValue = reader.readInt(); // Read the integer value
      final emotion = _getEmotionFromValue(emotionValue); // Convert to Emotions object
      emotionsList.add(emotion);
    }

    return emotionsList;
  }

  Emotions _getEmotionFromValue(int value) { //get emotions from a int value from enum
    switch (value) {
      case 0:
        return Emotions.sad;
      case 1:
        return Emotions.happy;
      case 2:
        return Emotions.fear;
      case 3:
        return Emotions.contempt;
      case 4:
        return Emotions.surprise;
      case 5:
        return Emotions.anger;
      case 6:
        return Emotions.disgust;
      default:
        throw Exception('Invalid emotion value');
    }
  }

}
//----End of Database set up----