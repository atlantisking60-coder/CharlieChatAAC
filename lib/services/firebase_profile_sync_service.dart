import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../firebase_options.dart';
import 'board_service.dart';
import 'profile_service.dart';

/// Result of comparing a user's local board against the admin's latest version.
class AdminUpdate {
  final String boardId;
  final String boardName;
  final String reason;
  final int adminRevision;
  final Map<String, dynamic> adminPayload;
  final Map<String, dynamic>? userPayload;

  const AdminUpdate({
    required this.boardId,
    required this.boardName,
    required this.reason,
    required this.adminRevision,
    required this.adminPayload,
    this.userPayload,
  });
}

enum AdminResolution {
  overwrite,
  append,
  keep,
}

/// Handles cloud storage and admin distribution of profiles/boards using
/// Firebase (Firestore for data, Storage for image assets).
class FirebaseProfileSyncService {
  FirebaseProfileSyncService._();
  static final FirebaseProfileSyncService _instance =
      FirebaseProfileSyncService._();
  static FirebaseProfileSyncService get instance => _instance;

  FirebaseFirestore? _firestore;
  FirebaseStorage? _storage;

  bool get _configured => FirebaseConfigValidator.isConfigured();

  Future<void> _ensureInitialized() async {
    if (!_configured) {
      throw StateError(
        'Firebase is not configured. Please update lib/firebase_options.dart '
        'with your real Firebase project values.',
      );
    }
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    _firestore ??= FirebaseFirestore.instance;
    _storage ??= FirebaseStorage.instance;
  }

  /// Upload an entire profile and its custom boards to Firestore.
  Future<void> uploadProfile(
    UserProfile profile, {
    List<Board>? boards,
    String? ownerUid,
  }) async {
    await _ensureInitialized();

    final doc = _firestore!
        .collection('profiles')
        .doc(profile.onlineId.isEmpty ? profile.id : profile.onlineId);

    final boardMaps = <Map<String, dynamic>>[];
    for (final board in boards ?? <Board>[]) {
      boardMaps.add({
        'id': board.id,
        'name': board.name,
        'area': board.area,
        'data': board.toMap(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }

    await doc.set({
      'id': profile.id,
      'onlineId': profile.onlineId,
      'name': profile.name,
      'role': profile.role,
      'ownerUid': ownerUid,
      'profileData': profile.toMap(),
      'boards': boardMaps,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Download a profile by its public onlineId.
  Future<UserProfile?> downloadProfile(String onlineId) async {
    await _ensureInitialized();
    final doc =
        await _firestore!.collection('profiles').doc(onlineId).get();
    if (!doc.exists) return null;
    final data = doc.data()?['profileData'] as Map<String, dynamic>?;
    if (data == null) return null;
    return UserProfile.fromMap(Map<String, dynamic>.from(data));
  }

  /// Download a board for a given profile.
  Future<Board?> downloadBoard(String onlineId, String boardId) async {
    await _ensureInitialized();
    final doc =
        await _firestore!.collection('profiles').doc(onlineId).get();
    if (!doc.exists) return null;
    final boards = doc.data()?['boards'] as List<dynamic>?;
    if (boards == null) return null;
    for (final b in boards) {
      final m = b as Map<String, dynamic>;
      if (m['id'] == boardId || m['name'] == boardId) {
        final data = m['data'] as Map<String, dynamic>?;
        if (data != null) {
          return Board.fromMap(Map<String, dynamic>.from(data));
        }
      }
    }
    return null;
  }

  /// Fetch the current admin version of a board.
  Future<Board?> downloadAdminBoard(String boardId) async {
    await _ensureInitialized();
    final doc = await _firestore!.collection('admin_boards').doc(boardId).get();
    if (!doc.exists) return null;
    final data = doc.data()?['data'] as Map<String, dynamic>?;
    if (data == null) return null;
    return Board.fromMap(Map<String, dynamic>.from(data));
  }

  /// Push an admin board to the public `admin_boards` collection.
  Future<void> pushAdminBoard(
    Board board, {
    String? note,
  }) async {
    await _ensureInitialized();
    final doc = _firestore!.collection('admin_boards').doc(board.id);
    await doc.set({
      'id': board.id,
      'name': board.name,
      'area': board.area,
      'data': board.toMap(),
      'note': note,
      'revision': board.version,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Check the admin collection for newer versions of boards this profile uses.
  Future<List<AdminUpdate>> checkForAdminUpdates(
    UserProfile profile,
    List<Board> localBoards,
  ) async {
    await _ensureInitialized();
    final adminSnapshots =
        await _firestore!.collection('admin_boards').get();
    final updates = <AdminUpdate>[];

    for (final adminDoc in adminSnapshots.docs) {
      final adminData = adminDoc.data();
      final adminBoard = Board.fromMap(
        Map<String, dynamic>.from(adminData['data'] as Map<String, dynamic>),
      );
      final adminRevision = (adminData['revision'] as num?)?.toInt() ?? 1;

      final local = localBoards.firstWhere(
        (b) => b.id == adminBoard.id || b.name == adminBoard.name,
        orElse: () => Board(
          id: '',
          name: '',
          area: '',
          columns: 0,
          rows: 0,
          tiles: const [],
        ),
      );

      if (local.id.isEmpty) continue;

      final localRevision = local.version;
      if (adminRevision > localRevision) {
        updates.add(AdminUpdate(
          boardId: local.id,
          boardName: local.name,
          reason: 'Admin version is newer',
          adminRevision: adminRevision,
          adminPayload: adminData['data'] as Map<String, dynamic>,
          userPayload: local.toMap(),
        ));
      }
    }
    return updates;
  }

  /// Resolve an admin update for a board on the local profile.
  Future<Board> resolveAdminUpdate(
    Board localBoard,
    Board adminBoard,
    AdminResolution resolution,
  ) async {
    final adminVersionId = adminBoard.version.toString();
    switch (resolution) {
      case AdminResolution.overwrite:
        return adminBoard.copyWith(
          version: adminBoard.version,
          adminUpdatePending: false,
          adminVersionId: adminVersionId,
        );
      case AdminResolution.append:
        final mergedTiles = [...localBoard.tiles, ...adminBoard.tiles];
        final newVersion =
            (localBoard.version > adminBoard.version ? localBoard.version : adminBoard.version) + 1;
        return localBoard.copyWith(
          tiles: mergedTiles,
          version: newVersion,
          adminUpdatePending: false,
          adminVersionId: adminVersionId,
        );
      case AdminResolution.keep:
        final newVersion = localBoard.version > adminBoard.version
            ? localBoard.version
            : adminBoard.version;
        return localBoard.copyWith(
          version: newVersion,
          adminUpdatePending: false,
          adminVersionId: adminVersionId,
        );
    }
  }

  /// Upload a symbol image asset to Firebase Storage for remote access.
  Future<String?> uploadImageAsset(String localPath, String onlineId) async {
    await _ensureInitialized();
    // Web and desktop paths are handled differently; this is a stub for the
    // upload flow that should be completed per-platform.
    throw UnimplementedError('Image asset upload not yet wired.');
  }
}
