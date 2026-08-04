/// Single source of truth for the board hierarchy across all 7 areas.

///

/// Each entry defines: board name, which area it belongs to, and its parent

/// board (null = top-level / tier 1). Tier is derived from the parent chain.

///

/// Two layers are merged at runtime:

/// 1. Static compiled hierarchy ([boardHierarchy]) — prebuilt boards baked

///    into the Dart source. When the admin profile creates, moves or edits a

///    board, the change is written DIRECTLY to this source file via the dev

///    server (POST /saveHierarchy). The admin layer IS the static layer.

/// 2. User custom hierarchy — boards created by individual users, stored

///    per-user in SharedPreferences. Only visible to that user.

///

/// Board ID prefixes:

/// - prebuilt_ — static / admin-created boards (available to everyone)

/// - {username}_ — user-created boards (personal to that user)



library;



import 'dart:convert';



import 'package:shared_preferences/shared_preferences.dart';



class BoardHierarchyEntry {

  final String name;

  final String area;

  final String? parentName;



  const BoardHierarchyEntry(this.name, this.area, [this.parentName]);



  Map<String, dynamic> toJson() => {

    'name': name,

    'area': area,

    if (parentName != null) 'parentName': parentName,

  };



  factory BoardHierarchyEntry.fromJson(Map<String, dynamic> json) =>

    BoardHierarchyEntry(

      json['name'] as String,

      json['area'] as String,

      json['parentName'] as String?,

    );

}



const List<BoardHierarchyEntry> boardHierarchy = [

  // ──────────────────────────────────────────────

  //  COMMON AREA  (matches AREA_COMMON.md tab + hierarchy order)

  // ──────────────────────────────────────────────

  BoardHierarchyEntry('Common Words', 'Common'),

  BoardHierarchyEntry('Small Words', 'Common'),

  BoardHierarchyEntry('Noun', 'Common', 'Small Words'),

  BoardHierarchyEntry('Proper Noun', 'Common', 'Small Words'),

  BoardHierarchyEntry('Abstract Noun', 'Common', 'Small Words'),

  BoardHierarchyEntry('Collective Noun', 'Common', 'Small Words'),

  BoardHierarchyEntry('Article', 'Common', 'Small Words'),

  BoardHierarchyEntry('Pronoun', 'Common', 'Small Words'),

  BoardHierarchyEntry('Adjective', 'Common', 'Small Words'),

  BoardHierarchyEntry('Transitive Verb', 'Common', 'Small Words'),

  BoardHierarchyEntry('Intransitive Verb', 'Common', 'Small Words'),

  BoardHierarchyEntry('Linking Verb', 'Common', 'Small Words'),

  BoardHierarchyEntry('Auxiliary Verb', 'Common', 'Small Words'),

  BoardHierarchyEntry('Adverb', 'Common', 'Small Words'),

  BoardHierarchyEntry('Preposition', 'Common', 'Small Words'),

  BoardHierarchyEntry('Conjunction', 'Common', 'Small Words'),

  BoardHierarchyEntry('Interjection', 'Common', 'Small Words'),

  BoardHierarchyEntry('Gerund', 'Common', 'Small Words'),

  BoardHierarchyEntry('Participle', 'Common', 'Small Words'),

  BoardHierarchyEntry('Other', 'Common', 'Small Words'),

  BoardHierarchyEntry('Letters', 'Common'),

  BoardHierarchyEntry('Phonics', 'Common', 'Letters'),

  BoardHierarchyEntry('Phase 2 Phonics', 'Common', 'Phonics'),

  BoardHierarchyEntry('Phase 3 Phonics', 'Common', 'Phonics'),

  BoardHierarchyEntry('Phase 4 Phonics', 'Common', 'Phonics'),

  BoardHierarchyEntry('Phase 5 Phonics', 'Common', 'Phonics'),

  BoardHierarchyEntry('Phase 6 Phonics', 'Common', 'Phonics'),

  BoardHierarchyEntry('Numbers', 'Common'),

  BoardHierarchyEntry('Feelings', 'Common'),

  BoardHierarchyEntry('Sad', 'Common', 'Feelings'),

  BoardHierarchyEntry('Mad', 'Common', 'Feelings'),

  BoardHierarchyEntry('Scared', 'Common', 'Feelings'),

  BoardHierarchyEntry('Joyful', 'Common', 'Feelings'),

  BoardHierarchyEntry('Strong', 'Common', 'Feelings'),

  BoardHierarchyEntry('Calm', 'Common', 'Feelings'),

  BoardHierarchyEntry('Actions', 'Common'),

  BoardHierarchyEntry('Movement', 'Common', 'Actions'),

  BoardHierarchyEntry('People', 'Common'),

  BoardHierarchyEntry('School People', 'Common', 'People'),

  BoardHierarchyEntry('Places', 'Common'),

  BoardHierarchyEntry('Buildings', 'Common', 'Places'),

  BoardHierarchyEntry('Rooms and Home', 'Common', 'Places'),

  BoardHierarchyEntry('Home Management', 'Common', 'Rooms and Home'),

  BoardHierarchyEntry('Furniture', 'Common', 'Rooms and Home'),

  BoardHierarchyEntry('Appliances', 'Common', 'Rooms and Home'),

  BoardHierarchyEntry('Food Equipment', 'Common', 'Rooms and Home'),

  BoardHierarchyEntry('Habitats', 'Common', 'Places'),

  BoardHierarchyEntry('Local Places', 'Common', 'Places'),

  BoardHierarchyEntry('Colours', 'Common'),

  BoardHierarchyEntry('Shades Of Colours', 'Common', 'Colours'),

  BoardHierarchyEntry('Prepositions', 'Common'),

  BoardHierarchyEntry('Body Parts', 'Common'),

  BoardHierarchyEntry('Medical', 'Common', 'Body Parts'),

  BoardHierarchyEntry('Internal Organs', 'Common', 'Body Parts'),

  BoardHierarchyEntry('Jobs and Careers', 'Common'),

  BoardHierarchyEntry('Animals', 'Common'),

  BoardHierarchyEntry('Mammals', 'Common', 'Animals'),

  BoardHierarchyEntry('Birds', 'Common', 'Animals'),

  BoardHierarchyEntry('Reptiles', 'Common', 'Animals'),

  BoardHierarchyEntry('Dinosaurs', 'Common', 'Reptiles'),

  BoardHierarchyEntry('Amphibians', 'Common', 'Animals'),

  BoardHierarchyEntry('Insects', 'Common', 'Animals'),

  BoardHierarchyEntry('Arachnids', 'Common', 'Animals'),

  BoardHierarchyEntry('Invertebrates', 'Common', 'Animals'),

  BoardHierarchyEntry('Fish', 'Common', 'Animals'),

  BoardHierarchyEntry('Sealife', 'Common', 'Animals'),

  BoardHierarchyEntry('Nature Vocabulary', 'Common', 'Animals'),

  BoardHierarchyEntry('Body Parts Of Animals', 'Common', 'Animals'),

  BoardHierarchyEntry('Child Animals', 'Common', 'Animals'),

  BoardHierarchyEntry('Groups Of Animals', 'Common', 'Animals'),

  BoardHierarchyEntry('Weather', 'Common'),

  BoardHierarchyEntry('Seasons', 'Common', 'Weather'),

  BoardHierarchyEntry('Disasters', 'Common', 'Weather'),

  BoardHierarchyEntry('Time', 'Common'),

  BoardHierarchyEntry('Time (Clocks)', 'Common', 'Time'),

  BoardHierarchyEntry('Months', 'Common', 'Time'),

  BoardHierarchyEntry('Events and Occasions', 'Common', 'Time'),

  BoardHierarchyEntry('Passover Keywords', 'Common', 'Events and Occasions'),

  BoardHierarchyEntry('Easter Keywords', 'Common', 'Events and Occasions'),

  BoardHierarchyEntry('Halloween Keywords', 'Common', 'Events and Occasions'),

  BoardHierarchyEntry('Bonfire Night Keywords', 'Common', 'Events and Occasions'),

  BoardHierarchyEntry('Christmas Keywords', 'Common', 'Events and Occasions'),

  BoardHierarchyEntry('Special Days', 'Common', 'Events and Occasions'),

  BoardHierarchyEntry('Clothes', 'Common'),

  BoardHierarchyEntry('Toys', 'Common'),

  BoardHierarchyEntry('Money', 'Common'),

  BoardHierarchyEntry('Transport', 'Common'),

  BoardHierarchyEntry('World Map', 'Common'),



  // ──────────────────────────────────────────────

  //  LEGENDS AREA  (matches AREA_LEGENDS.md tab + hierarchy order)

  // ──────────────────────────────────────────────

  BoardHierarchyEntry('Real Life Heroes', 'Legends'),



  // ──────────────────────────────────────────────

  //  RECIPES AREA

  // ──────────────────────────────────────────────

  BoardHierarchyEntry('Recipes Main', 'Recipes'),



  // ──────────────────────────────────────────────

  //  SUBJECT VOCAB AREA  (matches AREA_SUBJECT_VOCAB.md)

  // ──────────────────────────────────────────────

  BoardHierarchyEntry('Subject Vocabulary', 'Subject Vocab'),



  // ──────────────────────────────────────────────

  //  SIGN AREA  (matches AREA_SIGN.md)

  // ──────────────────────────────────────────────

  BoardHierarchyEntry('Sign Main', 'Sign'),

  BoardHierarchyEntry('A-Z Of Sign', 'Sign'),

  BoardHierarchyEntry('A (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('B (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('C (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('D (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('E (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('F (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('G (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('H (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('I (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('J (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('K (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('L (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('M (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('N (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('O (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('P (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('Q (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('R (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('S (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('T (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('U (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('V (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('W (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('X (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('Y (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('Z (Sign)', 'Sign', 'A-Z Of Sign'),

  BoardHierarchyEntry('Manners and Greetings', 'Sign'),

  BoardHierarchyEntry('Family and People', 'Sign'),

  BoardHierarchyEntry('Feelings and Health', 'Sign'),

  BoardHierarchyEntry('Questions', 'Sign'),

  BoardHierarchyEntry('Grammatical Elements', 'Sign'),

  BoardHierarchyEntry('Prepositions', 'Sign'),

  BoardHierarchyEntry('Descriptions and Attributes', 'Sign'),

  BoardHierarchyEntry('Colours', 'Sign'),

  BoardHierarchyEntry('Numbers', 'Sign'),

  BoardHierarchyEntry('Quantity and Measurement', 'Sign'),

  BoardHierarchyEntry('Time and Days', 'Sign'),

  BoardHierarchyEntry('Letters', 'Sign'),

  BoardHierarchyEntry('Food and Drink', 'Sign'),

  BoardHierarchyEntry('Personal Actions', 'Sign'),

  BoardHierarchyEntry('Shared Activities', 'Sign'),

  BoardHierarchyEntry('Personal Hygiene', 'Sign'),

  BoardHierarchyEntry('Clothing and Personal', 'Sign'),

  BoardHierarchyEntry('Personal Possessions', 'Sign'),

  BoardHierarchyEntry('Home and Household', 'Sign'),

  BoardHierarchyEntry('General Objects', 'Sign'),

  BoardHierarchyEntry('Computer Items', 'Sign'),

  BoardHierarchyEntry('School and Instructions', 'Sign'),

  BoardHierarchyEntry('Leisure Activities and Interests', 'Sign'),

  BoardHierarchyEntry('Sport', 'Sign'),

  BoardHierarchyEntry('Animals and Nature', 'Sign'),

  BoardHierarchyEntry('Weather', 'Sign'),

  BoardHierarchyEntry('Outside', 'Sign'),

  BoardHierarchyEntry('Places', 'Sign'),

  BoardHierarchyEntry('Transport and Vehicles', 'Sign'),

  BoardHierarchyEntry('Money', 'Sign'),

  BoardHierarchyEntry('Public Notices', 'Sign'),

  BoardHierarchyEntry('Other Countries', 'Sign'),

  BoardHierarchyEntry('Religion and Customs', 'Sign'),

  BoardHierarchyEntry('Gender and Sexuality', 'Sign'),



  // ──────────────────────────────────────────────

  //  MY SCHOOL AREA  (matches AREA_MY_SCHOOL.md)

  // ──────────────────────────────────────────────

  BoardHierarchyEntry('My School Main', 'My School'),

  BoardHierarchyEntry('Baycroft Expects', 'My School'),

  BoardHierarchyEntry('Thinking Skills', 'My School'),

  BoardHierarchyEntry('When Things Go Wrong', 'My School'),

  BoardHierarchyEntry('Blank Levels', 'My School'),

  BoardHierarchyEntry('My School Lessons', 'My School'),

  BoardHierarchyEntry('Class Equipment', 'My School'),

  BoardHierarchyEntry('People At School', 'My School'),

];



// ──────────────────────────────────────────────

//  Runtime (mutable) hierarchy

// ──────────────────────────────────────────────



/// Mutable copy of [boardHierarchy] that includes any admin changes

/// persisted in SharedPreferences between compiles.  All lookup functions

/// read from this list so that admin edits are immediately visible without

/// a full recompile.

///

/// On web startup this is loaded from SharedPreferences.  If nothing is

/// stored yet it defaults to a copy of the compiled const list.

final List<BoardHierarchyEntry> runtimeBoardHierarchy = [];



/// Per-user SharedPreferences key builder.

String _userHierarchyPrefsKey(String userId) =>

    'user_board_hierarchy_entries_${userId.toLowerCase()}';



/// SharedPreferences key for the runtime hierarchy cache (admin edits

/// between compiles).

const String _runtimeHierarchyPrefsKey = 'runtime_board_hierarchy';



// ──────────────────────────────────────────────

//  Persistence: runtime (admin = static) layer

// ──────────────────────────────────────────────



/// Load the runtime hierarchy from SharedPreferences.

/// Falls back to [boardHierarchy] if nothing is stored.

Future<void> loadRuntimeHierarchy() async {

  final prefs = await SharedPreferences.getInstance();

  final raw = prefs.getString(_runtimeHierarchyPrefsKey);

  if (raw != null && raw.isNotEmpty) {

    try {

      final list = json.decode(raw) as List;

      final loaded = list.map((e) =>

            BoardHierarchyEntry.fromJson(e as Map<String, dynamic>)).toList();

      

      // FIX: Ensure that if prebuilt boards were reordered in the source code

      // (like the Disney Stories reorder), we pick up that new order while

      // still preserving custom boards added by the admin at runtime.

      final prebuiltNames = boardHierarchy.map((e) => e.name.toLowerCase()).toSet();

      

      final merged = <BoardHierarchyEntry>[];

      // 1. Always start with the compiled-in prebuilt hierarchy (defines order)

      merged.addAll(boardHierarchy);

      

      // 2. Append any custom admin boards that aren't in the prebuilt set

      for (final item in loaded) {

        if (!prebuiltNames.contains(item.name.toLowerCase())) {

          merged.add(item);

        }

      }



      runtimeBoardHierarchy

        ..clear()

        ..addAll(merged);

      return;

    } catch (_) {}

  }

  // First run or out-of-sync — seed from compiled const.

  runtimeBoardHierarchy

    ..clear()

    ..addAll(boardHierarchy);

}



/// Persist the runtime hierarchy to SharedPreferences.

/// The dev server mirror is handled by board_service.dart.

Future<void> _persistRuntimeHierarchy() async {

  final prefs = await SharedPreferences.getInstance();

  final entries = runtimeBoardHierarchy.map((e) => e.toJson()).toList();

  await prefs.setString(_runtimeHierarchyPrefsKey, json.encode(entries));

}







// ──────────────────────────────────────────────

//  Admin operations (modifies static/compiled hierarchy)

// ──────────────────────────────────────────────



/// Add a board to the runtime hierarchy (admin creates a new board).

/// Returns true if added, false if already existed.

Future<bool> addToRuntimeHierarchy(BoardHierarchyEntry entry) async {

  final lower = entry.name.toLowerCase();

  if (runtimeBoardHierarchy.any((e) => e.name.toLowerCase() == lower)) {

    return false;

  }

  runtimeBoardHierarchy.add(entry);

  await _persistRuntimeHierarchy();

  return true;

}



/// Update an existing entry in the runtime hierarchy (admin moves/edits a

/// board).  Matches by [entry.name] (case-insensitive).

Future<void> updateRuntimeHierarchyEntry(BoardHierarchyEntry entry) async {

  final lower = entry.name.toLowerCase();

  final idx = runtimeBoardHierarchy.indexWhere(

      (e) => e.name.toLowerCase() == lower);

  if (idx >= 0) {

    runtimeBoardHierarchy[idx] = entry;

  } else {

    runtimeBoardHierarchy.add(entry);

  }

  await _persistRuntimeHierarchy();

}



/// Remove an entry from the runtime hierarchy (admin deletes a board).

Future<void> removeFromRuntimeHierarchy(String name) async {

  runtimeBoardHierarchy.removeWhere(

      (e) => e.name.toLowerCase() == name.toLowerCase());

  await _persistRuntimeHierarchy();

}



// ──────────────────────────────────────────────

//  Per-user operations

// ──────────────────────────────────────────────



/// User hierarchy entries for the current session.

final List<BoardHierarchyEntry> userCustomHierarchyEntries = [];



/// Load user hierarchy entries from SharedPreferences.

Future<void> loadUserCustomHierarchyEntries(String userId) async {

  final prefs = await SharedPreferences.getInstance();

  final raw = prefs.getString(_userHierarchyPrefsKey(userId));

  if (raw == null || raw.isEmpty) return;

  try {

    final list = json.decode(raw) as List;

    userCustomHierarchyEntries

      ..clear()

      ..addAll(list.map((e) =>

          BoardHierarchyEntry.fromJson(e as Map<String, dynamic>)));

  } catch (_) {}

}



/// Persist user hierarchy entries.

Future<void> _persistUserEntries(String userId) async {

  final prefs = await SharedPreferences.getInstance();

  await prefs.setString(

    _userHierarchyPrefsKey(userId),

    json.encode(userCustomHierarchyEntries.map((e) => e.toJson()).toList()),

  );

}



/// Add a user-created hierarchy entry (personal to [userId]).

Future<bool> addUserHierarchyEntry(String userId, BoardHierarchyEntry entry) async {

  final lower = entry.name.toLowerCase();

  if (userCustomHierarchyEntries.any((e) => e.name.toLowerCase() == lower)) {

    return false;

  }

  userCustomHierarchyEntries.add(entry);

  await _persistUserEntries(userId);

  return true;

}



/// Update an existing user hierarchy entry (e.g. when user moves a board).

Future<void> updateUserHierarchyEntry(String userId, BoardHierarchyEntry entry) async {

  final lower = entry.name.toLowerCase();

  final idx = userCustomHierarchyEntries.indexWhere(

      (e) => e.name.toLowerCase() == lower);

  if (idx >= 0) {

    userCustomHierarchyEntries[idx] = entry;

  } else {

    userCustomHierarchyEntries.add(entry);

  }

  await _persistUserEntries(userId);

}



/// Remove a user hierarchy entry by name.

Future<void> removeUserHierarchyEntry(String userId, String name) async {

  userCustomHierarchyEntries.removeWhere(

      (e) => e.name.toLowerCase() == name.toLowerCase());

  await _persistUserEntries(userId);

}



/// Ensure an empty user hierarchy document exists for [userId].

Future<void> ensureEmptyUserHierarchy(String userId) async {

  final prefs = await SharedPreferences.getInstance();

  if (!prefs.containsKey(_userHierarchyPrefsKey(userId))) {

    await prefs.setString(_userHierarchyPrefsKey(userId), '[]');

  }

}



// ──────────────────────────────────────────────

//  Board ID generator

// ──────────────────────────────────────────────

String _hierarchyBoardId(String name) {

  if (name.toLowerCase() == 'a-z of sign') {

    return 'prebuilt_a_to_z_of_sign';

  }

  return 'prebuilt_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+$'), '')}';

}



/// Generate a board ID for admin-created boards (prebuilt prefix).

String adminBoardId(String name) => _hierarchyBoardId(name);



/// Generate a board ID for user-created boards ({userId}_ prefix).

String userBoardId(String userId, String name) {

  final safe = name.toLowerCase()

      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')

      .replaceAll(RegExp(r'_+$'), '');

  return '${userId.toLowerCase()}_$safe';

}



// ──────────────────────────────────────────────

//  Lookup functions (search runtime + user)

// ──────────────────────────────────────────────



/// Look up the hierarchy entry for [name] (case-insensitive).

/// Priority: user custom > runtime (static + admin edits).

BoardHierarchyEntry? findHierarchyEntry(String name) {

  final lower = name.toLowerCase();

  // User entries override runtime.

  for (final e in userCustomHierarchyEntries) {

    if (e.name.toLowerCase() == lower) return e;

  }

  // Runtime = compiled const + any admin edits persisted in prefs.

  for (final e in runtimeBoardHierarchy) {

    if (e.name.toLowerCase() == lower) return e;

  }

  return null;

}



/// Returns the area for [name] from the hierarchy, or 'Common' as default.

String hierarchyArea(String name) {

  return findHierarchyEntry(name)?.area ?? 'Common';

}



/// Returns the parent board name for [name], or null if top-level.

String? hierarchyParent(String name) {

  return findHierarchyEntry(name)?.parentName;

}



/// Returns the parent board ID for [name], or null if top-level.

String? hierarchyParentId(String name) {

  final parent = hierarchyParent(name);

  return parent != null ? _hierarchyBoardId(parent) : null;

}



/// Derives the tier (1–5) by walking the parent chain.

int hierarchyTier(String name) {

  int tier = 1;

  String? current = name;

  while (current != null) {

    final entry = findHierarchyEntry(current);

    if (entry == null || entry.parentName == null) return tier;

    tier++;

    current = entry.parentName;

  }

  return tier;

}



/// Returns true if [name] is listed in the hierarchy.

bool isInBoardHierarchy(String name) {

  return findHierarchyEntry(name) != null;

}



/// Returns true if [name] is a sub-board (has a parent) in the hierarchy.

bool hierarchyIsSubBoard(String name) {

  return hierarchyParent(name) != null;

}



/// Returns all board names that are direct children of [parentName].

List<String> hierarchyChildren(String parentName) {

  return _allEntries

      .where((e) => e.parentName == parentName)

      .map((e) => e.name)

      .toList();

}



/// Returns all top-level (tier 1) board names for the given [area].

List<String> hierarchyTopLevel(String area) {

  return _allEntries

      .where((e) => e.area == area && e.parentName == null)

      .map((e) => e.name)

      .toList();

}



/// Merged view of all entries (runtime + user custom).

List<BoardHierarchyEntry> get _allEntries {

  final map = <String, BoardHierarchyEntry>{};

  for (final e in runtimeBoardHierarchy) {

    map[e.name.toLowerCase()] = e;

  }

  for (final e in userCustomHierarchyEntries) {

    map[e.name.toLowerCase()] = e;

  }

  return map.values.toList();

}



/// Returns the position of [name] within the hierarchy (0-based).

/// Uses case-insensitive, trimmed comparison so minor name differences

/// (whitespace, casing) don't break ordering. Returns -1 if not found.

int hierarchyPosition(String name) {

  final lower = name.trim().toLowerCase();

  for (int i = 0; i < runtimeBoardHierarchy.length; i++) {

    if (runtimeBoardHierarchy[i].name.trim().toLowerCase() == lower) return i;

  }

  return -1;

}

