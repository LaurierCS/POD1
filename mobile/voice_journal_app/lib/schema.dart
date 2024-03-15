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
    Emotions emotion;
    @HiveField(6)
    bool isTranscribed;
    @HiveField(7)
    String transcriptionId;
    @HiveField(8)
    int durration;
    Recording({ //Declaring the actual recording class.
      required this.id, 
      required this.title, 
      required this.audioFile, 
      required this.transcriptFile, 
      required this.timeStamp, 
      required this.emotion, 
      required this.isTranscribed, 
      required this.transcriptionId,
      required this.durration
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
      emotion: Emotions.values[reader.readInt()],
      isTranscribed: reader.readBool(),
      transcriptionId: reader.readString(),
      durration: reader.readInt(),

    );
  }
  @override
  void write(BinaryWriter writer, Recording obj) { //specific write class to allow hive to write recording class data
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.audioFile);
    writer.writeString(obj.transcriptFile);
    writer.write(obj.timeStamp);
    writer.writeInt(obj.emotion.index);
    writer.writeBool(obj.isTranscribed);
    writer.writeString(obj.transcriptionId);
    writer.writeInt(obj.durration);
  }
}
//----End of Database set up----