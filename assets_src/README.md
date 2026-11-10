# 源文件目录

这里放素材的**工程源文件**（PSD / AI / Procreate / 音频工程 / 未压缩原图）。

本目录带 `.gdignore`，Godot 不会导入这里的内容，因此可以放几百 MB 的 PSD 而不影响游戏启动。

建议结构：

```
assets_src/
  bgs/        背景源文件
  props/      道具与图标源文件
  ui/         UI 源文件
  audio/      录音/工程文件
  fonts/      字体源文件与授权说明
```

最终导出到 `assets/` 的 PNG/WAV/MP3 才是游戏读取的文件，具体规格见
[`docs/ASSET_GUIDE.md`](../docs/ASSET_GUIDE.md)。
