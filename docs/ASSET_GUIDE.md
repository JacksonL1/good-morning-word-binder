# 素材替换指南（美术 / 音频 / 字体 / 文案）

这版 MVP 的所有视觉和声音都在 `assets/` 下，**代码里没有写死任何图片或单词**。替换素材有两种做法：

1. **最省事**：保持文件名和尺寸不变，直接覆盖同名文件；
2. **更自由**：换成任意文件名/尺寸，然后改 `data/levels/morning_routine.json` 或对应 `.tscn` 的路径与参数。

替换后需要让 Godot 重新导入（见第 4 节）。游戏逻辑、拖拽、计时器都不需要改。

---

## 1. 30 秒速查

```text
背景  assets/bgs/*.png                 1280×720  RGBA
道具  assets/props/prop_*.png          512×512   透明背景
图标  assets/props/icon_*.png          256×256   透明背景
小人  assets/char/char_*.png           512×512   透明背景，脚底对齐
卡片  assets/ui/card.png               256×256   九宫格
面板  assets/ui/panel.png              512×256   九宫格
小手  assets/ui/ghost_hand.png         180×220   透明背景
星星  assets/ui/star.png / sparkle.png 128×128
声音  assets/audio/vo/*.mp3            单词/分幕/清单配音
音效  assets/audio/sfx/*.wav           pop/success/brush/splash...
环境  assets/audio/ambience/*.wav      卧室/浴室循环
音乐  assets/audio/bgm/morning_loop.wav 19.2s 循环
字体  assets/fonts/comic.ttf + deng.ttf
```

替换步骤：

1. 把新图导出为 **PNG（RGBA，透明背景）**，按上表尺寸覆盖同名文件；
2. 双击 `reimport_assets.bat`（或在 Godot 编辑器里切一下窗口让它自动导入）；
3. 运行 `run_game.bat` 看效果；
4. 位置/大小不合适 → 调 `data/levels/morning_routine.json` 里的 `prop_pos` / `prop_scale`。

> ⚠️ 不要运行 `tools/gen_art.py`，它会重新生成占位图并覆盖你的素材。详见第 9 节。

---

## 2. 资源清单

### 2.1 背景 `assets/bgs/`

| 文件 | 尺寸 | 用于 |
| --- | --- | --- |
| `bg_bedroom.png` | 1280×720 | 起床 / 穿衣 / 穿鞋 |
| `bg_bathroom.png` | 1280×720 | 喝水 / 刷牙 / 洗脸 |

- 显示模式是 `TextureRect.stretch_mode = KEEP_ASPECT_COVERED`（铺满并裁切），所以 **16:9** 最稳，2560×1440 也可以。
- 背景里不要画道具本身，也不要画底部单词本区域（会被面板遮住）。
- 中央 640×360 附近尽量留干净区域给道具。

### 2.2 道具 `assets/props/prop_*.png`

| 文件 | 现有尺寸 | 关卡 |
| --- | --- | --- |
| `prop_bed.png` | 512×512 | 起床 |
| `prop_cup.png` | 512×512 | 喝水 |
| `prop_brush.png` | 512×512 | 刷牙 |
| `prop_towel.png` | 512×512 | 洗脸 |
| `prop_shirt.png` | 512×512 | 穿衣 |
| `prop_shoes.png` | 512×512 | 穿鞋 |

- 必须 **透明背景**，物体居中，四周可以留透明边。
- 引擎会自动把它等比缩放到最多 **560×440**，再乘以 `data/levels/morning_routine.json` 的 `prop_scale`。
- 道具底部可以自带一点柔和阴影（像现在的图一样），会更有落地感。
- 尺寸不是 512 也能用，引擎按真实像素计算；只是非正方形时注意构图居中。

### 2.3 卡片图标 `assets/props/icon_*.png`

`icon_wake / icon_drink / icon_brush / icon_wash / icon_shirt / icon_shoes`

- 256×256 透明 PNG，显示在单词卡片上（约 74×74）。
- 六张图的 **视觉留白要一致**，否则有的图标看起来大、有的小。
- 不要在图标里写单词，单词由 Label 渲染（换语言/改文案更方便）。

### 2.4 UI 图片 `assets/ui/`

| 文件 | 尺寸 | 用途 | 替换注意 |
| --- | --- | --- | --- |
| `card.png` | 256×256 | 单词卡片底 | 九宫格，`patch_margin_*=44`；圆角/描边要落在 44px 内 |
| `panel.png` | 512×256 | 底部单词本底板 | 九宫格，左右 60、上下 52 |
| `ghost_hand.png` | 180×220 | 幽灵小手 | 透明底，食指朝下；实际显示 144×176 |
| `star.png` | 128×128 | 进度星、粒子、完成页、清单勾选 | 透明底 |
| `sparkle.png` | 128×128 | 预留装饰 | 透明底 |
| `sound_on.png` / `sound_off.png` | 64×64 | 静音按钮 | 深色线条，白色背景按钮上可见 |
| `glow.png` | 256×256 | 预留光晕 | 透明底 |
| `bubble.png` | 64×64 | 洗脸气泡粒子 | 透明底 |

九宫格说明：`card.png` 和 `panel.png` 会被拉伸到不同大小。四角区域（margin 内）保持原样，中间区域拉伸。若新图的圆角半径明显不同，需要同时改：

- `scenes/WordCard.tscn` → `CardBg.patch_margin_*`
- `scenes/BinderUI.tscn` → `Board.patch_margin_*`

### 2.5 小人 `assets/char/`

11 个姿态，全部 512×512 透明 PNG：

| 文件 | 动作 |
| --- | --- |
| `char_stand.png` | 站立待机 |
| `char_lying.png` | 躺在床上（横躺，头在左） |
| `char_sit.png` | 坐起 |
| `char_drink.png` | 举杯喝水 |
| `char_brush_a.png` / `char_brush_b.png` | 刷牙左/右两帧 |
| `char_wash.png` | 毛巾洗脸 |
| `char_shirt.png` | 穿好黄色上衣 |
| `char_shoes.png` | 弯腰穿鞋 |
| `char_stand_shoes.png` | 穿好鞋站立 |
| `char_happy.png` | 欢呼（清单/完成） |

替换要求：

- 保持 512×512 画布；
- 站立类姿态的**脚底对齐 y≈468**、身体水平居中，`Character` 会用 `offset = -212` 让脚底落在节点原点；
- 躺姿 `char_lying.png` 例外：整张图水平构图，节点以图片中心定位；
- 小人默认显示在舞台右侧 `(930, 505)`，缩放 `0.62`，可在 `data/levels/morning_routine.json` 的 `char.pos/scale` 调整；
- 11 张图必须同一画风、同一比例；否则切姿态时会“跳”。

### 2.6 门前清单 `data/checklist.json`

5 个徽章的标题、图标、语音都在这里：

```json
{
  "title": "Morning Checklist",
  "intro_vo": "res://assets/audio/vo/vo_act6_checklist.mp3",
  "finish_vo": "res://assets/audio/vo/vo_act6_finish.mp3",
  "timeout_vo": "res://assets/audio/vo/vo_timeout_act6.mp3",
  "badges": [
    {"label": "Water", "cn": "喝水", "icon": "res://assets/props/icon_drink.png", "vo": "res://assets/audio/vo/vo_act6_badge_0.mp3"}
  ]
}
```

添加/减少徽章只需要改这个数组（界面会自动排布）；图标建议 256×256，语音 0.5–1.5 秒。

### 2.7 分幕语音与环境音

- 每关的 `data/levels/morning_routine.json` 里有 `audio` 块：`intro` / `action` / `done` / `timeout`，以及刷牙 `left/right/all`、穿鞋 `left/right`、喝水 `sip`、洗脸 `loop`、穿衣 `wrong`；
- 文件名已按 `vo_act1_*.mp3`、`vo_act1_5_*.mp3` …… `vo_timeout_act6.mp3` 生成，直接在 `assets/audio/vo/` 覆盖即可；
- 环境音：`assets/audio/ambience/bedroom.wav`、`bathroom.wav`，由 `data/levels/morning_routine.json` 的 `ambience` 指定；
- 动作音效：`brush.wav`（刷牙）、`splash.wav`（洗脸）、`snap.wav`（穿鞋）、`sparkle.wav`（穿衣/打勾）；
- 全部由 `tools/gen_audio.py` 合成，替换后不要重复运行该脚本。

### 2.8 字体

- `assets/fonts/comic.ttf`：英文/数字（Comic Sans MS，Windows 自带）；
- `assets/fonts/deng.ttf`：中文回退（等线，Windows 自带）；
- `assets/ui/kid_theme.tres` 里配置了 `FontVariation(base_font=comic, fallbacks=[deng])`。

替换字体：

1. 把新字体放进 `assets/fonts/`；
2. 改 `assets/ui/kid_theme.tres` 的 `ext_resource path`；
3. 如果中文/英文分两个字体，保持 `fallbacks = [中文字体]`；
4. 重新导入。

发布前请换成 OFL 字体（Fredoka / Comic Neue + 站酷快乐体 / Noto Sans SC），原因见 `assets/fonts/README.md`。

---

## 3. 两种替换方式

### 方式 A：同名覆盖（推荐）

```text
assets/props/prop_bed.png   ← 用你的新床铺图覆盖
assets/bgs/bg_bedroom.png   ← 用你的新卧室图覆盖
```

优点：不用改任何代码/JSON。  
要求：路径和文件名完全一致（Windows 不区分大小写，导出后区分，建议全小写）。

### 方式 B：改路径

把新文件放到 `assets/` 下任意位置，然后改引用：

- 背景 / 道具 / 卡片：改 `data/levels/morning_routine.json` 对应字段的 `res://` 路径；
- UI 图片：改 `.tscn` 里的 `texture = ExtResource(...)`，或改 `ext_resource path`；
- 音频：改 `data/levels/morning_routine.json` 的 `vo` 或 `core/audio.gd` 的 `SFX_PATHS` / `BGM_PATH`。

适合一组全新素材（例如整套换成海洋主题），可以先把新图放进来、逐步替换 JSON，确认无误再删旧图。

---

## 4. 替换后必须重新导入

Godot 使用 `.godot/imported/` 缓存。覆盖 PNG/MP3 后，如果直接运行，可能仍显示旧图。

三种刷新方式，任选其一：

1. **Godot 编辑器**：切回编辑器窗口，FileSystem 会自动重新导入（右下角有进度）；
2. **命令行**（推荐给脚本启动）：

   ```powershell
   .\reimport_assets.bat
   ```

3. **删缓存重来**（最彻底，首次会慢几秒）：

   ```powershell
   Remove-Item .godot\imported -Recurse -Force
   .\run_game.bat
   ```

> `run_game.bat` 为了启动快，只在 `.godot\imported` 不存在时才自动 import。替换素材后请用 `reimport_assets.bat`。

---

## 5. 构图/大小不合适怎么调

改 `data/levels/morning_routine.json` 的关卡字段，不用改代码：

```json
"prop_pos": [640, 340],
"prop_scale": 1.0,
```

- `prop_pos`：道具中心在设计分辨率 1280×720 中的坐标；往左移减小 x，往下移增大 y。
- `prop_scale`：在“最大 560×440 等比适配”基础上的额外倍率；`1.1` 更大，`0.9` 更小。
- 道具热区会自动跟着尺寸走（+30%），并被限制在顶部 UI 和底部单词本之间。

卡片/图标尺寸在场景里：

- `scenes/WordCard.tscn`：卡片 190×146、`Icon` 74×74、`Word` 字体 30；
- `core/main.gd` 的 `_build_start_icons()`：开始页图标 64×64；
- 进度星在 `core/main.gd` 的 `_build_progress()`：34×34。

---

## 6. 新增一个单词 / 一个关卡

### 6.1 只加一张卡片（复用现有道具）

1. 做一张 `icon_jump.png`（256×256，透明）；
2. 把图标放进 `assets/props/`；
3. 在目标关卡的 `cards` 数组里加一项：

```json
{
  "id": "card_jump",
  "text": "Jump",
  "img": "res://assets/props/icon_jump.png",
  "vo": "res://assets/audio/vo/card_jump.mp3"
}
```

4. 生成/放入 `card_jump.mp3`：
   - 手动录音：把 mp3 放到 `assets/audio/vo/card_jump.mp3`；
   - 或运行 `python tools/vo_pipeline.py`（它会读取 data/levels/morning_routine.json，只为缺失的卡片生成）；
5. 运行 `reimport_assets.bat`，再跑一次游戏。

> `text` 决定卡片上的字和 TTS 读音；`id` 用来做匹配，必须唯一且和 `req_card` 对应。

### 6.2 加一整关

复制 `data/levels/morning_routine.json` 里任意一个关卡对象，改这些字段：

```json
{
  "id": "level_jump",
  "title": "跳一跳",
  "title_en": "Jump",
  "hint": "把 Jump 卡片拖到小蹦床上",
  "bg_img": "res://assets/bgs/bg_playroom.png",
  "prop_img": "res://assets/props/prop_trampoline.png",
  "prop_pos": [640, 360],
  "prop_scale": 1.0,
  "req_card": "card_jump",
  "cards": [ ... 至少包含 card_jump ... ]
}
```

然后把 `level_jump` 插到数组中合适的位置（数组顺序就是关卡顺序），保存即可。**不需要改任何 GDScript。**

新增后建议跑一次校验：

```powershell
& ".\.tools\godot\Godot_v4.3-stable_win64_console.exe" --headless --path . --script res://tools/validate_project.gd
```

它会检查 6 个关卡的所有图片/音频是否存在、音频是否为空、字体是否能显示中文。

---

## 7. 替换音频

### 7.1 单词配音

路径写在 `data/levels/morning_routine.json` 每个 card 的 `vo` 字段。两种做法：

- 覆盖同名文件（`assets/audio/vo/card_brush.mp3`）；
- 或换文件名，同时改 `vo` 路径。

录音建议：

- 单声道/立体声均可，MP3/WAV/OGG 都支持；
- 单词 0.4–1.0 秒，句尾不要留长空白；
- 峰值控制在 -3 dBFS 以下，整体响度约 -18 ~ -14 LUFS，避免和 BGM 打架；
- 文件名用英文小写 + 下划线。

### 7.2 流程配音（欢迎/成功/失败/完成/提示）

路径在 `core/main.gd` 顶部：

```gdscript
const VO_SUCCESS := "res://assets/audio/vo/success.mp3"
const VO_TRY_AGAIN := ...
const VO_FINISH := ...
const VO_WELCOME := ...
const VO_HINT := ...
```

- 成功配音要短（**< 1.4 秒**），因为 1.5 秒后自动进下一关；
- 完成页 `finish.mp3` 可以长一些；
- 提示音 `hint.mp3` 只在 10 秒空闲出现小手时播一次。

### 7.3 音效 & BGM

在 `core/audio.gd`：

```gdscript
const BGM_PATH := "res://assets/audio/bgm/morning_loop.wav"
const SFX_PATHS := {
    "pop": "res://assets/audio/sfx/pop.wav",
    "tap": ...,
    "success": ...,
    "error": ...,
    "clear": ...,
    "finish": ...,
}
```

- 音效名（`pop`/`tap`/`success`/`error`）被代码调用，换文件可以，**不要改 key**，除非同步改调用处；
- BGM 用 WAV 时运行时会自动设置 `LOOP_FORWARD`；如果用 OGG/MP3，需要在导入面板里勾选 Loop，否则只播一遍；
- 替换后重新导入。

---

## 8. 替换 UI 文案

| 文案 | 位置 |
| --- | --- |
| 关卡名 / 提示 | `data/levels/morning_routine.json` 的 `title` / `title_en` / `hint` |
| 开始页标题/副标题/按钮 | `scenes/Main.tscn`（`StartTitle`、`StartSub`、`PlayButton`、`StartNote`） |
| 完成页标题/按钮 | `scenes/Main.tscn`（`FinaleTitle`、`FinaleSub`、`ReplayButton`） |
| 成功 / 失败临时提示 | `core/main.gd`（`太棒了！`、`再试一次吧！`） |
| 幽灵手气泡 | `core/ghost_hand.gd`（`show_hint` / `show_at` 的默认文案） |
| 顶部固定标签 | `Main.tscn` + `core/main.gd` 的 `title_label` / `hint_label` |

改中文文案不需要改字体（主题已配置中文回退）。

---

## 9. 注意：生成脚本会覆盖你的素材

| 脚本 | 影响 | 建议 |
| --- | --- | --- |
| `tools/gen_art.py` | **覆盖 `assets/bgs` 全部背景、`assets/props` 全部道具/图标、`assets/ui` 全部图片** | 换成自己素材后不要再运行；或先备份 `assets/` |
| `tools/gen_character.py` | **覆盖 `assets/char` 全部 11 个小人姿态** | 同上；自定义小人后不要运行 |
| `tools/gen_audio.py` | 覆盖 `assets/audio/sfx/*.wav`、`bgm/morning_loop.wav`、`ambience/*.wav` | 同上 |
| `tools/vo_pipeline.py` | 默认只补缺失的 VO；`--force` 会覆盖全部（含 36 条分幕台词） | 自定义录音后不要加 `--force` |

建议：

- 用 Git 管理项目，替换前先提交一次；
- 自定义素材的源文件（PSD / AI / Procreate / 音频工程）放到 `assets_src/`，该目录带 `.gdignore`，Godot 不会导入；
- 或者直接删除/重命名对应的生成脚本，避免误运行。

---

## 10. AI 生图 / 抠图工作流

白皮书里的提示词可以直接用：

```text
flat 2D game asset, cartoon style for kids, solid white background,
thick clean outlines, soft pastel palette, centered object, no text
```

建议流程：

1. 生成 **正方形** 道具图（1024×1024 或 512×512），纯白背景；
2. 用 remove.bg / Photoshop / `rembg` 抠成透明 PNG；
3. 缩放到 512×512，检查边缘没有白边；
4. 覆盖 `assets/props/prop_xxx.png`；
5. 背景单独生成 16:9（1280×720 或更大），不要带道具；
6. 卡片图标单独生成，六个图标的物体占比一致。

保持统一感的几个小技巧：

- 固定一套主色（当前：珊瑚 `#ff8a80`、薄荷 `#7fd1ae`、天蓝 `#6ec6ff`、奶黄 `#ffd166`、墨蓝描边 `#4a4a6a`）；
- 描边粗细一致（当前约 5–6px @512）；
- 视角统一（正面或轻微 3/4），光源统一从左上；
- 不要在图片里写字，文字交给 Label；
- 道具图底部留一点柔和阴影，避免“浮在空中”。

---

## 11. 验收清单

替换后按顺序检查：

- [ ] 图片是 PNG RGBA，背景透明处没有被填成白色；
- [ ] 文件名/路径与 `data/levels/morning_routine.json`、`.tscn` 一致；
- [ ] 已运行 `reimport_assets.bat`（或编辑器已导入）；
- [ ] 道具完整出现在画面中央，没有被底部单词本遮住；
- [ ] 卡片图标大小一致、文字没有被裁切；
- [ ] 拖拽正确卡片能过关，拖错有红/摇晃反馈；
- [ ] 10 秒空闲后小手出现在正确卡片上方；
- [ ] 配音能播放、没有被 1.5 秒过场截断；
- [ ] 运行 `tools/validate_project.gd` 零错误。

自动巡演/截图回归：

```powershell
& ".\.tools\godot\Godot_v4.3-stable_win64_console.exe" --path . --audio-driver Dummy -- --autotest --shots="C:\temp\shots"
```

截图会输出 6 个关卡、拖拽残影、成功反馈、完成页，方便对比替换前后。

---

## 12. 常见问题

**换了图，游戏里还是旧图？**  
没重新导入。跑 `reimport_assets.bat`，或删 `.godot/imported`。

**道具太大/太小？**  
改 `data/levels/morning_routine.json` 的 `prop_scale`；位置改 `prop_pos`。热区会跟着变。

**道具下面被单词本挡住？**  
把 `prop_pos` 的 y 调小（向上移），或把 `prop_scale` 调小。

**卡片圆角被拉花？**  
`card.png` 的圆角必须落在 44px 的九宫格 margin 内；否则改 `WordCard.tscn` 的 `patch_margin_*`。

**图标看起来忽大忽小？**  
六张图标导出时物体占比不一致。统一留白（例如物体占画布 70%）。

**文字是豆腐块？**  
字体缺少中文字形。检查 `kid_theme.tres` 的 `fallbacks` 是否包含中文字体。

**MP3 不能循环？**  
BGM 只有在是 `AudioStreamWAV` 时自动设循环；OGG/MP3 请在导入面板勾 Loop，或换成 WAV。

**改完素材后 `run_game.bat` 仍很快启动？**  
它只在 `.godot/imported` 不存在时导入，这是故意的。请用 `reimport_assets.bat`。

**想回退到最初的占位素材？**  
重新运行 `python tools/gen_art.py` 和 `python tools/gen_audio.py`（会覆盖当前素材，先提交 Git）。
