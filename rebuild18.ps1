$ErrorActionPreference = "Stop"

function Blank($id) {
    @{id=$id;type="blank";label="";category="Custom";imageAsset="";emoji="";isBoardLink=$false;linkedBoardId="";linkedBoardName=$null;isFullScreenImage=$false;bgColor="transparent";textColor="#000000";tileSize=1;colSpan=1;rowSpan=1;customVoice=""}
}

function Tile($id,$label,$img,$bg="transparent",$tc="#000000",$cat="Assets",$inst=$false) {
    $t = @{id=$id;type="vocabulary";label=$label;category=$cat;imageAsset=$img;emoji="";isBoardLink=$false;linkedBoardId="";linkedBoardName=$null;isFullScreenImage=$false;bgColor=$bg;textColor=$tc;tileSize=1;colSpan=1;rowSpan=1;customVoice=""}
    if($inst){$t.isFullScreenImage=$true}
    $t
}

function Inst($id,$label,$img) { Tile $id $label $img "#000000" "#FFFFFF" "Assets" $true }
function Title($id,$label,$img) { Tile $id $label $img "#4FC3F7" }
function Vocab($id,$label,$img) { Tile $id $label $img }

function Write-Board($path,$cols,$rows,$tiles) {
    $existing = Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json
    $existing.columns = $cols
    $existing.layout.rows = $rows
    $existing.layout.blankTilesAdded = 0
    $existing.tiles = $tiles
    $existing | ConvertTo-Json -Depth 10 | Set-Content $path -Encoding UTF8
    Write-Host "OK: $path"
}

$base = "C:\Users\Craig\Downloads\Charlie Chat\lib\data\boards\Recipes\Recipes"
$cook = "assets/Subject Vocab\Cooking"
$common = "assets\Common"

# Board 18: Macaroni Cheese
Write-Board "$base\macaroni_cheese\prebuilt_recipes_macaroni_cheese.json" 7 7 @(
    # Row 1: Macaroni, Cheese, blank, blank, blank, 1 Instr, 2 Instr
    Title "prebuilt_recipes_macaroni_cheese_tile_1" "Macaroni" "$cook\Carbohydrates\pasta.png"
    Title "prebuilt_recipes_macaroni_cheese_tile_2" "Cheese" "$cook\Dairy\cheddar.png"
    Blank "prebuilt_recipes_macaroni_cheese_tile_3"
    Blank "prebuilt_recipes_macaroni_cheese_tile_4"
    Blank "prebuilt_recipes_macaroni_cheese_tile_5"
    Inst "prebuilt_recipes_macaroni_cheese_tile_6" "Macaroni Cheese Instructions 1" "$cook\Recipes\Instructions\Macaroni Cheese Instructions 1.jpg"
    Inst "prebuilt_recipes_macaroni_cheese_tile_7" "Macaroni Cheese Instructions 2" "$cook\Recipes\Instructions\Macaroni Cheese Instructions 2.jpg"
    # Row 2: blank x7
    Blank "prebuilt_recipes_macaroni_cheese_tile_8"
    Blank "prebuilt_recipes_macaroni_cheese_tile_9"
    Blank "prebuilt_recipes_macaroni_cheese_tile_10"
    Blank "prebuilt_recipes_macaroni_cheese_tile_11"
    Blank "prebuilt_recipes_macaroni_cheese_tile_12"
    Blank "prebuilt_recipes_macaroni_cheese_tile_13"
    Blank "prebuilt_recipes_macaroni_cheese_tile_14"
    # Row 3: 125g, pasta, blank, blank, 125ml, milk, blank
    Vocab "prebuilt_recipes_macaroni_cheese_tile_15" "125g" "$cook\Cooking Equipment\scales.png"
    Vocab "prebuilt_recipes_macaroni_cheese_tile_16" "pasta" "$cook\Carbohydrates\pasta.png"
    Blank "prebuilt_recipes_macaroni_cheese_tile_17"
    Blank "prebuilt_recipes_macaroni_cheese_tile_18"
    Vocab "prebuilt_recipes_macaroni_cheese_tile_19" "125ml" "$cook\Cooking Equipment\jug.png"
    Vocab "prebuilt_recipes_macaroni_cheese_tile_20" "milk" "$cook\Dairy\milk.png"
    Blank "prebuilt_recipes_macaroni_cheese_tile_21"
    # Row 4: 50g, cheddar, blank, blank, half, blank, tomato
    Vocab "prebuilt_recipes_macaroni_cheese_tile_22" "50g" "$cook\Cooking Equipment\scales.png"
    Vocab "prebuilt_recipes_macaroni_cheese_tile_23" "cheddar" "$cook\Dairy\cheddar.png"
    Blank "prebuilt_recipes_macaroni_cheese_tile_24"
    Blank "prebuilt_recipes_macaroni_cheese_tile_25"
    Vocab "prebuilt_recipes_macaroni_cheese_tile_26" "half" "$cook\Cooking Equipment\spoon.png"
    Blank "prebuilt_recipes_macaroni_cheese_tile_27"
    Vocab "prebuilt_recipes_macaroni_cheese_tile_28" "tomato" "$cook\Fruit\tomato.png"
    # Row 5: 13g, butter, blank, blank, blank, blank, black pepper
    Vocab "prebuilt_recipes_macaroni_cheese_tile_29" "13g" "$cook\Cooking Equipment\scales.png"
    Vocab "prebuilt_recipes_macaroni_cheese_tile_30" "butter" "$cook\Dairy\butter.png"
    Blank "prebuilt_recipes_macaroni_cheese_tile_31"
    Blank "prebuilt_recipes_macaroni_cheese_tile_32"
    Blank "prebuilt_recipes_macaroni_cheese_tile_33"
    Blank "prebuilt_recipes_macaroni_cheese_tile_34"
    Vocab "prebuilt_recipes_macaroni_cheese_tile_35" "black pepper" "$cook\Spices\peppercorns.png"
    # Row 6: 13g, plain flour, blank, blank, blank, blank, blank
    Vocab "prebuilt_recipes_macaroni_cheese_tile_36" "13g" "$cook\Cooking Equipment\scales.png"
    Vocab "prebuilt_recipes_macaroni_cheese_tile_37" "plain flour" "$cook\Carbohydrates\self raising flour.png"
    Blank "prebuilt_recipes_macaroni_cheese_tile_38"
    Blank "prebuilt_recipes_macaroni_cheese_tile_39"
    Blank "prebuilt_recipes_macaroni_cheese_tile_40"
    Blank "prebuilt_recipes_macaroni_cheese_tile_41"
    Blank "prebuilt_recipes_macaroni_cheese_tile_42"
    # Row 7: blank x7
    Blank "prebuilt_recipes_macaroni_cheese_tile_43"
    Blank "prebuilt_recipes_macaroni_cheese_tile_44"
    Blank "prebuilt_recipes_macaroni_cheese_tile_45"
    Blank "prebuilt_recipes_macaroni_cheese_tile_46"
    Blank "prebuilt_recipes_macaroni_cheese_tile_47"
    Blank "prebuilt_recipes_macaroni_cheese_tile_48"
    Blank "prebuilt_recipes_macaroni_cheese_tile_49"
)

Write-Host "Done 18"
