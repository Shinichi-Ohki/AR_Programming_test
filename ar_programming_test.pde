// AR Programming Test program
// Shinichi Ohki
// 2012/05

//
// Import library
//
import processing.serial.*;		// シリアルポートライブラリ
import ppopupmenu.*;			// ポップアップメニューライブラリ
import picking.*;				// ピッキングライブラリ
import processing.video.*;		// ビデオライブラリ
import jp.nyatla.nyar4psg.*;	// ARライブラリ

Serial myPort;					// シリアルポート
PImage tex0=null;				// 画像
PImage tex1=null;				// 画像
Capture cam=null;				// カメラ
MultiMarker nya=null;			// AR
Picker picker=null;				// ピッカー
PPopupMenu menu0=null;			// ポップアップメニュー
PPopupMenu menu1=null;			// ポップアップメニュー

int r=255;
int g=255;
int b=255;

int id0,id1;
int selected = -1;

//
// セットアップ(起動時に一度だけ実行される関数)
//
void setup(){
// テクスチャの準備
  tex0 = loadImage("onoff.png");		// テクスチャイメージの読み込み(ON/OFF画像)
  tex1 = loadImage("color_bright.png");	// テクスチャイメージの読み込み(色合い/明るさ画像)
  textureMode(NORMALIZED);

// 画面サイズとキャプチャの設定
  size(640, 480, P3D);					// 画面サイズの設定
  colorMode(RGB, 100);
  cam=new Capture(this, 640, 480);

// ARマーカの準備
  nya=new MultiMarker(this, width, height, "camera_para.dat", NyAR4PsgConfig.CONFIG_PSG);	
  id0 = nya.addARMarker("patt.hiro", 80);	// 実演に使ったマーカはもっと大きいが数値はこのままで
  id1 = nya.addARMarker("patt.kanji", 80);

// ピッキングの準備
  picker=new Picker(this);

// ポップアップメニューの準備
  menu0=new PPopupMenu(this);
  menu1=new PPopupMenu(this);

  menu0.addMenuItem("ON/OFF", "TurnONOFF");

  menu1.addMenuItem("Active", "changeBoxColorBlue");
  menu1.addMenuItem("Natual", "changeBoxColorGreen");
  menu1.addMenuItem("Relax", "changeBoxColorRed");
  menu1.addSeparator();
  menu1.addMenuItem("10", "changeBrigtness10");
  menu1.addMenuItem("9", "changeBrigtness09");
  menu1.addMenuItem("8", "changeBrigtness08");
  menu1.addMenuItem("7", "changeBrigtness07");
  menu1.addMenuItem("6", "changeBrigtness06");
  menu1.addMenuItem("5", "changeBrigtness05");
  menu1.addMenuItem("4", "changeBrigtness04");
  menu1.addMenuItem("3", "changeBrigtness03");
  menu1.addMenuItem("2", "changeBrigtness02");
  menu1.addMenuItem("1", "changeBrigtness01");

// シリアルポート(Arduinoと接続のため)の設定
  println(Serial.list());
  myPort=new Serial(this,Serial.list()[1],57600);
}

//
// draw(繰り返し実行される関数)
//
void draw(){
  if(cam.available()!=true)		// カメラの準備ができていない時は処理しない
    return;

  cam.read();					// カメラ画像の読み込み
  nya.detect(cam);				// マーカ認識
  hint(DISABLE_DEPTH_TEST);		// Zバッファを無効に
  image(cam, 0, 0);				// カメラ画像の描画
  hint(ENABLE_DEPTH_TEST);		// Zバッファを有効に

// マーカが認識されていたらオブジェクトを描画
  for (int i=0; i<2; i++) {
    if(nya.isExistMarker(i)) {
      picker.start(i);			// ピッキング用ID付与
      nya.beginTransform(i);
        if (i == selected) {	// オブジェクトが選択されていたら
          fill(255,255,0);		// 黄色にする
        } else {
          fill(255,255,255);	// そうでないときは白くする
        }
        translate(0, 0, 1);		// 少し移動
        box(80,80,1);			// 厚さ1の箱(板)を描画
      noStroke();
      beginShape();
        switch(i) {				// オブジェクトの番号でテクスチャを選択
          case 0: texture(tex0);break;
          case 1: texture(tex1);break;
        }
        vertex( 40, 40,2,0,0);	// テクスチャを貼る
        vertex(-40, 40,2,1,0);
        vertex(-40,-40,2,1,1);
        vertex( 40,-40,2,0,1);
      endShape();
      nya.endTransform();
      picker.stop();
    }
  }
  selected = picker.get(mouseX, mouseY);	// マウスカーソルの下にあるオブジェクトを判定
}

// オブジェクトの上で右クリックされたら右クリックメニューを表示
void mouseClicked(){
  if(mouseButton==RIGHT){
    println("id:"+selected);
    switch(selected){
      case 0:
        if(!nya.isExistMarker(0))
          return;
        menu0.show();
        break;
      case 1:
        if(!nya.isExistMarker(1))
          return;
        menu1.show();
        break;
    }
  }
}

// Arduino上のFirmata対応スケッチに対してデータを送信
void senddata(byte b) {
  myPort.write(0xf0);			// START_SYSEX
  myPort.write(0x71);			// STRING_DATA
  myPort.write(0x82 % 128);		// 送信データ1バイト目の下7bit(00000010)
  myPort.write(0x82 >> 7);		// 送信データ1バイト目の上1bitを下位に詰めて(1xxxxxxxx → 00000001)
  myPort.write(0x6d % 128);		// 送信データ2バイト目の下7bit(01101101)
  myPort.write(0x6d >> 7);		// 送信データ2バイト目の上1bitを下位に詰めて(0xxxxxxxx → 00000001)
  myPort.write(b % 128);		// 送信データ3バイト目の下7bit(xbbbbbbb)
  myPort.write(b >> 7);			// 送信データ3バイト目の上1bitを下位に詰めて(bxxxxxxxx → 0000000b)
  myPort.write(0xf7);			// END_SYSEX
}

// 以下、ポップアップメニューの中身
void TurnONOFF() {
  senddata(byte(0xab));			// Processingの数値は4バイトなので、byte型に変換する
  println("LED:ON/OFF");
}

void changeBoxColorRed(){
  senddata(byte(0xae));
  println("LED:Color Relax");
}

void changeBoxColorGreen(){
  senddata(byte(0xad));
  println("LED:Color Natural");
}

void changeBoxColorBlue(){
  senddata(byte(0xac));
  println("LED:Color Active");
}

void changeBrigtness10() {
  senddata(byte(0xb0));
  println("LED:Bright 10");
}

void changeBrigtness09() {
  senddata(byte(0xb1));
  println("LED:Bright 9");
}

void changeBrigtness08() {
  senddata(byte(0xb2));
  println("LED:Bright 8");
}

void changeBrigtness07() {
  senddata(byte(0xb3));
  println("LED:Bright 7");
}

void changeBrigtness06() {
  senddata(byte(0xb4));
  println("LED:Bright 6");
}

void changeBrigtness05() {
  senddata(byte(0xb5));
  println("LED:Bright 5");
}

void changeBrigtness04() {
  senddata(byte(0xb6));
  println("LED:Bright 4");
}

void changeBrigtness03() {
  senddata(byte(0xb7));
  println("LED:Bright 3");
}

void changeBrigtness02() {
  senddata(byte(0xb8));
  println("LED:Bright 2");
}

void changeBrigtness01() {
  senddata(byte(0xb9));
  println("LED:Bright 1");
}

