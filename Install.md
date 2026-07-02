# PCMgr インストール・ビルド手順

## 動作環境

- Windows 7 以降（推奨: Windows 10/11）
- .NET Framework 4.8 以降

---

## 方法 1: ビルド済みバイナリを使う（推奨）

リポジトリの `Release` / `Release_64` ディレクトリに事前ビルド済みの ZIP が含まれています。

### x86 版

1. [Release_x86_1.3.2.6.zip をダウンロード](https://github.com/imengyu/PCMgr/raw/master/Release/Release_x86_1.3.2.6.zip) して任意のフォルダに展開する
2. `ThirdPart/AeroWizard/AeroWizard32.dll` を展開先フォルダにコピーする
3. `PCMgr32.exe` を管理者として実行する

### x64 版

1. [Release_x64_1.3.2.6.zip をダウンロード](https://github.com/imengyu/PCMgr/raw/master/Release_64/Release_64_1.3.2.6.zip) して任意のフォルダに展開する
2. `ThirdPart/AeroWizard/AeroWizard64.dll` を展開先フォルダにコピーする
3. `PCMgr64.exe` を管理者として実行する

> capstone.dll は ZIP に同梱済みです。

---

## 方法 2: dotnet CLI でビルドして起動する

C++ ローダー (`PCMgr32.exe`) はビルド済みバイナリを流用し、C# 部分 (`PCMgrApp32.dll`) だけを dotnet CLI でビルドします。

### 必要なツール

- [.NET SDK 8.0](https://dotnet.microsoft.com/download)
- .NET Framework 4.8（Windows 10/11 に標準搭載）

### 手順

```powershell
# 1. C# 部分をビルド
dotnet build TaskMgr\PCMgr32.csproj -c Debug /p:Platform=x86 `
  /p:FrameworkPathOverride="C:\Windows\Microsoft.NET\Framework\v4.0.30319"

# 2. ビルド済み ZIP を Debug\ に展開（初回のみ）
Expand-Archive Release\Release_x86_1.3.2.6.zip -DestinationPath Debug\ -Force

# 3. サードパーティ DLL をコピー（初回のみ）
Copy-Item ThirdPart\AeroWizard\AeroWizard32.dll Debug\
Copy-Item ThirdPart\capstone\lib\x86\capstone.dll Debug\

# 4. 起動（管理者権限推奨）
Start-Process Debug\PCMgr32.exe -Verb RunAs
```

2 回目以降は手順 1 のビルドだけで `Debug\PCMgrApp32.dll` が更新されます。

---

## 注意事項

- プロセス管理機能を使うには**管理者として実行**する必要があります
- カーネルドライバ (`PCMgrKernel32.sys`) を使う機能はテスト署名が必要です（通常は不要）
