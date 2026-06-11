# Documentation Standard

このリポジトリのドキュメントは、**現在のブランチに存在する実装**を説明します。
現在の基準は **v0.1.0** です。

## ドキュメント種類

1. **API Reference (`api.md`)**: 公開型、関数、引数、戻り値の意味。
2. **User Guide (`tutorial.md`)**: 実践的な流れと実行例。
3. **Design Documentation (`design.md`)**: アーキテクチャ、制約、拡張点、制限。

## 構成

```text
doc/
  en_US/
  zh_CN/
  ja_JP/
    core/
      api.md
      tutorial.md
      design.md
    renderer/
      api.md
      tutorial.md
      design.md
    demo/
      api.md
      tutorial.md
      design.md
```

## 保守ルール

- ドキュメントは実装済みコードと一致させます。
- scene graph、material、texture、physics、BVH、asset loader など未実装の
  engine 機能は記述しません。
- geometry core の説明に terminal、ANSI、TUI background の詳細を混ぜません。
- terminal y-scale、background pattern、character rasterization は `renderer`
  または `demo` に記述します。
- サブシステム境界をまたぐ挙動を変更した場合は、API、tutorial、design を一緒に更新します。
