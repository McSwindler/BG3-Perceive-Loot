
function Convert-From-Integer {
    param (
        [long]$versionInt
    )

    $major = $versionInt -shr 55
    $minor = ($versionInt -shr 47) -band 0xFF
    $revision = ($versionInt -shr 31) -band 0xFFFF
    $build = $versionInt -band [UInt64]0x7FFFFFFF

    $major, $minor, $revision, $build
}

function Convert-To-Integer {
    param (
        [int[]]$versionArr
    )

    ([long]$versionArr[0] -shl 55) + ([long]$versionArr[1] -shl 47) + ([long]$versionArr[2] -shl 31) + [long]$versionArr[3]

}

$metaFile = Get-ChildItem -Path . -Filter meta.lsx -Recurse -ErrorAction SilentlyContinue -Force | ForEach-Object { $_.FullName }
$xml = [xml](Get-Content $metaFile)
$versionNode1 = $xml.SelectSingleNode("//node[@id='ModuleInfo']/attribute[@id='Version']")
$versionNode2 = $xml.SelectSingleNode("//node[@id='PublishVersion']/attribute[@id='Version']")
$currentVersion = $versionNode1.Value
$newVersion = [long]36028797018963968

if ($currentVersion -match "^[\d\.]+$") {

    Write-Output "Found Version $currentVersion"

    $versionArr = Convert-From-Integer $currentVersion

    Write-Output "Parsed Version $($versionArr[0]).$($versionArr[1]).$($versionArr[2]).$($versionArr[3])"

    switch ($args[0]) {
        "major" {
            $versionArr[0]++
            $versionArr[1] = 0
            $versionArr[2] = 0
            $versionArr[3] = 0
        }
        "minor" {
            $versionArr[1]++
            $versionArr[2] = 0
            $versionArr[3] = 0
        }
        "revision" {
            $versionArr[2]++
            $versionArr[3] = 0
        }
        "build" {
            $versionArr[3]++
        }
        default {
            Write-Error "Unsupported version category, please specify one of [major, minor, revision, build]."
            exit 1
        }
    }

    Write-Output "Updated Version $($versionArr[0]).$($versionArr[1]).$($versionArr[2]).$($versionArr[3])"

    $newVersion = Convert-To-Integer $versionArr
} else {
    Write-Warning "Could not find existing version - defaulting to 1.0.0.0"
}

Write-Output "New Version $newVersion"

$versionNode1.SetAttribute("value", $newVersion)
$versionNode2.SetAttribute("value", $newVersion)


$sw = New-Object System.IO.StringWriter
$writer = New-Object System.Xml.XmlTextwriter($sw)
$writer.Formatting = [System.XML.Formatting]::Indented
$xml.WriteContentTo($writer)


$sw.ToString() | Out-File -FilePath $metaFile -Encoding utf8
