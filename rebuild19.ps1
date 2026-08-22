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

# Board 19: Mince Pies
Write-Board "$base\mince_pies\prebuilt_recipes_mince_pies.json" 7 5 @(
    # Row 1: Mince Pies(img), Jam(img), Tart(img), blank, 1 Instr, 2 Instr, blank
    Title "prebuilt_recipes_mince_pies_tile_1" "Mince Pies" "$cook\More Symbols\mincemeat.png"
    Title "prebuilt_recipes_mince_pies_tile_2" "Jam" "$cook\More Symbols\jam.png"
    Title "prebuilt_recipes_mince_pies_tile_3" "Tart" "$cook\Meals\Desserts and Puddings\pie.png"
    Blank "prebuilt_recipes_mince_pies_tile_4"
    Inst "prebuilt_recipes_mince_pies_tile_5" "Mince Pies Instructions 1" "$cook\Recipes\Instructions\Mince Pies Instructions 1.png"
    Inst "prebuilt_recipes_mince_pies_tile_6" "Mince Pies Instructions 2" "$cook\Recipes\Instructions\Mince Pies Instructions 2.png"
    Blank "prebuilt_recipes_mince_pies_tile_7"
    # Row 2: blank x7
    Blank "prebuilt_recipes_mince_pies_tile_8"
    Blank "prebuilt_recipes_mince_pies_tile_9"
    Blank "prebuilt_recipes_mince_pies_tile_10"
    Blank "prebuilt_recipes_mince_pies_tile_11"
    Blank "prebuilt_recipes_mince_pies_tile_12"
    Blank "prebuilt_recipes_mince_pies_tile_13"
    Blank "prebuilt_recipes_mince_pies_tile_14"
    # Row 3: 87g, cold, butter, blank, 175g, plain flour, blank
    Vocab "prebuilt_recipes_mince_pies_tile_15" "87g" "$cook\Cooking Equipment\scales.png"
    Vocab "prebuilt_recipes_mince_pies_tile_16" "cold" "$cook\Dairy\butter.png"
    Vocab "prebuilt_recipes_mince_pies_tile_17" "butter" "$cook\Dairy\butter.png"
    Blank "prebuilt_recipes_mince_pies_tile_18"
    Vocab "prebuilt_recipes_mince_pies_tile_19" "175g" "$cook\Cooking Equipment\scales.png"
    Vocab "prebuilt_recipes_mince_pies_tile_20" "plain flour" "$cook\Carbohydrates\self raising flour.png"
    Blank "prebuilt_recipes_mince_pies_tile_21"
    # Row 4: jam, or, mincemeat, blank, blank, blank, icing sugar
    Vocab "prebuilt_recipes_mince_pies_tile_22" "jam" "$cook\More Symbols\jam.png"
    Vocab "prebuilt_recipes_mince_pies_tile_23" "or" "$cook\More Symbols\mincemeat.png"
    Vocab "prebuilt_recipes_mince_pies_tile_24" "mincemeat" "$cook\More Symbols\mincemeat.png"
    Blank "prebuilt_recipes_mince_pies_tile_25"
    Blank "prebuilt_recipes_mince_pies_tile_26"
    Blank "prebuilt_recipes_mince_pies_tile_27"
    Vocab "prebuilt_recipes_mince_pies_tile_28" "icing sugar" "$cook\Carbohydrates\icing sugar.png"
    # Row 5: blank x7
    Blank "prebuilt_recipes_mince_pies_tile_29"
    Blank "prebuilt_recipes_mince_pies_tile_30"
    Blank "prebuilt_recipes_mince_pies_tile_31"
    Blank "prebuilt_recipes_mince_pies_tile_32"
    Blank "prebuilt_recipes_mince_pies_tile_33"
    Blank "prebuilt_recipes_mince_pies_tile_34"
    Blank "prebuilt_recipes_mince_pies_tile_35"
)

Write-Host "Done 19"
