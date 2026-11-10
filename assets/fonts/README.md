# Fonts (MVP placeholder)

`comic.ttf` (Comic Sans MS) and `deng.ttf` (等线) are copied from Windows so the
MVP runs immediately with child-friendly Latin type and full Chinese coverage.

They are **not redistributable**. Before publishing the game, replace them with
open-licensed fonts and update `assets/ui/kid_theme.tres`:

- Latin: Fredoka (SIL OFL) or Comic Neue (SIL OFL)
- Chinese: ZCOOL KuaiLe (SIL OFL) or Noto Sans SC (SIL OFL)

Put the new `.ttf` files in this folder, point the `ext_resource` entries in
`assets/ui/kid_theme.tres` at them, keep `fallbacks = [<Chinese font>]`, then
re-import the project in Godot.
