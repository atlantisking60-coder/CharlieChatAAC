Option Explicit

Dim fso, base, logFile
Set fso = CreateObject("Scripting.FileSystemObject")
base = "C:\Users\Craig\Downloads\Charlie Chat"

On Error Resume Next
Set logFile = fso.CreateTextFile(fso.BuildPath(base, "rename_hash.log"), True)
If Err.Number <> 0 Then
    WScript.Echo "Could not create log file: " & Err.Description
    WScript.Quit 1
End If
On Error GoTo 0

logFile.WriteLine "Starting removal of '#' from names in " & base
RenameFolder fso.GetFolder(base)
logFile.WriteLine "Done."
logFile.Close
WScript.Echo "Done. See rename_hash.log for details."

Sub RenameFolder(folder)
    Dim f, i
    Dim subFolders()
    
    ' Rename files in this folder
    For Each f In folder.Files
        If InStr(f.Name, "#") > 0 Then
            RenameItem f
        End If
    Next
    
    ' Build array of subfolders to avoid collection-changes during iteration
    i = 0
    For Each f In folder.SubFolders
        ReDim Preserve subFolders(i)
        Set subFolders(i) = f
        i = i + 1
    Next
    
    ' Recurse into each subfolder, then rename the subfolder itself
    If i > 0 Then
        For i = 0 To UBound(subFolders)
            RenameFolder subFolders(i)
            If InStr(subFolders(i).Name, "#") > 0 Then
                RenameItem subFolders(i)
            End If
        Next
    End If
End Sub

Sub RenameItem(item)
    Dim oldName, newName
    oldName = item.Name
    newName = Replace(oldName, "#", "")
    newName = Trim(newName)
    If newName = "" Then
        logFile.WriteLine "SKIP (would become empty): " & item.Path
        WScript.Echo "SKIP (would become empty): " & oldName
        Exit Sub
    End If
    On Error Resume Next
    item.Name = newName
    If Err.Number <> 0 Then
        logFile.WriteLine "ERROR: " & item.Path & " -> " & newName & " | " & Err.Description
        WScript.Echo "ERROR: " & oldName & " -> " & newName & " | " & Err.Description
        Err.Clear
    Else
        logFile.WriteLine "OK: " & item.Path & " -> " & newName
        WScript.Echo "OK: " & oldName & " -> " & newName
    End If
    On Error GoTo 0
End Sub
