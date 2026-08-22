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

# Board 15: Herby Veg Crumble
Write-Board "$base\Herby Veg Crumble\prebuilt_recipes_herby_veg_crumble.json" 7 7 @(
    # Row 1: Herby, Vegetable, Crumble, blank, 1 Instr, 2 Instr, blank
    Title "prebuilt_recipes_herby_veg_crumble_tile_1" "Herby" "$cook\Herbs\basil.png"
    Title "prebuilt_recipes_herby_veg_crumble_tile_2" "Vegetable" "$cook\More Symbols\vegetable.png"
    Title "prebuilt_recipes_herby_veg_crumble_tile_3" "Crumble" "$cook\Meals\Desserts and Puddings\crumble.png"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_4"
    Inst "prebuilt_recipes_herby_veg_crumble_tile_5" "Herby Veg Crumble Instructions 1" "$cook\Recipes\Instructions\Herby Veg Crumble Instructions 1.png"
    Inst "prebuilt_recipes_herby_veg_crumble_tile_6" "Herby Veg Crumble Instructions 2" "$cook\Recipes\Instructions\Herby Veg Crumble Instructions 2.png"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_7"
    # Row 2: blank x7
    Blank "prebuilt_recipes_herby_veg_crumble_tile_8"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_9"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_10"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_11"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_12"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_13"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_14"
    # Row 3: 150g, wholemeal flour, blank, blank, four, mushroom, blank
    Vocab "prebuilt_recipes_herby_veg_crumble_tile_15" "150g" "$cook\Cooking Equipment\scales.png"
    Vocab "prebuilt_recipes_herby_veg_crumble_tile_16" "wholemeal flour" "$cook\Carbohydrates\wholemeal flour.png"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_17"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_18"
    Vocab "prebuilt_recipes_herby_veg_crumble_tile_19" "four" "$common\Numbers\4.png"
    Vocab "prebuilt_recipes_herby_veg_crumble_tile_20" "mushroom" "$cook\Vegetables\mushroom.png"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_21"
    # Row 4: 40g, butter, blank, blank, two, small leeks, blank
    Vocab "prebuilt_recipes_herby_veg_crumble_tile_22" "40g" "$cook\Cooking Equipment\scales.png"
    Vocab "prebuilt_recipes_herby_veg_crumble_tile_23" "butter" "$cook\Dairy\butter.png"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_24"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_25"
    Vocab "prebuilt_recipes_herby_veg_crumble_tile_26" "two" "$common\Numbers\2.png"
    Vocab "prebuilt_recipes_herby_veg_crumble_tile_27" "small leeks" "$cook\Vegetables\leek.png"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_28"
    # Row 5: tin, chopped tomato, blank, blank, one, pepper, blank
    Vocab "prebuilt_recipes_herby_veg_crumble_tile_29" "tin" "$cook\More Symbols\tin.png"
    Vocab "prebuilt_recipes_herby_veg_crumble_tile_30" "chopped tomatoes" "$cook\Fruit\tomato.png"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_31"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_32"
    Vocab "prebuilt_recipes_herby_veg_crumble_tile_33" "one" "$common\Numbers\1.png"
    Vocab "prebuilt_recipes_herby_veg_crumble_tile_34" "pepper" "$cook\Vegetables\pepper.png"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_35"
    # Row 6: 10ml, mixed herbs, blank, blank, blank, blank, blank
    Vocab "prebuilt_recipes_herby_veg_crumble_tile_36" "10ml" "$cook\Cooking Equipment\jug.png"
    Vocab "prebuilt_recipes_herby_veg_crumble_tile_37" "mixed herbs" "$cook\Herbs\basil.png"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_38"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_39"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_40"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_41"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_42"
    # Row 7: blank x7
    Blank "prebuilt_recipes_herby_veg_crumble_tile_43"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_44"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_45"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_46"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_47"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_48"
    Blank "prebuilt_recipes_herby_veg_crumble_tile_49"
)

Write-Host "Done 15"
