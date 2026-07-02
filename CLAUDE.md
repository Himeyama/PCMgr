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
  x86 側の同梱バイナリ（2019年ビルド）は今のところ本フォークでは再ビルドしていない
  （後述の通り C++ ビルドツールチェーン自体は利用可能になったが、x86 再ビルドは未着手）。
- **Visual Studio Build Tools 2022（C++ によるデスクトップ開発ワークロード）がインストール済み**
  （`cl.exe`/`rc.exe`/MSBuild for C++、MSVC v143 = 14.44）。以前は「この環境には C++ ビルド
  ツールチェーンが無い」という制約があったが解消済み。ただし WDK（Windows Driver Kit）は
  引き続き無く、カーネルドライバ（`PCMgrKernel32.sys`）はビルド不可（後述）。
- **64bit 版**: `run64.ps1` でネイティブ側（x64）＋ `TaskMgr/PCMgr64.csproj` を一括ビルド・起動
  できる。詳細は「64bit 版のビルドと起動」節を参照。

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

## 64bit 版のビルドと起動

`run64.ps1` が一式（ネイティブ x64 ＋ C# x64 ＋ ThirdPart DLL コピー＋起動）を行う。
`TaskMgr/PCMgr64.csproj`・`NativeMethods.cs` の `#if _X64_`・`PCMgrLoader` の `#ifdef _AMD64_`
など 64bit 対応の下地は元々存在したが、実際にビルドが通った実績が無く、以下の欠落・不具合が
あった（`run64.ps1` 実行前に一度だけ必要な修正で、いずれも対応済み）。

- **`PCMgr64.csproj` が日本語化前の古いファイル一覧のままだった**: `LanuageResource_ja` を含む
  約40ファイルが csproj に未登録で、コンパイル自体が通らなかった（`LanuageMgr.cs` が参照するため）。
  `PCMgr32.csproj` の `Compile`/`EmbeddedResource`/`None` ItemGroup と同期して解決。
- **ネイティブ側 `PlatformToolset` が `v142`/`v141_xp` 指定だが未インストール**: この環境には
  VS2022 付属の `v143` しか無い。`TaskMgrCore`/`PCMgrLoader`/`PCMgrCmd`/`PCMgrCmdRunner`/
  `PCMgrKrnlMgr` の **`Debug|x64` 構成のみ** `v143` に変更（Win32/Release は既存資産に影響しない
  よう未変更）。
- **`TaskMgrCore.vcxproj` の `Debug|x64` に `/source-charset:.936` と `capstone`/`NETFXSDK` の
  include パスが無かった**: Win32 構成にはあったが x64 構成に無く、ソース（GBK/936 コードページの
  中国語リテラルを含む）が文字化けして構文エラーになったり、`capstone/platform.h` が見つからな
  かったりした。Win32 と同じ設定を x64 の `ItemDefinitionGroup` にも追加。
- **`mscoree.lib` が無い**（NETFXSDK 4.6.1 未インストールのため）: `PCMgrLoader` が CLR ホスティング
  のためにリンクする。`ThirdPart\mscoree\GenerateMscoreeLib.ps1` がシステムの `mscoree.dll`
  （`C:\Windows\System32`）から `dumpbin /exports` → `.def` 生成 → `lib.exe /def` の手順で x64 用
  インポートライブラリを自動生成し `ThirdPart\mscoree\x64\mscoree.lib` に配置する（`*.lib` は
  `.gitignore` 対象のためリポジトリには含めず、`run64.ps1` が毎回自動生成を試みる＝既にあれば
  スキップ）。`PCMgrLoader.vcxproj` の `AdditionalLibraryDirectories` に参照を追加済み。
- **`PCMgrLoader.vcxproj` の `Debug|x64` が古い `WindowsSdk_71A_*` マクロを使っていた**（未インストール
  の Windows SDK 7.1A 前提で `kernel32.lib` すら見つからない）。標準の `$(WindowsSDK_IncludePath)`/
  `$(WindowsSDK_LibraryPath_x64)` に変更。
- **`MainPageKernelDrvMgr.cs` に `_X64_` ガード漏れ**: `KernelEnumCallBack` の `showAllDriver`
  分岐が `IntPtr.ToInt32()` を無条件使用しており、x64 のカーネルアドレスで `OverflowException`
  になり得た。修正済み。

**ビルド時の注意点:**
- vcxproj を `.sln` 経由でなく直接指定してビルドする場合、`$(SolutionDir)` が正しく解決されない
  （プロジェクト自身のディレクトリになる）ため、必ず `-p:SolutionDir=<リポジトリルート>\` を
  明示的に渡す（`run64.ps1` が対応済み）。
- ビルド順序に依存あり: `TaskMgrCore` は `PCMgrCmd64.lib`/`PCMgrKernel64.lib` をリンクするため、
  `PCMgrCmdRunner`・`PCMgrKrnlMgr` を先にビルドする必要がある（`run64.ps1` はこの順序で実行）。
- カーネルドライバ本体（`PCMgrKernel32.sys`）は WDK が無くビルド対象外。アプリ側は元々ドライバ
  未ロード時にグレースフルに機能無効化する設計（`LoadDriverErrNeed64` 等の既存エラー表示）のため、
  64bit 版でもドライバ関連の高度な機能が使えないだけで、通常のタスクマネージャー機能は動作する。
- Git Bash から `msbuild`/`dumpbin` 等を叩く場合、`/p:...`・`/t:...`・`/exports` のような
  スラッシュ始まりの引数が MSYS のパス変換で壊れる。`MSYS_NO_PATHCONV=1` を設定するか `-p:...`
  形式（ハイフン）を使う。
- PowerShell スクリプトに日本語コメントを書く場合、**UTF-8 BOM 付き**で保存しないと
  Windows PowerShell 5.1 がシステム既定の ANSI コードページ（このマシンでは 932 = Shift-JIS）で
  誤解釈し、構文エラーになる（`run.ps1`/`run64.ps1` は BOM 付き）。

**動作確認**: `run64.ps1` でビルド・起動し、`Debug_64\PCMgr64.exe` が本物の x64 プロセスとして
起動し（`IsWow64Process` で確認）、ウィンドウタイトルが日本語（「タスクマネージャー」）で
表示されることを確認済み。

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
- **Designer のフォント**: C# 側（`.resx` / `.Designer.cs`）の `微软雅黑`（Microsoft YaHei）を
  全て `Yu Gothic UI` に置換済み（`FormMain`、`FormSettings`、`PerformancePageCpu/Ram/Disk/Net`）。
  ネイティブ側 `TaskMgrCore\TaskMgrCore.rc`（PE ダンプ用ダイアログ）は未対応のまま残っている
  （C# アプリの表示には影響しない）。
- **メインウィンドウのメニューバー**（「文件(F) / 选项(O) / 系统(S) / 查看(V)」等）は WinForms の
  MenuStrip ではなく、`TaskMgrCore\TaskMgrCore.rc` のネイティブ Win32 MENU リソース
  （`IDR_MENUMAIN` 以下 14 個の MENU ブロック、`PCMgr32.dll` にコンパイル済みで埋め込まれている）
  だった。`.rc` ソース内の全 MENU 文字列を日本語化済み（POPUP のキャプション "TASKMENU" 等は
  内部識別用で非表示のため未変更）。**この修正は `Debug\PCMgr32.dll`（2019 年ビルドの同梱バイナリ、
  x86）へは未反映**（中国語のまま）。当初はこの環境に C++ ビルドツールチェーンが無く再ビルド
  不可という制約だったが、VS Build Tools 2022 のインストールによりその制約は解消済み
  （「64bit 版のビルドと起動」参照）。ただし実際に x86 の `TaskMgrCore.vcxproj` 等を再ビルドして
  `Debug\PCMgr32.dll`／`PCMgr32.exe` を置き換える作業はまだ行っていない（x64 版のみ対応済み）。
- **64bit 版のビルド・起動**: `run64.ps1` でネイティブ側（`TaskMgrCore`/`PCMgrLoader`/`PCMgrCmd`/
  `PCMgrCmdRunner`/`PCMgrKrnlMgr`）と C# 側（`PCMgr64.csproj`）を一括ビルドし、`Debug_64\
  PCMgr64.exe` を起動できることを確認済み（日本語サテライトも含め動作）。カーネルドライバ
  （`PCMgrKernel32.sys`）は WDK が無くビルド対象外だが、未ロード時のグレースフルな無効化は
  既存の設計どおり機能する。詳細は「64bit 版のビルドと起動」節。

### 未対応（今後の候補）
- **サテライト非対応フォーム**（`.en.resx` が無く Designer に中国語直書き）:
  `FormTcp` / `FormTest` / `FormWindowKillAsk` / `FormFind` / `FormKDbgPrint` / `FormHelp` /
  `FormSpeedBall` / `FormAlwaysOnTop` / `FormSL`。英語版でも未ローカライズ。日本語化するには
  Designer 直書きを resx 化（Localizable 化）するか、コードで対応する必要がある。
- ハードコード中国語（全言語で表示、`.cs` ロジック内）: `MainPagePerf.cs:294`（"资源信息页 "）、
  `MainNativeBridge.cs`（"窗口名称 ："）、`FormHelp.cs`（エラーメッセージ）、
  `FormSpyWindow.cs`（"正在加载……"）など。
