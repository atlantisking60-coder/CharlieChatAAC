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
$img = "assets/Subject Vocab"

# Board 14: Ginger Biscuits
Write-Board "$base\ginger_biscuits\prebuilt_recipes_ginger_biscuits.json" 7 2 @(
    Title "prebuilt_recipes_ginger_biscuits_tile_1" "Ginger" "$img\Cooking\Spices\ginger.png"
    Title "prebuilt_recipes_ginger_biscuits_tile_2" "Biscuits" "$img\Cooking\Carbohydrates\biscuits.png"
    Blank "prebuilt_recipes_ginger_biscuits_tile_3"
    Blank "prebuilt_recipes_ginger_biscuits_tile_4"
    Blank "prebuilt_recipes_ginger_biscuits_tile_5"
    Inst "prebuilt_recipes_ginger_biscuits_tile_6" "Ginger Biscuits Instructions 1" "$img\Cooking\Recipes\Instructions\Ginger Biscuits Instructions 1.jpg"
    Inst "prebuilt_recipes_ginger_biscuits_tile_7" "Ginger Biscuits Instructions 2" "$img\Cooking\Recipes\Instructions\Ginger Biscuits Instructions 2.jpg"
    Blank "prebuilt_recipes_ginger_biscuits_tile_8"
    Blank "prebuilt_recipes_ginger_biscuits_tile_9"
    Blank "prebuilt_recipes_ginger_biscuits_tile_10"
    Blank "prebuilt_recipes_ginger_biscuits_tile_11"
    Blank "prebuilt_recipes_ginger_biscuits_tile_12"
    Blank "prebuilt_recipes_ginger_biscuits_tile_13"
    Blank "prebuilt_recipes_ginger_biscuits_tile_14"
)

Write-Host "Done 14"
