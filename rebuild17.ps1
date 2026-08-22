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

# Board 17: Lasagne (Beef Lasagne)
Write-Board "$base\beef_lasagne\prebuilt_recipes_beef_lasagne.json" 7 9 @(
    # Row 1: Lasagne, black pepper, blank, 1 Instr, 2 Instr, 3 Instr, 4 Instr
    Title "prebuilt_recipes_beef_lasagne_tile_1" "Lasagne" "$cook\More Symbols\lasagne.png"
    Title "prebuilt_recipes_beef_lasagne_tile_2" "black pepper" "$cook\Spices\peppercorns.png"
    Blank "prebuilt_recipes_beef_lasagne_tile_3"
    Inst "prebuilt_recipes_beef_lasagne_tile_4" "Beef Lasagne Instructions 1" "$cook\Recipes\Instructions\Beef Lasagne Instructions 1.png"
    Inst "prebuilt_recipes_beef_lasagne_tile_5" "Beef Lasagne Instructions 2" "$cook\Recipes\Instructions\Beef Lasagne Instructions 2.png"
    Inst "prebuilt_recipes_beef_lasagne_tile_6" "Beef Lasagne Instructions 3" "$cook\Recipes\Instructions\Beef Lasagne Instructions 3.png"
    Inst "prebuilt_recipes_beef_lasagne_tile_7" "Beef Lasagne Instructions 4" "$cook\Recipes\Instructions\Beef Lasagne Instructions 4.png"
    # Row 2: one, onion, blank, blank, 250g, minced beef, blank
    Vocab "prebuilt_recipes_beef_lasagne_tile_8" "one" "$common\Numbers\1.png"
    Vocab "prebuilt_recipes_beef_lasagne_tile_9" "onion" "$cook\Vegetables\onion.png"
    Blank "prebuilt_recipes_beef_lasagne_tile_10"
    Blank "prebuilt_recipes_beef_lasagne_tile_11"
    Vocab "prebuilt_recipes_beef_lasagne_tile_12" "250g" "$cook\Cooking Equipment\scales.png"
    Vocab "prebuilt_recipes_beef_lasagne_tile_13" "minced beef" "$cook\Protein\beef.png"
    Blank "prebuilt_recipes_beef_lasagne_tile_14"
    # Row 3: one, carrot, blank, blank, one, garlic, clove
    Vocab "prebuilt_recipes_beef_lasagne_tile_15" "one" "$common\Numbers\1.png"
    Vocab "prebuilt_recipes_beef_lasagne_tile_16" "carrot" "$cook\Vegetables\carrot.png"
    Blank "prebuilt_recipes_beef_lasagne_tile_17"
    Blank "prebuilt_recipes_beef_lasagne_tile_18"
    Vocab "prebuilt_recipes_beef_lasagne_tile_19" "one" "$common\Numbers\1.png"
    Vocab "prebuilt_recipes_beef_lasagne_tile_20" "garlic" "$cook\Vegetables\garlic.png"
    Vocab "prebuilt_recipes_beef_lasagne_tile_21" "clove" "$cook\Vegetables\garlic.png"
    # Row 4: 25g, reduced fat spread, blank, blank, 15ml, spoon, oil
    Vocab "prebuilt_recipes_beef_lasagne_tile_22" "25g" "$cook\Cooking Equipment\scales.png"
    Vocab "prebuilt_recipes_beef_lasagne_tile_23" "reduced fat spread" "$cook\Dairy\reduced fat spread.png"
    Blank "prebuilt_recipes_beef_lasagne_tile_24"
    Blank "prebuilt_recipes_beef_lasagne_tile_25"
    Vocab "prebuilt_recipes_beef_lasagne_tile_26" "15ml" "$cook\Cooking Equipment\jug.png"
    Vocab "prebuilt_recipes_beef_lasagne_tile_27" "spoon" "$cook\Cooking Equipment\spoon.png"
    Vocab "prebuilt_recipes_beef_lasagne_tile_28" "oil" "$cook\More Symbols\oil.png"
    # Row 5: 25g, plain flour, blank, blank, 400g tin, chopped, tomato
    Vocab "prebuilt_recipes_beef_lasagne_tile_29" "25g" "$cook\Cooking Equipment\scales.png"
    Vocab "prebuilt_recipes_beef_lasagne_tile_30" "plain flour" "$cook\Carbohydrates\self raising flour.png"
    Blank "prebuilt_recipes_beef_lasagne_tile_31"
    Blank "prebuilt_recipes_beef_lasagne_tile_32"
    Vocab "prebuilt_recipes_beef_lasagne_tile_33" "400g tin" "$cook\Cooking Equipment\scales.png"
    Vocab "prebuilt_recipes_beef_lasagne_tile_34" "chopped" "$cook\More Symbols\chopped.png"
    Vocab "prebuilt_recipes_beef_lasagne_tile_35" "tomato" "$cook\Fruit\tomato.png"
    # Row 6: 300ml, semi-skimmed milk, blank, blank, 15ml, spoon, tomato puree
    Vocab "prebuilt_recipes_beef_lasagne_tile_36" "300ml" "$cook\Cooking Equipment\jug.png"
    Vocab "prebuilt_recipes_beef_lasagne_tile_37" "semi-skimmed milk" "$cook\Dairy\semi-skimmed milk.png"
    Blank "prebuilt_recipes_beef_lasagne_tile_38"
    Blank "prebuilt_recipes_beef_lasagne_tile_39"
    Vocab "prebuilt_recipes_beef_lasagne_tile_40" "15ml" "$cook\Cooking Equipment\jug.png"
    Vocab "prebuilt_recipes_beef_lasagne_tile_41" "spoon" "$cook\Cooking Equipment\spoon.png"
    Vocab "prebuilt_recipes_beef_lasagne_tile_42" "tomato puree" "$cook\More Symbols\tomato puree.png"
    # Row 7: 100ml, water, blank, blank, 5ml, spoon, mixed herbs
    Vocab "prebuilt_recipes_beef_lasagne_tile_43" "100ml" "$cook\Cooking Equipment\jug.png"
    Vocab "prebuilt_recipes_beef_lasagne_tile_44" "water" "$cook\More Symbols\water.png"
    Blank "prebuilt_recipes_beef_lasagne_tile_45"
    Blank "prebuilt_recipes_beef_lasagne_tile_46"
    Vocab "prebuilt_recipes_beef_lasagne_tile_47" "5ml" "$cook\Cooking Equipment\jug.png"
    Vocab "prebuilt_recipes_beef_lasagne_tile_48" "spoon" "$cook\Cooking Equipment\spoon.png"
    Vocab "prebuilt_recipes_beef_lasagne_tile_49" "mixed herbs" "$cook\Herbs\basil.png"
    # Row 8: 50g, cheddar, blank, blank, 6, lasagne, sheets
    Vocab "prebuilt_recipes_beef_lasagne_tile_50" "50g" "$cook\Cooking Equipment\scales.png"
    Vocab "prebuilt_recipes_beef_lasagne_tile_51" "cheddar" "$cook\Dairy\cheddar.png"
    Blank "prebuilt_recipes_beef_lasagne_tile_52"
    Blank "prebuilt_recipes_beef_lasagne_tile_53"
    Vocab "prebuilt_recipes_beef_lasagne_tile_54" "6" "$common\Numbers\6.png"
    Vocab "prebuilt_recipes_beef_lasagne_tile_55" "lasagne" "$cook\More Symbols\lasagne sheet.png"
    Vocab "prebuilt_recipes_beef_lasagne_tile_56" "sheets" "$cook\More Symbols\lasagne sheet.png"
    # Row 9: blank x7
    Blank "prebuilt_recipes_beef_lasagne_tile_57"
    Blank "prebuilt_recipes_beef_lasagne_tile_58"
    Blank "prebuilt_recipes_beef_lasagne_tile_59"
    Blank "prebuilt_recipes_beef_lasagne_tile_60"
    Blank "prebuilt_recipes_beef_lasagne_tile_61"
    Blank "prebuilt_recipes_beef_lasagne_tile_62"
    Blank "prebuilt_recipes_beef_lasagne_tile_63"
)

Write-Host "Done 17"
