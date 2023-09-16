
function Rename-To-Folder {
    param (
        [String]$string
    )

    $string -replace '[\W]',''
}


$metaFile = Get-ChildItem -Path . -Filter meta.lsx -Recurse -ErrorAction SilentlyContinue -Force | ForEach-Object { $_.FullName }
$xml = [xml](Get-Content $metaFile)
$nameNode = $xml.SelectSingleNode("//node[@id='ModuleInfo']/attribute[@id='Name']")
$folderNode = $xml.SelectSingleNode("//node[@id='ModuleInfo']/attribute[@id='Folder']")
$currentFolder = $folderNode.Value

$newName = $args[0]
$newFolder = Rename-To-Folder $newName

if ($args[1] -match "^.+$") {
    $authorNode = $xml.SelectSingleNode("//node[@id='ModuleInfo']/attribute[@id='Author']")
    $authorNode.SetAttribute("value", $args[1])
}

$uuidNode = $xml.SelectSingleNode("//node[@id='ModuleInfo']/attribute[@id='UUID']")
$uuidNode.SetAttribute("value", [guid]::NewGuid().ToString())

$nameNode.SetAttribute("value", $newName)
$folderNode.SetAttribute("value", $newFolder)

$sw = New-Object System.IO.StringWriter
$writer = New-Object System.Xml.XmlTextwriter($sw)
$writer.Formatting = [System.XML.Formatting]::Indented
$xml.WriteContentTo($writer)


$sw.ToString() | Out-File -FilePath $metaFile -Encoding utf8

Get-ChildItem -Path ".\Source\Localization" -Recurse -Include "$currentFolder.xml" | 
    Rename-Item -NewName {$_.name -replace "$currentFolder.xml","$newFolder.xml" }

Rename-Item -Path ".\Source\Mods\$currentFolder" -NewName "$newFolder"
