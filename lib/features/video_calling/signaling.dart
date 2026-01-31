import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:new_flutter_firebase_webrtc/utils/print/print.dart';

class Signaling {
  FirebaseFirestore db = FirebaseFirestore.instance;
  String? _roomId;

  final Map<String, dynamic> _configurationServer = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {
        'urls': 'turn:global.relay.metered.ca:80',
        'username': 'ff9db3b54b9fae3ac2ccd6dc',
        'credential': '/HQd62yJI3kOBqV/',
      },
      {
        'urls': 'turn:global.relay.metered.ca:80?transport=tcp',
        'username': 'ff9db3b54b9fae3ac2ccd6dc',
        'credential': '/HQd62yJI3kOBqV/',
      },
      {
        'urls': 'turns:global.relay.metered.ca:443',
        'username': 'ff9db3b54b9fae3ac2ccd6dc',
        'credential': '/HQd62yJI3kOBqV/',
      },
    ],
  };

  final Map<String, dynamic> offerSdpConstraints = {
    "mandatory": {"OfferToReceiveAudio": true, "OfferToReceiveVideo": true},
    "optional": [],
  };

  RTCPeerConnection? _rtcPeerConnection;
  MediaStream? _localStream;
  late Function(MediaStream stream) onLocalStream;
  late Function(MediaStream stream) onAddRemoteStream;
  late Function() onRemoveRemoteStream;
  late Function() onDisconnect;
  String currentRole = 'unknown';
  Future<String?> createRoom() async {
    try {
      currentRole = 'caller';
      final roomRef = db.collection('rooms').doc();

      _roomId = roomRef.id;

      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio_recorder': true,
        'video': {'facingMode': 'user'},
      });

      onLocalStream.call(_localStream!);

      _rtcPeerConnection = await createPeerConnection(_configurationServer);

      registerPeerConnectionListeners();

      _localStream!.getTracks().forEach((track) {
        _rtcPeerConnection!.addTrack(track, _localStream!);
      });

      final callerCandidatesCollection = roomRef.collection('callerCandidates');

      _rtcPeerConnection!.onIceCandidate = ((RTCIceCandidate? candidate) {
        if (candidate == null) {
          compPrint('Got final candidate!');
          return;
        }
        final candidateMap = candidate.toMap();

        callerCandidatesCollection.add(candidateMap);
      });

      final offer = await _rtcPeerConnection!.createOffer(offerSdpConstraints);
      await _rtcPeerConnection!.setLocalDescription(offer);

      final roomWithOffer = {
        'offer': offer.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      await roomRef.set(roomWithOffer);

      _rtcPeerConnection!.onTrack = (RTCTrackEvent event) {
        onAddRemoteStream.call(event.streams[0]);
      };

      roomRef.snapshots().listen((snapshot) async {
        final data = snapshot.data();
        if (data != null && data.containsKey('answer')) {
          final rtcSessionDescription = RTCSessionDescription(
            data['answer']['sdp'],
            data['answer']['type'],
          );
          await _rtcPeerConnection!.setRemoteDescription(rtcSessionDescription);
        }
      });

      roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
        snapshot.docChanges.forEach((change) async {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();

            await _rtcPeerConnection!.addCandidate(
              RTCIceCandidate(
                data?['candidate'],
                data?['sdpMid'],
                data?['sdpMlineIndex'],
              ),
            );
          }
        });
      });

      return _roomId;
    } catch (e) {
      compPrint('Error creating room: $e');
      return null;
    }
  }

  Future<String> joinRoomById(String roomId) async {
    try {
      currentRole = 'callee';
      _roomId = roomId;

      final roomRef = db.collection('rooms').doc(_roomId);
      final roomSnapshot = await roomRef.get();

      if (!roomSnapshot.exists) {
        return 'Invalid Room';
      }

      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio_recorder': true,
        'video': {'facingMode': 'user'},
      });
      onLocalStream.call(_localStream!);

      _rtcPeerConnection = await createPeerConnection(_configurationServer);
      registerPeerConnectionListeners();

      _localStream!.getTracks().forEach((MediaStreamTrack track) {
        _rtcPeerConnection!.addTrack(track, _localStream!);
      });

      final calleeCandidatesCollection = roomRef.collection('calleeCandidates');

      _rtcPeerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
        if (candidate == null) {
          return;
        }

        calleeCandidatesCollection.add(candidate.toMap());
      };

      _rtcPeerConnection!.onTrack = (RTCTrackEvent event) {
        onAddRemoteStream.call(event.streams[0]);
      };

      final offer = roomSnapshot.data()?['offer'];

      await _rtcPeerConnection!.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );

      final RTCSessionDescription answer = await _rtcPeerConnection!
          .createAnswer(offerSdpConstraints);

      await _rtcPeerConnection!.setLocalDescription(answer);

      final roomWithAnswer = {'answer': answer.toMap()};
      await roomRef.update(roomWithAnswer);

      roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
        snapshot.docChanges.forEach((change) async {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();

            await _rtcPeerConnection!.addCandidate(
              RTCIceCandidate(
                data?['candidate'],
                data?['sdpMid'],
                data?['sdpMlineIndex'],
              ),
            );
          }
        });
      });

      return '';
    } catch (e) {
      return e.toString();
    }
  }

  void muteMic() {
    if (_localStream != null && _localStream!.getAudioTracks().isNotEmpty) {
      bool enabled = _localStream!.getAudioTracks()[0].enabled;
      _localStream!.getAudioTracks()[0].enabled = !enabled;
    }
  }

  Future<void> hungUp() async {
    _localStream?.getTracks().forEach((track) {
      track.stop();
    });

    onRemoveRemoteStream();

    if (_rtcPeerConnection != null) {
      _rtcPeerConnection!.close();
    }

    if (_roomId != null) {
      final roomRef = db.collection('rooms').doc(_roomId);
      final calleeCandidates = await roomRef
          .collection('calleeCandidates')
          .get();
      calleeCandidates.docs.forEach((candidate) async {
        await candidate.reference.delete();
      });
      final callerCandidates = await roomRef
          .collection('callerCandidates')
          .get();
      callerCandidates.docs.forEach((candidate) async {
        await candidate.reference.delete();
      });
      await roomRef.delete();
    }
  }

  void registerPeerConnectionListeners() {
    _rtcPeerConnection!.onIceGatheringState = (RTCIceGatheringState state) {};

    _rtcPeerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _localStream?.getTracks().forEach((track) {
          track.stop();
        });
        onRemoveRemoteStream();
        if (_rtcPeerConnection != null) {
          _rtcPeerConnection!.close();
        }
        onDisconnect();
      }
    };

    _rtcPeerConnection!.onSignalingState = (RTCSignalingState state) {
      compPrint('Signaling state change: $state');
    };

    _rtcPeerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      compPrint('ICE connection state change: $state');
    };
  }
}
