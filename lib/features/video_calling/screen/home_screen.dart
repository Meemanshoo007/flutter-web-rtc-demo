import 'package:flutter/material.dart';
import 'package:new_flutter_firebase_webrtc/common/app_icon/app_icon.dart';
import 'package:new_flutter_firebase_webrtc/common/background/rive_background.dart';
import 'package:new_flutter_firebase_webrtc/common/button/comp_fill_button.dart';
import 'package:new_flutter_firebase_webrtc/common/button/comp_outline_button.dart';
import 'package:new_flutter_firebase_webrtc/common/dialog/comp_dialog.dart';
import 'package:new_flutter_firebase_webrtc/features/audio_recorder/screen/audio_recorder_page.dart';
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
  const HomeUI({
    super.key,
    required this.signaling,
    required this.onCreateRoom,
    required this.onJoinRoom,
  });

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return RiveBackground(
      child: Center(
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
                    AppIconWidget(),

                    AppSpacing.vXl,
                    Text(
                      'Start Video Call',
                      style: themeNotifier.themeData.textTheme.headlineLarge,
                    ),

                    AppSpacing.vXs,
                    Text(
                      'Create a new room or join an existing one',
                      style: themeNotifier.themeData.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    // Version
                    AppSpacing.vSm,
                    Text(
                      'Version 1.1.10',
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
                    AppSpacing.vLg,
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecordingPage(),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.login_rounded, size: 24),
                            AppSpacing.hSm,
                            const Text('Test Transcription'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
