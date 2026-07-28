/// Single source of truth for the board hierarchy across all 5 areas.

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

  BoardHierarchyEntry('Rooms & Home', 'Common', 'Places'),

  BoardHierarchyEntry('Home Management', 'Common', 'Rooms & Home'),

  BoardHierarchyEntry('Furniture', 'Common', 'Rooms & Home'),

  BoardHierarchyEntry('Appliances', 'Common', 'Rooms & Home'),

  BoardHierarchyEntry('Food Equipment', 'Common', 'Rooms & Home'),

  BoardHierarchyEntry('Habitats', 'Common', 'Places'),

  BoardHierarchyEntry('Local Places', 'Common', 'Places'),

  BoardHierarchyEntry('Colours', 'Common'),

  BoardHierarchyEntry('Shades Of Colours', 'Common', 'Colours'),

  BoardHierarchyEntry('Prepositions', 'Common'),

  BoardHierarchyEntry('Body Parts', 'Common'),

  BoardHierarchyEntry('Medical', 'Common', 'Body Parts'),

  BoardHierarchyEntry('Internal Organs', 'Common', 'Body Parts'),

  BoardHierarchyEntry('Jobs & Careers', 'Common'),

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

  BoardHierarchyEntry('Events & Occasions', 'Common', 'Time'),

  BoardHierarchyEntry('Passover Keywords', 'Common', 'Events & Occasions'),

  BoardHierarchyEntry('Easter Keywords', 'Common', 'Events & Occasions'),

  BoardHierarchyEntry('Halloween Keywords', 'Common', 'Events & Occasions'),

  BoardHierarchyEntry('Bonfire Night Keywords', 'Common', 'Events & Occasions'),

  BoardHierarchyEntry('Christmas Keywords', 'Common', 'Events & Occasions'),

  BoardHierarchyEntry('Special Days', 'Common', 'Events & Occasions'),

  BoardHierarchyEntry('Clothes', 'Common'),

  BoardHierarchyEntry('Toys', 'Common'),

  BoardHierarchyEntry('Money', 'Common'),

  BoardHierarchyEntry('Transport', 'Common'),

  BoardHierarchyEntry('World Map', 'Common'),



  // ──────────────────────────────────────────────

  //  LEGENDS AREA  (matches AREA_LEGENDS.md tab + hierarchy order)

  // ──────────────────────────────────────────────

BoardHierarchyEntry('Real Life Heroes', 'Legends'),
  BoardHierarchyEntry('Characters', 'Legends'),

  BoardHierarchyEntry('Creatures & Races', 'Legends'),

  BoardHierarchyEntry('Gods, Titans, Heroes & Monsters', 'Legends'),

  BoardHierarchyEntry('Family Trees', 'Legends', 'Gods, Titans, Heroes & Monsters'),

  BoardHierarchyEntry('Egyptian Gods', 'Legends', 'Gods, Titans, Heroes & Monsters'),

  BoardHierarchyEntry('Norse Gods', 'Legends', 'Gods, Titans, Heroes & Monsters'),

  BoardHierarchyEntry('Aesir (29+1)', 'Legends', 'Norse Gods'),

  BoardHierarchyEntry('Jotnar (14+1)', 'Legends', 'Norse Gods'),

  BoardHierarchyEntry('Norse Locations', 'Legends', 'Norse Gods'),

  BoardHierarchyEntry('Norse Races', 'Legends', 'Norse Gods'),

  BoardHierarchyEntry('Vanir (6+1)', 'Legends', 'Norse Gods'),

  BoardHierarchyEntry('Greek Gods', 'Legends', 'Gods, Titans, Heroes & Monsters'),

  BoardHierarchyEntry('Olympians', 'Legends', 'Greek Gods'),

  BoardHierarchyEntry('Titans', 'Legends', 'Greek Gods'),

  BoardHierarchyEntry('Roman Gods', 'Legends', 'Gods, Titans, Heroes & Monsters'),

  BoardHierarchyEntry('Roman Unique Gods', 'Legends', 'Roman Gods'),

  BoardHierarchyEntry('Heroes & Monsters (Greek & Roman)', 'Legends', 'Gods, Titans, Heroes & Monsters'),

  BoardHierarchyEntry('Hindu Gods', 'Legends', 'Gods, Titans, Heroes & Monsters'),

  BoardHierarchyEntry('Christian Angels Demons', 'Legends', 'Gods, Titans, Heroes & Monsters'),

  BoardHierarchyEntry('Other Mythology', 'Legends', 'Gods, Titans, Heroes & Monsters'),

  BoardHierarchyEntry('Fairy Tale Characters', 'Legends'),

  BoardHierarchyEntry('Disney Stories', 'Legends'),

  BoardHierarchyEntry('Mickey & Friends', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1937 Snow White & The Seven Dwarfs', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1940 Fantasia', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1940 Pinocchio', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1941 Dumbo', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1942 Bambi', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1950 Cinderella', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1951 Alice In Wonderland', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1953 Peter Pan', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1955 Lady & The Tramp', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1959 Sleeping Beauty', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1961 101 Dalmatians', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1963 The Sword In The Stone', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1967 The Jungle Book', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1970 The Aristocats', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1973 Robin Hood', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1977 The Rescuers', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1977 Winnie The Pooh', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1981 The Fox & The Hound', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1985 The Black Cauldron', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1986 The Great Mouse Detective', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1988 Oliver & Company', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1989 The Little Mermaid', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1990 The Rescuers Down Under', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1991 Beauty & The Beast', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1992 Aladdin', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1993 The Nightmare Before Christmas', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1994 The Lion King', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1995 Pocahontas', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1995 Toy Story', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1996 The Hunchback Of Notre Dame', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1997 Hercules', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1998 A Bug\'s Life', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1998 Mulan', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('1999 Tarzan', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2000 Dinosaur', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2000 The Emperor\'s New Groove', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2001 Atlantis - The Lost Empire', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2001 Monsters, Inc', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2002 Lilo & Stitch', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2002 Treasure Planet', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2003 Brother Bear', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2003 Finding Nemo', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2004 Home On The Range', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2004 The Incredibles', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2005 Chicken Little', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2006 Cars', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2007 Meet The Robinsons', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2007 Ratatouille', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2008 Bolt', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2008 WALL-E', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2009 The Princess & The Frog', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2009 Up', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2010 Tangled', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2012 Brave', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2012 Wreck-It Ralph', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2013 Frozen', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2014 Big Hero 6', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2015 Inside Out', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2015 The Good Dinosaur', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2016 Moana', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2016 Zootopia', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2017 Coco', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2020 Onward', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2020 Soul', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2021 Encanto', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2021 Luca', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2021 Raya & The Last Dragon', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2022 Lightyear', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2022 Strange World', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2022 Turning Red', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2023 Elemental', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2023 Wish', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('2025 Elio', 'Legends', 'Disney Stories'),

  BoardHierarchyEntry('D&D', 'Legends'),

  BoardHierarchyEntry('Arthurian Legend', 'Legends'),

  BoardHierarchyEntry('Arabian & Middle Eastern Tales', 'Legends'),

  BoardHierarchyEntry('Asian Legends & Folklore', 'Legends'),

  BoardHierarchyEntry('Horror Icons', 'Legends'),

  BoardHierarchyEntry('Legendary Heroes & Folk Heroes', 'Legends'),

  BoardHierarchyEntry('Literary & Gothic Characters', 'Legends'),

  BoardHierarchyEntry('Marvel', 'Legends'),

  BoardHierarchyEntry('X-Men', 'Legends'),

  BoardHierarchyEntry('DC', 'Legends'),

  BoardHierarchyEntry('The Muppets', 'Legends'),

  BoardHierarchyEntry('Star Wars', 'Legends'),

  BoardHierarchyEntry('Star Trek', 'Legends'),

  BoardHierarchyEntry('Starships', 'Legends', 'Star Trek'),

  BoardHierarchyEntry('The Lord Of The Rings', 'Legends'),

  BoardHierarchyEntry('Computer Games', 'Legends'),

  BoardHierarchyEntry('Misc', 'Legends'),



  // ──────────────────────────────────────────────

  //  RECIPES AREA

  // ──────────────────────────────────────────────

  BoardHierarchyEntry('Recipes Main', 'Recipes'),



  // ──────────────────────────────────────────────

  //  SUBJECT VOCAB AREA  (matches AREA_SUBJECT_VOCAB.md)

  // ──────────────────────────────────────────────

  BoardHierarchyEntry('Subject Vocabulary', 'Subject Vocab'),

  BoardHierarchyEntry('Better Words (Thesaurus)', 'Subject Vocab'),

  BoardHierarchyEntry('Actions Verbs Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),

  BoardHierarchyEntry('Appearance Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),

  BoardHierarchyEntry(' Bad Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),

  BoardHierarchyEntry('Feelings Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),

  BoardHierarchyEntry(' Good Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),

  BoardHierarchyEntry('Move Actions Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),

  BoardHierarchyEntry('Nouns Abstract Nouns Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),

  BoardHierarchyEntry('People Places Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),

  BoardHierarchyEntry('Say Actions Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),

  BoardHierarchyEntry('Lessons', 'Subject Vocab'),

  BoardHierarchyEntry('Sentence Creator', 'Subject Vocab'),

  BoardHierarchyEntry('Small Words (Subject)', 'Subject Vocab'),

  BoardHierarchyEntry('Letters (Subject)', 'Subject Vocab'),

  BoardHierarchyEntry('Numbers (Subject)', 'Subject Vocab'),

  BoardHierarchyEntry('Breaktime', 'Subject Vocab'),

  BoardHierarchyEntry('Lunchtime', 'Subject Vocab'),

  BoardHierarchyEntry('Tutor Time, Events & Clubs', 'Subject Vocab'),

  BoardHierarchyEntry('English', 'Subject Vocab'),

  BoardHierarchyEntry('Maths', 'Subject Vocab'),

  BoardHierarchyEntry('Algebra', 'Subject Vocab', 'Maths'),

  BoardHierarchyEntry('Numbers', 'Subject Vocab', 'Maths'),

  BoardHierarchyEntry('Fractions & Percentages', 'Subject Vocab', 'Maths'),

  BoardHierarchyEntry('Maths Resources', 'Subject Vocab', 'Maths'),

  BoardHierarchyEntry('Measurements (Length & Width, Perimeter & Area)', 'Subject Vocab', 'Maths'),

  BoardHierarchyEntry('Money', 'Subject Vocab', 'Maths'),

  BoardHierarchyEntry('Position & Direction', 'Subject Vocab', 'Maths'),

  BoardHierarchyEntry('Ratios & Proportion', 'Subject Vocab', 'Maths'),

  BoardHierarchyEntry('Shapes & Angles', 'Subject Vocab', 'Maths'),

  BoardHierarchyEntry('Statistics', 'Subject Vocab', 'Maths'),

  BoardHierarchyEntry('Time', 'Subject Vocab', 'Maths'),

  BoardHierarchyEntry('Weight & Capacity', 'Subject Vocab', 'Maths'),

  BoardHierarchyEntry('Science', 'Subject Vocab'),

  BoardHierarchyEntry('Chemical Compositions', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('PH Scale', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Animals & Humans', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Ecosystems', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Components', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Electrical Safety', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Alternative & Renewable Energy', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Hot Stuff - Thermal Processes', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Are You Overreacting', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Attractive Forces', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Babies', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Body Wars', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Casualty', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Clean Air & Water', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Controlling Systems', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Creepy Crawlies', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Driving Along', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Elements', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Everything In Its Place', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Extinction', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Fly Me To The Moon', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Food Factory', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Fooling Your Senses', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Fuels', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Full Spectrum', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Getting The Message', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Heavy Metals', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Let\'S Get Together', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Medical Rays', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('My Genes', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Novel Materials', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Nuclear Power', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Our Electrical Supply', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Physical Or Chemical Change', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Pushes & Pulls', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Sorting Out', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('You Only Have One Life', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Equipment', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Evolution & Genes', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Forces', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Hazard Symbols', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Intro', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Levers, Pulleys & Gears', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Light & Sound', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Material Properties', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Matter', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Breathing Vs Respiration', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Cells & Organelles', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Circulatory System', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Digestive System', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Levels Of Organisation', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Specific Muscles', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('The Skeleton', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Plants', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Reactions', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Earth\'S Layers', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Fossil Formation', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Igneous', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Metamorphic', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Sedimentary', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Soil Formation', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Types Of Rock', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Digestion & Excretion', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Exercise', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Health', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Healthy Lifestyle', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Mental & Social Health', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Nutrition', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('Universe', 'Subject Vocab', 'Science'),

  BoardHierarchyEntry('T.F.L. / I.T.', 'Subject Vocab'),

  BoardHierarchyEntry('Company Logos', 'Subject Vocab', 'T.F.L. / I.T.'),

  BoardHierarchyEntry('Programs', 'Subject Vocab', 'T.F.L. / I.T.'),

  BoardHierarchyEntry('TFL Equipment', 'Subject Vocab', 'T.F.L. / I.T.'),

  BoardHierarchyEntry('Personal Development', 'Subject Vocab'),

  BoardHierarchyEntry('Being Responsible', 'Subject Vocab', 'Personal Development'),

  BoardHierarchyEntry('Diversity', 'Subject Vocab', 'Personal Development'),

  BoardHierarchyEntry('Health & Wellbeing', 'Subject Vocab', 'Personal Development'),

  BoardHierarchyEntry('Hygiene', 'Subject Vocab', 'Personal Development'),

  BoardHierarchyEntry('Making Friends', 'Subject Vocab', 'Personal Development'),

  BoardHierarchyEntry('Relationships', 'Subject Vocab', 'Personal Development'),

  BoardHierarchyEntry('Intimate Relationships', 'Subject Vocab', 'Personal Development'),

  BoardHierarchyEntry('Unhealthy Relationships', 'Subject Vocab', 'Personal Development'),

  BoardHierarchyEntry('Sexuality', 'Subject Vocab', 'Personal Development'),

  BoardHierarchyEntry('Drugs & Alcohol Awareness', 'Subject Vocab', 'Personal Development'),

  BoardHierarchyEntry('NSPCC Pants', 'Subject Vocab', 'Personal Development'),

  BoardHierarchyEntry('Sun Safety', 'Subject Vocab', 'Personal Development'),

  BoardHierarchyEntry('Digital Literacy', 'Subject Vocab', 'Personal Development'),

  BoardHierarchyEntry('Media & Social Media', 'Subject Vocab', 'Personal Development'),

  BoardHierarchyEntry('P.E.E.P.', 'Subject Vocab'),

  BoardHierarchyEntry('Ancient Greece', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Places & People (Anglo-Saxons)', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Biomes & Climate', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Blue Planet', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Bone Finders', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Unsorted', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('WW Aftermath & Leadership', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('WW Homefront', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('WW1', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('WW2', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Continent Maps', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Africa', 'Subject Vocab', 'Continent Maps'),

  BoardHierarchyEntry('Asia', 'Subject Vocab', 'Continent Maps'),

  BoardHierarchyEntry('Canada & Greenland', 'Subject Vocab', 'Continent Maps'),

  BoardHierarchyEntry('Central America & The Caribbean', 'Subject Vocab', 'Continent Maps'),

  BoardHierarchyEntry('Europe', 'Subject Vocab', 'Continent Maps'),

  BoardHierarchyEntry('North American States', 'Subject Vocab', 'Continent Maps'),

  BoardHierarchyEntry('Oceania', 'Subject Vocab', 'Continent Maps'),

  BoardHierarchyEntry('Oceans & Poles', 'Subject Vocab', 'Continent Maps'),

  BoardHierarchyEntry('South America', 'Subject Vocab', 'Continent Maps'),

  BoardHierarchyEntry('States', 'Subject Vocab', 'Continent Maps'),

  BoardHierarchyEntry('Disasters', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Egypt', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Emergencies', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Houses', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Explorers', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Flags', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Great Britain', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Industrial Revolution', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Journeys Through Time', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Keywords', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Heroes', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Maps & Atlas', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Crew', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Famous Real Pirates', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Fictional Pirates', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Prehistoric', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Romans', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Seasons', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('People', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('Victorians', 'Subject Vocab', 'P.E.E.P.'),

  BoardHierarchyEntry('E.P.I.C.', 'Subject Vocab'),

  BoardHierarchyEntry('P.E.', 'Subject Vocab'),

  BoardHierarchyEntry('Adventure & Extreme Sports', 'Subject Vocab', 'P.E.'),

  BoardHierarchyEntry('Creativity & Brainpower', 'Subject Vocab', 'P.E.'),

  BoardHierarchyEntry('Gym Equipment', 'Subject Vocab', 'P.E.'),

  BoardHierarchyEntry('Individual Sports', 'Subject Vocab', 'P.E.'),

  BoardHierarchyEntry('Leisure Sports', 'Subject Vocab', 'P.E.'),

  BoardHierarchyEntry('Outdoors', 'Subject Vocab', 'P.E.'),

  BoardHierarchyEntry('P.E. Games', 'Subject Vocab', 'P.E.'),

  BoardHierarchyEntry('P.E. Keywords', 'Subject Vocab', 'P.E.'),

  BoardHierarchyEntry('Relaxation', 'Subject Vocab', 'P.E.'),

  BoardHierarchyEntry('Sports Day Events', 'Subject Vocab', 'P.E.'),

  BoardHierarchyEntry('Team Sports', 'Subject Vocab', 'P.E.'),

  BoardHierarchyEntry('Technology', 'Subject Vocab', 'P.E.'),

  BoardHierarchyEntry('Water & Winter Sports', 'Subject Vocab', 'P.E.'),

  BoardHierarchyEntry('Art', 'Subject Vocab'),

  BoardHierarchyEntry('7', 'Subject Vocab', 'Art'),

  BoardHierarchyEntry('8', 'Subject Vocab', 'Art'),

  BoardHierarchyEntry('9', 'Subject Vocab', 'Art'),

  BoardHierarchyEntry('Performing Arts', 'Subject Vocab'),

  BoardHierarchyEntry('Sustainability', 'Subject Vocab'),

  BoardHierarchyEntry('Cooking', 'Subject Vocab'),

  BoardHierarchyEntry('Carbohydrates', 'Subject Vocab', 'Cooking'),

  BoardHierarchyEntry('Cooking Equipment', 'Subject Vocab', 'Cooking'),

  BoardHierarchyEntry('Dairy', 'Subject Vocab', 'Cooking'),

  BoardHierarchyEntry('Good Fats', 'Subject Vocab', 'Cooking'),

  BoardHierarchyEntry('Food Groups', 'Subject Vocab', 'Cooking'),

  BoardHierarchyEntry('Fruit', 'Subject Vocab', 'Cooking'),

  BoardHierarchyEntry('Herbs', 'Subject Vocab', 'Cooking'),

  BoardHierarchyEntry('Key Terminology', 'Subject Vocab', 'Cooking'),

  BoardHierarchyEntry('Meal Times', 'Subject Vocab', 'Cooking'),

  BoardHierarchyEntry('Desserts & Puddings', 'Subject Vocab', 'Cooking'),

  BoardHierarchyEntry('More Symbols', 'Subject Vocab', 'Cooking'),

  BoardHierarchyEntry('Protein', 'Subject Vocab', 'Cooking'),

  BoardHierarchyEntry('Photos', 'Subject Vocab', 'Cooking'),

  BoardHierarchyEntry('Spices', 'Subject Vocab', 'Cooking'),

  BoardHierarchyEntry('Vegetables', 'Subject Vocab', 'Cooking'),

  BoardHierarchyEntry('Resistant Materials', 'Subject Vocab'),

  BoardHierarchyEntry('Equipment', 'Subject Vocab', 'Resistant Materials'),

  BoardHierarchyEntry('Textiles', 'Subject Vocab'),

  BoardHierarchyEntry('Religion & Worldviews', 'Subject Vocab'),

  BoardHierarchyEntry('Angels', 'Subject Vocab', 'Religion & Worldviews'),

  BoardHierarchyEntry('Belonging & Baptism', 'Subject Vocab', 'Religion & Worldviews'),

  BoardHierarchyEntry('Community', 'Subject Vocab', 'Religion & Worldviews'),

  BoardHierarchyEntry('Creation Stories', 'Subject Vocab', 'Religion & Worldviews'),

  BoardHierarchyEntry('Good & Evil', 'Subject Vocab', 'Religion & Worldviews'),

  BoardHierarchyEntry('Hindu Traditions', 'Subject Vocab', 'Religion & Worldviews'),

  BoardHierarchyEntry('Holy Books', 'Subject Vocab', 'Religion & Worldviews'),

  BoardHierarchyEntry('Islam Belonging', 'Subject Vocab', 'Religion & Worldviews'),

  BoardHierarchyEntry('Love & Belonging', 'Subject Vocab', 'Religion & Worldviews'),

  BoardHierarchyEntry('Love & Easter', 'Subject Vocab', 'Religion & Worldviews'),

  BoardHierarchyEntry('Love, Rules, Choice, Consequences', 'Subject Vocab', 'Religion & Worldviews'),

  BoardHierarchyEntry('People Making A Difference', 'Subject Vocab', 'Religion & Worldviews'),

  BoardHierarchyEntry('Special Festivals', 'Subject Vocab', 'Religion & Worldviews'),

  BoardHierarchyEntry('Special People', 'Subject Vocab', 'Religion & Worldviews'),

  BoardHierarchyEntry('Special Things', 'Subject Vocab', 'Religion & Worldviews'),

  BoardHierarchyEntry('Gods & Characters', 'Subject Vocab', 'Religion & Worldviews'),

  BoardHierarchyEntry('Z Buddhism', 'Subject Vocab', 'Religion & Worldviews'),

  BoardHierarchyEntry('Z Christianity', 'Subject Vocab', 'Religion & Worldviews'),

  BoardHierarchyEntry('Z Islam', 'Subject Vocab', 'Religion & Worldviews'),

  BoardHierarchyEntry('Z Judaism', 'Subject Vocab', 'Religion & Worldviews'),

  BoardHierarchyEntry('Z Paganism', 'Subject Vocab', 'Religion & Worldviews'),

  BoardHierarchyEntry('Z Sikhism', 'Subject Vocab', 'Religion & Worldviews'),

  BoardHierarchyEntry('Music', 'Subject Vocab'),

  BoardHierarchyEntry('Musical Genres', 'Subject Vocab', 'Music'),

  BoardHierarchyEntry('Musical Instruments', 'Subject Vocab', 'Music'),

  BoardHierarchyEntry('Horticulture', 'Subject Vocab'),

  BoardHierarchyEntry('Equipment For Horticulture', 'Subject Vocab', 'Horticulture'),

  BoardHierarchyEntry('Flowers (combined from boards 1, 2, 3 & 4)', 'Subject Vocab', 'Horticulture'),

  BoardHierarchyEntry('Retail', 'Subject Vocab'),

  BoardHierarchyEntry('Environment', 'Subject Vocab', 'Retail'),

  BoardHierarchyEntry('Legislation', 'Subject Vocab', 'Retail'),

  BoardHierarchyEntry('Marketing', 'Subject Vocab', 'Retail'),

  BoardHierarchyEntry('Operations', 'Subject Vocab', 'Retail'),

  BoardHierarchyEntry('Payment & Finance', 'Subject Vocab', 'Retail'),

  BoardHierarchyEntry('Staff', 'Subject Vocab', 'Retail'),

  BoardHierarchyEntry('Photography', 'Subject Vocab'),

  BoardHierarchyEntry('Artistic & Conceptual', 'Subject Vocab', 'Photography'),

  BoardHierarchyEntry('Artists, Context, Process, Assessment', 'Subject Vocab', 'Photography'),

  BoardHierarchyEntry('Editing & Post Production', 'Subject Vocab', 'Photography'),

  BoardHierarchyEntry('Equipment (Photography)', 'Subject Vocab', 'Photography'),

  BoardHierarchyEntry('Lighting & Composition', 'Subject Vocab', 'Photography'),

  BoardHierarchyEntry('Technical & Analytical', 'Subject Vocab', 'Photography'),

  BoardHierarchyEntry('Construction', 'Subject Vocab'),

  BoardHierarchyEntry('Design Technology', 'Subject Vocab'),

  BoardHierarchyEntry('Engineering', 'Subject Vocab'),

  BoardHierarchyEntry('Living Life Skills', 'Subject Vocab'),

  BoardHierarchyEntry('Arts & Crafts', 'Subject Vocab', 'Living Life Skills'),

  BoardHierarchyEntry('Environment & Community', 'Subject Vocab', 'Living Life Skills'),

  BoardHierarchyEntry('Finance & Numeracy', 'Subject Vocab', 'Living Life Skills'),

  BoardHierarchyEntry('Home Equipment', 'Subject Vocab', 'Living Life Skills'),

  BoardHierarchyEntry('Office Practice', 'Subject Vocab', 'Living Life Skills'),

  BoardHierarchyEntry('Identify, Collaborate', 'Subject Vocab', 'Living Life Skills'),

  BoardHierarchyEntry('Road Safety', 'Subject Vocab', 'Living Life Skills'),

  BoardHierarchyEntry('Prepare For Adulthood', 'Subject Vocab'),

  BoardHierarchyEntry('Belonging To A Community', 'Subject Vocab', 'Prepare For Adulthood'),

  BoardHierarchyEntry('Careers', 'Subject Vocab', 'Prepare For Adulthood'),

  BoardHierarchyEntry('Wider World', 'Subject Vocab', 'Prepare For Adulthood'),

  BoardHierarchyEntry('Hair & Beauty', 'Subject Vocab'),

  BoardHierarchyEntry('Health & Social Care', 'Subject Vocab'),

  BoardHierarchyEntry('Public Services', 'Subject Vocab'),

  BoardHierarchyEntry('S.T.E.M.', 'Subject Vocab'),

  BoardHierarchyEntry('Option A', 'Subject Vocab'),

  BoardHierarchyEntry('Option B', 'Subject Vocab'),

  BoardHierarchyEntry('Option C', 'Subject Vocab'),

  BoardHierarchyEntry('Tech Rotation', 'Subject Vocab'),



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

  BoardHierarchyEntry('Manners & Greetings', 'Sign'),

  BoardHierarchyEntry('Family & People', 'Sign'),

  BoardHierarchyEntry('Feelings & Health', 'Sign'),

  BoardHierarchyEntry('Questions', 'Sign'),

  BoardHierarchyEntry('Grammatical Elements', 'Sign'),

  BoardHierarchyEntry('Prepositions', 'Sign'),

  BoardHierarchyEntry('Descriptions & Attributes', 'Sign'),

  BoardHierarchyEntry('Colours', 'Sign'),

  BoardHierarchyEntry('Numbers', 'Sign'),

  BoardHierarchyEntry('Quantity & Measurement', 'Sign'),

  BoardHierarchyEntry('Time & Days', 'Sign'),

  BoardHierarchyEntry('Letters', 'Sign'),

  BoardHierarchyEntry('Food & Drink', 'Sign'),

  BoardHierarchyEntry('Personal Actions', 'Sign'),

  BoardHierarchyEntry('Shared Activities', 'Sign'),

  BoardHierarchyEntry('Personal Hygiene', 'Sign'),

  BoardHierarchyEntry('Clothing & Personal', 'Sign'),

  BoardHierarchyEntry('Personal Possessions', 'Sign'),

  BoardHierarchyEntry('Home & Household', 'Sign'),

  BoardHierarchyEntry('General Objects', 'Sign'),

  BoardHierarchyEntry('Computer Items', 'Sign'),

  BoardHierarchyEntry('School & Instructions', 'Sign'),

  BoardHierarchyEntry('Leisure Activities & Interests', 'Sign'),

  BoardHierarchyEntry('Sport', 'Sign'),

  BoardHierarchyEntry('Animals & Nature', 'Sign'),

  BoardHierarchyEntry('Weather', 'Sign'),

  BoardHierarchyEntry('Outside', 'Sign'),

  BoardHierarchyEntry('Places', 'Sign'),

  BoardHierarchyEntry('Transport & Vehicles', 'Sign'),

  BoardHierarchyEntry('Money', 'Sign'),

  BoardHierarchyEntry('Public Notices', 'Sign'),

  BoardHierarchyEntry('Other Countries', 'Sign'),

  BoardHierarchyEntry('Religion & Customs', 'Sign'),

  BoardHierarchyEntry('Gender & Sexuality', 'Sign'),



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

