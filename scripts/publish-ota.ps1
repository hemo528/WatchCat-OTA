<#
.SYNOPSIS
  发布 WatchCat 新版本到 GitHub OTA 仓库。

.DESCRIPTION
  把构建好的 APK 复制到 apk/、计算 SHA-256、重写 version.json，然后提交并推送。
  在 WatchCat-OTA 仓库根目录执行（脚本放在 scripts/ 下即可自动定位仓库根目录）。

.EXAMPLE
  .\scripts\publish-ota.ps1 -ApkPath 'C:\path\app-debug.apk' -VersionCode 8 -VersionName '1.2.3' -Changelog "1.2.3 更新：修复若干问题"
#>
param(
    [Parameter(Mandatory = $true)][string]$ApkPath,
    [Parameter(Mandatory = $true)][int]$VersionCode,
    [Parameter(Mandatory = $true)][string]$VersionName,
    [string]$Changelog = "",
    [string]$RepoOwner = "hemo528",
    [string]$RepoName = "WatchCat-OTA",
    [string]$Branch = "main",
    [switch]$SkipPush
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $root '.git'))) {
    $root = (Get-Location).Path
}
Set-Location $root
if (-not (Test-Path (Join-Path $root '.git'))) {
    throw "请在 WatchCat-OTA 仓库根目录或 scripts/ 目录下运行本脚本"
}

if (-not (Test-Path $ApkPath)) { throw "APK 不存在：$ApkPath" }
$apk = Get-Item $ApkPath
if ($apk.Extension -ne '.apk') { throw "不是 APK 文件：$ApkPath" }

$apkDir = Join-Path $root 'apk'
New-Item -ItemType Directory -Force -Path $apkDir | Out-Null
$targetName = "watchcat-$VersionName.apk"
$target = Join-Path $apkDir $targetName
Copy-Item $apk.FullName $target -Force

$hash = (Get-FileHash $target -Algorithm SHA256).Hash.ToLowerInvariant()
$size = (Get-Item $target).Length
$apkUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch/apk/$targetName"

$manifest = [ordered]@{
    versionCode = $VersionCode
    versionName = $VersionName
    apkUrl      = $apkUrl
    changelog   = $Changelog
    sizeBytes   = $size
    sha256      = $hash
    publishedAt = (Get-Date -Format 'yyyy-MM-dd')
}
$json = $manifest | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText(
    (Join-Path $root 'version.json'),
    $json,
    (New-Object System.Text.UTF8Encoding($false))
)

git add -A
git commit -m "release: v$VersionName ($VersionCode)"
if (-not $SkipPush) {
    git push origin $Branch
}

Write-Host "已发布 v$VersionName：$apkUrl"
Write-Host "size=$size sha256=$hash"
