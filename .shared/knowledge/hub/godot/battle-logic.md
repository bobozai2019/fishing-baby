# Logic Knowledge

## 2026-05-20: 遗物接入战斗后会激活旧的被动修正路径

**Symptom:** HUD 显示遗物时把 run mode 的 `owned_relics` 注入 `RelicSystem`，攻击牌会真正走 `get_damage_delta` / `get_cost_delta` 被动修正路径，导致意外的数值变化。

**Investigation:**
- `RelicSystem` 有两套触发路径：主动触发（信号驱动）和被动修正（查询时计算）。
- 注入 owned_relics 后，被动修正路径被激活，影响所有攻击牌的伤害和费用计算。

**Root cause:** 遗物 UI 接入时复用了 `RelicSystem` 的完整状态，包括被动修正逻辑。HUD 只需要读取遗物列表用于显示，但注入后触发了战斗逻辑。

**Fix:** 接入遗物 UI 时必须回归测试实际出牌路径——不只测 HUD 渲染，还要验证攻击牌的伤害和费用是否符合预期。

**Failed approaches:** 只测试 HUD 渲染正确 → 遗漏被动修正路径对战斗数值的影响。

**How to apply:** 任何 UI 系统接入战斗系统时，必须同时回归测试该系统影响的所有游戏逻辑路径，不能只验证 UI 渲染。

## 2026-05-16: Multi-target card hover toggle

**Symptom:** Multi-target cards originally selected one target per drag/drop and auto-finalized when the hit count was reached, which did not match the desired interaction: drag over an enemy to select it, leave without changing it, enter it again to deselect it, then release to play.

**Failure paths:**
- Reusing `select_target()` -> repeated targets are ignored, so there is no way to deselect a target.
- Finalizing when selected target count reaches `hits` -> the card resolves before mouse release, so the player cannot revise the target set.
- Treating multi-target like repeated single-target drops -> the card returns to hand between picks, which fights the intended continuous drag interaction.

**Anti-pattern:** Modeling multi-target selection as "append target and maybe auto-resolve" when the UI needs an editable selection set.

**Root cause:** The target system only represented target accumulation and automatic completion. It did not expose selection changes or defer resolution until the drag release.

**Fix:** Add `toggle_target()`, `get_selected_targets()`, `target_selection_changed`, and `finalize_selected_targets()` to the card resolution system. During drag, toggle only when entering a new enemy; on mouse release, finalize the current selected target set. Battle UI listens to `target_selection_changed` and maps the selected set to `EnemyView.set_selected()`.

**Early signal:** If an interaction needs deselect/reselect, but the system only has `select_target()`, the state model is too narrow.

**Reusable rule:** Multi-select UI should own an editable selection set and emit selection-change events; resolution should be an explicit confirmation step.
