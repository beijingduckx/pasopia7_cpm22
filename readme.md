# CP/M version 2.2 for Toshiba Pasopia & Paspoia7
東芝製 Pasopia (PA7010/PA7012), Pasopia7 (PA7007) で動作する 60K CP/M version 2.2です  
(Pasopia700で動くかは不明)

# 仕様
## サポートされている I/O
- ディスク (1, 2)
- カラーモニタ
- キーボード

## サポートされていない I/O
- RS-232C   (READER)
- プリンタ  (LIST)
- CMT
- ROM/RAM-PAC

## コンソール
- 80 column x 24 line
- PFキー未サポート

- コントロールコード

|Key   |code| 機能 |
|--------|---|----|
|Ctrl-H | 08H | カーソルを左へ|
|Ctrl-J | 0AH | 改行|
|Ctrl-K | 0BH | カーソルを(0,0)へ|
|Ctrl-L | 0CH | 画面クリア|
|Ctrl-M | 0DH | 復帰|
|Ctrl-M | 1AH | 画面クリア|

(ベルは実装していません)

- エスケープシーケンス (X1 + Televideo920 flavor)

|ESC-   | 機能 |
|---  |---    |
|*    |画面クリア|
|+    |画面クリア|
|T    |カーソル以降行内クリア|
|Y    |カーソル以降画面末端までクリア|
|= Y X|カーソル移動|
|(   |反転文字開始 (X1準拠: TeleVideoと異なります)|
|)   |反転文字終了 (X1準拠: TeleVideoと異なります)|
|R   |カーソル行削除  (以降の行は上スクロール)|
|E   |カーソル行へ行挿入 (以降の行は下スクロール)|

- キーボード (PASOPIA7)

|キートップ   | 機能 | +SHIFT  |
|---          |---   | ----    |
|TAB/ESC  |ESC | ESC |
|LABEL    |TAB | TAB |
|INS/DEL  |BS (Ctrl-H)| INS (Ctrl-R)|
|STOP     |Ctrl-C | Ctrl-C|
|↓/↑      |↑   | ↓ |



- 特殊キー

|キー  | 機能 |
|---          |---   |
|CTRL + GRAPH + STOP  |ログインドライブを1に設定しリブート |


## 制限など
- CP/M BIOS は、IOBYTE を見ていません

- 画面表示に割り込みを使っています  
割り込みを禁止すると、画面表示が停止します  
(例えば、MOVCPMのシリアルチェックにひっかかると、画面に何も出ずに動作が停止します)

- Pasopia7での本体リセットボタン(NMI)押下は、CP/MのFCBエリアにジャンプすることになるので、正常な動作は期待できません  
  Paspoiaでの本体リセットボタン押下についても、CP/Mのリブートは実行されません

- 特殊キーによるリブートは、非常用です(他に手段の無いBDOSエラーからの復帰など)  
  オープン中のファイルがあるときの特殊キーでのリブートは、ファイル破損のリスクがあるかもしれません

- WRITEは、デブロッキングを実装していません  
  作者がBDOS内部を理解しておらず、遅延書き込みにより(特にディスク交換時)ディスクの内容を壊す可能性が否定できないため、見送っています  

- Sharp製X1用CP/M (ランゲージマスター) のディスクパラメタに合わせています  
  東芝製の Pasopia/7用CP/M のディスクは(おそらく)読めません  
   (資料がなく、ディスクパラメタが不明です)  

- 80トラックをサポートしたディスクドライブの使用が前提です  
  東芝純正ドライブでは、71トラック以降は読めないと思います

- SYSGEN, FORMAT は用意できていません  
  実機で動作させるためには、イメージを2D ディスクに書き戻せる環境が必要です

- 実機で動作テストしていません  
  作者は、ディスクドライブを所有していないのです...  
  エミュレータでは気になりませんが、ディスクアクセス(特にデブロッキングがないライト)が相当遅いと思います  
  ディスクフォーマット時に適切なスキューが必要と思いますが、未検討です  
  また、独自のディスクI/Oを実装しており、実ディスクドライブで正常に動作するか未確認です
  (特に、実機ではMOTOR ON時にエラーとなる可能性があります)

- Paspoiaでは、部分スクロール(ESC-R, ESC-E)時にアトリビュートをスクロールさせて
  いません

- OSブートプログラム(IPL)のエラーチェックは不完全です  ブート中にディスク読み取りエラーなどが発生すると
  暴走すると思います

# トラック構成

|Track#  | Head | Sector | 機能 |
|-------|----|----|---|
|0  | 0 | *|未使用 (128B/sector)|
|0  | 1 | 1-|CP/M-BIOS | 
|1  | 0 | 1-2|ブート|
|1  | 0 | 3-|CCP+BDOS|
|1  | 1 | *|未使用|
| それ以降|  ||CP/M|

(Track1, Head1が空いていますが、そこはCP/Mが利用すると作者が勘違いしたためです...  
そのトラックを利用すると、ブートコードがもっと簡単になるのですが、もうそのままにしておきます)

# ビルド

## 準備
1. ソースコードフォルダ下に`build`フォルダを作成
1. [CP/M Player Console](http://takeda-toshiya.my.coocan.jp/cpm/index.html)をダウンロードし、`build`フォルダ内に `cpm.exe` をコピー
1. Microsoft製 MACRO-80 および LINK-80 (`M80.COM`/`L80.COM`)を`build`フォルダ内にコピー
1. `cpmtools` もしくは `CpmtoolsGUI`を用いて新規ディスクを作成(本リポジトリの`diskdefs`に`sharp-x1`のフォーマットを定義してあります)し、`cpm_base.2d` として保存し、`build`フォルダに保存  
(X1用CP/Mの2D形式ディスクイメージをお持ちでしたら、それを利用することでもかまいません)

## ビルド
1. PowerShellから、ソースコードフォルダ内で`./compile.ps1`を実行
1. `build`フォルダ内に、ディスクイメージ `cpm_7010.2d` (PA7010/PA7012用), `cpm_7007.2d`(PA7007用) が作成される


# コードについて
- CCP + BDOSのコードは、http://www.cpm.z80.de/source.html の `cpm2-asm.zip`に含まれているZ80二モニックものです  
ただ、元のコードには8080からのコンバートに失敗していると思われる箇所があり、それを修正しています  
また、プロンプトのドライブレターが大文字で表示されるように修正しています



# 参考文献, ツール

- [Unofficial CP/M Web site](http://www.cpm.z80.de/)

- [Digital Research CP/M Operating System Manual](https://www.autometer.de/unix4fun/z80pack/cpm2/)

- [TeleVideo Operator's Reference Handbook, TVI-912B and TVI-920B, TVI-912C and TVI-920C](https://vt100.net/televideo/)

- [Cpmtools](http://www.moria.de/~michael/cpmtools/) [(or unofficial fork)](https://github.com/lipro-cpm4l/cpmtools)

- [CpmtoolsGUI](http://star.gmobb.jp/koji/cgi/wiki.cgi?page=CpmtoolsGUI)

- 東芝パーソナルコンピュータ パソピア7 テクニカルマニュアル

- [パソピアの内部構造](https://dl.ndl.go.jp/pid/12628498/1/76)
