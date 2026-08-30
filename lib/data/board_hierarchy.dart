/// Single source of truth for the board hierarchy across all 7 areas.

///

/// Each entry defines: board name, which area it belongs to, and its parent

/// board (null = top-level / tier 1). Tier is derived from the parent chain.

///

/// Two layers are merged at runtime:

/// 1. Static compiled hierarchy ([boardHierarchy]) â€” prebuilt boards baked

///    into the Dart source. When the admin profile creates, moves or edits a

///    board, the change is written DIRECTLY to this source file via the dev

///    server (POST /saveHierarchy). The admin layer IS the static layer.

/// 2. User custom hierarchy â€” boards created by individual users, stored

///    per-user in SharedPreferences. Only visible to that user.

///

/// Board ID prefixes:

/// - prebuilt_ â€” static / admin-created boards (available to everyone)

/// - {username}_ â€” user-created boards (personal to that user)



library;



import 'dart:convert';



import 'package:flutter/foundation.dart';



import 'package:http/http.dart' as http;



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
  BoardHierarchyEntry('Common Words', 'Common'),
  BoardHierarchyEntry('1. January', 'Common', 'Special Days'),
  BoardHierarchyEntry('10. October', 'Common', 'Special Days'),
  BoardHierarchyEntry('11. November', 'Common', 'Special Days'),
  BoardHierarchyEntry('12. December', 'Common', 'Special Days'),
  BoardHierarchyEntry('2. February', 'Common', 'Special Days'),
  BoardHierarchyEntry('3. March', 'Common', 'Special Days'),
  BoardHierarchyEntry('4. April', 'Common', 'Special Days'),
  BoardHierarchyEntry('5. May', 'Common', 'Special Days'),
  BoardHierarchyEntry('6. June', 'Common', 'Special Days'),
  BoardHierarchyEntry('7. July', 'Common', 'Special Days'),
  BoardHierarchyEntry('8. August', 'Common', 'Special Days'),
  BoardHierarchyEntry('9. September', 'Common', 'Special Days'),
  BoardHierarchyEntry('Abstract Nouns (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Adjectives (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Adverbs (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Africa (North)', 'Common', 'World Map'),
  BoardHierarchyEntry('Africa (South)', 'Common', 'World Map'),
  BoardHierarchyEntry('Articles (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Asia (Central)', 'Common', 'World Map'),
  BoardHierarchyEntry('Asia (East)', 'Common', 'World Map'),
  BoardHierarchyEntry('Asia (North)', 'Common', 'World Map'),
  BoardHierarchyEntry('Asia (South)', 'Common', 'World Map'),
  BoardHierarchyEntry('Asia (West)', 'Common', 'World Map'),
  BoardHierarchyEntry('Auxiliary Verbs (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Board Games', 'Common', 'Toys'),
  BoardHierarchyEntry('Canada and Greenland', 'Common', 'World Map'),
  BoardHierarchyEntry('Collective Nouns (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Conjunctions (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Europe', 'Common', 'World Map'),
  BoardHierarchyEntry('Gerunds (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Halloween Keywords', 'Common', 'Events and Occasions'),
  BoardHierarchyEntry('Home Equipment (Common)', 'Common', 'Home Management (Common)'),
  BoardHierarchyEntry('Interjections (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Intransitive Verbs (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Linking Verbs (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Nouns (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Oceania', 'Common', 'World Map'),
  BoardHierarchyEntry('Others (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Participles (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Passover Keywords', 'Common', 'Events and Occasions'),
  BoardHierarchyEntry('Prepositions (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Pronouns (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Proper Nouns (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Punctuation', 'Common', 'Small Words'),
  BoardHierarchyEntry('South America', 'Common', 'World Map'),
  BoardHierarchyEntry('Transitive Verbs (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('United Kingdom', 'Common', 'Europe'),
  BoardHierarchyEntry('Buildings', 'Common', 'Places'),
  BoardHierarchyEntry('Easter Keywords', 'Common', 'Events and Occasions'),
  BoardHierarchyEntry('Furniture', 'Common', 'Rooms and Home'),
  BoardHierarchyEntry('Mammals', 'Common', 'Animals'),
  BoardHierarchyEntry('Seasons (Common)', 'Common', 'Weather'),
  BoardHierarchyEntry('Time (Clocks)', 'Common', 'Time'),
  BoardHierarchyEntry('Appliances', 'Common', 'Rooms and Home'),
  BoardHierarchyEntry('Birds', 'Common', 'Animals'),
  BoardHierarchyEntry('Months', 'Common', 'Time'),
  BoardHierarchyEntry('Rooms and Home', 'Common', 'Places'),
  BoardHierarchyEntry('Small Words', 'Common'),
  BoardHierarchyEntry('Bonfire Night Keywords', 'Common', 'Events and Occasions'),
  BoardHierarchyEntry('Events and Occasions', 'Common', 'Time'),
  BoardHierarchyEntry('Food Equipment', 'Common', 'Rooms and Home'),
  BoardHierarchyEntry('Reptiles', 'Common', 'Animals'),
  BoardHierarchyEntry('Amphibians', 'Common', 'Animals'),
  BoardHierarchyEntry('Christmas Keywords', 'Common', 'Events and Occasions'),
  BoardHierarchyEntry('Habitats', 'Common', 'Places'),
  BoardHierarchyEntry('Home Management (Common)', 'Common', 'Rooms and Home'),
  BoardHierarchyEntry('Insects', 'Common', 'Animals'),
  BoardHierarchyEntry('Local Places', 'Common', 'Places'),
  BoardHierarchyEntry('Special Days', 'Common', 'Events and Occasions'),
  BoardHierarchyEntry('Arachnids', 'Common', 'Animals'),
  BoardHierarchyEntry('Invertebrates', 'Common', 'Animals'),
  BoardHierarchyEntry('Fish', 'Common', 'Animals'),
  BoardHierarchyEntry('Verbs (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Sealife', 'Common', 'Animals'),
  BoardHierarchyEntry('Nature Vocabulary', 'Common', 'Animals'),
  BoardHierarchyEntry('Body Parts Of Animals', 'Common', 'Animals'),
  BoardHierarchyEntry('Jobs and Careers', 'Common'),
  BoardHierarchyEntry('Child Animals', 'Common', 'Animals'),
  BoardHierarchyEntry('Groups Of Animals', 'Common', 'Animals'),
  BoardHierarchyEntry('Transport', 'Common'),
  BoardHierarchyEntry('World Map', 'Common'),
  BoardHierarchyEntry('Letters', 'Common'),
  BoardHierarchyEntry('Phonics', 'Common', 'Letters'),
  BoardHierarchyEntry('Phase 2 Phonics', 'Common', 'Phonics'),
  BoardHierarchyEntry('Phase 3 Phonics', 'Common', 'Phonics'),
  BoardHierarchyEntry('Phase 4 Phonics', 'Common', 'Phonics'),
  BoardHierarchyEntry('Phase 5 Phonics', 'Common', 'Phonics'),
  BoardHierarchyEntry('Phase 6 Phonics', 'Common', 'Phonics'),
  BoardHierarchyEntry('Numbers', 'Common'),
  BoardHierarchyEntry('Feelings (Common)', 'Common'),
  BoardHierarchyEntry('Sad', 'Common', 'Feelings (Common)'),
  BoardHierarchyEntry('Mad', 'Common', 'Feelings (Common)'),
  BoardHierarchyEntry('Scared', 'Common', 'Feelings (Common)'),
  BoardHierarchyEntry('Joyful', 'Common', 'Feelings (Common)'),
  BoardHierarchyEntry('Strong', 'Common', 'Feelings (Common)'),
  BoardHierarchyEntry('Calm', 'Common', 'Feelings (Common)'),
  BoardHierarchyEntry('Actions', 'Common'),
  BoardHierarchyEntry('Movement', 'Common', 'Actions'),
  BoardHierarchyEntry('People (Common)', 'Common'),
  BoardHierarchyEntry('School People', 'Common', 'People (Common)'),
  BoardHierarchyEntry('Places', 'Common'),
  BoardHierarchyEntry('Colours', 'Common'),
  BoardHierarchyEntry('Shades Of Colours', 'Common', 'Colours'),
  BoardHierarchyEntry('Prepositions', 'Common'),
  BoardHierarchyEntry('Body Parts', 'Common'),
  BoardHierarchyEntry('Medical', 'Common', 'Body Parts'),
  BoardHierarchyEntry('Internal Organs', 'Common', 'Body Parts'),
  BoardHierarchyEntry('Animals', 'Common'),
  BoardHierarchyEntry('Dinosaurs', 'Common', 'Reptiles'),
  BoardHierarchyEntry('Time', 'Common'),
  BoardHierarchyEntry('Clothes', 'Common'),
  BoardHierarchyEntry('Toys', 'Common'),
  BoardHierarchyEntry('Weather', 'Common'),
  BoardHierarchyEntry('Money', 'Common'),
  BoardHierarchyEntry('Central America and the Caribbean', 'Common', 'World Map'),
  BoardHierarchyEntry('North American States', 'Common', 'World Map'),
  BoardHierarchyEntry('Disasters (Common)', 'Common', 'Weather'),
  BoardHierarchyEntry('Legends', 'Legends'),
  BoardHierarchyEntry('1982 The Secret Of Nimh', 'Legends', 'Animations (Not Disney)'),
  BoardHierarchyEntry('1989 Wallace and Gromit', 'Legends', 'Animations (Not Disney)'),
  BoardHierarchyEntry('1997 Anastasia', 'Legends', 'Animations (Not Disney)'),
  BoardHierarchyEntry('1998 The Prince Of Egypt', 'Legends', 'Animations (Not Disney)'),
  BoardHierarchyEntry('1999 The Iron Giant', 'Legends', 'Animations (Not Disney)'),
  BoardHierarchyEntry('2000 The Road To El Dorado', 'Legends', 'Animations (Not Disney)'),
  BoardHierarchyEntry('2001 Shrek', 'Legends', 'Animations (Not Disney)'),
  BoardHierarchyEntry('2002 Ice Age', 'Legends', 'Animations (Not Disney)'),
  BoardHierarchyEntry('2007 Enchanted', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('2010 Despicable Me and Minions', 'Legends', 'Animations (Not Disney)'),
  BoardHierarchyEntry('2010 How To Train Your Dragon', 'Legends', 'Animations (Not Disney)'),
  BoardHierarchyEntry('Charlie and The Chocolate Factory', 'Legends', 'Books'),
  BoardHierarchyEntry('Gargoyles', 'Legends', 'Cartoons and Puppets'),
  BoardHierarchyEntry('Sesame Street', 'Legends', 'Cartoons and Puppets'),
  BoardHierarchyEntry('Golden Axe', 'Legends', 'Computer Games'),
  BoardHierarchyEntry('Kid Chameleon', 'Legends', 'Computer Games'),
  BoardHierarchyEntry('Legacy of Kain', 'Legends', 'Computer Games'),
  BoardHierarchyEntry('Street Fighter', 'Legends', 'Computer Games'),
  BoardHierarchyEntry('Streets of Rage', 'Legends', 'Computer Games'),
  BoardHierarchyEntry('1937 Snow White and The Seven Dwarfs', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1940 Fantasia', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1940 Pinocchio', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1941 Dumbo', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1942 Bambi', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1950 Cinderella', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1951 Alice In Wonderland', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1953 Peter Pan', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1955 Lady and The Tramp', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1959 Sleeping Beauty', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1961 101 Dalmatians', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1963 The Sword In The Stone', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1964 Mary Poppins', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1967 The Jungle Book', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1970 The Aristocats', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1971 Bedknobs and Broomsticks', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1973 Robin Hood', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1977 Pete\'s Dragon', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1977 The Rescuers', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1977 Winnie The Pooh', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1981 The Fox and The Hound', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1985 The Black Cauldron', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1986 An American Tail', 'Legends', 'Animations (Not Disney)'),
  BoardHierarchyEntry('1986 The Great Mouse Detective', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1988 Oliver and Company', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1988 The Land Before Time', 'Legends', 'Animations (Not Disney)'),
  BoardHierarchyEntry('1989 All Dogs Go to Heaven', 'Legends', 'Animations (Not Disney)'),
  BoardHierarchyEntry('1988 Who Framed Roger Rabbit', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1989 The Little Mermaid', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1991 Beauty and The Beast', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1992 Aladdin', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1993 The Nightmare Before Christmas', 'Legends', 'Animations (Not Disney)'),
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
  BoardHierarchyEntry('2002 Lilo and Stitch', 'Legends', 'Disney Stories'),
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
  BoardHierarchyEntry('2009 The Princess and The Frog', 'Legends', 'Disney Stories'),
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
  BoardHierarchyEntry('2021 Raya and The Last Dragon', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('2022 Strange World', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('2022 Turning Red', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('2023 Elemental', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('2023 Wish', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('2025 Elio', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('80s TV Shows', 'Legends', 'Cartoons and Puppets'),
  BoardHierarchyEntry('Angels', 'Legends', 'Christian Angels and Demons'),
  BoardHierarchyEntry('Animaniacs', 'Legends', 'Cartoons and Puppets'),
  BoardHierarchyEntry('Animations (Not Disney)', 'Legends'),
  BoardHierarchyEntry('Ant-Man', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Flash Gordon', 'Legends', 'Sci-Fi and Fantasy'),
  BoardHierarchyEntry('Anti-Mutant Threats', 'Legends', 'X-Men'),
  BoardHierarchyEntry('Apocalypse and The Horsemen', 'Legends', 'X-Men'),
  BoardHierarchyEntry('Aquaman', 'Legends', 'DC'),
  BoardHierarchyEntry('Arabian and Middle Eastern Tales', 'Legends', 'Religion, Myth and History'),
  BoardHierarchyEntry('Arthurian Legend', 'Legends', 'Religion, Myth and History'),
  BoardHierarchyEntry('Asian Legends and Folklore', 'Legends', 'Religion, Myth and History'),
  BoardHierarchyEntry('Baldur\'s Gate 3', 'Legends', 'Computer Games'),
  BoardHierarchyEntry('Bat Family', 'Legends', 'DC'),
  BoardHierarchyEntry('Black Panther', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Black Widow and Hawkeye', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Bleach', 'Legends', 'Sci-Fi and Fantasy'),
  BoardHierarchyEntry('Blueprints', 'Legends', 'The Expanse'),
  BoardHierarchyEntry('Books', 'Legends'),
  BoardHierarchyEntry('Borderlands', 'Legends', 'Computer Games'),
  BoardHierarchyEntry('Brotherhood of Mutants', 'Legends', 'X-Men'),
  BoardHierarchyEntry('Buddhism Deities and People', 'Legends', 'Gods, Titans, Heroes and Monsters'),
  BoardHierarchyEntry('Burning Shores', 'Legends', 'Horizon'),
  BoardHierarchyEntry('Captain America', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Cartoons and Puppets', 'Legends'),
  BoardHierarchyEntry('Christian Angels and Demons', 'Legends', 'Christian Deities and People'),
  BoardHierarchyEntry('Christian Deities and People', 'Legends', 'Gods, Titans, Heroes and Monsters'),
  BoardHierarchyEntry('Computer Games', 'Legends'),
  BoardHierarchyEntry('Creatures and Races', 'Legends', 'Religion, Myth and History'),
  BoardHierarchyEntry('Cuphead', 'Legends', 'Computer Games'),
  BoardHierarchyEntry('Custom Eeveelutions', 'Legends', 'Pokemon'),
  BoardHierarchyEntry('DC', 'Legends', 'Superheroes'),
  BoardHierarchyEntry('Deadpool', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Deep Space 9', 'Legends', 'Star Trek'),
  BoardHierarchyEntry('Demons', 'Legends', 'Christian Angels and Demons'),
  BoardHierarchyEntry('Discovery', 'Legends', 'Star Trek'),
  BoardHierarchyEntry('Disney Stories', 'Legends'),
  BoardHierarchyEntry('DnD', 'Legends', 'Sci-Fi and Fantasy'),
  BoardHierarchyEntry('DnD Classes', 'Legends', 'DnD'),
  BoardHierarchyEntry('DnD Magic and Status', 'Legends', 'DnD'),
  BoardHierarchyEntry('DnD Races', 'Legends', 'DnD'),
  BoardHierarchyEntry('Doctor Strange', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Doctor Who', 'Legends', 'Sci-Fi and Fantasy'),
  BoardHierarchyEntry('Doom Patrol', 'Legends', 'DC'),
  BoardHierarchyEntry('Dragon Age', 'Legends', 'Computer Games'),
  BoardHierarchyEntry('Egyptian Gods', 'Legends', 'Gods, Titans, Heroes and Monsters'),
  BoardHierarchyEntry('Enterprise', 'Legends', 'Star Trek'),
  BoardHierarchyEntry('Eternals', 'Legends', 'Marvel'),
  BoardHierarchyEntry('FF10', 'Legends', 'Final Fantasy'),
  BoardHierarchyEntry('FF12', 'Legends', 'Final Fantasy'),
  BoardHierarchyEntry('FF13', 'Legends', 'Final Fantasy'),
  BoardHierarchyEntry('FF15', 'Legends', 'Final Fantasy'),
  BoardHierarchyEntry('FF16', 'Legends', 'Final Fantasy'),
  BoardHierarchyEntry('FF6', 'Legends', 'Final Fantasy'),
  BoardHierarchyEntry('FF7', 'Legends', 'Final Fantasy'),
  BoardHierarchyEntry('FF8', 'Legends', 'Final Fantasy'),
  BoardHierarchyEntry('FF9', 'Legends', 'Final Fantasy'),
  BoardHierarchyEntry('Fable', 'Legends', 'Computer Games'),
  BoardHierarchyEntry('Fairy Tale Characters', 'Legends', 'Religion, Myth and History'),
  BoardHierarchyEntry('Family Trees', 'Legends', 'Gods, Titans, Heroes and Monsters'),
  BoardHierarchyEntry('Famous Monsters and Horror Icons', 'Legends', 'Religion, Myth and History'),
  BoardHierarchyEntry('Fantastic 4', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Farscape', 'Legends', 'Sci-Fi and Fantasy'),
  BoardHierarchyEntry('Final Fantasy', 'Legends', 'Computer Games'),
  BoardHierarchyEntry('Forbidden West', 'Legends', 'Horizon'),
  BoardHierarchyEntry('Frozen Wilds', 'Legends', 'Horizon'),
  BoardHierarchyEntry('Generation X', 'Legends', 'X-Men'),
  BoardHierarchyEntry('Ghostbusters', 'Legends', 'Cartoons and Puppets'),
  BoardHierarchyEntry('Gods, Titans, Heroes and Monsters', 'Legends', 'Religion, Myth and History'),
  BoardHierarchyEntry('Greek Gods', 'Legends', 'Gods, Titans, Heroes and Monsters'),
  BoardHierarchyEntry('Green Arrow', 'Legends', 'DC'),
  BoardHierarchyEntry('Green Lantern', 'Legends', 'DC'),
  BoardHierarchyEntry('Gremlins', 'Legends', 'Sci-Fi and Fantasy'),
  BoardHierarchyEntry('Guardians Of The Galaxy', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Heartless', 'Legends', 'Kingdom Hearts'),
  BoardHierarchyEntry('Hellfire Club', 'Legends', 'X-Men'),
  BoardHierarchyEntry('Heroes and Monsters (Greek and Roman)', 'Legends', 'Gods, Titans, Heroes and Monsters'),
  BoardHierarchyEntry('Hindu Deities and People', 'Legends', 'Gods, Titans, Heroes and Monsters'),
  BoardHierarchyEntry('Hollow Knight', 'Legends', 'Computer Games'),
  BoardHierarchyEntry('Horizon', 'Legends', 'Computer Games'),
  BoardHierarchyEntry('Hulk', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Inhumans', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Iron Man', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Islam Deities and People', 'Legends', 'Gods, Titans, Heroes and Monsters'),
  BoardHierarchyEntry('Jewish Deities and People', 'Legends', 'Gods, Titans, Heroes and Monsters'),
  BoardHierarchyEntry('Justice League', 'Legends', 'DC'),
  BoardHierarchyEntry('Justice League Dark  Supernatural', 'Legends', 'DC'),
  BoardHierarchyEntry('Kingdom Hearts', 'Legends', 'Computer Games'),
  BoardHierarchyEntry('Known Races', 'Legends', 'Star Trek'),
  BoardHierarchyEntry('Legendary Heroes and Folk Heroes', 'Legends', 'Religion, Myth and History'),
  BoardHierarchyEntry('Legends Of Tomorrow', 'Legends', 'DC'),
  BoardHierarchyEntry('Literary and Gothic Characters', 'Legends', 'Religion, Myth and History'),
  BoardHierarchyEntry('Looney Tunes', 'Legends', 'Cartoons and Puppets'),
  BoardHierarchyEntry('Lower Decks', 'Legends', 'Star Trek'),
  BoardHierarchyEntry('Major Villains', 'Legends', 'X-Men'),
  BoardHierarchyEntry('Marauders', 'Legends', 'X-Men'),
  BoardHierarchyEntry('Mario', 'Legends', 'Computer Games'),
  BoardHierarchyEntry('Marvel', 'Legends', 'Superheroes'),
  BoardHierarchyEntry('Misc', 'Legends', 'Religion, Myth and History'),
  BoardHierarchyEntry('Morlocks', 'Legends', 'X-Men'),
  BoardHierarchyEntry('New Gods, Apokolips and Cosmic Villains', 'Legends', 'DC'),
  BoardHierarchyEntry('New Mutants', 'Legends', 'X-Men'),
  BoardHierarchyEntry('No Man\'s Sky', 'Legends', 'Computer Games'),
  BoardHierarchyEntry('Nobodies', 'Legends', 'Kingdom Hearts'),
  BoardHierarchyEntry('Norse Gods', 'Legends', 'Gods, Titans, Heroes and Monsters'),
  BoardHierarchyEntry('Norse Heroes', 'Legends', 'Norse Gods'),
  BoardHierarchyEntry('Norse Locations', 'Legends', 'Norse Gods'),
  BoardHierarchyEntry('Norse Races', 'Legends', 'Norse Gods'),
  BoardHierarchyEntry('Norse Valkyries', 'Legends', 'Norse Gods'),
  BoardHierarchyEntry('Olympians', 'Legends', 'Greek Gods'),
  BoardHierarchyEntry('Ori', 'Legends', 'Computer Games'),
  BoardHierarchyEntry('Other', 'Legends', 'X-Men'),
  BoardHierarchyEntry('Other Mythology', 'Legends', 'Gods, Titans, Heroes and Monsters'),
  BoardHierarchyEntry('Other Teams', 'Legends', 'DC'),
  BoardHierarchyEntry('Pagan Deities and People', 'Legends', 'Gods, Titans, Heroes and Monsters'),
  BoardHierarchyEntry('Palworld', 'Legends', 'Computer Games'),
  BoardHierarchyEntry('Picard', 'Legends', 'Star Trek'),
  BoardHierarchyEntry('Pokeballs and Important Items', 'Legends', 'Pokemon'),
  BoardHierarchyEntry('Pokemon', 'Legends', 'Computer Games'),
  BoardHierarchyEntry('Pokemon - Gen 1 - Kanto (Fire Red, Leaf Green, Ocean Blue, Lightning Yellow)', 'Legends', 'Pokemon'),
  BoardHierarchyEntry('Pokemon - Gen 2 - Johto (Silver and Gold)', 'Legends', 'Pokemon'),
  BoardHierarchyEntry('Pokemon - Gen 4 - Sinnoh (Diamond and Pearl)', 'Legends', 'Pokemon'),
  BoardHierarchyEntry('Pokemon - Gen 5 - Unova (Black and White)', 'Legends', 'Pokemon'),
  BoardHierarchyEntry('Pokemon - Gen 6 - Kalos (X and Y)', 'Legends', 'Pokemon'),
  BoardHierarchyEntry('Pokemon - Gen 7 - Alola (Sun and Moon)', 'Legends', 'Pokemon'),
  BoardHierarchyEntry('Pokemon - Gen 8 - Galar (Sword and Shield)', 'Legends', 'Pokemon'),
  BoardHierarchyEntry('Pokemon - Gen 9 - Paldea (Scarlet and Violet)', 'Legends', 'Pokemon'),
  BoardHierarchyEntry('Pokemon Missed Evolutions', 'Legends', 'Pokemon'),
  BoardHierarchyEntry('Prodigy', 'Legends', 'Star Trek'),
  BoardHierarchyEntry('ReBoot', 'Legends', 'Cartoons and Puppets'),
  BoardHierarchyEntry('Real Life Heroes', 'Legends'),
  BoardHierarchyEntry('Activism, Charity and Heroism', 'Legends', 'Real Life Heroes'),
  BoardHierarchyEntry('Celebrated Writers', 'Legends', 'Real Life Heroes'),
  BoardHierarchyEntry('Culinary Masters', 'Legends', 'Real Life Heroes'),
  BoardHierarchyEntry('Famous Actors', 'Legends', 'Real Life Heroes'),
  BoardHierarchyEntry('Fashionable Designers', 'Legends', 'Real Life Heroes'),
  BoardHierarchyEntry('Financial Gurus', 'Legends', 'Real Life Heroes'),
  BoardHierarchyEntry('Intrepid Explorers', 'Legends', 'Real Life Heroes'),
  BoardHierarchyEntry('Musical Practitioners', 'Legends', 'Real Life Heroes'),
  BoardHierarchyEntry('Overcoming Challenges', 'Legends', 'Real Life Heroes'),
  BoardHierarchyEntry('Political Figures', 'Legends', 'Real Life Heroes'),
  BoardHierarchyEntry('Popular Artists', 'Legends', 'Real Life Heroes'),
  BoardHierarchyEntry('Scientific Pioneers', 'Legends', 'Real Life Heroes'),
  BoardHierarchyEntry('Sporting Icons', 'Legends', 'Real Life Heroes'),
  BoardHierarchyEntry('Religion, Myth and History', 'Legends'),
  BoardHierarchyEntry('Robin Hood and English Folklore', 'Legends', 'Religion, Myth and History'),
  BoardHierarchyEntry('Roman Gods', 'Legends', 'Gods, Titans, Heroes and Monsters'),
  BoardHierarchyEntry('Scarlet Witch', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Sci-Fi and Fantasy', 'Legends'),
  BoardHierarchyEntry('Shazam', 'Legends', 'DC'),
  BoardHierarchyEntry('Sikh Deities and People', 'Legends', 'Gods, Titans, Heroes and Monsters'),
  BoardHierarchyEntry('Sonic', 'Legends', 'Computer Games'),
  BoardHierarchyEntry('Spiderman', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Star Trek', 'Legends', 'Sci-Fi and Fantasy'),
  BoardHierarchyEntry('Star Wars', 'Legends', 'Sci-Fi and Fantasy'),
  BoardHierarchyEntry('Starfleet Academy', 'Legends', 'Star Trek'),
  BoardHierarchyEntry('Starships', 'Legends', 'Star Trek'),
  BoardHierarchyEntry('Strange New Worlds', 'Legends', 'Star Trek'),
  BoardHierarchyEntry('Super Family', 'Legends', 'DC'),
  BoardHierarchyEntry('Superheroes', 'Legends'),
  BoardHierarchyEntry('Teen Titans', 'Legends', 'DC'),
  BoardHierarchyEntry('The Animated Series', 'Legends', 'Star Trek'),
  BoardHierarchyEntry('The Avengers', 'Legends', 'Marvel'),
  BoardHierarchyEntry('The Defenders and Street Level', 'Legends', 'Marvel'),
  BoardHierarchyEntry('The Expanse', 'Legends', 'Sci-Fi and Fantasy'),
  BoardHierarchyEntry('The Flash', 'Legends', 'DC'),
  BoardHierarchyEntry('The Hobbit', 'Legends', 'The Lord Of The Rings'),
  BoardHierarchyEntry('The House Of Mouse', 'Legends', 'Cartoons and Puppets'),
  BoardHierarchyEntry('The Lord Of The Rings', 'Legends', 'Sci-Fi and Fantasy'),
  BoardHierarchyEntry('The Muppets', 'Legends', 'Cartoons and Puppets'),
  BoardHierarchyEntry('The Next Generation', 'Legends', 'Star Trek'),
  BoardHierarchyEntry('The Original Series', 'Legends', 'Star Trek'),
  BoardHierarchyEntry('The Orville', 'Legends', 'Sci-Fi and Fantasy'),
  BoardHierarchyEntry('The Simpsons', 'Legends', 'Cartoons and Puppets'),
  BoardHierarchyEntry('The Turtles', 'Legends', 'Cartoons and Puppets'),
  BoardHierarchyEntry('The X-Men', 'Legends', 'X-Men'),
  BoardHierarchyEntry('The X-Men Main Team', 'Legends', 'X-Men'),
  BoardHierarchyEntry('Thor', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Titans', 'Legends', 'Greek Gods'),
  BoardHierarchyEntry('Villains', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Voyager', 'Legends', 'Star Trek'),
  BoardHierarchyEntry('Weapon Program', 'Legends', 'X-Men'),
  BoardHierarchyEntry('Wednesday', 'Legends', 'Sci-Fi and Fantasy'),
  BoardHierarchyEntry('Wonder Woman', 'Legends', 'DC'),
  BoardHierarchyEntry('X-Factor and Excalibur', 'Legends', 'X-Men'),
  BoardHierarchyEntry('X-Force', 'Legends', 'X-Men'),
  BoardHierarchyEntry('X-Men', 'Legends', 'Superheroes'),
  BoardHierarchyEntry('X-Men Later Additions', 'Legends', 'X-Men'),
  BoardHierarchyEntry('Xavier\'s Students', 'Legends', 'X-Men'),
  BoardHierarchyEntry('Zero Dawn', 'Legends', 'Horizon'),
  BoardHierarchyEntry('Zero Dawn Project', 'Legends', 'Horizon'),
  BoardHierarchyEntry('Pokemon - Gen 3 - Hoenn (Ruby and Sapphire)', 'Legends', 'Pokemon'),
  BoardHierarchyEntry('My School Main', 'My School'),
  BoardHierarchyEntry('Baycroft Expects', 'My School'),
  BoardHierarchyEntry('Thinking Skills', 'My School'),
  BoardHierarchyEntry('When Things Go Wrong', 'My School'),
  BoardHierarchyEntry('Blank Levels', 'My School'),
  BoardHierarchyEntry('My School Lessons', 'My School'),
  BoardHierarchyEntry('Class Equipment', 'My School'),
  BoardHierarchyEntry('Food Options', 'My School'),
  BoardHierarchyEntry('Other Useful Stuff', 'My School'),
  BoardHierarchyEntry('School Events', 'My School'),
  BoardHierarchyEntry('Timetables', 'My School'),
  BoardHierarchyEntry('People at Baycroft', 'My School'),
  BoardHierarchyEntry('7EmS', 'My School', 'People at Baycroft'),
  BoardHierarchyEntry('7LDo', 'My School', 'People at Baycroft'),
  BoardHierarchyEntry('7MCa', 'My School', 'People at Baycroft'),
  BoardHierarchyEntry('7NGr', 'My School', 'People at Baycroft'),
  BoardHierarchyEntry('8LBr', 'My School', 'People at Baycroft'),
  BoardHierarchyEntry('8MGr', 'My School', 'People at Baycroft'),
  BoardHierarchyEntry('8SLP', 'My School', 'People at Baycroft'),
  BoardHierarchyEntry('9EBl', 'My School', 'People at Baycroft'),
  BoardHierarchyEntry('9LMc', 'My School', 'People at Baycroft'),
  BoardHierarchyEntry('9RCo', 'My School', 'People at Baycroft'),
  BoardHierarchyEntry('10BCl', 'My School', 'People at Baycroft'),
  BoardHierarchyEntry('10KLa', 'My School', 'People at Baycroft'),
  BoardHierarchyEntry('10RLi', 'My School', 'People at Baycroft'),
  BoardHierarchyEntry('11HSu', 'My School', 'People at Baycroft'),
  BoardHierarchyEntry('11STo', 'My School', 'People at Baycroft'),
  BoardHierarchyEntry('RLP', 'My School', 'People at Baycroft'),
  BoardHierarchyEntry('KL', 'My School', 'People at Baycroft'),
  BoardHierarchyEntry('AW', 'My School', 'People at Baycroft'),
  BoardHierarchyEntry('safeguarding team', 'My School', 'People at Baycroft'),
  BoardHierarchyEntry('senior leadership', 'My School', 'People at Baycroft'),
  BoardHierarchyEntry('helpful people', 'My School', 'People at Baycroft'),
  BoardHierarchyEntry('governors and friends of baycroft', 'My School', 'People at Baycroft'),
  BoardHierarchyEntry('Personal', 'Personal'),
  BoardHierarchyEntry('Common Interests', 'Personal'),
  BoardHierarchyEntry('Confectionery', 'Personal'),
  BoardHierarchyEntry('Sweets', 'Personal', 'Confectionery'),
  BoardHierarchyEntry('Chocolates', 'Personal', 'Confectionery'),
  BoardHierarchyEntry('Crisps', 'Personal', 'Confectionery'),
  BoardHierarchyEntry('Recipes', 'Recipes'),
  BoardHierarchyEntry('Bacon and Mushroom Risotto', 'Recipes'),
  BoardHierarchyEntry('Banana Dolphins', 'Recipes'),
  BoardHierarchyEntry('Beef Lasagne', 'Recipes'),
  BoardHierarchyEntry('Breakfast Muffins', 'Recipes'),
  BoardHierarchyEntry('Brilliant Bread', 'Recipes'),
  BoardHierarchyEntry('Chicken Fajitas', 'Recipes'),
  BoardHierarchyEntry('Chilli Con Carne', 'Recipes'),
  BoardHierarchyEntry('Christmas Cookies', 'Recipes'),
  BoardHierarchyEntry('Cottage Pie', 'Recipes'),
  BoardHierarchyEntry('Cupcakes', 'Recipes'),
  BoardHierarchyEntry('Dutch Apple Cake', 'Recipes'),
  BoardHierarchyEntry('Easy Veg Frittatas', 'Recipes'),
  BoardHierarchyEntry('Egg Fried Rice', 'Recipes'),
  BoardHierarchyEntry('Eggy Bread', 'Recipes'),
  BoardHierarchyEntry('Fruit Scones', 'Recipes'),
  BoardHierarchyEntry('Ginger Biscuits', 'Recipes'),
  BoardHierarchyEntry('Herby Veg Crumble', 'Recipes'),
  BoardHierarchyEntry('Italian Pasta', 'Recipes'),
  BoardHierarchyEntry('Macaroni Cheese', 'Recipes'),
  BoardHierarchyEntry('Mince Pies', 'Recipes'),
  BoardHierarchyEntry('Mini Carrot Cakes', 'Recipes'),
  BoardHierarchyEntry('Mini Meatballs', 'Recipes'),
  BoardHierarchyEntry('Pasta Fiorentina', 'Recipes'),
  BoardHierarchyEntry('Pizza Toast', 'Recipes'),
  BoardHierarchyEntry('Pizza Wheels', 'Recipes'),
  BoardHierarchyEntry('Potato Cakes', 'Recipes'),
  BoardHierarchyEntry('Savoury Rice', 'Recipes'),
  BoardHierarchyEntry('Simple Spring Rolls', 'Recipes'),
  BoardHierarchyEntry('Sizzling Stir Fry', 'Recipes'),
  BoardHierarchyEntry('Spicy Bean Burger', 'Recipes'),
  BoardHierarchyEntry('Sweet Pancake', 'Recipes'),
  BoardHierarchyEntry('Thai Green Curry', 'Recipes'),
  BoardHierarchyEntry('Toastie', 'Recipes'),
  BoardHierarchyEntry('Tomato and Basil Tart', 'Recipes'),
  BoardHierarchyEntry('Tuna Pasta Bake', 'Recipes'),
  BoardHierarchyEntry('Turkey Burgers', 'Recipes'),
  BoardHierarchyEntry('Veg Cous Cous Salad', 'Recipes'),
  BoardHierarchyEntry('Veg Soup', 'Recipes'),
  BoardHierarchyEntry('Vegetable Samosas', 'Recipes'),
  BoardHierarchyEntry('Sign', 'Sign'),
  BoardHierarchyEntry('A-Z Of Sign', 'Sign'),
  BoardHierarchyEntry('Animals and Nature', 'Sign'),
  BoardHierarchyEntry('Clothing and Personal', 'Sign'),
  BoardHierarchyEntry('Colours (Sign)', 'Sign'),
  BoardHierarchyEntry('Family and People', 'Sign'),
  BoardHierarchyEntry('Feelings and Health', 'Sign'),
  BoardHierarchyEntry('Food and Drink', 'Sign'),
  BoardHierarchyEntry('Gender and Sexuality (Sign)', 'Sign'),
  BoardHierarchyEntry('Home and Household', 'Sign'),
  BoardHierarchyEntry('Leisure Activities and Interests', 'Sign'),
  BoardHierarchyEntry('Letters (Sign)', 'Sign'),
  BoardHierarchyEntry('Manners and Greetings', 'Sign'),
  BoardHierarchyEntry('Money (Sign)', 'Sign'),
  BoardHierarchyEntry('Numbers (Sign)', 'Sign'),
  BoardHierarchyEntry('Places (Sign)', 'Sign'),
  BoardHierarchyEntry('Prepositions (Sign)', 'Sign'),
  BoardHierarchyEntry('Quantity and Measurement', 'Sign'),
  BoardHierarchyEntry('Religion and Customs', 'Sign'),
  BoardHierarchyEntry('School and Instructions', 'Sign'),
  BoardHierarchyEntry('Sign Of The Week', 'Sign'),
  BoardHierarchyEntry('Time and Days', 'Sign'),
  BoardHierarchyEntry('Transport and Vehicles', 'Sign'),
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
  BoardHierarchyEntry('Questions', 'Sign'),
  BoardHierarchyEntry('Grammatical Elements', 'Sign'),
  BoardHierarchyEntry('Personal Actions', 'Sign'),
  BoardHierarchyEntry('Personal Hygiene', 'Sign'),
  BoardHierarchyEntry('Personal Possessions', 'Sign'),
  BoardHierarchyEntry('General Objects', 'Sign'),
  BoardHierarchyEntry('Computer Items', 'Sign'),
  BoardHierarchyEntry('Sport', 'Sign'),
  BoardHierarchyEntry('Outside', 'Sign'),
  BoardHierarchyEntry('Public Notices', 'Sign'),
  BoardHierarchyEntry('Other Countries', 'Sign'),
  BoardHierarchyEntry('Descriptions and Attributes', 'Sign'),
  BoardHierarchyEntry('Shared Activities', 'Sign'),
  BoardHierarchyEntry('Weather (Sign)', 'Sign'),
  BoardHierarchyEntry('Subject Vocab', 'Subject Vocab'),
  BoardHierarchyEntry('Individual Gemstones', 'Subject Vocab', 'Gemstones and Jewels'),
  BoardHierarchyEntry('Trees', 'Subject Vocab', 'Horticulture'),
  BoardHierarchyEntry('Absorbent Or Waterproof', 'Subject Vocab', 'Material Properties'),
  BoardHierarchyEntry('Acids', 'Subject Vocab', 'Acids and Alkelis'),
  BoardHierarchyEntry('Gemstones and Jewels', 'Subject Vocab', 'Rocks'),
  BoardHierarchyEntry('Acids and Alkelis', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Air and Water Resistance', 'Subject Vocab', 'Forces'),
  BoardHierarchyEntry('Alcohol Awareness', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Algebra', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('Alkelis', 'Subject Vocab', 'Acids and Alkelis'),
  BoardHierarchyEntry('Ancient Egyptians (3100 BC – 30BC)', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Ancient Greeks (800 BC – 146 BC)', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Anglo-Saxons (410 – 1066)', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Animal Groups', 'Subject Vocab', 'Animals and Humans'),
  BoardHierarchyEntry('Appliances (Science)', 'Subject Vocab', 'Electrical Safety (Science)'),
  BoardHierarchyEntry('Art', 'Subject Vocab'),
  BoardHierarchyEntry('Artistic and Conceptual', 'Subject Vocab', 'Photography'),
  BoardHierarchyEntry('Artists, Context, Process, Assessment', 'Subject Vocab', 'Photography'),
  BoardHierarchyEntry('Aztecs	(1300 Bc - 1521 Bc)', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Basic Maths Vocab', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('Biodiversity', 'Subject Vocab', 'Sustainability'),
  BoardHierarchyEntry('Body Parts and Internal Organs', 'Subject Vocab', 'Animals and Humans'),
  BoardHierarchyEntry('Britain At War 1914–1918, 1939-1945', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('British Values', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Buddhism Creation Story', 'Subject Vocab', 'Creation Stories'),
  BoardHierarchyEntry('Bunsen Burners and Microscopes', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('CSI Plus', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Change Over Time', 'Subject Vocab', 'Evolution and Genes'),
  BoardHierarchyEntry('Changing Environment and Danger', 'Subject Vocab', 'Ecosystems (Science)'),
  BoardHierarchyEntry('Chemistry Of Cooking', 'Subject Vocab', 'Reactions'),
  BoardHierarchyEntry('Christian Creation Story', 'Subject Vocab', 'Creation Stories'),
  BoardHierarchyEntry('Circuit Symbols', 'Subject Vocab', 'Electricity'),
  BoardHierarchyEntry('Climate Change', 'Subject Vocab', 'Sustainability'),
  BoardHierarchyEntry('Company Logos', 'Subject Vocab', 'TFL / IT'),
  BoardHierarchyEntry('Condensation', 'Subject Vocab', 'Matter'),
  BoardHierarchyEntry('Cooling', 'Subject Vocab', 'Matter'),
  BoardHierarchyEntry('Crew', 'Subject Vocab', 'Pirates (PEEP)'),
  BoardHierarchyEntry('Darwin, Anning and Wallace', 'Subject Vocab', 'Evolution and Genes'),
  BoardHierarchyEntry('Describing Timbre', 'Subject Vocab', 'Music'),
  BoardHierarchyEntry('Development and Puberty', 'Subject Vocab', 'Animals and Humans'),
  BoardHierarchyEntry('Drugs', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('EPIC', 'Subject Vocab'),
  BoardHierarchyEntry('Earth\'s Layers', 'Subject Vocab', 'Rocks'),
  BoardHierarchyEntry('Ecosystems', 'Subject Vocab', 'Sustainability'),
  BoardHierarchyEntry('Editing and Post Production', 'Subject Vocab', 'Photography'),
  BoardHierarchyEntry('Electrical Safety', 'Subject Vocab', 'Keeping Safe'),
  BoardHierarchyEntry('Electrical Safety (Science)', 'Subject Vocab', 'Electricity'),
  BoardHierarchyEntry('Emergencies (PD)', 'Subject Vocab', 'Living In The Wider World'),
  BoardHierarchyEntry('Energy', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('English Monarchy', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Entry Level', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Environment (Retail)', 'Subject Vocab', 'Retail'),
  BoardHierarchyEntry('Equipment (Photography)', 'Subject Vocab', 'Photography'),
  BoardHierarchyEntry('Ethical Trading', 'Subject Vocab', 'Sustainability'),
  BoardHierarchyEntry('Evaporation', 'Subject Vocab', 'Matter'),
  BoardHierarchyEntry('Evolution', 'Subject Vocab', 'Evolution and Genes'),
  BoardHierarchyEntry('Famous Pirates', 'Subject Vocab', 'Pirates (PEEP)'),
  BoardHierarchyEntry('Famous Real Pirates', 'Subject Vocab', 'Pirates (PEEP)'),
  BoardHierarchyEntry('Final Frontier', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Finite Planet', 'Subject Vocab', 'Sustainability'),
  BoardHierarchyEntry('Flexible Or Rigid', 'Subject Vocab', 'Material Properties'),
  BoardHierarchyEntry('Float Or Sink', 'Subject Vocab', 'Material Properties'),
  BoardHierarchyEntry('Flowers', 'Subject Vocab', 'Horticulture'),
  BoardHierarchyEntry('Food Chains', 'Subject Vocab', 'Ecosystems (Science)'),
  BoardHierarchyEntry('Forces (2)', 'Subject Vocab', 'Forces'),
  BoardHierarchyEntry('Forces Recap', 'Subject Vocab', 'Levers, Pulleys and Gears'),
  BoardHierarchyEntry('Fractions and Percentages', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('Gears', 'Subject Vocab', 'Levers, Pulleys and Gears'),
  BoardHierarchyEntry('Gender and Sexuality', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Gravity', 'Subject Vocab', 'Forces'),
  BoardHierarchyEntry('Greek People', 'Subject Vocab', 'Ancient Greeks (800 BC – 146 BC)'),
  BoardHierarchyEntry('Habitats (Science)', 'Subject Vocab', 'Ecosystems (Science)'),
  BoardHierarchyEntry('Hair and Beauty', 'Subject Vocab'),
  BoardHierarchyEntry('Health and Social Care', 'Subject Vocab'),
  BoardHierarchyEntry('Heating', 'Subject Vocab', 'Matter'),
  BoardHierarchyEntry('Heating Materials Investigation', 'Subject Vocab', 'Reactions'),
  BoardHierarchyEntry('Heliocentricity Vs Geocentricity', 'Subject Vocab', 'Universe'),
  BoardHierarchyEntry('Heroes', 'Subject Vocab', 'Local Places'),
  BoardHierarchyEntry('Hinduism', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Hinduism Creation Story', 'Subject Vocab', 'Creation Stories'),
  BoardHierarchyEntry('Home Management (LLS)', 'Subject Vocab', 'Living Life Skills'),
  BoardHierarchyEntry('Houses', 'Subject Vocab', 'English Monarchy'),
  BoardHierarchyEntry('Industrial Revolution (1760 – 1840)', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Information Technology', 'Subject Vocab', 'TFL / IT'),
  BoardHierarchyEntry('Insulators and Conductors', 'Subject Vocab', 'Electricity'),
  BoardHierarchyEntry('Intro to Science', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Islam Creation Story', 'Subject Vocab', 'Creation Stories'),
  BoardHierarchyEntry('Jobs, Careers, Aspirations', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Judaism Creation Story', 'Subject Vocab', 'Creation Stories'),
  BoardHierarchyEntry('Keeping Safe', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Legislation (Retail)', 'Subject Vocab', 'Retail'),
  BoardHierarchyEntry('Let\'s Get Together', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Levers', 'Subject Vocab', 'Levers, Pulleys and Gears'),
  BoardHierarchyEntry('Light Sources', 'Subject Vocab', 'Light and Sound'),
  BoardHierarchyEntry('Lighting and Composition', 'Subject Vocab', 'Photography'),
  BoardHierarchyEntry('Living In The Wider World', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Living Life Skills', 'Subject Vocab'),
  BoardHierarchyEntry('Living Or Not', 'Subject Vocab', 'Ecosystems (Science)'),
  BoardHierarchyEntry('Local Heroes', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Local Places (PEEP)', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Magnetic Or Not', 'Subject Vocab', 'Forces'),
  BoardHierarchyEntry('Marketing', 'Subject Vocab', 'Retail'),
  BoardHierarchyEntry('Maths Resources', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('Maya (2000 Bc - 1697 Bc)', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Measurements (Length and Width, Perimeter and Area)', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('Moon Phases', 'Subject Vocab', 'Universe'),
  BoardHierarchyEntry('Mutations and Adaptations', 'Subject Vocab', 'Evolution and Genes'),
  BoardHierarchyEntry('Names Of Moon Phases', 'Subject Vocab', 'Moon Phases'),
  BoardHierarchyEntry('Natural Selection', 'Subject Vocab', 'Evolution and Genes'),
  BoardHierarchyEntry('Neutralisation', 'Subject Vocab', 'Acids and Alkelis'),
  BoardHierarchyEntry('Night, Day, Months and Seasons', 'Subject Vocab', 'Universe'),
  BoardHierarchyEntry('Operations', 'Subject Vocab', 'Retail'),
  BoardHierarchyEntry('Organs', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Our Solar System', 'Subject Vocab', 'Universe'),
  BoardHierarchyEntry('Outer Space', 'Subject Vocab', 'Universe'),
  BoardHierarchyEntry('Oxidation', 'Subject Vocab', 'Reactions'),
  BoardHierarchyEntry('PE', 'Subject Vocab'),
  BoardHierarchyEntry('Parachutes', 'Subject Vocab', 'Levers, Pulleys and Gears'),
  BoardHierarchyEntry('Parallel Construction', 'Subject Vocab', 'Electricity'),
  BoardHierarchyEntry('Passport', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Payment and Finance', 'Subject Vocab', 'Retail'),
  BoardHierarchyEntry('People (The Tudors)', 'Subject Vocab', 'The Tudors (1485 – 1603)'),
  BoardHierarchyEntry('Personal Development', 'Subject Vocab'),
  BoardHierarchyEntry('Pirate Crew', 'Subject Vocab', 'Pirates (PEEP)'),
  BoardHierarchyEntry('Pirates (PEEP)', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Pitch Patterns', 'Subject Vocab', 'Light and Sound'),
  BoardHierarchyEntry('Plant Life Cycle', 'Subject Vocab', 'Plants'),
  BoardHierarchyEntry('Plant Parts', 'Subject Vocab', 'Plants'),
  BoardHierarchyEntry('Pollination and Seed Dispersal', 'Subject Vocab', 'Plants'),
  BoardHierarchyEntry('Position and Direction', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('Prepare For Adulthood', 'Subject Vocab'),
  BoardHierarchyEntry('Programs', 'Subject Vocab', 'TFL / IT'),
  BoardHierarchyEntry('Pulleys', 'Subject Vocab', 'Levers, Pulleys and Gears'),
  BoardHierarchyEntry('Punctuation (Lessons)', 'Subject Vocab', 'Small Words (Subject)'),
  BoardHierarchyEntry('Ratios and Proportion', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('Reflection', 'Subject Vocab', 'Light and Sound'),
  BoardHierarchyEntry('Reproduction In Plants', 'Subject Vocab', 'Plants'),
  BoardHierarchyEntry('Reversible Or Irreversible?', 'Subject Vocab', 'Reactions'),
  BoardHierarchyEntry('Roman Empire (27 BC – 476)', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Roman Numerals', 'Subject Vocab', 'Roman Empire (27 BC – 476)'),
  BoardHierarchyEntry('S.T.E.M.', 'Subject Vocab'),
  BoardHierarchyEntry('Selective Breeding', 'Subject Vocab', 'Evolution and Genes'),
  BoardHierarchyEntry('Separating Mixtures', 'Subject Vocab', 'Reactions'),
  BoardHierarchyEntry('Shadows and Colour Spectrum', 'Subject Vocab', 'Light and Sound'),
  BoardHierarchyEntry('Shapes and Angles', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('Shiny Or Dull', 'Subject Vocab', 'Material Properties'),
  BoardHierarchyEntry('Ship Parts', 'Subject Vocab', 'Pirates (PEEP)'),
  BoardHierarchyEntry('Sikhism', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Sikhism Creation Story', 'Subject Vocab', 'Creation Stories'),
  BoardHierarchyEntry('Simple Series Circuit', 'Subject Vocab', 'Electricity'),
  BoardHierarchyEntry('Skeletons and Senses', 'Subject Vocab', 'Animals and Humans'),
  BoardHierarchyEntry('Slime, Bicarb and Vinegar Fountains', 'Subject Vocab', 'Reactions'),
  BoardHierarchyEntry('Solid, Liquid Or Gas', 'Subject Vocab', 'Matter'),
  BoardHierarchyEntry('Sound Sources', 'Subject Vocab', 'Light and Sound'),
  BoardHierarchyEntry('Staff (Retail)', 'Subject Vocab', 'Retail'),
  BoardHierarchyEntry('Statistics', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('Staying Healthy, Nutrition, Hygiene', 'Subject Vocab', 'Animals and Humans'),
  BoardHierarchyEntry('Structure Of Plants and Trees', 'Subject Vocab', 'Plants'),
  BoardHierarchyEntry('Structure and Function - Plant Parts', 'Subject Vocab', 'Plants'),
  BoardHierarchyEntry('Sun, Earth and Moon', 'Subject Vocab', 'Universe'),
  BoardHierarchyEntry('Survival, Offspring and Growth', 'Subject Vocab', 'Animals and Humans'),
  BoardHierarchyEntry('TFL - Year 7', 'Subject Vocab', 'TFL / IT'),
  BoardHierarchyEntry('TFL - Year 8', 'Subject Vocab', 'TFL / IT'),
  BoardHierarchyEntry('TFL - Year 9', 'Subject Vocab', 'TFL / IT'),
  BoardHierarchyEntry('TFL / IT', 'Subject Vocab'),
  BoardHierarchyEntry('TFL Equipment', 'Subject Vocab', 'TFL / IT'),
  BoardHierarchyEntry('Technical and Analytical', 'Subject Vocab', 'Photography'),
  BoardHierarchyEntry('The Great Fire Of London (1666)', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('The Home Front', 'Subject Vocab', 'Britain At War 1914–1918, 1939-1945'),
  BoardHierarchyEntry('The Muscles', 'Subject Vocab', 'Organs'),
  BoardHierarchyEntry('The Titanic (1912)', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('The Tudors (1485 – 1603)', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('The Water Cycle', 'Subject Vocab', 'Matter'),
  BoardHierarchyEntry('Tourism Hampshire', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Transparent, Translucent Or Opaque', 'Subject Vocab', 'Material Properties'),
  BoardHierarchyEntry('Tutor Time, Events and Clubs', 'Subject Vocab'),
  BoardHierarchyEntry('Tutor Transition', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Types Of Materials', 'Subject Vocab', 'Material Properties'),
  BoardHierarchyEntry('Variety and Dependency', 'Subject Vocab', 'Ecosystems (Science)'),
  BoardHierarchyEntry('Vertebrates and Invertebrates', 'Subject Vocab', 'Ecosystems (Science)'),
  BoardHierarchyEntry('Victorians (1837 – 1901)', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Voltage and Brightness', 'Subject Vocab', 'Electricity'),
  BoardHierarchyEntry('Water Scarcity', 'Subject Vocab', 'Sustainability'),
  BoardHierarchyEntry('Water Transportation In Plants', 'Subject Vocab', 'Plants'),
  BoardHierarchyEntry('Ways To Present', 'Subject Vocab'),
  BoardHierarchyEntry('Weight and Capacity', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('World Of Work', 'Subject Vocab', 'Prepare For Adulthood'),
  BoardHierarchyEntry('World War 1 (1914–1918)', 'Subject Vocab', 'Britain At War 1914–1918, 1939-1945'),
  BoardHierarchyEntry('World War 2 (1939–1945)', 'Subject Vocab', 'Britain At War 1914–1918, 1939-1945'),
  BoardHierarchyEntry('Year 7 Art', 'Subject Vocab', 'Art'),
  BoardHierarchyEntry('pH Scale Numbers', 'Subject Vocab', 'Acids and Alkelis'),
  BoardHierarchyEntry('No Small Words', 'Subject Vocab', 'Sentence Creator'),
  BoardHierarchyEntry('Time (Clocks) (Maths)', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('Small Words (Subject)', 'Subject Vocab'),
  BoardHierarchyEntry('With Small Words', 'Subject Vocab', 'Sentence Creator'),
  BoardHierarchyEntry('Advanced Sentence Building', 'Subject Vocab', 'Sentence Creator'),
  BoardHierarchyEntry('Fire Safety', 'Subject Vocab', 'Keeping Safe'),
  BoardHierarchyEntry('Nouns', 'Subject Vocab', 'Sentence Creator'),
  BoardHierarchyEntry('Train Safety', 'Subject Vocab', 'Keeping Safe'),
  BoardHierarchyEntry('Verbs', 'Subject Vocab', 'Sentence Creator'),
  BoardHierarchyEntry('Internet Safety', 'Subject Vocab', 'Keeping Safe'),
  BoardHierarchyEntry('Adverbs', 'Subject Vocab', 'Sentence Creator'),
  BoardHierarchyEntry('Feelings (Subject Vocab)', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Numbers (Subject)', 'Subject Vocab'),
  BoardHierarchyEntry('Home Management (Subject Vocab)', 'Subject Vocab', 'Living Life Skills'),
  BoardHierarchyEntry('Seasons (Subject Vocab)', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Disasters (Subject Vocab)', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Better Words (Thesaurus)', 'Subject Vocab'),
  BoardHierarchyEntry('Actions Verbs Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),
  BoardHierarchyEntry('Appearance Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),
  BoardHierarchyEntry('Bad Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),
  BoardHierarchyEntry('Feelings Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),
  BoardHierarchyEntry('Good Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),
  BoardHierarchyEntry('Move Actions Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),
  BoardHierarchyEntry('Nouns Abstract Nouns Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),
  BoardHierarchyEntry('People Places Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),
  BoardHierarchyEntry('Lessons', 'Subject Vocab'),
  BoardHierarchyEntry('Say Actions Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),
  BoardHierarchyEntry('Sentence Creator', 'Subject Vocab'),
  BoardHierarchyEntry('Letters (Subject)', 'Subject Vocab'),
  BoardHierarchyEntry('Breaktime', 'Subject Vocab'),
  BoardHierarchyEntry('Lunchtime', 'Subject Vocab'),
  BoardHierarchyEntry('English', 'Subject Vocab'),
  BoardHierarchyEntry('Maths', 'Subject Vocab'),
  BoardHierarchyEntry('Science', 'Subject Vocab'),
  BoardHierarchyEntry('Chemical Compositions', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Class Equipment (Maths)', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('PH Scale', 'Subject Vocab', 'Acids and Alkelis'),
  BoardHierarchyEntry('Animals and Humans', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Ecosystems (Science)', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Components', 'Subject Vocab', 'Electricity'),
  BoardHierarchyEntry('Alternative and Renewable Energy', 'Subject Vocab', 'Energy'),
  BoardHierarchyEntry('Hot Stuff - Thermal Processes', 'Subject Vocab', 'Energy'),
  BoardHierarchyEntry('Are You Overreacting', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Attractive Forces', 'Subject Vocab', 'Forces'),
  BoardHierarchyEntry('Babies', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Body Wars', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Casualty', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Clean Air and Water', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Controlling Systems', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Creepy Crawlies', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Driving Along', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Elements', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Everything In Its Place', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Extinction', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Fly Me To The Moon', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Food Factory', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Fooling Your Senses', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Fuels', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Full Spectrum', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Money (Maths)', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('Getting The Message', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Heavy Metals', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Medical Rays', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Equipment For Science', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('My Genes', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Novel Materials', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Nuclear Power', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Hazard Symbols', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Our Electrical Supply', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Physical Or Chemical Change', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Pushes and Pulls', 'Subject Vocab', 'Forces'),
  BoardHierarchyEntry('Sorting Out', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('You Only Have One Life', 'Subject Vocab', 'Entry Level'),
  BoardHierarchyEntry('Evolution and Genes', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Forces', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Levers, Pulleys and Gears', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Light and Sound', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Material Properties', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Matter', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Breathing Vs Respiration', 'Subject Vocab', 'Organs'),
  BoardHierarchyEntry('Cells and Organelles', 'Subject Vocab', 'Organs'),
  BoardHierarchyEntry('Circulatory System', 'Subject Vocab', 'Organs'),
  BoardHierarchyEntry('Digestive System', 'Subject Vocab', 'Organs'),
  BoardHierarchyEntry('Levels Of Organisation', 'Subject Vocab', 'Organs'),
  BoardHierarchyEntry('Staying Healthy', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Specific Muscles', 'Subject Vocab', 'The Muscles'),
  BoardHierarchyEntry('The Skeleton', 'Subject Vocab', 'Organs'),
  BoardHierarchyEntry('Plants', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Reactions', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Fossil Formation', 'Subject Vocab', 'Rocks'),
  BoardHierarchyEntry('Electricity', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Igneous', 'Subject Vocab', 'Rocks'),
  BoardHierarchyEntry('Metamorphic', 'Subject Vocab', 'Rocks'),
  BoardHierarchyEntry('Sedimentary', 'Subject Vocab', 'Rocks'),
  BoardHierarchyEntry('Soil Formation', 'Subject Vocab', 'Rocks'),
  BoardHierarchyEntry('Types Of Rock', 'Subject Vocab', 'Rocks'),
  BoardHierarchyEntry('Digestion and Excretion', 'Subject Vocab', 'Staying Healthy'),
  BoardHierarchyEntry('Exercise', 'Subject Vocab', 'Staying Healthy'),
  BoardHierarchyEntry('Health', 'Subject Vocab', 'Staying Healthy'),
  BoardHierarchyEntry('Healthy Lifestyle', 'Subject Vocab', 'Staying Healthy'),
  BoardHierarchyEntry('Rocks', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Being Responsible', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Mental and Social Health', 'Subject Vocab', 'Staying Healthy'),
  BoardHierarchyEntry('Diversity', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Nutrition', 'Subject Vocab', 'Staying Healthy'),
  BoardHierarchyEntry('Health and Wellbeing', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Universe', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Making Friends', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('RSE', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Relationships', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Intimate Relationships', 'Subject Vocab', 'RSE'),
  BoardHierarchyEntry('Unhealthy Relationships', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Sexuality', 'Subject Vocab', 'Gender and Sexuality'),
  BoardHierarchyEntry('NSPCC Pants', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Sun Safety', 'Subject Vocab', 'Keeping Safe'),
  BoardHierarchyEntry('Digital Literacy', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Media and Social Media', 'Subject Vocab', 'Living Life Skills'),
  BoardHierarchyEntry('PEEP', 'Subject Vocab'),
  BoardHierarchyEntry('Cooking', 'Subject Vocab'),
  BoardHierarchyEntry('Carbohydrates', 'Subject Vocab', 'Cooking'),
  BoardHierarchyEntry('Cooking Equipment', 'Subject Vocab', 'Cooking'),
  BoardHierarchyEntry('Dairy', 'Subject Vocab', 'Cooking'),
  BoardHierarchyEntry('Food Groups', 'Subject Vocab', 'Cooking'),
  BoardHierarchyEntry('Fruit', 'Subject Vocab', 'Cooking'),
  BoardHierarchyEntry('Herbs', 'Subject Vocab', 'Cooking'),
  BoardHierarchyEntry('Key Cooking Terminology', 'Subject Vocab', 'Cooking'),
  BoardHierarchyEntry('Key Terminology', 'Subject Vocab', 'Cooking'),
  BoardHierarchyEntry('Meal Times', 'Subject Vocab', 'Cooking'),
  BoardHierarchyEntry('Desserts and Puddings', 'Subject Vocab', 'Cooking'),
  BoardHierarchyEntry('Protein', 'Subject Vocab', 'Cooking'),
  BoardHierarchyEntry('Spices', 'Subject Vocab', 'Cooking'),
  BoardHierarchyEntry('Vegetables', 'Subject Vocab', 'Cooking'),
  BoardHierarchyEntry('More food words', 'Subject Vocab', 'Cooking'),
  BoardHierarchyEntry('Religion and Worldviews', 'Subject Vocab'),
  BoardHierarchyEntry('Angels (RWV)', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Belonging and Baptism', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Community', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Community (RWV)', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Creation Stories', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Good and Evil', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Hindu Traditions', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Holy Books', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Islam Belonging', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Love and Belonging', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Love and Easter', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Love, Rules, Choice, Consequences', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('People Making A Difference', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Special Festivals', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Special People', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Special Things', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Performing Arts', 'Subject Vocab'),
  BoardHierarchyEntry('Sustainability', 'Subject Vocab'),
  BoardHierarchyEntry('TFL Careers', 'Subject Vocab', 'TFL / IT'),
  BoardHierarchyEntry('Retail', 'Subject Vocab'),
  BoardHierarchyEntry('Electrical Safety (PD)', 'Subject Vocab', 'Keeping Safe'),
  BoardHierarchyEntry('Appliances (PD)', 'Subject Vocab', 'Electrical Safety (PD)'),
  BoardHierarchyEntry('PEEP Keywords', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Maps and Atlas', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Countries and Continents', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Explorers', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Biomes and Climate', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Seasons (PEEP)', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Journeys Through Time', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Great Britain (PEEP)', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Prehistoric', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Photography', 'Subject Vocab'),
  BoardHierarchyEntry('Places and People (Anglo-Saxons)', 'Subject Vocab', 'Anglo-Saxons (410 – 1066)'),
  BoardHierarchyEntry('Construction', 'Subject Vocab'),
  BoardHierarchyEntry('Design Technology', 'Subject Vocab'),
  BoardHierarchyEntry('Engineering', 'Subject Vocab'),
  BoardHierarchyEntry('Arts and Crafts', 'Subject Vocab', 'Living Life Skills'),
  BoardHierarchyEntry('Environment and Community', 'Subject Vocab', 'Living Life Skills'),
  BoardHierarchyEntry('Finance and Numeracy', 'Subject Vocab', 'Living Life Skills'),
  BoardHierarchyEntry('Home Equipment', 'Subject Vocab', 'Living Life Skills'),
  BoardHierarchyEntry('WW Aftermath and Leadership', 'Subject Vocab', 'Britain At War 1914–1918, 1939-1945'),
  BoardHierarchyEntry('Office Practice', 'Subject Vocab', 'Prepare For Adulthood'),
  BoardHierarchyEntry('Identify, Collaborate', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Bone Finders', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Road Safety', 'Subject Vocab', 'Keeping Safe'),
  BoardHierarchyEntry('Blue Planet', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Belonging To A Community', 'Subject Vocab', 'Prepare For Adulthood'),
  BoardHierarchyEntry('Careers', 'Subject Vocab', 'Prepare For Adulthood'),
  BoardHierarchyEntry('Wider World', 'Subject Vocab', 'Prepare For Adulthood'),
  BoardHierarchyEntry('Fictional Pirates', 'Subject Vocab', 'Pirates (PEEP)'),
  BoardHierarchyEntry('Emergencies (PEEP)', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Public Services', 'Subject Vocab'),
  BoardHierarchyEntry('Flags', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Option A', 'Subject Vocab'),
  BoardHierarchyEntry('Option B', 'Subject Vocab'),
  BoardHierarchyEntry('Option C', 'Subject Vocab'),
  BoardHierarchyEntry('Disasters (PEEP)', 'Subject Vocab', 'PEEP'),
  BoardHierarchyEntry('Tech Rotation', 'Subject Vocab'),
  BoardHierarchyEntry('PE Keywords', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('PE Games', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('Gym Equipment', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('Team Sports', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('Individual Sports', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('Sports Day Events', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('Adventure and Extreme Sports', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('Water and Winter Sports', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('Leisure Sports', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('Outdoors', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('Creativity and Brainpower', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('Relaxation', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('Technology', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('Year 8 Art', 'Subject Vocab', 'Art'),
  BoardHierarchyEntry('Year 9 Art', 'Subject Vocab', 'Art'),
  BoardHierarchyEntry('KS4 Art', 'Subject Vocab', 'Art'),
  BoardHierarchyEntry('Fats', 'Subject Vocab', 'Cooking'),
  BoardHierarchyEntry('Other Meals', 'Subject Vocab', 'Cooking'),
  BoardHierarchyEntry('Resistant Materials', 'Subject Vocab'),
  BoardHierarchyEntry('Equipment For Resistant Materials', 'Subject Vocab', 'Resistant Materials'),
  BoardHierarchyEntry('Textiles', 'Subject Vocab'),
  BoardHierarchyEntry('Music', 'Subject Vocab'),
  BoardHierarchyEntry('Musical Genres', 'Subject Vocab', 'Music'),
  BoardHierarchyEntry('Musical Instruments', 'Subject Vocab', 'Music'),
  BoardHierarchyEntry('Christianity', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Horticulture', 'Subject Vocab'),
  BoardHierarchyEntry('Judaism', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Terminology For Horticulture', 'Subject Vocab', 'Horticulture'),
  BoardHierarchyEntry('Equipment For Horticulture', 'Subject Vocab', 'Horticulture'),
  BoardHierarchyEntry('Islam', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Buddhism', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Paganism', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Trips', 'Subject Vocab', 'Prepare For Adulthood'),
  BoardHierarchyEntry('Home Equipment (LLS)', 'Subject Vocab', 'Home Management (LLS)'),
  BoardHierarchyEntry('Hygiene and Healthy Living', 'Subject Vocab', 'Living Life Skills'),
  BoardHierarchyEntry('Communication', 'Subject Vocab', 'Living Life Skills'),
  BoardHierarchyEntry('Personal Skills', 'Subject Vocab', 'Living Life Skills'),
  BoardHierarchyEntry('More Symbols', 'Subject Vocab', 'Cooking'),
];







// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

//  Runtime (mutable) hierarchy

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€



/// Mutable copy of [boardHierarchy] that includes any admin changes

/// persisted in SharedPreferences between compiles.  All lookup functions

/// read from this list so that admin edits are immediately visible without

/// a full recompile.

///

/// On web startup this is loaded from SharedPreferences.  If nothing is

/// stored yet it defaults to a copy of the compiled const list.

final List<BoardHierarchyEntry> runtimeBoardHierarchy = List.of(boardHierarchy);



/// Per-user SharedPreferences key builder.

String _userHierarchyPrefsKey(String userId) =>

    'user_board_hierarchy_entries_${userId.toLowerCase()}';



/// SharedPreferences key for the runtime hierarchy cache (admin edits

/// between compiles).

const String runtimeHierarchyPrefsKey = 'runtime_board_hierarchy';



// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

//  Persistence: runtime (admin = static) layer

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€



/// Load the runtime hierarchy from SharedPreferences.

/// Falls back to [boardHierarchy] if nothing is stored.

Future<void> loadRuntimeHierarchy() async {

  final prefs = await SharedPreferences.getInstance();

  final raw = prefs.getString(runtimeHierarchyPrefsKey);

  if (raw != null && raw.isNotEmpty) { // use persisted if available

    try {

      final list = json.decode(raw) as List;

      final loaded = list.map((e) =>

            BoardHierarchyEntry.fromJson(e as Map<String, dynamic>)).toList();

      

      // Remove any stale (Common) suffixed boards that were renamed back.

      loaded.removeWhere((e) => e.name.endsWith(' (Common)'));

      

      // The COMPILED hierarchy is the source of truth for prebuilt boards: it

      // defines their area, parent and order. Letting the persisted browser

      // copy win meant a stale localStorage list could silently override the

      // project, and any board hidden from a tab row disappeared entirely.

      // Only genuinely custom boards are carried over from storage.

      final prebuiltNames = boardHierarchy.map((e) => e.name.toLowerCase()).toSet();

      

      final merged = <BoardHierarchyEntry>[];

      // 1. Compiled prebuilt hierarchy defines order.

      merged.addAll(boardHierarchy);

      

      // 2. Append custom boards that aren't part of the prebuilt set.

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

  // First run or out-of-sync â€” seed from compiled const.

  runtimeBoardHierarchy

    ..clear()

    ..addAll(boardHierarchy);

}



/// Persist the runtime hierarchy to SharedPreferences.

/// The dev server mirror is handled by board_service.dart.

Future<void> _persistRuntimeHierarchy() async {

  final prefs = await SharedPreferences.getInstance();

  final entries = runtimeBoardHierarchy.map((e) => e.toJson()).toList();

  await prefs.setString(runtimeHierarchyPrefsKey, json.encode(entries));

  // Mirror to the dev server so the project file stays in sync too.

  if (kIsWeb && Uri.base.host == 'localhost') {

    try {

      await http

          .post(

            Uri.parse('http://localhost:8787/saveHierarchy'),

            headers: {'Content-Type': 'application/json'},

            body: json.encode({'entries': entries}),

          )

          .timeout(const Duration(seconds: 5));

    } catch (e) {

      debugPrint('Failed to mirror runtime hierarchy to dev server: $e');

    }

  }

}







// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

//  Admin operations (modifies static/compiled hierarchy)

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€



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
/// If [area] is provided, only entries with the matching name and area are
/// removed, so same-named boards in other areas are not affected.

Future<void> removeFromRuntimeHierarchy(String name, {String? area}) async {

  final lowerName = name.toLowerCase();
  final lowerArea = area?.toLowerCase();

  runtimeBoardHierarchy.removeWhere((e) {
    if (e.name.toLowerCase() != lowerName) return false;
    if (lowerArea == null) return true;
    return e.area.toLowerCase() == lowerArea;
  });

  await _persistRuntimeHierarchy();

}



// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

//  Per-user operations

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€



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



// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

//  Board ID generator

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

String _hierarchyBoardId(String name) {
  final lower = name.toLowerCase();
  if (lower == 'a-z of sign') {
    return 'prebuilt_a-z_of_sign';
  }
  if (name == 'Not Disney Animations' || name == 'Animations (Not Disney)') {
    return 'prebuilt_not_disney_animations';
  }
  if (name == 'The Turtles') {
    return 'prebuilt_turtles';
  }

  // Baycroft-specific boards must have the baycroft_ prefix to remain
  // private to the baycroft profile.
  final baycroftNames = {
    '7ems', '7ldo', '7mca', '7ngr', '8lbr', '8mgr', '8slp', '9ebl', '9lmc', '9rco',
    '10bcl', '10kla', '10rli', '11hsu', '11sto', 'rlp', 'kl', 'aw',
    'safeguarding team', 'senior leadership', 'helpful people',
    'governors and friends of baycroft', 'people at baycroft', 'timetables'
  };
  if (baycroftNames.contains(lower)) {
    return 'baycroft_${lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+$'), '')}';
  }

  return 'prebuilt_${lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+$'), '')}';
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



// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

//  Lookup functions (search runtime + user)

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€



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



/// Derives the tier (1â€“5) by walking the parent chain.

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

/// Uses a composite key (name + area) so that boards with the same name in
/// different areas (e.g. "Numbers" in both Common and Subject Vocab) do not
/// overwrite each other.  User-created entries augment the prebuilt list.

List<BoardHierarchyEntry> get _allEntries {

  final prebuiltNames = boardHierarchy.map((e) => e.name.toLowerCase()).toSet();

  final map = <String, BoardHierarchyEntry>{};

  for (final e in runtimeBoardHierarchy) {

    map['${e.name.toLowerCase()}::${e.area.toLowerCase()}'] = e;

  }

  // User custom entries should not re-order or re-parent prebuilt boards.

  for (final e in userCustomHierarchyEntries) {

    final key = '${e.name.toLowerCase()}::${e.area.toLowerCase()}';

    if (!prebuiltNames.contains(e.name.toLowerCase()) || !map.containsKey(key)) {

      map[key] = e;

    }

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