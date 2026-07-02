# CLAUDE.md

PCMgr（Powerful Task Manager、元は中国語アプリ）を日本語化するフォークです。このファイルは
Claude Code 用のプロジェクトメモです。

## ビルド

- C# 部分（`TaskMgr/PCMgr32.csproj` → `Debug\PCMgrApp32.dll`）は **`dotnet build`（Roslyn）** で
  ビルドする。`run.ps1` がビルド＋ThirdPart DLL コピー＋起動をまとめて行う。
- **Framework 版 MSBuild（v4.0.30319）は使えない**：同梱の csc が C# 5 相当で `using static` 等の
  新しい構文を解釈できずコンパイルエラーになる。ビルドは必ず `dotnet build`。
- ターゲットフレームワークは `Directory.Build.props` で v4.8 に上書き。生成物は x86。
- C++ 側（PCMgrKernel32 等）のバイナリは別途 `Debug\` に配置する必要がある（`run.ps1` 参照）。

## ローカライズのしくみ（重要）

言語は実行時に 2 系統でローカライズされる。

1. **`LanuageResource_{zh,en,ja}`（GetStr 系）** — `LanuageMgr.GetStr("Key")` で引く文字列。
   各言語は別クラスの中立リソースとして本体アセンブリに埋め込まれ、`LanuageMgr` が実行時に
   `ResourceManager(typeof(LanuageResource_ja))` で切り替える。既定言語は `ja-JP`
   （`LanuageMgr.InitLanuage`）。
2. **フォームのデザイナーリソース（`ApplyResources` 系）** — WinForms のサテライト方式。
   - 中立 `Form.resx` = **中国語**、`Form.en.resx` = 英語、`Form.ja.resx` = 日本語。
   - `InitLanuage` が `Thread.CurrentUICulture` を `ja-JP` に設定 → `ComponentResourceManager`
     がサテライト `ja\PCMgrApp32.resources.dll` を読む。

### ビルドのカスタム部分（ハマりどころ）

`dotnet build` の SDK は AL タスク非互換のため、標準のサテライト生成が無効化されている
（`TaskMgr/Directory.Build.targets`）。そのため独自の仕組みを持つ：

- `PrecompileResources.ps1` … **中立 resx のみ**を PowerShell 5.1（BinaryFormatter 対応）で
  `.resources` に事前コンパイルし本体に埋め込む（`*.{culture}.resx` は除外）。
- `BuildSatellites.ps1`（本フォークで追加）… `*.ja.resx` / `*.en.resx` を集めて Framework csc で
  カルチャ別サテライト `Debug\<culture>\PCMgrApp32.resources.dll` を生成する。
  `Directory.Build.targets` の `BuildLanguageSatellites`（`AfterTargets="Build"`）から呼ばれ、
  対象カルチャは `"ja,en"`。

**サテライト生成の要点（壊しやすい）:**
- サテライト内のリソースストリーム名は **カルチャ入り**（例 `PCMgr.WorkWindow.FormVPrivileges.ja.resources`）。
  ResourceManager は `<baseName>.<culture>.resources` を探すため、中立名にすると解決されない。
- サテライトのアセンブリ **バージョンは本体と一致**させる（不一致だとローダーが黙って無視）。
  `BuildSatellites.ps1` は本体 dll から読み取る（現状 1.3.2.6）。
- `Directory.Build.targets` の Exec に渡すパス引数は **末尾のバックスラッシュを除去**する
  （`path\"` が閉じ引用符をエスケープして次の引数を飲み込むため。`.TrimEnd('\')` 使用）。
- フォームのファイル名 = クラス名 が前提。例外は `FormVPrivileges.cs`（クラスは `FormVPrivilege`
  単数）で、中立・サテライトとも解決されないが `FormVPrivileges.cs` 側が `useJapanese` 三項で
  日本語を出すため実害なし。

### 検証方法

x86 のため 32bit ランタイムで確認する。`Debug\` を AppBase にして
`ResourceManager("PCMgr.<Form>", asm).GetString(key, CultureInfo("ja-JP"))` が日本語を返すことを見る
（GUI を起動しなくても確認可能）。

## 日本語化の進捗

### 完了
- `LanuageResource_ja`（GetStr 文字列）: 翻訳済み（CPU/PID 等の技術語は原語のまま）。
- ハードコード文字列: `FormVPrivileges.cs`（権限説明）、`FormSettings.cs`（言語ドロップダウン）、
  `FormAbout.cs`（日本語 About ページ）、`MainPageScMgr.cs` 等は `ja` 分岐対応済み。
- `FormMain.cs`: ウィンドウタイトル既定値のハードコード中国語 `"任务管理器"` を除去し、
  ローカライズ済み `Str_AppTitle` にフォールバックするよう修正。
- **フォームのサテライト日本語化**: 全対象フォーム（`.en.resx` を持つ 22 個）に `.ja.resx` を作成し、
  csproj 登録＋サテライト生成の仕組みを整備。`dotnet build` で `Debug\ja\` が生成され、実行時に
  日本語で解決されることを確認済み。英語（`Debug\en\`）も併せて機能するようになった。

### 未対応（今後の候補）
- **サテライト非対応フォーム**（`.en.resx` が無く Designer に中国語直書き）:
  `FormTcp` / `FormTest` / `FormWindowKillAsk` / `FormFind` / `FormKDbgPrint` / `FormHelp` /
  `FormSpeedBall` / `FormAlwaysOnTop` / `FormSL`。英語版でも未ローカライズ。日本語化するには
  Designer 直書きを resx 化（Localizable 化）するか、コードで対応する必要がある。
- ハードコード中国語（全言語で表示、`.cs` ロジック内）: `MainPagePerf.cs:294`（"资源信息页 "）、
  `MainNativeBridge.cs`（"窗口名称 ："）、`FormHelp.cs`（エラーメッセージ）、
  `FormSpyWindow.cs`（"正在加载……"）など。
- Designer のフォント `微软雅黑`（Microsoft YaHei）は日本語も描画できるが、`Yu Gothic UI` 等への
  変更は未実施。
