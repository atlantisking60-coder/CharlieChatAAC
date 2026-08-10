import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

import '../models/symbol_tile.dart';
import 'symbol_metadata_service.dart';

class ExternalSymbol {
  final String id;
  final String label;
  final String imageUrl;
  final String source;

  ExternalSymbol({
    required this.id,
    required this.label,
    required this.imageUrl,
    required this.source,
  });

  SymbolTile toSymbolTile() {
    return SymbolTile(
      id: 'external_${source.toLowerCase()}_$id',
      label: label.toLowerCase(),
      category: source,
      imageAsset: imageUrl,
      emoji: '',
    );
  }
}

class ExternalSearchLink {
  final String name;
  final String description;
  final String urlTemplate;

  const ExternalSearchLink({
    required this.name,
    required this.description,
    required this.urlTemplate,
  });

  Uri uriForQuery(String query) {
    final encoded = Uri.encodeQueryComponent(query);
    return Uri.parse(urlTemplate.replaceAll('{query}', encoded));
  }
}

class ExternalSymbolService {
  SymbolMetadataService? _metadataService;
  
  // Cache for asset symbols to avoid reparsing manifest on every keystroke
  static List<ExternalSymbol>? _assetSymbolCache;

  // Bidirectional synonym map: searching for any key also searches for its values and vice-versa.
  static const _querySynonyms = <String, List<String>>{
    'p': ['pence'],
    'pence': ['p'],
    '£': ['pound', 'pounds'],
    'pound': ['£'],
    'pounds': ['£'],
    '\$': ['dollar', 'dollars'],
    'dollar': ['\$'],
    'dollars': ['\$'],
    '€': ['euro', 'euros'],
    'euro': ['€'],
    'euros': ['€'],
    'bathroom': ['toilet', 'loo', 'wc', 'restroom'],
    'toilet': ['bathroom', 'loo', 'wc', 'restroom'],
    'loo': ['toilet', 'bathroom'],
    'wc': ['toilet', 'bathroom'],
    'restroom': ['toilet', 'bathroom'],
    'home': ['house', 'building'],
    'house': ['home', 'building'],
    'school': ['classroom', 'college', 'university', 'learn', 'class', 'teacher'],
    'shop': ['store', 'shopping'],
    'store': ['shop', 'shopping'],
    'park': ['playground'],
    'hospital': ['medical', 'clinic', 'doctor'],
    'church': ['chapel', 'temple', 'mosque', 'synagogue'],
    'garden': ['yard', 'outside'],
    'kitchen': ['cooking'],
    'bedroom': ['bed', 'sleep'],
    'outside': ['outdoors', 'garden', 'out'],
    'inside': ['indoors', 'in'],
    'mum': ['mom', 'mother', 'mummy', 'mama'],
    'mom': ['mum', 'mother', 'mummy', 'mama'],
    'mother': ['mum', 'mom', 'mummy', 'mama'],
    'mummy': ['mum', 'mom', 'mother'],
    'mama': ['mum', 'mom', 'mother'],
    'dad': ['father', 'daddy', 'papa'],
    'father': ['dad', 'daddy', 'papa'],
    'daddy': ['dad', 'father'],
    'papa': ['dad', 'father'],
    'brother': ['bro'],
    'sister': ['sis'],
    'friend': ['buddy', 'pal', 'mate'],
    'buddy': ['friend', 'pal'],
    'baby': ['infant', 'toddler'],
    'child': ['kid', 'children'],
    'kid': ['child', 'children'],
    'children': ['kids', 'child'],
    'boy': ['man', 'male'],
    'girl': ['woman', 'female'],
    'man': ['boy', 'male'],
    'woman': ['girl', 'female'],
    'teacher': ['ta', 'instructor'],
    'doctor': ['nurse', 'hospital'],
    'nurse': ['doctor'],
    'grandma': ['grandmother', 'nan', 'nana', 'granny'],
    'grandmother': ['grandma', 'nan', 'nana', 'granny'],
    'grandpa': ['grandfather', 'grandad', 'gramps'],
    'grandfather': ['grandpa', 'grandad'],
    'happy': ['smile', 'smiling', 'glad', 'pleased', 'cheerful', 'joyful'],
    'smile': ['happy', 'smiling', 'grin'],
    'smiling': ['happy', 'smile'],
    'sad': ['cry', 'crying', 'frown', 'unhappy', 'upset', 'down'],
    'cry': ['sad', 'crying', 'tears', 'weep'],
    'crying': ['sad', 'cry', 'tears'],
    'frown': ['sad', 'unhappy'],
    'unhappy': ['sad', 'upset'],
    'angry': ['mad', 'furious', 'annoyed', 'cross', 'angrier'],
    'mad': ['angry', 'furious'],
    'annoyed': ['angry', 'irritated'],
    'scared': ['afraid', 'frightened', 'fear', 'terrified', 'worried'],
    'afraid': ['scared', 'frightened', 'fear'],
    'frightened': ['scared', 'afraid', 'fear'],
    'fear': ['scared', 'afraid'],
    'worried': ['anxious', 'nervous', 'scared'],
    'anxious': ['worried', 'nervous'],
    'excited': ['thrilled', 'eager', 'happy'],
    'tired': ['exhausted', 'sleepy', 'fatigued', 'weary'],
    'sleepy': ['tired', 'exhausted'],
    'exhausted': ['tired', 'sleepy'],
    'confused': ['puzzled', 'lost', 'baffled'],
    'puzzled': ['confused'],
    'surprised': ['shocked', 'amazed', 'astonished'],
    'shocked': ['surprised', 'amazed'],
    'amazed': ['surprised', 'shocked', 'astonished'],
    'bored': ['fed up', 'tired'],
    'brave': ['courageous', 'bold'],
    'proud': ['pleased'],
    'pleased': ['proud', 'happy', 'glad'],
    'glad': ['happy', 'pleased'],
    'lonely': ['alone', 'lonesome'],
    'alone': ['lonely'],
    'calm': ['relax', 'relaxed', 'peaceful', 'chill'],
    'relax': ['calm', 'relaxed', 'rest'],
    'relaxed': ['calm', 'relax'],
    'kind': ['nice', 'gentle', 'friendly'],
    'nice': ['kind', 'good'],
    'gentle': ['kind', 'soft'],
    'sick': ['ill', 'unwell', 'poorly'],
    'ill': ['sick', 'unwell'],
    'hurt': ['pain', 'sore', 'ouch'],
    'pain': ['hurt', 'sore'],
    'sore': ['hurt', 'pain'],
    'big': ['large', 'huge', 'enormous', 'giant', 'massive', 'bigger'],
    'large': ['big', 'huge', 'enormous'],
    'huge': ['big', 'large', 'enormous'],
    'small': ['little', 'tiny', 'mini', 'smaller'],
    'little': ['small', 'tiny', 'mini'],
    'tiny': ['small', 'little', 'mini'],
    'more': ['extra', 'additional'],
    'less': ['fewer'],
    'all': ['every', 'everything'],
    'every': ['all', 'each'],
    'nothing': ['none', 'empty'],
    'none': ['nothing', 'empty'],
    'empty': ['none', 'blank'],
    'want': ['need', 'like', 'fancy', 'wish', 'desire'],
    'need': ['want', 'must', 'require'],
    'go': ['move', 'travel', 'leave', 'going'],
    'come': ['return', 'arrive'],
    'come back': ['return'],
    'return': ['come back', 'go back'],
    'leave': ['go', 'depart'],
    'stay': ['wait', 'remain'],
    'wait': ['stay', 'hold'],
    'help': ['assist', 'support', 'aid'],
    'please': ['thanks'],
    'thank': ['thanks', 'please'],
    'thanks': ['thank', 'please'],
    'sorry': ['apologise'],
    'start': ['begin', 'commence'],
    'begin': ['start', 'commence'],
    'finish': ['end', 'stop', 'done', 'complete'],
    'end': ['finish', 'stop', 'complete'],
    'stop': ['finish', 'end', 'halt'],
    'done': ['finish', 'complete', 'finished'],
    'complete': ['finish', 'done'],
    'look': ['see', 'watch', 'stare', 'peek'],
    'see': ['look', 'watch', 'view'],
    'watch': ['look', 'see', 'view', 'time', 'clock', 'wrist'],
    'listen': ['hear', 'sound'],
    'hear': ['listen'],
    'eat': ['food', 'meal', 'snack', 'dining', 'hungry'],
    'food': ['meal', 'eat', 'snack', 'hungry'],
    'meal': ['food', 'eat', 'dinner', 'lunch', 'breakfast'],
    'snack': ['food', 'eat'],
    'drink': ['beverage', 'sip', 'thirsty'],
    'beverage': ['drink'],
    'cook': ['cooking', 'bake', 'baking'],
    'make': ['create', 'build', 'do'],
    'create': ['make', 'build'],
    'build': ['make', 'create'],
    'play': ['fun', 'game', 'toy'],
    'run': ['jog', 'sprint'],
    'walk': ['stroll', 'step', 'foot'],
    'jump': ['leap', 'hop', 'bounce'],
    'sit': ['seat', 'chair'],
    'stand': ['standing'],
    'open': ['unlock'],
    'close': ['shut', 'lock'],
    'shut': ['close', 'close'],
    'push': ['press', 'shove'],
    'pull': ['tug', 'drag'],
    'hit': ['bang', 'bump', 'knock'],
    'wash': ['clean', 'rinse'],
    'clean': ['wash', 'tidy', 'washed'],
    'dry': ['wipe', 'parched'],
    'turn': ['spin', 'rotate'],
    'give': ['hand', 'offer', 'pass'],
    'take': ['grab', 'get', 'fetch'],
    'get': ['take', 'fetch', 'grab'],
    'hold': ['grip', 'grasp', 'carry'],
    'carry': ['hold', 'bring', 'transport'],
    'put': ['place', 'set', 'lay'],
    'place': ['put', 'set'],
    'get up': ['wake', 'wake up', 'arise'],
    'wake up': ['get up', 'arise'],
    'go to bed': ['sleep', 'bedtime'],
    'sleep': ['rest', 'nap', 'snooze'],
    'rest': ['relax', 'sleep', 'nap'],
    'read': ['book', 'story'],
    'write': ['draw', 'pen'],
    'draw': ['write', 'colour', 'color'],
    'colour': ['color', 'draw', 'paint', 'crayon', 'art'],
    'color': ['colour', 'draw'],
    'sing': ['song', 'music'],
    'dance': ['music', 'move'],
    'talk': ['speak', 'say', 'tell', 'chat', 'conversation'],
    'speak': ['talk', 'say'],
    'say': ['talk', 'tell'],
    'tell': ['talk', 'say'],
    'ask': ['question', 'request'],
    'answer': ['reply', 'respond'],
    'reply': ['answer', 'respond'],
    'show': ['demonstrate', 'display'],
    'hide': ['conceal'],
    'buy': ['purchase', 'shop'],
    'purchase': ['buy'],
    'sell': ['sell'],
    'pay': ['buy', 'purchase', 'money'],
    'cut': ['snip', 'chop'],
    'break': ['smash', 'shatter'],
    'fix': ['repair', 'mend'],
    'repair': ['fix', 'mend'],
    'mend': ['fix', 'repair'],
    'bend': ['fold'],
    'fall': ['trip', 'drop', 'fall down'],
    'laugh': ['giggle', 'chuckle', 'funny'],
    'kiss': ['love', 'hug'],
    'hug': ['love', 'kiss', 'cuddle'],
    'love': ['like', 'adore', 'care'],
    'like': ['love', 'enjoy', 'fancy'],
    'hate': ['dislike', 'despise'],
    'dislike': ['hate'],
    'good': ['nice', 'well', 'great', 'fine', 'better', 'best', 'okay'],
    'bad': ['wrong', 'terrible', 'worse'],
    'great': ['good', 'excellent', 'wonderful', 'amazing'],
    'best': ['good', 'great'],
    'better': ['good', 'well'],
    'fast': ['quick', 'rapid', 'speedy', 'rapidly'],
    'quick': ['fast', 'rapid'],
    'slow': ['slower', 'steady'],
    'hot': ['warm', 'heat', 'heated'],
    'warm': ['hot', 'heated'],
    'cold': ['cool', 'freezing', 'chilly', 'icy'],
    'cool': ['cold', 'chilly'],
    'freezing': ['cold', 'icy'],
    'wet': ['damp', 'soaked'],
    'hard': ['difficult', 'tough', 'solid'],
    'soft': ['gentle', 'smooth', 'squishy'],
    'easy': ['simple', 'quick'],
    'new': ['fresh', 'modern'],
    'old': ['aged', 'elderly', 'ancient', 'worn'],
    'young': ['youthful'],
    'dirty': ['messy', 'muddy', 'filthy'],
    'messy': ['dirty', 'untidy'],
    'tidy': ['clean', 'neat', 'orderly'],
    'loud': ['noisy', 'deafening'],
    'noisy': ['loud'],
    'quiet': ['silent', 'calm', 'peaceful'],
    'silent': ['quiet'],
    'dark': ['dim', 'gloomy'],
    'light': ['bright', 'brighter', 'feather', 'lightweight', 'lamp', 'bulb', 'electricity'],
    'bright': ['light', 'shiny', 'glowing'],
    'shiny': ['bright', 'glitter', 'sparkle'],
    'heavy': ['weight', 'weighted'],
    'safe': ['secure', 'protection', 'careful', 'safe', 'care'],
    'dangerous': ['risky', 'hazard'],
    'right': ['correct'],
    'wrong': ['incorrect', 'bad'],
    'yes': ['yeah', 'yep', 'sure', 'okay', 'ok'],
    'no': ['nah', 'nope', 'not'],
    'okay': ['ok', 'fine', 'alright'],
    'ok': ['okay', 'fine'],
    'now': ['immediate', 'currently'],
    'later': ['after', 'soon', 'eventually'],
    'soon': ['later', 'shortly'],
    'always': ['forever', 'constantly'],
    'never': ['not ever'],
    'here': ['this place'],
    'there': ['that place'],
    'where': ['which place'],
    'today': ['now', 'this day'],
    'tomorrow': ['next day'],
    'yesterday': ['last day'],
    'morning': ['am', 'dawn', 'breakfast'],
    'afternoon': ['pm', 'midday'],
    'night': ['evening', 'bedtime', 'dark'],
    'evening': ['night'],
    'time': ['clock', 'watch', 'hour'],
    'first': ['1st'],
    'last': ['final', 'previous'],
    'next': ['following'],
    'head': ['brain'],
    'face': ['face'],
    'eye': ['eyes', 'see', 'look'],
    'eyes': ['eye', 'see', 'look'],
    'ear': ['ears', 'hear', 'listen'],
    'ears': ['ear', 'hear'],
    'nose': ['smell'],
    'mouth': ['speak', 'talk', 'eat'],
    'tooth': ['teeth', 'dentist'],
    'teeth': ['tooth', 'dentist'],
    'hand': ['hands', 'hold', 'touch'],
    'hands': ['hand', 'hold'],
    'finger': ['fingers', 'point'],
    'fingers': ['finger'],
    'arm': ['arms', 'hug'],
    'arms': ['arm'],
    'leg': ['legs', 'walk', 'run'],
    'legs': ['leg'],
    'foot': ['feet', 'shoe', 'sock'],
    'feet': ['foot', 'shoe'],
    'stomach': ['tummy', 'belly', 'hungry'],
    'tummy': ['stomach', 'belly'],
    'belly': ['stomach', 'tummy'],
    'heart': ['love', 'care'],
    'body': ['self'],
    'bone': ['skeleton'],
    'hat': ['cap', 'headwear'],
    'cap': ['hat'],
    'shoe': ['shoes', 'trainers', 'sneakers', 'boots', 'footwear'],
    'shoes': ['shoe', 'trainers', 'sneakers', 'boots'],
    'sock': ['socks', 'tights'],
    'socks': ['sock', 'tights'],
    'coat': ['jacket', 'outerwear'],
    'jacket': ['coat'],
    'shirt': ['top', 't-shirt', 'blouse'],
    'trousers': ['pants', 'jeans', 'shorts'],
    'pants': ['trousers', 'shorts'],
    'dress': ['frock'],
    'glasses': ['specs', 'spectacles', 'glasses'],
    'bag': ['rucksack', 'backpack', 'purse', 'hold', 'carry'],
    'backpack': ['bag', 'rucksack'],
    'umbrella': ['brolly', 'rain'],
    'clothes': ['clothing', 'wear'],
    'clothing': ['clothes', 'wear'],
    'dog': ['puppy', 'hound', 'canine', 'woof', 'bark'],
    'puppy': ['dog', 'pup'],
    'cat': ['kitten', 'kitty', 'feline', 'meow'],
    'kitten': ['cat', 'kitty'],
    'bird': ['tweet', 'chirp', 'avian', 'flying'],
    'fish': ['swim', 'aquatic', 'fins'],
    'horse': ['pony', 'stallion', 'mare', 'neigh', 'gallop'],
    'pony': ['horse'],
    'cow': ['cattle', 'bull', 'ox', 'moo'],
    'pig': ['piglet', 'hog', 'oink'],
    'sheep': ['lamb', 'wool', 'baa'],
    'lamb': ['sheep', 'baby sheep'],
    'rabbit': ['bunny', 'hare'],
    'bunny': ['rabbit', 'hare'],
    'mouse': ['rat', 'rodent', 'squeak'],
    'bear': ['teddy', 'teddy bear'],
    'lion': ['king', 'roar'],
    'tiger': ['stripe', 'roar'],
    'monkey': ['ape', 'primate'],
    'frog': ['toad', 'hop'],
    'snake': ['hiss', 'slither'],
    'bee': ['wasp', 'sting', 'buzz'],
    'ant': ['insect', 'bug'],
    'bug': ['insect', 'beetle'],
    'butterfly': ['flutter', 'moth'],
    'spider': ['web', 'arachnid'],
    'turtle': ['tortoise', 'shell'],
    'duck': ['quack', 'pond'],
    'chicken': ['hen', 'rooster', 'chick', 'meat', 'poultry'],
    'owl': ['hoot', 'night bird'],
    'whale': ['dolphin', 'ocean'],
    'elephant': ['trunk', 'tusks'],
    'giraffe': ['tall', 'neck'],
    'apple': ['fruit'],
    'banana': ['fruit'],
    'orange': ['fruit', 'citrus'],
    'grape': ['fruit', 'grapes'],
    'strawberry': ['fruit', 'berry'],
    'fruit': ['apple', 'banana', 'orange', 'grape', 'berry'],
    'vegetable': ['veg', 'carrot', 'broccoli', 'potato'],
    'bread': ['toast', 'sandwich', 'loaf'],
    'toast': ['bread', 'breakfast'],
    'sandwich': ['bread', 'lunch'],
    'rice': ['grain'],
    'pasta': ['spaghetti', 'noodle', 'noodles'],
    'noodles': ['pasta', 'spaghetti'],
    'meat': ['beef', 'chicken', 'pork'],
    'egg': ['eggs', 'breakfast'],
    'cheese': ['dairy'],
    'milk': ['dairy', 'drink'],
    'water': ['drink', 'thirsty', 'h2o'],
    'juice': ['drink', 'orange juice'],
    'tea': ['drink', 'cuppa'],
    'coffee': ['drink', 'cafe'],
    'soup': ['broth', 'stew'],
    'cake': ['bake', 'sweet', 'dessert', 'birthday', 'celebration'],
    'biscuit': ['cookie', 'cracker'],
    'cookie': ['biscuit', 'sweet'],
    'sweet': ['candy', 'chocolate', 'treat', 'dessert'],
    'chocolate': ['sweet', 'candy', 'treat'],
    'ice cream': ['dessert', 'frozen', 'sweet'],
    'pizza': ['food', 'italian'],
    'chip': ['fries', 'crisp', 'crisps'],
    'fries': ['chips', 'french fries'],
    'crisp': ['chip', 'crisps', 'snack'],
    'popcorn': ['snack'],
    'cereal': ['breakfast'],
    'breakfast': ['morning meal', 'cereal'],
    'lunch': ['midday meal', 'meal', 'food', 'eat', 'dinner'],
    'dinner': ['evening meal', 'tea', 'supper'],
    'supper': ['dinner', 'evening meal'],
    'hungry': ['food', 'eat', 'stomach', 'starving'],
    'thirsty': ['drink', 'water', 'mouth'],
    'book': ['read', 'story', 'page', 'library'],
    'story': ['book', 'read', 'tale'],
    'ball': ['play', 'sport', 'kick', 'throw'],
    'toy': ['play', 'fun'],
    'pen': ['write', 'pencil', 'marker'],
    'pencil': ['write', 'pen', 'draw'],
    'paper': ['write', 'draw', 'sheet'],
    'table': ['desk', 'furniture'],
    'desk': ['table', 'work'],
    'chair': ['seat', 'sit'],
    'seat': ['chair', 'sit'],
    'bed': ['sleep', 'bedroom', 'mattress'],
    'door': ['open', 'close', 'entrance'],
    'window': ['glass', 'view'],
    'wall': ['brick'],
    'floor': ['ground', 'carpet'],
    'carpet': ['rug', 'floor'],
    'rug': ['carpet', 'mat'],
    'lamp': ['light', 'bulb'],
    'clock': ['time', 'watch', 'timer'],
    'key': ['lock', 'unlock'],
    'lock': ['key', 'secure'],
    'money': ['cash', 'coins', 'notes', 'pay'],
    'cash': ['money', 'coins'],
    'bin': ['rubbish', 'trash', 'garbage'],
    'rubbish': ['bin', 'trash', 'garbage'],
    'phone': ['mobile', 'telephone', 'cell', 'call', 'text'],
    'mobile': ['phone', 'telephone'],
    'telephone': ['phone'],
    'computer': ['laptop', 'pc', 'screen', 'internet'],
    'laptop': ['computer', 'pc'],
    'tv': ['television', 'screen', 'watch'],
    'television': ['tv', 'screen'],
    'radio': ['music', 'listen'],
    'music': ['song', 'sing', 'listen', 'tune'],
    'song': ['music', 'sing', 'tune'],
    'photo': ['picture', 'image', 'camera', 'photograph'],
    'picture': ['photo', 'image', 'draw', 'paint'],
    'image': ['picture', 'photo'],
    'camera': ['photo', 'picture'],
    'paint': ['colour', 'draw', 'brush'],
    'brush': ['hair', 'teeth', 'paint'],
    'soap': ['wash', 'clean'],
    'towel': ['dry', 'bath', 'wash'],
    'toothbrush': ['teeth', 'brush', 'wash'],
    'toothpaste': ['teeth', 'brush'],
    'shampoo': ['wash', 'hair'],
    'scissors': ['cut', 'snip'],
    'glue': ['stick', 'paste'],
    'stick': ['glue', 'paste'],
    'spoon': ['eat', 'fork', 'knife'],
    'fork': ['eat', 'spoon', 'knife'],
    'knife': ['cut', 'fork', 'spoon'],
    'cup': ['mug', 'glass', 'drink'],
    'mug': ['cup', 'drink'],
    'bottle': ['drink', 'water'],
    'bowl': ['eat', 'food', 'soup'],
    'plate': ['eat', 'food'],
    'box': ['container', 'package'],
    'present': ['gift', 'birthday', 'christmas'],
    'gift': ['present', 'birthday'],
    'balloon': ['party', 'blow'],
    'banner': ['party', 'celebration'],
    'party': ['celebration', 'birthday', 'fun'],
    'candle': ['birthday', 'light', 'fire'],
    'flower': ['plant', 'garden', 'rose'],
    'plant': ['flower', 'garden', 'grow', 'tree'],
    'tree': ['plant', 'wood', 'forest', 'leaf'],
    'leaf': ['tree', 'plant'],
    'grass': ['garden', 'green', 'lawn'],
    'rock': ['stone', 'pebble'],
    'stone': ['rock'],
    'sand': ['beach', 'play', 'desert'],
    'mud': ['dirty', 'wet', 'messy'],
    'rain': ['wet', 'umbrella', 'rainy', 'shower'],
    'snow': ['cold', 'ice', 'winter', 'snowy'],
    'ice': ['cold', 'frozen', 'snow'],
    'wind': ['blow', 'breezy'],
    'sun': ['hot', 'bright', 'sunny', 'warm', 'shine'],
    'moon': ['night', 'dark', 'stars'],
    'star': ['night', 'sky', 'shine'],
    'sky': ['blue', 'clouds', 'air'],
    'cloud': ['sky', 'rain', 'grey'],
    'fire': ['hot', 'burn', 'flame', 'warm'],
    'flame': ['fire', 'burn'],
    'earth': ['world', 'planet', 'ground', 'mud'],
    'world': ['earth', 'planet', 'globe'],
    'car': ['vehicle', 'automobile', 'drive', 'drive'],
    'vehicle': ['car', 'transport'],
    'bus': ['coach', 'transport', 'ride'],
    'coach': ['bus'],
    'train': ['railway', 'track', 'steam'],
    'bike': ['bicycle', 'cycle', 'ride', 'pedal'],
    'bicycle': ['bike', 'cycle'],
    'boat': ['ship', 'sail', 'ferry'],
    'ship': ['boat', 'sail'],
    'plane': ['aircraft', 'fly', 'aeroplane', 'airplane'],
    'airplane': ['plane', 'fly', 'aircraft'],
    'aircraft': ['plane', 'fly'],
    'fly': ['plane', 'airplane', 'bird'],
    'drive': ['car', 'drive', 'road'],
    'ride': ['bike', 'horse', 'car'],
    'road': ['street', 'path', 'drive'],
    'street': ['road', 'path'],
    'path': ['road', 'walk', 'trail'],
    'class': ['lesson', 'school'],
    'lesson': ['class', 'learn', 'teach'],
    'homework': ['work', 'study'],
    'test': ['exam', 'quiz', 'assess'],
    'exam': ['test', 'quiz'],
    'learn': ['study', 'teach', 'school'],
    'study': ['learn', 'read', 'homework'],
    'letter': ['alphabet', 'write', 'word'],
    'word': ['letter', 'read', 'write'],
    'number': ['count', 'math', 'digit'],
    'count': ['number', 'maths'],
    'art': ['draw', 'paint', 'craft'],
    'sport': ['play', 'ball', 'game', 'exercise'],
    'game': ['play', 'fun', 'sport'],
    'exercise': ['workout', 'play', 'sport'],
    'PE': ['sport', 'exercise', 'gym'],
    'assembly': ['school', 'gathering'],
    'playground': ['play', 'outside', 'recess'],
    'recess': ['playground', 'break', 'play'],
    'library': ['book', 'read', 'quiet'],
    'computing': ['computer', 'technology'],
    'drama': ['act', 'play', 'performance'],
    'birthday': ['cake', 'present', 'party', 'celebration'],
    'christmas': ['xmas', 'present', 'santa', 'tree'],
    'easter': ['egg', 'bunny'],
    'holiday': ['vacation', 'break', 'trip'],
    'vacation': ['holiday', 'trip'],
    'trip': ['visit', 'travel', 'journey'],
    'visit': ['see', 'trip', 'go'],
    'adventure': ['explore', 'fun'],
    'explore': ['adventure', 'discover', 'find'],
    'discover': ['find', 'explore'],
    'find': ['search', 'look', 'found'],
    'search': ['look', 'find', 'explore'],
    'win': ['winner', 'victory', 'first'],
    'lose': ['lost', 'miss', 'gone'],
    'lost': ['miss', 'find'],
    'miss': ['lost', 'want', 'wish'],
    'remember': ['recall', 'memory'],
    'forget': ['remember', 'memory'],
    'think': ['thought', 'idea'],
    'idea': ['think', 'thought', 'plan'],
    'know': ['understand', 'learn'],
    'understand': ['know', 'get it'],
    'believe': ['trust', 'think'],
    'imagine': ['dream', 'think', 'creative'],
    'dream': ['sleep', 'imagine', 'night'],
    'wish': ['hope', 'want', 'magic'],
    'hope': ['wish', 'want'],
    'promise': ['agree', 'yes'],
    'agree': ['yes', 'okay', 'right'],
    'choose': ['pick', 'select', 'choice'],
    'pick': ['choose', 'select'],
    'choice': ['choose', 'pick', 'select'],
    'problem': ['issue', 'trouble', 'difficulty'],
    'trouble': ['problem', 'difficulty'],
    'danger': ['dangerous', 'careful', 'warning'],
    'warning': ['danger', 'careful'],
    'careful': ['care', 'safe', 'slow'],
    'care': ['careful', 'safe', 'help'],
    'rule': ['rules', 'follow', 'obey'],
    'share': ['take turns', 'together'],
    'together': ['share', 'friend', 'team'],
    'team': ['together', 'group', 'play'],
    'group': ['team', 'class'],
    'change': ['move', 'switch', 'different'],
    'different': ['change', 'new', 'other'],
    'same': ['equal', 'match'],
    'match': ['same', 'equal', 'pair'],
    'pattern': ['match', 'repeat'],
    'repeat': ['pattern', 'again'],
    'again': ['more', 'repeat', 'another'],
    'another': ['more', 'again', 'other'],
    'other': ['different', 'another', 'else'],
    'else': ['other', 'another'],
    'enough': ['sufficient', 'done'],
    'keep': ['have', 'hold', 'save'],
    'save': ['keep', 'store'],
    'gone': ['lost', 'away', 'leave'],
    'away': ['gone', 'far', 'leave'],
    'near': ['close', 'here'],
    'far': ['away', 'distant'],
    'above': ['over', 'up', 'top'],
    'below': ['under', 'down', 'bottom'],
    'up': ['above', 'top', 'higher'],
    'down': ['below', 'bottom', 'lower'],
    'front': ['forward', 'ahead'],
    'back': ['behind', 'return', 'backward'],
    'side': ['beside', 'next'],
    'between': ['middle', 'center'],
    'middle': ['between', 'center'],
    'center': ['middle'],
    'with': ['and', 'together'],
    'without': ['no', 'none'],
    'before': ['earlier', 'first'],
    'after': ['later', 'then', 'next'],
    'then': ['next', 'after', 'and'],
    'because': ['cause', 'since', 'why'],
    'why': ['because', 'reason'],
    'what': ['which', 'thing'],
    'which': ['what', 'that'],
    'who': ['person', 'which'],
    'how': ['way', 'method'],
    'and': ['with', 'plus', 'also'],
    'or': ['else', 'choice'],
    'not': ['no', 'don\t'],
    'very': ['really', 'extremely', 'super'],
    'really': ['very', 'truly'],
    'just': ['only', 'simply'],
    'also': ['too', 'and', 'plus'],
    'too': ['also', 'very', 'also'],
  };

  /// Returns a list of alternate queries to also search, derived from synonyms
  /// and from searching each non-trivial word individually.
  List<String> expandedQueries(String query) {
    final lower = query.toLowerCase().trim();
    if (lower.isEmpty) return const [];
    final words = lower.split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty && s != 'the').toList();
    final alts = <String>{};

    // Also search each word on its own, e.g. "world braille" -> "braille"
    for (final w in words) {
      if (w.length > 2) alts.add(w);
    }

    for (var i = 0; i < words.length; i++) {
      final synonyms = _querySynonyms[words[i]];
      if (synonyms != null) {
        for (final syn in synonyms) {
          final newWords = List<String>.from(words);
          newWords[i] = syn;
          alts.add(newWords.join(' '));
        }
      }
    }
    alts.remove(lower);
    return alts.toList();
  }

  // Cache to map session-specific blob URLs (keys) to persistent project paths (values)
  static final Map<String, String> _webPersistentPathCache = {};

  Future<String?> findExistingAssetByFilename(String filename) async {
    await _ensureMetadata();
    final cache = _assetSymbolCache ?? [];
    final cleanName = filename.toLowerCase().split('.').first;
    for (final s in cache) {
      if (s.source == 'Assets') {
        final assetFile = s.imageUrl.split('/').last.toLowerCase().split('.').first;
        if (assetFile == cleanName) {
          return s.imageUrl;
        }
      }
    }
    return null;
  }

  static void cacheWebPath(String blobUrl, String persistentPath) {
    _webPersistentPathCache[blobUrl] = persistentPath;
  }

  static String? getPersistentPath(String blobUrl) {
    return _webPersistentPathCache[blobUrl];
  }

  Future<List<ExternalSymbol>> searchArasaac(String query, {int limit = 30}) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.https(
      'api.arasaac.org',
      '/api/pictograms/en/search/${Uri.encodeComponent(query)}',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];

      final decoded = json.decode(response.body);
      if (decoded is! List) return [];

      final results = <ExternalSymbol>[];
      for (final entry in decoded) {
        if (entry is Map<String, dynamic>) {
          final id = entry['_id']?.toString() ?? entry['id']?.toString();
          final label = _bestLabelForArasaac(entry, query);
          if (id != null && id.isNotEmpty) {
            results.add(ExternalSymbol(
              id: id,
              label: label,
              imageUrl: _arasaacImageUrl(id),
              source: 'ARASAAC',
            ));
          }
        }
      }
      return sortByRelevance(results, query).take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ExternalSymbol>> searchOpenSymbols(String query, {int limit = 30, String? repo}) async {
    if (query.trim().isEmpty) return [];

    final params = {'q': query};
    if (repo != null) params['repo_key'] = repo;

    final uri = Uri.https(
      'www.opensymbols.org',
      '/api/v1/symbols/search',
      params,
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];

      final decoded = json.decode(response.body);
      if (decoded is! List) return [];

      final results = <ExternalSymbol>[];
      for (final entry in decoded) {
        if (entry is Map<String, dynamic>) {
          final id = entry['id']?.toString();
          final label = entry['name']?.toString() ?? query;
          final imageUrl = entry['image_url']?.toString();
          if (id != null && imageUrl != null) {
            results.add(ExternalSymbol(
              id: id,
              label: label,
              imageUrl: imageUrl,
              source: 'OpenSymbols',
            ));
          }
        }
        if (results.length >= limit) break;
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  Future<List<ExternalSymbol>> searchGlobalSymbols(String query, {int limit = 30}) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.https(
      'globalsymbols.com',
      '/api/v1/labels/search',
      {
        'query': query,
        'language': 'eng',
        'limit': limit.toString(),
      },
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];

      final decoded = json.decode(response.body);
      if (decoded is! List) return [];

      final results = <ExternalSymbol>[];
      for (final entry in decoded) {
        if (entry is Map<String, dynamic>) {
          final id = entry['id']?.toString();
          final label = entry['text']?.toString() ?? query;
          final picto = entry['picto'];
          if (id != null && picto is Map) {
            final imageUrl = picto['image_url']?.toString();
            if (imageUrl != null) {
              results.add(ExternalSymbol(
                id: id,
                label: label,
                imageUrl: imageUrl,
                source: 'GlobalSymbols',
              ));
            }
          }
        }
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  Future<List<ExternalSymbol>> searchWidgit(String query, {int limit = 30}) async {
    if (query.trim().isEmpty) return [];

    // Widgit symbols are not available through a public API. The closest
    // aggregator, OpenSymbols, can filter by repo with a valid access token.
    // If you have a Widgit/Symgate account or an OpenSymbols v2 token, update
    // the token below (or inject it from your environment).
    const accessToken = '';

    try {
      if (accessToken.isNotEmpty) {
        final uri = Uri.https(
          'www.opensymbols.org',
          '/api/v2/symbols',
          {
            'q': query,
            'repo': 'widgit',
            'access_token': accessToken,
          },
        );
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          if (decoded is List) {
            return _parseOpenSymbolsResults(decoded, source: 'Widgit', limit: limit);
          }
        }
      }

      // Fallback to public OpenSymbols v1 search and filter by repo_key.
      final uri = Uri.https(
        'www.opensymbols.org',
        '/api/v1/symbols/search',
        {'q': query},
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];

      final decoded = json.decode(response.body);
      if (decoded is! List) return [];

      final results = <ExternalSymbol>[];
      for (final entry in decoded) {
        if (entry is Map<String, dynamic>) {
          final repoKey = entry['repo_key']?.toString().toLowerCase() ?? '';
          if (!repoKey.contains('widgit')) continue;

          final id = entry['id']?.toString();
          final label = entry['name']?.toString() ?? query;
          final imageUrl = entry['image_url']?.toString();
          if (id != null && imageUrl != null) {
            results.add(ExternalSymbol(
              id: id,
              label: label,
              imageUrl: imageUrl,
              source: 'Widgit',
            ));
          }
        }
        if (results.length >= limit) break;
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  List<ExternalSymbol> _parseOpenSymbolsResults(List<dynamic> decoded, {required String source, int limit = 30}) {
    final results = <ExternalSymbol>[];
    for (final entry in decoded) {
      if (entry is Map<String, dynamic>) {
        final id = entry['id']?.toString();
        final label = entry['name']?.toString() ?? '';
        final imageUrl = entry['image_url']?.toString();
        if (id != null && imageUrl != null) {
          results.add(ExternalSymbol(
            id: id,
            label: label,
            imageUrl: imageUrl,
            source: source,
          ));
        }
      }
      if (results.length >= limit) break;
    }
    return results;
  }

  Future<List<ExternalSymbol>> searchAll(String query, {int limit = 30, List<String>? preferredSets, List<String>? priorityPaths}) async {
    const stopWords = {'the', 'a', 'an', 'of', 'and', '&', 'to', 'in', 'on', 'for', 'with', 'is', 'it', 'at', 'by'};
    final rawWords = query.toLowerCase().trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();

    // Strip a trailing 'day' from holiday names like "Popcorn Day" or "World Braille Day"
    final endsWithDay = rawWords.isNotEmpty && rawWords.last == 'day';
    final meaningfulWords = rawWords
        .take(endsWithDay ? rawWords.length - 1 : rawWords.length)
        .map((s) => s.replaceAll(RegExp(r"[^a-z0-9']"), ''))
        .where((s) => s.isNotEmpty && !stopWords.contains(s))
        .toList();

    final cleanQuery = meaningfulWords.join(' ');
    // For "X Day" tiles the important word is the one before "day"
    // (e.g. "Popcorn Day" -> "Popcorn", "World Braille Day" -> "Braille").
    final lastMeaningful = meaningfulWords.isNotEmpty ? meaningfulWords.last : '';
    final searchTerms = endsWithDay && lastMeaningful.isNotEmpty ? lastMeaningful : cleanQuery;

    if (cleanQuery.isEmpty && query.trim().isNotEmpty) {
      // If query was ONLY stop words/day, don't return everything
      return [];
    }
    if (query.trim().isEmpty) return [];

    final results = <ExternalSymbol>[];

    // Search local assets first so they appear at the top of combined results
    final assetResults = await searchAssets(searchTerms.isEmpty ? cleanQuery : searchTerms, limit: limit, preferredSets: preferredSets, priorityPaths: priorityPaths);
    results.addAll(assetResults);

    // Search all available external APIs in parallel, including synonym-expanded queries
    final alts = expandedQueries(cleanQuery);
    final queries = <String>{searchTerms, if (cleanQuery != searchTerms) cleanQuery, ...alts}.where((q) => q.isNotEmpty).toList();
    try {
      final futures = <Future<List<ExternalSymbol>>>[];
      for (final q in queries) {
        futures.add(searchArasaac(q, limit: limit));
        futures.add(searchOpenSymbols(q, limit: limit));
        futures.add(searchGlobalSymbols(q, limit: limit));
        futures.add(searchWidgit(q, limit: limit));
      }
      final allFutures = await Future.wait(futures);

      for (final futureResults in allFutures) {
        results.addAll(futureResults);
      }
    } catch (e) {
      debugPrint('Error searching external symbol libraries: $e');
      // Keep any locally matched assets and continue without crashing.
    }

    // Deduplicate results by imageUrl
    final seenUrls = <String>{};
    final uniqueResults = <ExternalSymbol>[];
    for (final s in results) {
      if (seenUrls.add(s.imageUrl)) {
        uniqueResults.add(s);
      }
    }

    // Filter out NSFW words unless the query itself is one of those exact words
    const blockedWords = {'penis', 'vagina', 'breasts'};
    final qLower = query.trim().toLowerCase();
    final queryIsBlocked = blockedWords.contains(qLower);
    final filtered = queryIsBlocked
        ? uniqueResults
        : uniqueResults.where((s) {
            final label = s.label.toLowerCase();
            return !blockedWords.any((w) => label.contains(w));
          }).toList();

    return sortByRelevance(filtered, query, preferredSets: preferredSets, priorityPaths: priorityPaths);
  }

  String _arasaacImageUrl(String id) {
    return 'https://static.arasaac.org/pictograms/$id/${id}_500.png';
  }

  Future<String?> downloadImage(String imageUrl, String id) async {
    if (kIsWeb) return imageUrl; // No direct download needed for web, just use URL

    try {
      final uri = Uri.parse(imageUrl);
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final directory = await getApplicationDocumentsDirectory();
      final ext = _fileExtension(uri.path) ?? 'png';
      final folder = Directory('${directory.path}/external_symbols');
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final output = File('${folder.path}/$id.$ext');
      await output.writeAsBytes(response.bodyBytes);
      return output.path;
    } catch (_) {
      return null;
    }
  }

  String? _fileExtension(String path) {
    final index = path.lastIndexOf('.');
    if (index < 0 || index == path.length - 1) return null;
    return path.substring(index + 1);
  }

  static final _wordSeparator = RegExp(r'[^a-z0-9]+');

  String _bestLabelForArasaac(Map<String, dynamic> entry, String query) {
    final candidates = <String>[];
    if (entry['keywords'] is List) {
      for (final k in entry['keywords']!) {
        if (k is Map<String, dynamic>) {
          final keyword = k['keyword']?.toString();
          if (keyword != null && keyword.isNotEmpty) candidates.add(keyword);
          final plural = k['plural']?.toString();
          if (plural != null && plural.isNotEmpty) candidates.add(plural);
        } else {
          candidates.add(k.toString());
        }
      }
    }
    if (entry['keywords_en'] is List) {
      for (final k in entry['keywords_en']!) {
        candidates.add(k.toString());
      }
    }
    if (candidates.isEmpty) return query;
    final lowerQuery = query.trim().toLowerCase();
    var best = candidates.first;
    var bestScore = _relevanceScoreOptimized(best, lowerQuery, [lowerQuery]);
    for (var i = 1; i < candidates.length; i++) {
      final score = _relevanceScoreOptimized(candidates[i], lowerQuery, [lowerQuery]);
      if (score < bestScore || (score == bestScore && candidates[i].length < best.length)) {
        best = candidates[i];
        bestScore = score;
      }
    }
    return best;
  }

  List<ExternalSymbol> sortByRelevance(List<ExternalSymbol> symbols, String query, {List<String>? preferredSets, List<String>? priorityPaths}) {
    final lowerQuery = query.trim().toLowerCase();
    if (lowerQuery.isEmpty) return symbols;

    final queryWords = lowerQuery.split(_wordSeparator).where((s) => s.isNotEmpty).toList();
    if (queryWords.isEmpty) return symbols;

    // Pre-calculate scores to avoid O(N log N * Words) complexity during sort.
    // Consider both the asset label and any user-added tags.
    final scores = <String, int>{};
    for (final s in symbols) {
      final labelScore = _relevanceScoreOptimized(s.label, lowerQuery, queryWords);
      final tagScore = _tagScore(s.imageUrl, lowerQuery);
      scores[s.id] = labelScore < tagScore ? labelScore : tagScore;
    }

    symbols.sort((a, b) {
      final priorityCount = priorityPaths?.length ?? 0;
      final inAppCount = priorityCount + 3;

      int sourceIndex(String imageUrl) {
        final p = imageUrl.toLowerCase();
        if (priorityPaths != null) {
          for (int i = 0; i < priorityPaths.length; i++) {
            if (p.startsWith(priorityPaths[i].toLowerCase())) return i;
          }
        }
        final offset = priorityCount;
        if (!p.startsWith('assets/')) return offset + 3; // Free external sets
        if (p.startsWith('assets/common/small words/montessori/')) return offset + 1;
        if (p.startsWith('assets/sign/')) return offset + 2;
        return offset; // Other in-app assets
      }

      const closeMatchMaxScore = 10;

      int sortGroup(ExternalSymbol s) {
        final sIdx = sourceIndex(s.imageUrl);
        final score = scores[s.id] ?? 9999;
        final sLabelLower = s.label.trim().toLowerCase();
        final sAlpha = sLabelLower.replaceAll(RegExp(r'[^a-z0-9]'), '');
        final qAlpha = lowerQuery.replaceAll(RegExp(r'[^a-z0-9]'), '');
        final tags = _metadataService?.getTags(s.imageUrl) ?? [];
        final labelExact = sLabelLower == lowerQuery || (qAlpha.isNotEmpty && sAlpha == qAlpha);
        final tagExact = tags.any((t) => t == lowerQuery);
        final exact = labelExact || tagExact;
        final close = score <= closeMatchMaxScore;

        if (sIdx < inAppCount) {
          if (sIdx < priorityCount) {
            // Priority in-app source
            if (exact) return sIdx;
            if (close) return priorityCount + sIdx;
          } else {
            // Non-priority in-app source
            final rel = sIdx - priorityCount;
            final base = priorityCount * 2;
            final nonPriorityInAppCount = inAppCount - priorityCount;
            if (exact) return base + rel;
            if (close) return base + rel + nonPriorityInAppCount;
          }
        } else {
          final extIdx = sIdx - inAppCount;
          final base = inAppCount * 2;
          if (exact) return base + extIdx;
          if (close) return base + extIdx + 1;
        }
        return inAppCount * 2 + 2; // Everything else
      }

      final aGroup = sortGroup(a);
      final bGroup = sortGroup(b);
      if (aGroup != bGroup) return aGroup.compareTo(bGroup);

      // Within the same group, respect the user's preferred sets.
      if (preferredSets != null && preferredSets.isNotEmpty) {
        final sourceA = a.source == 'Assets' ? 'In App Assets' : a.source;
        final sourceB = b.source == 'Assets' ? 'In App Assets' : b.source;

        final indexA = preferredSets.indexOf(sourceA);
        final indexB = preferredSets.indexOf(sourceB);

        if (indexA != -1 && indexB != -1) {
          if (indexA != indexB) return indexA.compareTo(indexB);
        } else if (indexA != -1) {
          return -1;
        } else if (indexB != -1) {
          return 1;
        }
      }

      // Final tiebreakers
      final scoreA = scores[a.id] ?? 9999;
      final scoreB = scores[b.id] ?? 9999;
      if (scoreA != scoreB) return scoreA.compareTo(scoreB);

      final aLen = a.label.length;
      final bLen = b.label.length;
      if (aLen != bLen) return aLen.compareTo(bLen);

      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    return symbols;
  }

  int _tagScore(String imageUrl, String lowerQuery) {
    final tags = _metadataService?.getTags(imageUrl) ?? [];
    if (tags.any((t) => t == lowerQuery)) return 0;
    if (tags.any((t) => t.contains(lowerQuery))) return 5;
    return 9999;
  }

  Future<void> addTag(String imageUrl, String tag) async {
    final clean = tag.trim().toLowerCase();
    if (clean.isEmpty) return;
    await _ensureMetadata();
    await _metadataService?.addTag(imageUrl, clean);
  }

  int _relevanceScoreOptimized(String label, String lowerQuery, List<String> queryWords) {
    final l = label.trim().toLowerCase();
    if (l.isEmpty) return 9999;
    if (l == lowerQuery) return 0;

    final labelWords = l.split(_wordSeparator).where((s) => s.isNotEmpty).toList();
    if (labelWords.isEmpty) return 9999;

    // Strong phrase match
    if (_isSubsequence(queryWords, labelWords)) return 1;

    var total = 0;
    for (int i = 0; i < queryWords.length; i++) {
      total += _wordScoreOptimized(queryWords[i], queryWords[i], labelWords, l, '');
    }
    return total;
  }

  int _wordScoreOptimized(String word, String normWord, List<String> labelWords, String label, String normLabel) {
    if (labelWords.contains(word)) return 1;
    if (labelWords.any((w) => w.startsWith(word))) return 2;
    if (labelWords.any((w) => w.contains(word))) return 5;
    if (label.startsWith(word)) return 6;
    if (label.contains(word)) return 7;

    return 100 + _minLevenshtein(word, labelWords);
  }

  bool _isSubsequence(List<String> sub, List<String> superList) {
    var i = 0;
    for (final word in superList) {
      if (i < sub.length && word == sub[i]) i++;
    }
    return i == sub.length;
  }

  int _minLevenshtein(String word, List<String> words) {
    if (words.isEmpty) return 1000;
    var min = 1000;
    for (final w in words) {
      final d = _levenshtein(word, w);
      if (d < min) min = d;
    }
    return min;
  }

  int _levenshtein(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    var previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 0; i < a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0);
      current[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        final deletion = current[j] + 1;
        final insertion = previous[j + 1] + 1;
        final substitution = previous[j] + cost;
        final m = deletion < insertion ? deletion : insertion;
        current[j + 1] = substitution < m ? substitution : m;
      }
      previous = current;
    }
    return previous[b.length];
  }

  List<ExternalSearchLink> get libraryLinks => const [
        ExternalSearchLink(
          name: 'Mulberry',
          description: 'Open Mulberry symbol search in your browser.',
          urlTemplate: 'https://www.google.com/search?q=site:mulberrysymbols.org+{query}',
        ),
        ExternalSearchLink(
          name: 'Sclera',
          description: 'Open Sclera symbol search in your browser.',
          urlTemplate: 'https://www.google.com/search?q=site:sclera.be+{query}',
        ),
      ];

  Future<void> _ensureMetadata() async {
    _metadataService ??= await SymbolMetadataService.init();
    if (_assetSymbolCache == null) {
      await _prewarmAssetCache();
    }
  }

  Future<void> _prewarmAssetCache() async {
    try {
      final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assetList = assetManifest.listAssets();
      final imageExtensions = {'.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg'};
      
      final symbols = <ExternalSymbol>[];
      
      for (final assetPath in assetList) {
        if (!assetPath.startsWith('assets/')) continue;
        
        final extIndex = assetPath.lastIndexOf('.');
        if (extIndex == -1) continue;
        final extension = assetPath.substring(extIndex).toLowerCase();
        if (!imageExtensions.contains(extension)) continue;
        
        final filename = p.basenameWithoutExtension(assetPath);
        final assetId = assetPath.hashCode.toString();
        
        symbols.add(ExternalSymbol(
          id: assetId,
          label: filename,
          imageUrl: assetPath,
          source: 'Assets',
        ));
      }
      _assetSymbolCache = symbols;
    } catch (e) {
      debugPrint('Error prewarming asset cache: $e');
      _assetSymbolCache = [];
    }
  }

  Future<List<ExternalSymbol>> searchAssets(String query, {int limit = 30, List<String>? preferredSets, List<String>? priorityPaths}) async {
    await _ensureMetadata();
    final allAssets = _assetSymbolCache ?? [];

    if (query.trim().isEmpty) return allAssets.take(limit).toList();

    try {
      // Score and sort every local asset so the "assets only" order mirrors
      // the order assets appear in a full search (relevance, preferred sets,
      // exact matches, etc.) and includes close matches as well as exact ones.
      return sortByRelevance(allAssets, query, preferredSets: preferredSets, priorityPaths: priorityPaths).take(limit).toList();
    } catch (e) {
      debugPrint('Error searching assets: $e');
      return [];
    }
  }

  Future<bool> deleteAsset(String assetPath) async {
    if (kIsWeb) return false;
    try {
      final file = File(assetPath);
      if (await file.exists()) {
        await file.delete();
        _assetSymbolCache = null; // Invalidate cache
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting asset $assetPath: $e');
    }
    return false;
  }

  Future<bool> removeWhiteBackground(String path) async {
    if (kIsWeb) return false;
    try {
      final file = File(path);
      if (!await file.exists()) return false;

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return false;

      // Ensure image has an alpha channel
      final workImage = image.hasAlpha ? image : image.convert(format: img.Format.uint8, numChannels: 4);

      for (final frame in workImage.frames) {
        for (final pixel in frame) {
          if (pixel.r > 240 && pixel.g > 240 && pixel.b > 240) {
            pixel.a = 0;
          }
        }
      }

      final outBytes = img.encodePng(workImage);
      await file.writeAsBytes(outBytes);
      return true;
    } catch (e) {
      debugPrint('Error removing background: $e');
      return false;
    }
  }
}
