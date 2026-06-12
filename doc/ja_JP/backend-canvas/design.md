# Canvas Backend Design

## Responsibilities

- TUI backend と同じ backend-neutral `DrawList` を消費します。
- frontend の perspective-correct software Z-buffer を再利用します。
- visible luma を quantized RGB shade に変換します。
- 同じ shade の隣接 pixel を水平 Canvas fill run に結合します。

## Boundary

package は JS target 専用で browser Canvas の詳細を所有します。core、view、
frontend は DOM type に依存しません。element lookup、animation frame、demo selection
は `demo_canvas` が所有します。

## Limitations

opaque background と単一 foreground RGB color の luma scaling のみをサポートします。
material、texture、alpha blending、anti-aliasing、GPU acceleration はありません。
