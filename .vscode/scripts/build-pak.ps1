$metaFile = Get-ChildItem -Path . -Filter meta.lsx -Recurse -ErrorAction SilentlyContinue -Force | ForEach-Object { $_.FullName }
$modName = Select-Xml -Path $metaFile -XPath "//attribute[@id='Folder']/@value" | ForEach-Object { $_.Node.value }

$prm = "-g", "bg3", "-a", "create-package", "-s", "$pwd\Source", "-d", "$pwd\Build\$modName.pak"

& $args[0] $prm