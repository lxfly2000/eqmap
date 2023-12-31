PFont fontRegular,fontBold;
int captionNumber=0,lastCaptionNumber=0;

void setup(){
  size(1920,1080);
  pixelDensity(displayDensity());
  fontRegular=createFont("../eqmap_processing/data/sarasa-mono-sc-regular.ttf",33.0f);
  fontBold=createFont("../eqmap_processing/data/sarasa-mono-sc-bold.ttf",33.0f);
}

void draw(){
  background(0,0,0);
  switch(lastCaptionNumber){
    case 0:caption0();break;
    case 1:caption1();break;
    case 13:caption3();break;
  }
  if(lastCaptionNumber>=2&&lastCaptionNumber<=12){
    caption2(lastCaptionNumber-2);
  }
  if(captionNumber==lastCaptionNumber+1){
    saveFrame("frames/f-"+lastCaptionNumber+".png");
    lastCaptionNumber=captionNumber;
  }
}



void keyPressed(){
  captionNumber++;
}

void caption0(){
  textFont(fontRegular);
  fill(255,255,255);
  textSize(108);
  textAlign(LEFT,TOP);
  int top=225,left=120;
  text("中国及周边地区地震分布(速报数据)",left,top);
  textSize(72);
  top+=108*1.5;
  text("Earthquake Records in China and Nearby Regions\n(Quick Report Data)",left,top);
  textSize(72);
  top+=72*3*1.5;
  text("2020-1-1 ～ 2024-1-1",left,top);
}

void caption1(){
  textFont(fontRegular);
  fill(255,255,255);
  textSize(72);
  textAlign(LEFT,TOP);
  int top=83,left=75;
  text("数据来源：国家地震科学数据中心",left,top);
  textSize(54);
  top+=72*1.5;
  text("Data Source: National Earthquake Data Center",left,top);
  color linkColor=color(255,227,8);
  fill(linkColor);
  top+=54*1.5;
  translate(left,top);
  scale(1,1);
  String linkStr="https://data.earthquake.cn/gcywfl/index.html";
  text(linkStr,0,0);
  fill(255,64,154);
  text("(要登录/Login Required)",textWidth(linkStr),0);
  resetMatrix();
  textSize(72);
  fill(255,255,255);
  top+=54*2;
  text("地图来源 / Map Source:",left,top);
  textSize(54);
  top+=72*1.5;
  text("使用中国地图的正确姿势                NASA Visible Earth",left,top);
  fill(linkColor);
  top+=54*1.5;
  text("https://zhuanlan.zhihu.com/p/25634886 https://visibleearth.nasa.gov",left,top);
  textSize(72);
  fill(255,255,255);
  top+=54*2;
  text("＊本视频不能作为任何科学研究的依据，\n　仅为个人学习之用。",left,top);
  textSize(54);
  top+=72*2*1.5;
  text("＊ This video cannot be used for any kinds of research and is\n　 intended only for personal studying.",left,top);
}

void DrawCircle(float x,float y,float magnitude,float depth){
  //图形部分
  strokeWeight(6.0f);
  float radius=5.31f*exp(0.45f*magnitude);
  //阴影
  translate(x,y);
  stroke(0,0,0,150);
  fill((int)(255.0f*exp(depth*(-0.02f))),(int)(16.0f*exp(depth*(-0.02f))),(int)(8.0f*exp(depth*(-0.02f))),255*0.25f);
  circle(0,0,radius*2.0f);
  noFill();
  circle(1,1,radius*2.0f);
  rotate(radians(0.38f*sqrt(80.0f*depth)));
  line(1,1,radius,0);
  resetMatrix();
  stroke(255,255,255);
  circle(x,y,radius*2.0f);
  translate(x,y);
  rotate(radians(0.38f*sqrt(80.0f*depth)));
  line(0,0,radius,0);
  resetMatrix();
  strokeWeight(3.75f);
  stroke((int)(255.0f*exp(depth*(-0.02f))),(int)(16.0f*exp(depth*(-0.02f))),(int)(8.0f*exp(depth*(-0.02f))));
  noFill();
  //float radius=3.54f*exp(0.45f*magnitude);
  circle(x,y,radius*2.0f);
  translate(x,y);
  rotate(radians(0.38f*sqrt(80.0f*depth)));
  line(0,0,radius,0);
  resetMatrix();
}
void DrawCircleText(float x,float y,float magnitude,float depth){
  //文字部分
  if(magnitude<3.5f){
    return;
  }
  textFont(fontBold);
  textAlign(CENTER,BASELINE);
  float radius=5.31f*exp(0.45f*magnitude);
  textSize(radius*0.6);
  fill(32,32,6);
  text(String.format("%.1f",magnitude),x+3,y+3);
  fill(240,240,12);
  text(String.format("%.1f",magnitude),x,y);
}

void caption2(int testSound){
  fill(255,255,255);
  textSize(72);
  textAlign(LEFT,TOP);
  int top=83,left=75;
  text("震级 (Magnitude)",left,top);
  float smpMags[]={3,4,5,7,8.7f};
  for(int i=0;i<5;i++){
    textFont(fontBold);
    //strokeWeight(3);
    DrawCircle(width*(i+1)/6,top+225,smpMags[i],0);
  }
  for(int i=0;i<5;i++){
    textFont(fontBold);
    strokeWeight(4.5f);
    DrawCircleText(width*(i+1)/6,top+225,smpMags[i],0);
    textAlign(CENTER,CENTER);
    textFont(fontRegular);
    fill(255,255,255);
    textSize(72);
    if(i+1==testSound){
      text("["+String.valueOf(smpMags[i])+"]",width*(i+1)/6,top+375);
    }else{
      text(String.valueOf(smpMags[i]),width*(i+1)/6,top+375);
    }
  }
  fill(255,255,255);
  textSize(72);
  textAlign(LEFT,TOP);
  top+=495;
  text("深度 (Depth)",left,top);
  int smpDepths[]={10,50,100,300,500};
  for(int i=0;i<5;i++){
    textFont(fontBold);
    strokeWeight(4.5f);
    DrawCircle(width*(i+1)/6,top+225,7,smpDepths[i]);
  }
  for(int i=0;i<5;i++){
    textFont(fontBold);
    strokeWeight(4.5f);
    DrawCircleText(width*(i+1)/6,top+225,7,smpDepths[i]);
    textAlign(CENTER,CENTER);
    textFont(fontRegular);
    fill(255,255,255);
    textSize(72);
    if(i+6==testSound){
      text("["+String.format("%dkm",smpDepths[i])+"]",width*(i+1)/6,top+375);
    }else{
      text(String.format("%dkm",smpDepths[i]),width*(i+1)/6,top+375);
    }
  }
}

void caption3(){
  textFont(fontRegular);
  fill(255,255,255);
  textSize(72);
  textAlign(LEFT,TOP);
  int top=83,left=75;
  text("制作：lxfly2000",left,top);
  textSize(54);
  top+=72*1.5;
  text("Made by: lxfly2000",left,top);
  color linkColor=color(255,227,8);
  top+=54*2;
  textSize(72);
  text("使用工具：ArcGIS, Processing, FFmpeg",left,top);
  textSize(54);
  top+=72*1.5;
  text("Using Tools: ArcGIS, Processing, FFmpeg",left,top);
  top+=54*2*1.5;
  textSize(72);
  text("参考资料 / Reference Data:\n日本の地震 Japan Earthquakes 2016-03-01",left,top);
  textSize(54);
  top+=72*2*1.3;
  fill(linkColor);
  text("https://youtu.be/1jCXdatTHNQ",left,top);
  top+=54*1.5;
  textSize(72);
  fill(255,255,255);
  text("CENC Earthquake List",left,top);
  textSize(54);
  top+=72*1.5;
  fill(linkColor);
  text("https://github.com/Project-BS-CN/CENC-Earthquake-List",left,top);
}
