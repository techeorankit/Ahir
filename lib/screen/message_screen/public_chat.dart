import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart' as html_core;  // Alias the flutter_widget_from_html_core
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart' as image_picker_lib;  // Alias the image_picker
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shortzz/common/functions/media_picker_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../common/manager/logger.dart';
import '../../common/manager/session_manager.dart';
import '../../common/service/api/common_service.dart';
import '../../utilities/const_res.dart';


class PublicChatScreen extends StatefulWidget {
  final String groupId; // use camelCase for variables
  final String groupName; // use camelCase for variables

  const PublicChatScreen(this.groupId,this.groupName, {super.key}); // pass via constructor

  @override
  State<PublicChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<PublicChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String name = "";
  int userId=0 ;

  @override
  void initState() {
    super.initState();
    initializeChat();
  }

  Future<void> initializeChat() async {

    userId =  SessionManager.instance.getUserID();
    name = SessionManager.instance.getUser()!.fullname.toString();

    print("namename $userId");
  }

  void _sendMessage() async {

    if (_controller.text.isNotEmpty) {
      await _firestore.collection('groups').doc(widget.groupId).collection('messages').add({
        'text': _controller.text,
        'sender': userId ?? 'Anonymous',
        'name': name ?? 'Anonymous',
        'timestamp': FieldValue.serverTimestamp(),
      });
      _controller.clear();
      _scrollToBottom();
    }

  }
  void _sendImage(String image) async {

    if (image.isNotEmpty) {
      await _firestore.collection('groups').doc(widget.groupId).collection('messages').add({
        'text': '',
        'imageVideo': image,
        'sender': userId ?? 'Anonymous',
        'name': name ?? 'Anonymous',
        'timestamp': FieldValue.serverTimestamp(),
      });
      _controller.clear();
      _scrollToBottom();
    }

  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }


  Future<String> getAddress(double lat, double lng) async {
    final placemarks = await placemarkFromCoordinates(lat, lng);
    final place = placemarks.first;
    return '${place.street}, ${place.locality}';
  }
  Widget locationBubble(double lat, double lng) {
    final url = 'https://www.google.com/maps?q=$lat,$lng';

    return InkWell(
      onTap: () async {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade700,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.location_on, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Live Location',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> locationUpload() async {
    final position = await getCurrentLocation();

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .add({
      'type': 'location',
      'latitude': position.latitude,
      'longitude': position.longitude,
      'sender': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }


  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location service enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled';
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permission denied';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission permanently denied';
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }


// Assuming your existing CommonService and Loggers are set up correctly
  Future<void> imageUpload() async {
    // Pick image or video
    final image_picker_lib.ImagePicker _picker = image_picker_lib.ImagePicker();
    XFile? pickedFile;

    // Show options to pick either an image or a video
    final pickedMedia = await showDialog<MediaType>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Pick Media", style: TextStyle(color: Colors.black)),
            actions: <Widget>[
            TextButton(
              child: Text("Pick Image"),
              onPressed: () => Navigator.of(context).pop(MediaType.image),
            ),
            TextButton(
              child: Text("Pick Video"),
              onPressed: () => Navigator.of(context).pop(MediaType.video),
            ),
          ],
        );
      },
    );

    // If user cancels the dialog
    if (pickedMedia == null) {
      return;
    }

    try {
      if (pickedMedia == MediaType.image) {
        pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      } else if (pickedMedia == MediaType.video) {
        pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
      }

      if (pickedFile != null) {
        // Proceed to upload the selected media
        await CommonService.instance
            .uploadFileGivePath(XFile(pickedFile.path))
            .then((result) {
          if (result.status == true && result.data != null) {
            // uploadedImagePaths.add(result.data!);
            Loggers.success('Media uploaded: ${result.data}');

            _sendImage(result.data.toString());
          } else {
            Loggers.error('Media upload failed: ${result.message}');
            // deleteFiles([pickedFile.path]);
            return Loggers.error('Media upload failed: ${result.message}');
          }
        });
      } else {
        Loggers.error('No media selected');
      }
    } catch (e) {
      Loggers.error('Error uploading media: $e');
      return Loggers.error('Error uploading media: $e');
    }
  }

// Enum for media type




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff131b28),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        // Set back button/icon color

        backgroundColor: const Color(0xff252d3a),
        title:  Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.group, color: Colors.white),
            ),
            SizedBox(width: 15),
            Text(widget.groupName,
                style: TextStyle(fontSize: 14, color: Colors.white)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('groups').doc(widget.groupId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                _scrollToBottom();
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final data = message.data() as Map<String, dynamic>;

                    final String text = data['text'] ?? '';
                    final int sender = data['sender'] ?? '';
                    final String name = data['name'] ?? '';
                    final String imageVideo = data['imageVideo'] ?? '';

                    final isMe = sender == userId;

                    if (data['type'] == 'location') {
                      return locationBubble(
                        data['latitude'],
                        data['longitude'],
                      );
                    }


                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isMe)
                            const CircleAvatar(
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xff222e3a),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(10),
                                  topRight: const Radius.circular(10),
                                  bottomLeft: Radius.circular(isMe ? 10 : 0),
                                  bottomRight: Radius.circular(isMe ? 0 : 10),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    GestureDetector(
                                      onTap: () {
                                        // Navigator.push(
                                        //   context,
                                        //   MaterialPageRoute(
                                        //     builder: (context) =>
                                        //         PrivateChatScreen(
                                        //           contactName: name,
                                        //           contactAvatar:
                                        //           'Chat',
                                        //           receiverId: sender,
                                        //           message: '',
                                        //         ),
                                        //   ),
                                        // );
                                      },
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  if (!isMe) const SizedBox(height: 5),

                                  buildMediaWidget(imageVideo,text)


                                ],
                              ),
                            ),
                          ),
                          if (isMe) const SizedBox(width: 10),
                          if (isMe)
                            const CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: Colors.black54,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                    onTap: _scrollToBottom,
                  ),
                ),

                IconButton(
                  onPressed: locationUpload,
                  icon: const Icon(Icons.location_on_rounded, color: Colors.grey),
                ),
                IconButton(
                  onPressed: imageUpload,
                  icon: const Icon(Icons.image, color: Colors.grey),
                ),

                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: Colors.blue),
                ),


              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Assuming imageVideo is a string that holds the file path or URL

Widget buildMediaWidget(String imageVideo, String text) {
  if (imageVideo.isEmpty) {
    // If imageVideo is empty, show text
    return Text(
      text,
      style: const TextStyle(color: Colors.white),
    );
  } else if (imageVideo.contains(".mp4")) {
    // If it's a video (contains .mp4), show the video player
    return AnimalCardItem(imagePath: imageVideo);
  } else {
    // Otherwise, treat it as an image
    return Image.network(storageURL+imageVideo);  // Or use Image.file() if it's a local path
  }
}

class AnimalCardItem extends StatefulWidget {
  final String imagePath;


  const AnimalCardItem({required this.imagePath, super.key});

  @override
  State<AnimalCardItem> createState() => _AnimalCardItemState();
}

class _AnimalCardItemState extends State<AnimalCardItem> {
  VideoPlayerController? _videoController;

  void _initializeVideoControllerIfNeeded() async {
    final videoUrl;
    videoUrl = storageURL + widget.imagePath;

    print(videoUrl);

    if (widget.imagePath.contains(".mp4")) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.network(videoUrl);

      await _videoController!.initialize();
      _videoController!.setLooping(true);

      // if(widget.type=='1'){
      //   _videoController!.play(); // Auto-play
      //
      // }

      if (mounted) {
        setState(() {});
      }
    } else {
      _videoController?.dispose();
      _videoController = null;
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeVideoControllerIfNeeded();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
    setState(() {}); // Refresh UI
  }

  void _seekBy(Duration offset) {
    final newPosition = _videoController!.value.position + offset;
    _videoController!.seekTo(newPosition);
  }

  @override
  Widget build(BuildContext context) {
    if (_videoController != null && _videoController!.value.isInitialized) {
       return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
              IconButton(
                icon: Icon(
                  _videoController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
                onPressed: _togglePlayPause,
              ),
            ],
          ),
          VideoProgressIndicator(
            _videoController!,
            allowScrubbing: true,
            padding: const EdgeInsets.only(top: 6),
          ),
        ],
      );

    } else {
      return const CircularProgressIndicator();
    }
  }
}
