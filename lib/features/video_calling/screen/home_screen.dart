import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:new_flutter_firebase_webrtc/common/app_icon/app_icon.dart';
import 'package:new_flutter_firebase_webrtc/common/button/comp_fill_button.dart';
import 'package:new_flutter_firebase_webrtc/common/button/comp_outline_button.dart';
import 'package:new_flutter_firebase_webrtc/common/dialog/comp_dialog.dart';
import 'package:new_flutter_firebase_webrtc/features/video_calling/dialog/room_created_dialog.dart';
import 'package:new_flutter_firebase_webrtc/features/video_calling/dialog/join_room_dialog.dart';
import 'package:new_flutter_firebase_webrtc/features/video_calling/signaling.dart';
import 'package:new_flutter_firebase_webrtc/utils/constants/sizes.dart';
import 'package:new_flutter_firebase_webrtc/utils/sizing/app_sizing.dart';
import 'package:new_flutter_firebase_webrtc/utils/theme/controller/theme_controller.dart';
import 'package:provider/provider.dart';

class HomeUI extends StatelessWidget {
  final Signaling? signaling;
  final Function(String roomId) onCreateRoom;
  final Function(String roomId) onJoinRoom;
  HomeUI({
    super.key,
    required this.signaling,
    required this.onCreateRoom,
    required this.onJoinRoom,
  });

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            alignment: Alignment.center,
            width: constraints.maxWidth < 600
                ? constraints.maxWidth
                : constraints.maxWidth / 2,
            child: Padding(
              padding: const EdgeInsets.all(TSizes.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  AppIconWidget(),

                  AppSpacing.vXl,
                  // Title
                  Text(
                    'Start Video Call',
                    style: themeNotifier.themeData.textTheme.headlineLarge,
                  ),

                  AppSpacing.vXs,
                  // Subtitle
                  Text(
                    'Create a new room or join an existing one',
                    style: themeNotifier.themeData.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  // Version
                  AppSpacing.vSm,
                  Text(
                    'Version 1.1.3',
                    style: themeNotifier.themeData.textTheme.labelMedium,
                    textAlign: TextAlign.center,
                  ),

                  AppSpacing.vXl,
                  AppSpacing.vXl,
                  CompFillButton(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Create Room',
                    onPressed: () async {
                      try {
                        if (signaling == null) {
                          throw Exception('Signaling is null');
                        }

                        final lRoomId = await signaling?.createRoom();

                        if (lRoomId != null) {
                          showDialog(
                            context: context,
                            builder: (context) =>
                                RoomCreatedDialog(lRoomId: lRoomId),
                          );

                          onCreateRoom(lRoomId);
                        }
                      } catch (e) {
                        print("object $e");
                      }
                    },
                  ),

                  // Join Room Button
                  AppSpacing.vLg,
                  CompOutlineButton(
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder: (context) => JoinRoomDialog(
                          onRoomSelected: (roomId) async {
                            if (roomId.isEmpty) {
                              CompDialog.show(
                                context: context,
                                message: "Must enter room id",
                                dialogStyle: DialogStyle.error,
                              );
                            } else {
                              onJoinRoom(roomId);
                            }
                          },
                        ),
                      );
                    },
                    title: 'Join Room',
                    icon: Icons.login_rounded,
                  ),
                  // AppSpacing.vLg,
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: OutlinedButton(
                  //     onPressed: () async {
                  //       String? url = await uploadImageAndSaveToFirestore();
                  //       if (url != null) {
                  //         print('Uploaded Image URL: $url');
                  //       }
                  //
                  //       // Navigator.push(
                  //       //   context,
                  //       //   MaterialPageRoute(
                  //       //     builder: (context) => const TranscriptionTestPage(),
                  //       //   ),
                  //       // );
                  //     },
                  //     child: Row(
                  //       mainAxisAlignment: MainAxisAlignment.center,
                  //       children: [
                  //         const Icon(Icons.login_rounded, size: 24),
                  //         AppSpacing.hSm,
                  //         const Text('Test Transcription'),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String?> uploadImageAndSaveToFirestore() async {
    try {
      print('STEP 1: Function called');

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      print('STEP 2: Image picked -> ${image?.name}');

      if (image == null) {
        print('STOP: User cancelled image picker');
        return null;
      }

      Uint8List imageBytes = await image.readAsBytes();
      print('STEP 3: Image bytes length -> ${imageBytes.length}');

      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance.ref('images/$fileName.jpg');

      print('STEP 4: Uploading image...');
      await storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      print('STEP 5: Upload completed');

      String downloadUrl = await storageRef.getDownloadURL();
      print('STEP 6: Download URL -> $downloadUrl');

      await FirebaseFirestore.instance.collection('images').add({
        'imageUrl': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('STEP 7: Firestore saved');

      return downloadUrl;
    } catch (e, st) {
      print('ERROR: $e');
      print(st);
      return null;
    }
  }
}
