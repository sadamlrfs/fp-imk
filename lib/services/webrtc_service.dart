import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  RTCPeerConnection? _pc;
  MediaStream? _localStream;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  bool _initialized = false;

  // Callbacks to wire up signaling
  void Function(RTCIceCandidate)? onLocalIceCandidate;
  void Function(MediaStream)? onRemoteStream;
  void Function()? onConnectionEstablished;
  void Function()? onConnectionFailed;

  static const Map<String, dynamic> _iceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  bool get isInitialized => _initialized;
  bool get hasLocalStream => _localStream != null;

  Future<void> initialize(bool isVideo) async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': isVideo
            ? {
                'facingMode': 'user',
                'width': {'ideal': 640},
                'height': {'ideal': 480},
              }
            : false,
      });
      localRenderer.srcObject = _localStream;
      _initialized = true;
    } catch (e) {
      debugPrint('WebRTC getUserMedia error: $e');
      // Try audio only as fallback
      try {
        _localStream =
            await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
        localRenderer.srcObject = _localStream;
        _initialized = true;
      } catch (e2) {
        debugPrint('WebRTC audio-only fallback error: $e2');
      }
    }
  }

  Future<RTCPeerConnection> _buildPC() async {
    final pc = await createPeerConnection(_iceConfig);

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate != null && candidate.candidate!.isNotEmpty) {
        onLocalIceCandidate?.call(candidate);
      }
    };

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams.first;
        onRemoteStream?.call(event.streams.first);
      }
    };

    pc.onConnectionState = (state) {
      debugPrint('WebRTC connection state: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        onConnectionEstablished?.call();
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        onConnectionFailed?.call();
      }
    };

    // Add local tracks to peer connection
    _localStream?.getTracks().forEach((track) {
      pc.addTrack(track, _localStream!);
    });

    return pc;
  }

  Future<Map<String, dynamic>> createOffer() async {
    _pc = await _buildPC();
    final offer = await _pc!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': true,
    });
    await _pc!.setLocalDescription(offer);
    return {'sdp': offer.sdp, 'type': offer.type};
  }

  Future<Map<String, dynamic>> createAnswer(Map<String, dynamic> offerPayload) async {
    _pc = await _buildPC();
    final offer = RTCSessionDescription(offerPayload['sdp'], offerPayload['type']);
    await _pc!.setRemoteDescription(offer);
    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    return {'sdp': answer.sdp, 'type': answer.type};
  }

  Future<void> setRemoteAnswer(Map<String, dynamic> answerPayload) async {
    final answer = RTCSessionDescription(answerPayload['sdp'], answerPayload['type']);
    await _pc?.setRemoteDescription(answer);
  }

  Future<void> addRemoteIceCandidate(Map<String, dynamic> candidatePayload) async {
    try {
      final candidate = RTCIceCandidate(
        candidatePayload['candidate'],
        candidatePayload['sdpMid'],
        candidatePayload['sdpMLineIndex'],
      );
      await _pc?.addCandidate(candidate);
    } catch (e) {
      debugPrint('addRemoteIceCandidate error: $e');
    }
  }

  void setMicEnabled(bool enabled) {
    _localStream?.getAudioTracks().forEach((t) => t.enabled = enabled);
  }

  void setCameraEnabled(bool enabled) {
    _localStream?.getVideoTracks().forEach((t) => t.enabled = enabled);
  }

  Future<void> switchCamera() async {
    final videoTrack = _localStream?.getVideoTracks().firstOrNull;
    if (videoTrack != null) {
      await Helper.switchCamera(videoTrack);
    }
  }

  Future<void> dispose() async {
    _initialized = false;
    try {
      await _localStream?.dispose();
    } catch (_) {}
    try {
      await _pc?.close();
    } catch (_) {}
    try {
      localRenderer.dispose();
    } catch (_) {}
    try {
      remoteRenderer.dispose();
    } catch (_) {}
    _localStream = null;
    _pc = null;
  }
}
