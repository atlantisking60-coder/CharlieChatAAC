Set fso = CreateObject("Scripting.FileSystemObject")
On Error Resume Next

' Rename #MAIN
If fso.FolderExists("c:\Users\Craig\Downloads\Charlie Chat\assets\symbols\3. Lesson Vocab\Religion & Worldviews\#MAIN") Then
    fso.MoveFolder "c:\Users\Craig\Downloads\Charlie Chat\assets\symbols\3. Lesson Vocab\Religion & Worldviews\#MAIN", "c:\Users\Craig\Downloads\Charlie Chat\assets\symbols\3. Lesson Vocab\Religion & Worldviews\MAIN"
    If Err.Number <> 0 Then
        WScript.Echo "Error renaming MAIN folder: " & Err.Description
    Else
        WScript.Echo "Successfully renamed MAIN folder"
    End If
    Err.Clear
End If

' Rename #Elements
If fso.FolderExists("c:\Users\Craig\Downloads\Charlie Chat\assets\symbols\3. Lesson Vocab\Science\Entry Level\#Elements") Then
    fso.MoveFolder "c:\Users\Craig\Downloads\Charlie Chat\assets\symbols\3. Lesson Vocab\Science\Entry Level\#Elements", "c:\Users\Craig\Downloads\Charlie Chat\assets\symbols\3. Lesson Vocab\Science\Entry Level\Elements"
    If Err.Number <> 0 Then
        WScript.Echo "Error renaming Elements folder: " & Err.Description
    Else
        WScript.Echo "Successfully renamed Elements folder"
    End If
    Err.Clear
End If

WScript.Echo "Done"
