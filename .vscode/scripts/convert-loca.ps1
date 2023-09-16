$divine_path = $args[0]
Get-ChildItem -Path .\*\Localization -Filter *.xml -Recurse -ErrorAction SilentlyContinue -Force | ForEach-Object -Process { 
    & $divine_path -g bg3 -a convert-loca -s "$($_.DirectoryName)\$($_.BaseName).xml" -d "$($_.DirectoryName)\$($_.BaseName).loca"
}