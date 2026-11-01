---
name: art-design-gimp-processing
description: GIMP/PSD图像处理技能，负责分层处理、合成、蒙版应用和色彩统一（GIMP 2.10 script-fu 无头执行）
---

# Art Design GIMP Processing (GIMP/PSD处理)

统一工作流的 **GIMP/PSD 处理子技能**：分层处理与最终合成。无头执行环境为 **GIMP 2.10.38 script-fu (TinyScheme)**——不要用 GIMP 3.0 GI API（本机没有 GIMP 3），也不要用 python-fu（PNG 加载会挂起）。

## 后端分工

| 需求 | 工具 |
|---|---|
| 分层 PSD + 合成 PNG | `gimp-layered-psd-cli/scripts/assemble_layers.sh` |
| 简单 RGBA 叠加 / 抠图 / 修复 / 换脸 / 姿态 | compositor CLI（`extract/inpaint/face-swap/composite/pipeline`） |
| 文字艺术字 | PIL（见 artistic-text-generation） |
| 蒙版/选择/色彩调整等 GIMP 专属操作 | 本技能 script-fu 模板 |

compositor 路径：`$COMPOSITOR_BIN`（默认 `~/.codebuddy/bin/compositor`，即 install.sh 编译后软链的位置；可用环境变量覆盖；缺失则由 install.sh 执行 `swift build` 并软链）

## script-fu 批处理模板（已验证）

```bash
GIMP=/Applications/GIMP.app/Contents/MacOS/gimp-console
CFG=/tmp/gimp-cfg DATA=/tmp/gimp-data   # mkdir -p，含 gradients/brushes/patterns 子目录
GIMP_CONFIG=$CFG GIMP_DATA=$DATA $GIMP -i -b "$SCRIPT" -b "(gimp-quit 0)" </dev/null
```

必须带兜底 `-b "(gimp-quit 0)"`，否则脚本出错时 console 停在 REPL 挂起。

### 常用过程（2.10 签名）

```scheme
;; 加载与图层
(car (gimp-file-load RUN-NONINTERACTIVE path path))
(car (gimp-layer-new-from-drawable drawable img))
(gimp-image-insert-layer img layer 0 -1)          ; 追加到顶部
(gimp-layer-set-offsets layer x y)
(gimp-layer-scale layer int_w int_h FALSE)        ; 参数必须是整数
(gimp-layer-set-opacity layer 80)                 ; 0-100
(gimp-layer-set-mode layer MULTIPLY-LAYER-MODE)   ; SCREEN/OVERLAY/SOFTLIGHT...
(gimp-layer-add-alpha layer)                      ; clear 前必须加 alpha

;; 选择与蒙版
(gimp-image-select-rectangle img CHANNEL-OP-REPLACE x y w h)
(gimp-selection-feather img 10)
(gimp-selection-invert img)
(gimp-drawable-edit-clear drawable)
(gimp-selection-none img)
(gimp-selection-save img)                         ; 存为 channel

;; 色彩统一
(gimp-brightness-contrast drawable 5 -3)
(gimp-hue-saturation drawable HUE-RANGE-ALL 0 -7 0)
(gimp-color-balance drawable HISTOGRAM-VALUE 0 0 10 -5)   ; cyan/mag/yellow
(gimp-curves-spline drawable HISTOGRAM-VALUE 10 #(0 0 0.5 0.55 1 1))
(gimp-drawable-posterize drawable 36)

;; 导出（先存 PSD 再 flatten！）
(file-psd-save RUN-NONINTERACTIVE img drawable "out.psd" "out.psd" 1 0)   ; 7 参数
(gimp-image-flatten img)
(file-png-save RUN-NONINTERACTIVE img drawable "out.png" "out.png" 0 9 1 1 1 0 0) ; 10 参数
```

## 图层合成流程（语义化）

1. 建画布 `(gimp-image-new W H RGB)`，DPI 用 `(gimp-image-set-resolution img 300 300)` 不需要则跳过
2. 按 bottom→top 顺序插入图层，记录图层命名表（background / main_subject / text_title / overlay）
3. 区域保护：复制受保护对象为独立图层 → `add-alpha` → 选择对象区 → invert → clear 外部
4. 色彩统一：以主体层为参考，`hue-saturation`/`color-balance` 轻调，避免全局色偏破坏材质色
5. 导出：PSD（分层，供后续编辑）→ flatten → PNG（交付）

## 混合模式选择

- normal 正常 / multiply 加深 / screen 提亮 / overlay 对比 / softlight 柔光 / color 只改色相

## 注意事项

1. `gimp-image-flatten` 会毁掉图层结构——PSD 导出永远在 flatten 之前
2. 清选区前必须 `gimp-layer-add-alpha`，否则被清区域填充不透明底色
3. 所有整数参数（scale 尺寸、opacity 用 0-100 整数）
4. 大画布（>2480x3508）先小尺寸迭代，最后一步才全尺寸运行
5. 处理前保留原始文件；中间产物放任务目录 `temp/`
