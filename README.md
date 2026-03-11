# 字幕打包工具 (Subtitle Packer)

自动将 ASS 字幕文件内嵌到 MKV 视频文件中。

## 功能特性

- 通用性强：可处理任意目录下的视频文件
- 自动检测：自动查找匹配的字幕文件
- 智能识别：识别多种字幕命名格式和语言代码
- 批量处理：一次处理目录下所有视频
- 保持结构：输出文件保持原有目录结构
- 多格式支持：支持 mkv、mp4、avi、mov、flv、wmv

## 文件说明

| 文件 | 说明 |
|------|------|
| `pack.ps1` | 主程序脚本 |
| `run.bat` | 双击运行批处理文件 |

## 使用方法

### 方式一：双击运行
直接双击 `run.bat` 即可

### 方式二：命令行运行
```powershell
# 默认处理脚本所在目录
.\pack.ps1

# 指定其他目录
.\pack.ps1 -InputDir "D:\Videos\Anime"
.\pack.ps1 -InputDir "D:\Videos" -OutputDir "D:\Videos\output"
```

## 前置要求

1. 安装 **MKVToolNix**
   - 下载地址: https://mkvtoolnix.download/
   - 安装后确保 `mkvmerge` 已添加到系统 PATH

2. Windows PowerShell 5.0 或更高版本

## 字幕命名规则

程序支持两种字幕命名方式：

| 类型 | 命名格式 | 示例 |
|------|----------|------|
| 基础字幕 | `视频名.ass` | `video.ass` |
| 语言字幕 | `视频名.后缀.ass` | `video.sc.ass` |

### 支持的语言代码

| 后缀 | 轨道名称 | ISO 639-2 代码 |
|------|----------|-----------------|
| `sc`, `chs`, `cn`, `zh` | Simplified Chinese | zho |
| `tc`, `cht` | Traditional Chinese | zho |
| `en` | English | eng |
| `jp`, `ja` | Japanese | jpn |
| `ko`, `kr` | Korean | kor |
| 其他 | 大写后缀名 | und |

### 字幕识别示例

```
video.ass           → Default (und)
video.sc.ass        → Simplified Chinese (zho)
video.tc.ass        → Traditional Chinese (zho)
video.en.ass        → English (eng)
video.jp.ass        → Japanese (jpn)
```

## 输出说明

- 输出目录默认为输入目录下的 `out` 子目录
- 保持原有目录结构
- 不会覆盖原视频文件

## 工作原理

1. 递归扫描目录中的所有视频文件
2. 查找与视频同名的字幕文件（支持基础字幕和语言后缀字幕）
3. 使用 mkvmerge 将字幕内嵌到视频中
4. 输出到 `out` 目录

## 注意事项

- 输出文件保存在 `out` 目录，不会覆盖原文件
- 需要安装 MKVToolNix
- 没有找到字幕的视频会被跳过

### 目前只测试了ass字幕和mkv视频文件。

