# ========================================================
# 字幕打包工具 (Subtitle Packer)
# ========================================================
# 功能：将 ASS 字幕文件内嵌到 MKV 视频文件中
# 工具：依赖 MKVToolNix 的 mkvmerge 命令
# ========================================================

param(
    [string]$InputDir = "",
    [string]$OutputDir = ""
)

# 根据后缀返回字幕轨道显示名称
function Get-LanguageName {
    param([string]$suffix)
    $s = $suffix.ToLower()
    if ($s -match "^(tc|cht)$")        { return "Traditional Chinese" }
    if ($s -match "^(sc|chs|cn|zh)$")  { return "Simplified Chinese" }
    if ($s -match "^(en)$")            { return "English" }
    if ($s -match "^(jp|ja)$")         { return "Japanese" }
    if ($s -match "^(ko|kr)$")         { return "Korean" }
    return $suffix.ToUpper()
}

# 根据后缀返回 ISO 639-2 语言代码
function Get-LanguageCode {
    param([string]$suffix)
    $s = $suffix.ToLower()
    if ($s -match "^(sc|chs|cn|zh|tc|cht)$") { return "zho" }
    if ($s -match "^(en)$")                   { return "eng" }
    if ($s -match "^(jp|ja)$")                { return "jpn" }
    if ($s -match "^(ko|kr)$")                { return "kor" }
    return "und"
}

# 默认使用脚本所在目录作为输入目录
if ($InputDir -eq "") { $InputDir = $PSScriptRoot }
# 默认输出到输入目录下的 out 子目录
if ($OutputDir -eq "") { $OutputDir = Join-Path $InputDir "out" }

# 检查 mkvmerge 是否已安装
$mkvmergeCmd = Get-Command mkvmerge -ErrorAction SilentlyContinue
if (-not $mkvmergeCmd) {
    Write-Host "错误：未找到 mkvmerge，请先安装 MKVToolNix。" -ForegroundColor Red
    exit 1
}

# 创建输出目录（如果不存在）
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  字幕打包工具 (Subtitle Packer)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "输入目录：$InputDir" -ForegroundColor Gray
Write-Host "输出目录：$OutputDir" -ForegroundColor Gray
Write-Host ""

# 递归查找所有视频文件，排除输出目录
$videos = Get-ChildItem -Path $InputDir -Include @("*.mkv","*.mp4","*.avi","*.mov","*.flv","*.wmv") -Recurse |
    Where-Object { $_.FullName -notlike "$OutputDir*" }

if ($videos.Count -eq 0) {
    Write-Host "未找到任何视频文件！" -ForegroundColor Yellow
    exit 0
}

Write-Host "共找到 $($videos.Count) 个视频文件" -ForegroundColor Gray
Write-Host ""

$processed = 0
$skipped   = 0
$errors    = 0

# 去掉末尾反斜杠，确保路径截取偏移量正确（兼容 PS5）
$normalizedInput = $InputDir.TrimEnd("\")

foreach ($video in $videos) {
    $baseName = $video.BaseName
    $videoDir = $video.DirectoryName

    Write-Host "处理：$($video.Name)" -ForegroundColor Cyan

    # 同时检测 video.ass（基础字幕）和 video.*.ass（带语言后缀的字幕）
    $subBase  = Get-ChildItem -Path $videoDir -Filter "$baseName.ass"   -ErrorAction SilentlyContinue
    $subLangs = Get-ChildItem -Path $videoDir -Filter "$baseName.*.ass" -ErrorAction SilentlyContinue
    $subs = @($subBase) + @($subLangs) | Where-Object { $_ -ne $null }

    if ($subs.Count -eq 0) {
        Write-Host "  跳过：未找到匹配字幕" -ForegroundColor Yellow
        $skipped++
        Write-Host ""
        continue
    }

    # 计算相对路径，拼接输出路径（使用字符串截取，兼容 PS5）
    $relativePath = $video.FullName.Substring($normalizedInput.Length).TrimStart("\")
    $outPath = Join-Path $OutputDir $relativePath
    $outDir  = Split-Path $outPath -Parent

    # 创建输出子目录（如果不存在）
    if (-not (Test-Path $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }

    # 构建 mkvmerge 参数（使用 $mkvArgs 避免与 PS 内置变量 $args 冲突）
    $mkvArgs = @("--output", $outPath, $video.FullName)

    foreach ($sub in $subs) {
        # 提取语言后缀（基础字幕后缀为空）
        $rawSuffix = $sub.BaseName.Substring($baseName.Length).Trim(".")
        if ($rawSuffix -eq "") {
            $trackName = "Default"
            $langCode  = "und"
        } else {
            $trackName = Get-LanguageName $rawSuffix
            $langCode  = Get-LanguageCode $rawSuffix
        }
        $mkvArgs += @("--language", "0:$langCode", "--track-name", "0:$trackName", $sub.FullName)
        Write-Host "  + 字幕：$($sub.Name) [$trackName / $langCode]" -ForegroundColor Gray
    }

    & mkvmerge @mkvArgs --quiet 2>$null

    # mkvmerge 返回码：0 = 成功，1 = 有警告但成功，2 = 失败
    if ($LASTEXITCODE -le 1) {
        if ($LASTEXITCODE -eq 1) {
            Write-Host "  完成（有警告）：已保存到 out/" -ForegroundColor Yellow
        } else {
            Write-Host "  完成：已保存到 out/" -ForegroundColor Green
        }
        $processed++
    } else {
        Write-Host "  错误：打包失败（返回码：$LASTEXITCODE）" -ForegroundColor Red
        $errors++
    }

    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "完成！成功：$processed，跳过：$skipped，失败：$errors" -ForegroundColor White
Write-Host ""

if ($processed -gt 0) {
    Write-Host "输出目录：$OutputDir" -ForegroundColor Green
}
