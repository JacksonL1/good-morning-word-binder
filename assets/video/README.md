# 插入视频（cutscene）

把做好的动画/实拍视频放到这个目录，然后在关卡 JSON 的 `cutscene` 步骤里写 `video` 路径即可，
**不需要改任何代码**。

## 格式

Godot 4.3 的 `VideoStreamPlayer` 原生只支持 **OGV / Theora**。MP4 请先转换：

```bash
ffmpeg -i brush_teeth.mp4 -c:v libtheora -q:v 6 -c:a libvorbis -q:a 4 brush_teeth.ogv
```

> 也可以用 WebM（需插件）或直接改用逐帧 PNG 序列做 `poses` 动画。

## 放进关卡

```json
{
  "id": "brush_video",
  "type": "cutscene",
  "room": "bathroom",
  "caption": "Up and down, round and round!",
  "vo": "res://assets/audio/vo/vo_brush_video.mp3",
  "video": "res://assets/video/brush_teeth.ogv",
  "duration": 4.0,
  "skip_after": 1.2
}
```

- `duration`：视频结束后额外等待的总时长（含淡入），到点自动进入下一步；
- `skip_after`：多少秒后出现“点击继续”，孩子随时可以点一下跳过；
- 视频文件缺失或格式不支持时，会自动回退到 `poses` / `character_action`，不会崩游戏；
- 建议 1280×720、H.264 转 Theora 时保持 30fps，单段 ≤ 8 秒。

## 目录约定

```
assets/video/brush_teeth.ogv     刷牙示范
assets/video/wear_shirt.ogv      穿衣示范
assets/video/wear_shoes.ogv      穿鞋示范
```

做好的视频直接丢进来，再在 `data/levels/*.json` 对应 cutscene 步骤里引用即可。
