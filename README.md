# IchigoJamSerialConsole

IchigoJamのシリアルをMacに接続し、MacのキーボードをIchigoJamのキーボードとして使えるようにするアプリです。

開発環境:Xcode 6.2

# ビルド方法

シリアル通信のライブラリとしてORSSerialPortをCocoaPodsで使用しています。  
CocoaPodsをインストールしていない場合は、まずCocoaPodsのインストールをお願いします。  
$ sudo gem install cocoapods  
  
本プロジェクトを取得後、プロジェクトフォルダにて  
pod install  
を実行して下さい。

CocoaPods実行後、 IchigoJamSerialConsole.xcworkspace を開いてビルドして下さい。

# 使用方法

USBシリアル変換基板などで、MacのUSBとIchigoJamのシリアルを接続してIchigoJamの電源を入れて下さい。  
本アプリ起動後、Serial:ポップアップボタンから該当するUSBデバイスを選択し、Openボタンを押下します。  
左上に緑色の丸が表示されたらシリアル接続完了です。  
本アプリにフォーカスがある状態でMacのキーボードがIchigoJamのキーボードとして機能します。

