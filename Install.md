# PCMgr インストール・ビルド手順

## 動作環境

- Windows 7 以降（推奨: Windows 10/11）
- .NET Framework 4.5 以降

---

## 方法 1: ビルド済みバイナリを使う（推奨）

リポジトリの `Release` / `Release_64` ディレクトリに事前ビルド済みの ZIP が含まれています。

### x86 版

1. `Release/Release_x86_1.3.2.6.zip` を任意のフォルダに展開する
2. `ThirdPart/AeroWizard/AeroWizard32.dll` を展開先フォルダにコピーする
3. `PCMgr32.exe` を実行する

### x64 版

1. `Release_64/Release_x64_1.3.2.6.zip` を任意のフォルダに展開する
2. `ThirdPart/AeroWizard/AeroWizard64.dll` を展開先フォルダにコピーする
3. `PCMgr64.exe` を実行する

> capstone.dll は ZIP に同梱済みです。

---

## 方法 2: ソースからビルドする

### 必要なツール

- Visual Studio 2019 以降
  - C++ によるデスクトップ開発 ワークロード（v141_xp および v142 ツールセット）
  - .NET デスクトップ開発 ワークロード
- Windows SDK 10.0

### ビルド手順

1. Visual Studio で `PCMgr.sln` を開く

2. スタートアッププロジェクトを **PCMgrLoader** に設定する

3. ソリューション構成を選ぶ
   | 構成 | プラットフォーム | 出力先 |
   |------|---------|--------|
   | Debug | x86 (Win32) | `Debug\` |
   | Debug | x64 | `Debug_64\` |
   | Release | x86 (Win32) | `Release\` |
   | Release | x64 | `Release_64\` |

4. ソリューションエクスプローラーで **PCMgrLoader** を右クリック → **ビルド**

5. サードパーティ DLL をコピーする

   **x86 の場合** → 出力先フォルダ (`Debug\` または `Release\`) へコピー:
   ```
   ThirdPart\AeroWizard\AeroWizard32.dll
   ThirdPart\capstone\lib\x86\capstone.dll
   ```

   **x64 の場合** → 出力先フォルダ (`Debug_64\` または `Release_64\`) へコピー:
   ```
   ThirdPart\AeroWizard\AeroWizard64.dll
   ThirdPart\capstone\lib\x64\capstone.dll
   ```

6. 出力先フォルダの `PCMgr32.exe`（x86）または `PCMgr64.exe`（x64）を実行する

### ビルド不要なサブプロジェクト

以下のプロジェクトはビルドしなくても動作に影響ありません:

| プロジェクト | 理由 |
|---|---|
| `PCMgrKernel` | カーネルドライバ。ビルドには WDK 10 が必要 |
| `PCMgrNetMon` | 未実装 |
| `PCMgrRegedit` | 未実装 |
| `PCMgrUpdate` | 更新サーバーが廃止済みで機能しない |

---

## 注意事項

- プロセス管理機能を使うには**管理者として実行**する必要があります
- カーネルドライバ (`PCMgrKernel32.sys`) を使う機能はテスト署名が必要です（通常は不要）
