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
  // --- COMMON AREA ---
  BoardHierarchyEntry('Common Words', 'Common'),
  BoardHierarchyEntry('Small Words', 'Common'),
  BoardHierarchyEntry('Nouns (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Proper Nouns (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Abstract Nouns (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Collective Nouns (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Articles (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Pronouns (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Adjectives (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Verbs (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Transitive Verbs (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Intransitive Verbs (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Linking Verbs (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Auxiliary Verbs (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Adverbs (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Prepositions (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Conjunctions (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Interjections (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Gerunds (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Participles (Montessori)', 'Common', 'Small Words'),
  BoardHierarchyEntry('Others (Montessori)', 'Common', 'Small Words'),
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
  BoardHierarchyEntry('1. January', 'Common', 'Special Days'),
  BoardHierarchyEntry('2. February', 'Common', 'Special Days'),
  BoardHierarchyEntry('3. March', 'Common', 'Special Days'),
  BoardHierarchyEntry('4. April', 'Common', 'Special Days'),
  BoardHierarchyEntry('5. May', 'Common', 'Special Days'),
  BoardHierarchyEntry('6. June', 'Common', 'Special Days'),
  BoardHierarchyEntry('7. July', 'Common', 'Special Days'),
  BoardHierarchyEntry('8. August', 'Common', 'Special Days'),
  BoardHierarchyEntry('9. September', 'Common', 'Special Days'),
  BoardHierarchyEntry('10. October', 'Common', 'Special Days'),
  BoardHierarchyEntry('11. November', 'Common', 'Special Days'),
  BoardHierarchyEntry('12. December', 'Common', 'Special Days'),
  BoardHierarchyEntry('Clothes', 'Common'),
  BoardHierarchyEntry('Toys', 'Common'),
  BoardHierarchyEntry('Board Games', 'Common', 'Toys'),
  BoardHierarchyEntry('Money', 'Common'),
  BoardHierarchyEntry('Transport', 'Common'),
  BoardHierarchyEntry('World Map', 'Common'),
  BoardHierarchyEntry('Canada and Greenland', 'Common', 'World Map'),
  BoardHierarchyEntry('North American States', 'Common', 'World Map'),
  BoardHierarchyEntry('Central America and the Caribbean', 'Common', 'World Map'),
  BoardHierarchyEntry('South America', 'Common', 'World Map'),
  BoardHierarchyEntry('Europe', 'Common', 'World Map'),
  BoardHierarchyEntry('Africa (North)', 'Common', 'World Map'),
  BoardHierarchyEntry('Africa (South)', 'Common', 'World Map'),
  BoardHierarchyEntry('Asia (North)', 'Common', 'World Map'),
  BoardHierarchyEntry('Asia (West)', 'Common', 'World Map'),
  BoardHierarchyEntry('Asia (Central)', 'Common', 'World Map'),
  BoardHierarchyEntry('Asia (East)', 'Common', 'World Map'),
  BoardHierarchyEntry('Asia (South)', 'Common', 'World Map'),
  BoardHierarchyEntry('Oceania', 'Common', 'World Map'),

  // --- SUBJECT VOCAB AREA ---
  BoardHierarchyEntry('Subject Vocab', 'Subject Vocab'),
  BoardHierarchyEntry('Better Words (Thesaurus)', 'Subject Vocab'),
  BoardHierarchyEntry('Actions Verbs Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),
  BoardHierarchyEntry('Appearance Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),
  BoardHierarchyEntry('Bad Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),
  BoardHierarchyEntry('Feelings Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),
  BoardHierarchyEntry('Good Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),
  BoardHierarchyEntry('Move Actions Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),
  BoardHierarchyEntry('Nouns Abstract Nouns Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),
  BoardHierarchyEntry('People Places Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),
  BoardHierarchyEntry('Say Actions Thesaurus', 'Subject Vocab', 'Better Words (Thesaurus)'),
  BoardHierarchyEntry('Lessons', 'Subject Vocab'),
  BoardHierarchyEntry('Sentence Creator', 'Subject Vocab'),
  BoardHierarchyEntry('No Small Words', 'Subject Vocab', 'Sentence Creator'),
  BoardHierarchyEntry('With Small Words', 'Subject Vocab', 'Sentence Creator'),
  BoardHierarchyEntry('Advanced Sentence Building', 'Subject Vocab', 'Sentence Creator'),
  BoardHierarchyEntry('Nouns', 'Subject Vocab', 'Sentence Creator'),
  BoardHierarchyEntry('Verbs', 'Subject Vocab', 'Sentence Creator'),
  BoardHierarchyEntry('Adjectives', 'Subject Vocab', 'Sentence Creator'),
  BoardHierarchyEntry('Adverbs', 'Subject Vocab', 'Sentence Creator'),
  BoardHierarchyEntry('Small Words (Subject)', 'Subject Vocab'),
  BoardHierarchyEntry('Letters (Subject)', 'Subject Vocab'),
  BoardHierarchyEntry('Numbers (Subject)', 'Subject Vocab'),
  BoardHierarchyEntry('Breaktime', 'Subject Vocab'),
  BoardHierarchyEntry('Lunchtime', 'Subject Vocab'),
  BoardHierarchyEntry('Tutor Time, Events and Clubs', 'Subject Vocab'),
  BoardHierarchyEntry('English', 'Subject Vocab'),
  BoardHierarchyEntry('Maths', 'Subject Vocab'),
  BoardHierarchyEntry('Algebra', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('Numbers', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('Fractions and Percentages', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('Maths Resources', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('Measurements (Length and Width, Perimeter and Area)', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('Money', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('Position and Direction', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('Ratios and Proportion', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('Shapes and Angles', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('Statistics', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('Time', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('Weight and Capacity', 'Subject Vocab', 'Maths'),
  BoardHierarchyEntry('Science', 'Subject Vocab'),
  BoardHierarchyEntry('Chemical Compositions', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('PH Scale', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Animals and Humans', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Ecosystems (Science)', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Components', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Electrical Safety', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Alternative and Renewable Energy', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Hot Stuff - Thermal Processes', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Are You Overreacting', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Attractive Forces', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Babies', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Body Wars', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Casualty', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Clean Air and Water', 'Subject Vocab', 'Science'),
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
  BoardHierarchyEntry('Let\'s Get Together', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Medical Rays', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('My Genes', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Novel Materials', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Nuclear Power', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Our Electrical Supply', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Physical Or Chemical Change', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Pushes and Pulls', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Sorting Out', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('You Only Have One Life', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Equipment', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Evolution and Genes', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Forces', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Hazard Symbols', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Intro', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Levers, Pulleys and Gears', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Light and Sound', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Material Properties', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Matter', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Breathing Vs Respiration', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Cells and Organelles', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Circulatory System', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Digestive System', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Levels Of Organisation', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Specific Muscles', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('The Skeleton', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Plants', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Reactions', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Earth\'s Layers', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Fossil Formation', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Igneous', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Metamorphic', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Sedimentary', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Soil Formation', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Types Of Rock', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Digestion and Excretion', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Exercise', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Health', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Healthy Lifestyle', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Mental and Social Health', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Nutrition', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('Universe', 'Subject Vocab', 'Science'),
  BoardHierarchyEntry('TFL / IT', 'Subject Vocab'),
  BoardHierarchyEntry('Company Logos', 'Subject Vocab', 'TFL / IT'),
  BoardHierarchyEntry('Programs', 'Subject Vocab', 'TFL / IT'),
  BoardHierarchyEntry('TFL Equipment', 'Subject Vocab', 'TFL / IT'),
  BoardHierarchyEntry('Personal Development', 'Subject Vocab'),
  BoardHierarchyEntry('Being Responsible', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Diversity', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Health and Wellbeing', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Hygiene', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Making Friends', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Relationships', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Intimate Relationships', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Unhealthy Relationships', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Sexuality', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Drugs and Alcohol Awareness', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('NSPCC Pants', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Sun Safety', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Digital Literacy', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('Media and Social Media', 'Subject Vocab', 'Personal Development'),
  BoardHierarchyEntry('PEEP', 'Subject Vocab'),
  BoardHierarchyEntry('EPIC', 'Subject Vocab'),
  BoardHierarchyEntry('PE', 'Subject Vocab'),
  BoardHierarchyEntry('Adventure and Extreme Sports', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('Creativity and Brainpower', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('Gym Equipment', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('Individual Sports', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('Leisure Sports', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('Outdoors', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('PE Games', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('PE Keywords', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('Relaxation', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('Sports Day Events', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('Team Sports', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('Technology', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('Water and Winter Sports', 'Subject Vocab', 'PE'),
  BoardHierarchyEntry('Art', 'Subject Vocab'),
  BoardHierarchyEntry('7', 'Subject Vocab', 'Art'),
  BoardHierarchyEntry('8', 'Subject Vocab', 'Art'),
  BoardHierarchyEntry('9', 'Subject Vocab', 'Art'),
  BoardHierarchyEntry('Performing Arts', 'Subject Vocab'),
  BoardHierarchyEntry('Sustainability', 'Subject Vocab'),
  BoardHierarchyEntry('Ethical Trading', 'Subject Vocab', 'Sustainability'),
  BoardHierarchyEntry('Ecosystems', 'Subject Vocab', 'Sustainability'),
  BoardHierarchyEntry('Climate Change', 'Subject Vocab', 'Sustainability'),
  BoardHierarchyEntry('Water Scarcity', 'Subject Vocab', 'Sustainability'),
  BoardHierarchyEntry('Biodiversity', 'Subject Vocab', 'Sustainability'),
  BoardHierarchyEntry('Finite Planet', 'Subject Vocab', 'Sustainability'),
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
  BoardHierarchyEntry('Desserts and Puddings', 'Subject Vocab', 'Cooking'),
  BoardHierarchyEntry('More Symbols', 'Subject Vocab', 'Cooking'),
  BoardHierarchyEntry('Protein', 'Subject Vocab', 'Cooking'),
  BoardHierarchyEntry('Photos', 'Subject Vocab', 'Cooking'),
  BoardHierarchyEntry('Spices', 'Subject Vocab', 'Cooking'),
  BoardHierarchyEntry('Vegetables', 'Subject Vocab', 'Cooking'),
  BoardHierarchyEntry('Resistant Materials', 'Subject Vocab'),
  BoardHierarchyEntry('Textiles', 'Subject Vocab'),
  BoardHierarchyEntry('Religion and Worldviews', 'Subject Vocab'),
  BoardHierarchyEntry('Angels', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Belonging and Baptism', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Community', 'Subject Vocab', 'Religion and Worldviews'),
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
  BoardHierarchyEntry('Z Buddhism', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Z Christianity', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Gods and Characters', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Z Islam', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Z Judaism', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Z Paganism', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Z Sikhism', 'Subject Vocab', 'Religion and Worldviews'),
  BoardHierarchyEntry('Music', 'Subject Vocab'),
  BoardHierarchyEntry('Musical Genres', 'Subject Vocab', 'Music'),
  BoardHierarchyEntry('Musical Instruments', 'Subject Vocab', 'Music'),
  BoardHierarchyEntry('Horticulture', 'Subject Vocab'),
  BoardHierarchyEntry('Equipment For Horticulture', 'Subject Vocab', 'Horticulture'),
  BoardHierarchyEntry('Flowers (combined from boards 1, 2, 3 and 4)', 'Subject Vocab', 'Horticulture'),
  BoardHierarchyEntry('Retail', 'Subject Vocab'),
  BoardHierarchyEntry('Environment', 'Subject Vocab', 'Retail'),
  BoardHierarchyEntry('Legislation', 'Subject Vocab', 'Retail'),
  BoardHierarchyEntry('Marketing', 'Subject Vocab', 'Retail'),
  BoardHierarchyEntry('Operations', 'Subject Vocab', 'Retail'),
  BoardHierarchyEntry('Payment and Finance', 'Subject Vocab', 'Retail'),
  BoardHierarchyEntry('Staff', 'Subject Vocab', 'Retail'),
  BoardHierarchyEntry('Photography', 'Subject Vocab'),
  BoardHierarchyEntry('Artistic and Conceptual', 'Subject Vocab', 'Photography'),
  BoardHierarchyEntry('Artists, Context, Process, Assessment', 'Subject Vocab', 'Photography'),
  BoardHierarchyEntry('Editing and Post Production', 'Subject Vocab', 'Photography'),
  BoardHierarchyEntry('Equipment (Photography)', 'Subject Vocab', 'Photography'),
  BoardHierarchyEntry('Lighting and Composition', 'Subject Vocab', 'Photography'),
  BoardHierarchyEntry('Technical and Analytical', 'Subject Vocab', 'Photography'),
  BoardHierarchyEntry('Construction', 'Subject Vocab'),
  BoardHierarchyEntry('Design Technology', 'Subject Vocab'),
  BoardHierarchyEntry('Engineering', 'Subject Vocab'),
  BoardHierarchyEntry('Living Life Skills', 'Subject Vocab'),
  BoardHierarchyEntry('Arts and Crafts', 'Subject Vocab', 'Living Life Skills'),
  BoardHierarchyEntry('Environment and Community', 'Subject Vocab', 'Living Life Skills'),
  BoardHierarchyEntry('Finance and Numeracy', 'Subject Vocab', 'Living Life Skills'),
  BoardHierarchyEntry('Home Equipment', 'Subject Vocab', 'Living Life Skills'),
  BoardHierarchyEntry('Office Practice', 'Subject Vocab', 'Living Life Skills'),
  BoardHierarchyEntry('Identify, Collaborate', 'Subject Vocab', 'Living Life Skills'),
  BoardHierarchyEntry('Road Safety', 'Subject Vocab', 'Living Life Skills'),
  BoardHierarchyEntry('Prepare For Adulthood', 'Subject Vocab'),
  BoardHierarchyEntry('Belonging To A Community', 'Subject Vocab', 'Prepare For Adulthood'),
  BoardHierarchyEntry('Careers', 'Subject Vocab', 'Prepare For Adulthood'),
  BoardHierarchyEntry('Wider World', 'Subject Vocab', 'Prepare For Adulthood'),
  BoardHierarchyEntry('Hair and Beauty', 'Subject Vocab'),
  BoardHierarchyEntry('Health and Social Care', 'Subject Vocab'),
  BoardHierarchyEntry('Public Services', 'Subject Vocab'),
  BoardHierarchyEntry('S.T.E.M.', 'Subject Vocab'),
  BoardHierarchyEntry('Option A', 'Subject Vocab'),
  BoardHierarchyEntry('Option B', 'Subject Vocab'),
  BoardHierarchyEntry('Option C', 'Subject Vocab'),
  BoardHierarchyEntry('Tech Rotation', 'Subject Vocab'),

  // --- MY SCHOOL AREA ---
  BoardHierarchyEntry('My School Main', 'My School'),
  BoardHierarchyEntry('Baycroft Expects', 'My School'),
  BoardHierarchyEntry('Thinking Skills', 'My School'),
  BoardHierarchyEntry('When Things Go Wrong', 'My School'),
  BoardHierarchyEntry('Blank Levels', 'My School'),
  BoardHierarchyEntry('My School Lessons', 'My School'),
  BoardHierarchyEntry('Class Equipment', 'My School'),
  BoardHierarchyEntry('People At School', 'My School'),
  BoardHierarchyEntry('Safeguarding Team', 'My School', 'People At School'),
  BoardHierarchyEntry('Senior Leadership', 'My School', 'People At School'),
  BoardHierarchyEntry('Office and Other Helpful People', 'My School', 'People At School'),
  BoardHierarchyEntry('7EmS', 'My School', 'People At School'),
  BoardHierarchyEntry('7LDo', 'My School', 'People At School'),
  BoardHierarchyEntry('7MCa', 'My School', 'People At School'),
  BoardHierarchyEntry('7NGr', 'My School', 'People At School'),
  BoardHierarchyEntry('8LBr', 'My School', 'People At School'),
  BoardHierarchyEntry('8MGr', 'My School', 'People At School'),
  BoardHierarchyEntry('8SLP', 'My School', 'People At School'),
  BoardHierarchyEntry('9EBl', 'My School', 'People At School'),
  BoardHierarchyEntry('9LMc', 'My School', 'People At School'),
  BoardHierarchyEntry('9RCo', 'My School', 'People At School'),
  BoardHierarchyEntry('10BCl', 'My School', 'People At School'),
  BoardHierarchyEntry('10KLa', 'My School', 'People At School'),
  BoardHierarchyEntry('10RLi', 'My School', 'People At School'),
  BoardHierarchyEntry('11HSu', 'My School', 'People At School'),
  BoardHierarchyEntry('11STo', 'My School', 'People At School'),
  BoardHierarchyEntry('RLP', 'My School', 'People At School'),
  BoardHierarchyEntry('KL', 'My School', 'People At School'),
  BoardHierarchyEntry('AW', 'My School', 'People At School'),
  BoardHierarchyEntry('Governors and Friends Of Baycroft', 'My School', 'People At School'),


  // --- LEGENDS AREA ---
  BoardHierarchyEntry('Arabian and Middle Eastern Tales', 'Legends', 'Characters'),
  BoardHierarchyEntry('Arthurian Legend', 'Legends', 'Characters'),
  BoardHierarchyEntry('Asian Legends and Folklore', 'Legends', 'Characters'),
  BoardHierarchyEntry('Biblical and Ancient Legendary Figures', 'Legends', 'Characters'),
  BoardHierarchyEntry('Books', 'Legends', 'Characters'),
  BoardHierarchyEntry('Computer Games', 'Legends', 'Characters'),
  BoardHierarchyEntry('Creatures and Races', 'Legends', 'Characters'),
  BoardHierarchyEntry('Aquaman', 'Legends', 'DC'),
  BoardHierarchyEntry('Bat Family', 'Legends', 'DC'),
  BoardHierarchyEntry('Doom Patrol', 'Legends', 'DC'),
  BoardHierarchyEntry('Green Arrow', 'Legends', 'DC'),
  BoardHierarchyEntry('Green Lantern', 'Legends', 'DC'),
  BoardHierarchyEntry('Justice League Dark  Supernatural', 'Legends', 'DC'),
  BoardHierarchyEntry('Justice League', 'Legends', 'DC'),
  BoardHierarchyEntry('Justice Society Of America (JSA)', 'Legends', 'DC'),
  BoardHierarchyEntry('Justice Society Of America (JSA)', 'Legends', 'DC'),
  BoardHierarchyEntry('Legends Of Tomorrow', 'Legends', 'DC'),
  BoardHierarchyEntry('New Gods, Apokolips and Cosmic Villains', 'Legends', 'DC'),
  BoardHierarchyEntry('Other Teams', 'Legends', 'DC'),
  BoardHierarchyEntry('Shazam', 'Legends', 'DC'),
  BoardHierarchyEntry('Super Family', 'Legends', 'DC'),
  BoardHierarchyEntry('Teen Titans', 'Legends', 'DC'),
  BoardHierarchyEntry('The Flash', 'Legends', 'DC'),
  BoardHierarchyEntry('Wonder Woman', 'Legends', 'DC'),
  BoardHierarchyEntry('DC', 'Legends', 'Characters'),
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
  BoardHierarchyEntry('1967 The Jungle Book', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1970 The Aristocats', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1973 Robin Hood', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1977 The Rescuers', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1977 Winnie The Pooh', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1981 The Fox and The Hound', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1985 The Black Cauldron', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1986 The Great Mouse Detective', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1988 Oliver and Company', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1989 The Little Mermaid', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1991 Beauty and The Beast', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1992 Aladdin', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1993 The Nightmare Before Christmas', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1994 The Lion King', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1995 Pocahontas', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1995 Toy Story', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1996 The Hunchback Of Notre Dame', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1997 Hercules', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry("1998 A Bug's Life", 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1998 Mulan', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('1999 Tarzan', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('2000 Dinosaur', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry("2000 The Emperor's New Groove", 'Legends', 'Disney Stories'),
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
  BoardHierarchyEntry('Mickey and Friends', 'Legends', 'Disney Stories'),
  BoardHierarchyEntry('Disney Stories', 'Legends', 'Characters'),
  BoardHierarchyEntry('DnD Classes', 'Legends', 'D&D'),
  BoardHierarchyEntry('DnD Magic and Status', 'Legends', 'D&D'),
  BoardHierarchyEntry('DnD Races', 'Legends', 'D&D'),
  BoardHierarchyEntry('D&D', 'Legends', 'Characters'),
  BoardHierarchyEntry('Fairy Tale Characters', 'Legends', 'Characters'),
  BoardHierarchyEntry('Famous Monsters and Horror Icons', 'Legends', 'Characters'),
  BoardHierarchyEntry('Christian Angels Demons', 'Legends', 'Gods, Titans, Heroes and Monsters'),
  BoardHierarchyEntry('Egyptian Gods', 'Legends', 'Gods, Titans, Heroes and Monsters'),
  BoardHierarchyEntry('Family Trees', 'Legends', 'Gods, Titans, Heroes and Monsters'),
  BoardHierarchyEntry('Olympians', 'Legends', 'Greek Gods'),
  BoardHierarchyEntry('Titans', 'Legends', 'Greek Gods'),
  BoardHierarchyEntry('Greek Gods', 'Legends', 'Gods, Titans, Heroes and Monsters'),
  BoardHierarchyEntry('Hindu Gods', 'Legends', 'Gods, Titans, Heroes and Monsters'),
  BoardHierarchyEntry('Norse Heroes', 'Legends', 'Norse Gods'),
  BoardHierarchyEntry('Norse Locations', 'Legends', 'Norse Gods'),
  BoardHierarchyEntry('Norse Races', 'Legends', 'Norse Gods'),
  BoardHierarchyEntry('Norse Valkyries', 'Legends', 'Norse Gods'),
  BoardHierarchyEntry('Norse Gods', 'Legends', 'Gods, Titans, Heroes and Monsters'),
  BoardHierarchyEntry('Other Mythology', 'Legends', 'Gods, Titans, Heroes and Monsters'),
  BoardHierarchyEntry('Roman Gods', 'Legends', 'Gods, Titans, Heroes and Monsters'),
  BoardHierarchyEntry('Roman Unique Gods', 'Legends', 'Gods, Titans, Heroes and Monsters'),
  BoardHierarchyEntry('Gods, Titans, Heroes and Monsters', 'Legends', 'Characters'),
  BoardHierarchyEntry('Heroes and Monsters (Greek and Roman)', 'Legends', 'Characters'),
  BoardHierarchyEntry('Horror Icons', 'Legends', 'Characters'),
  BoardHierarchyEntry('Legendary Heroes and Folk Heroes', 'Legends', 'Characters'),
  BoardHierarchyEntry('Literary and Gothic Characters', 'Legends', 'Characters'),
  BoardHierarchyEntry('Ant-Man', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Black Panther', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Black Widow and Hawkeye', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Captain America', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Deadpool', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Doctor Strange', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Eternals', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Fantastic 4', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Guardians Of The Galaxy', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Hulk', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Inhumans', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Iron Man', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Scarlet Witch', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Spiderman', 'Legends', 'Marvel'),
  BoardHierarchyEntry('The Avengers', 'Legends', 'Marvel'),
  BoardHierarchyEntry('The Defenders and Street Level', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Thor', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Villains', 'Legends', 'Marvel'),
  BoardHierarchyEntry('Marvel', 'Legends', 'Characters'),
  BoardHierarchyEntry('Pokeballs and Important Items', 'Legends'),
  BoardHierarchyEntry('Pokemon - Generation 1 (Fire Red, Leaf Green, Ocean Blue, Lightning Yellow)', 'Legends'),
  BoardHierarchyEntry('Pokemon - Generation 1 (Fire Red, Leaf Green, Ocean Blue, Lightning Yellow)', 'Legends'),
  BoardHierarchyEntry('Pokemon - Generation 2 (Silver and Gold)', 'Legends'),
  BoardHierarchyEntry('Pokemon - Generation 2 (Silver and Gold)', 'Legends'),
  BoardHierarchyEntry('Robin Hood and English Folklore', 'Legends', 'Characters'),
  BoardHierarchyEntry('Starships', 'Legends', 'Star Trek'),
  BoardHierarchyEntry('Star Trek', 'Legends', 'Characters'),
  BoardHierarchyEntry('Star Wars', 'Legends', 'Characters'),
  BoardHierarchyEntry('The Lord Of The Rings', 'Legends', 'Characters'),
  BoardHierarchyEntry('The Muppets', 'Legends', 'Characters'),
  BoardHierarchyEntry('Anti-Mutant Threats', 'Legends', 'X-Men'),
  BoardHierarchyEntry('Apocalypse and The Horsemen', 'Legends', 'X-Men'),
  BoardHierarchyEntry('Brotherhood of Mutants', 'Legends', 'X-Men'),
  BoardHierarchyEntry('Generation X', 'Legends', 'X-Men'),
  BoardHierarchyEntry('Hellfire Club', 'Legends', 'X-Men'),
  BoardHierarchyEntry('Major Villains', 'Legends', 'X-Men'),
  BoardHierarchyEntry('Marauders', 'Legends', 'X-Men'),
  BoardHierarchyEntry('Morlocks', 'Legends', 'X-Men'),
  BoardHierarchyEntry('New Mutants', 'Legends', 'X-Men'),
  BoardHierarchyEntry('Other', 'Legends', 'X-Men'),
  BoardHierarchyEntry('Weapon Program', 'Legends', 'X-Men'),
  BoardHierarchyEntry('X-Factor and Excalibur', 'Legends', 'X-Men'),
  BoardHierarchyEntry('X-Force', 'Legends', 'X-Men'),
  BoardHierarchyEntry('X-Men Later Additions', 'Legends', 'X-Men'),
  BoardHierarchyEntry("Xavier's Students", 'Legends', 'X-Men'),
  BoardHierarchyEntry('X-Men', 'Legends', 'Characters'),
  BoardHierarchyEntry('Characters', 'Legends', 'Legends'),
  BoardHierarchyEntry('Real People', 'Legends'),
  BoardHierarchyEntry('Legends', 'Legends'),

  // --- RECIPES AREA ---
  BoardHierarchyEntry('Recipes', 'Recipes'),

  // --- SIGN AREA ---
  BoardHierarchyEntry('Sign', 'Sign'),
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
  BoardHierarchyEntry('Weather (Sign)', 'Sign'),
  BoardHierarchyEntry('Outside', 'Sign'),
  BoardHierarchyEntry('Places', 'Sign'),
  BoardHierarchyEntry('Transport and Vehicles', 'Sign'),
  BoardHierarchyEntry('Money', 'Sign'),
  BoardHierarchyEntry('Public Notices', 'Sign'),
  BoardHierarchyEntry('Other Countries', 'Sign'),
  BoardHierarchyEntry('Religion and Customs', 'Sign'),
  BoardHierarchyEntry('Gender and Sexuality', 'Sign'),

  // --- PERSONAL AREA ---
  BoardHierarchyEntry('Personal', 'Personal'),

  // --- COMMON AREA ---
  BoardHierarchyEntry('Habitats (2)', 'Common')
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

final List<BoardHierarchyEntry> runtimeBoardHierarchy = List.of(boardHierarchy);



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

  if (raw != null && raw.isNotEmpty) { // use persisted if available

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

    return 'prebuilt_a-z_of_sign';

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

