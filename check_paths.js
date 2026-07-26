const fs=require('fs');
const path=require('path');
const base='C:\\Users\\Craig\\Downloads\\Charlie Chat';
const files=[
  'lib\\data\\boards\\Common\\Animals\\prebuilt_animals.json',
  'lib\\data\\boards\\Common\\Animals\\Mammals\\prebuilt_mammals.json',
  'lib\\data\\boards\\Common\\Animals\\Birds\\prebuilt_birds.json',
  'lib\\data\\boards\\Common\\Animals\\Reptiles\\prebuilt_reptiles.json',
  'lib\\data\\boards\\Common\\Animals\\Insects\\prebuilt_insects.json',
  'lib\\data\\boards\\Common\\Animals\\Invertebrates\\prebuilt_invertebrates.json',
  'lib\\data\\boards\\Common\\Animals\\Fish\\prebuilt_fish.json',
  'lib\\data\\boards\\Common\\Animals\\Amphibians\\prebuilt_amphibians.json',
  'lib\\data\\boards\\Common\\Animals\\Habitats\\prebuilt_habitats.json',
  'lib\\data\\boards\\Common\\Animals\\Sealife\\prebuilt_sealife.json',
  'lib\\data\\boards\\Common\\Animals\\Nature Vocabulary\\prebuilt_nature_vocabulary.json',
  'lib\\data\\boards\\Common\\Animals\\Child Animals\\prebuilt_child_animals.json',
  'lib\\data\\boards\\Common\\Animals\\Groups of Animals\\prebuilt_groups_of_animals.json',
  'lib\\data\\boards\\Common\\Animals\\Arachnids\\prebuilt_arachnids.json',
  'lib\\data\\boards\\Common\\Animals\\Body Parts of Animals\\prebuilt_body_parts_of_animals.json',
];
const broken=[];
let total=0;
for(const f of files){
  const json=JSON.parse(fs.readFileSync(path.join(base,f),'utf8'));
  for(const tile of json.tiles){
    if(!tile.image) continue;
    if(tile.image.startsWith('http')) continue;
    if(tile.image.startsWith('data:')) continue;
    total++;
    const fullPath=path.join(base,tile.image);
    if(!fs.existsSync(fullPath)){
      broken.push({file:f,tile:tile.label,image:tile.image});
    }
  }
}
console.log('Total local paths checked:', total);
console.log('Broken paths found:', broken.length);
for(const b of broken){
  console.log('  BROKEN: tile="' + b.tile + '" path="' + b.image + '" in ' + b.file);
}
