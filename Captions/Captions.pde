PFont fontRegular,fontBold;
int captionNumber=0,lastCaptionNumber=0;

void setup(){
  size(1280,720);
  pixelDensity(displayDensity());
  fontRegular=createFont("思源黑体 HW",22.0f);
  fontBold=createFont("思源黑体 HW Bold",22.0f);
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
  textSize(72);
  textAlign(LEFT,TOP);
  int top=150,left=80;
  text("中国及周边地区3级以上地震分布",left,top);
  textSize(48);
  top+=72*1.5;
  text("Earthquake Records in China and Nearby Regions\n(Magnitude≥3)",left,top);
  textSize(48);
  top+=48*3*1.5;
  text("1970-1-1 ～ 1980-1-1",left,top);
}

void caption1(){
  textFont(fontRegular);
  fill(255,255,255);
  textSize(48);
  textAlign(LEFT,TOP);
  int top=55,left=50;
  text("数据来源：国家地震科学数据中心",left,top);
  textSize(36);
  top+=48*1.5;
  text("Data Source: National Earthquake Data Center",left,top);
  color linkColor=color(255,227,8);
  fill(linkColor);
  top+=36*1.5;
  String linkStr="https://data.earthquake.cn/gcywfl/index.html";
  text(linkStr,left,top);
  fill(255,64,154);
  text("(要登录/Login Required)",left+textWidth(linkStr),top);
  textSize(48);
  fill(255,255,255);
  top+=36*2;
  text("地图来源 / Map Source:",left,top);
  textSize(36);
  top+=48*1.5;
  text("使用中国地图的正确姿势                NASA Visible Earth",left,top);
  fill(linkColor);
  top+=36*1.5;
  text("https://zhuanlan.zhihu.com/p/25634886 https://visibleearth.nasa.gov",left,top);
  textSize(48);
  fill(255,255,255);
  top+=36*2;
  text("＊本视频不能作为任何科学研究的依据，\n　仅为个人学习之用。",left,top);
  textSize(36);
  top+=48*2*1.5;
  text("＊ This video cannot be used for any kinds of research and is\n　 intended only for personal studying.",left,top);
}

void DrawCircle(float x,float y,float magnitude,float depth){
  //图形部分
  strokeWeight(3.0f);
  stroke(255,255,255);
  noFill();
  float radius=3.54f*exp(0.45f*magnitude);
  circle(x,y,radius*2.0f);
  translate(x,y);
  rotate(radians(0.38f*sqrt(80.0f*depth)));
  line(0,0,radius,0);
  resetMatrix();
  strokeWeight(2.5f);
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
  float radius=3.54f*exp(0.45f*magnitude);
  textSize(radius*0.6);
  fill(32,32,6);
  text(String.format("%.1f",magnitude),x+2,y+2);
  fill(240,240,12);
  text(String.format("%.1f",magnitude),x,y);
}

void caption2(int testSound){
  fill(255,255,255);
  textSize(48);
  textAlign(LEFT,TOP);
  int top=55,left=50;
  text("震级 (Magnitude)",left,top);
  float smpMags[]={3,4,5,7,8.7f};
  for(int i=0;i<5;i++){
    textFont(fontBold);
    //strokeWeight(3);
    DrawCircle(width*(i+1)/6,top+150,smpMags[i],0);
  }
  for(int i=0;i<5;i++){
    textFont(fontBold);
    strokeWeight(3);
    DrawCircleText(width*(i+1)/6,top+150,smpMags[i],0);
    textAlign(CENTER,CENTER);
    textFont(fontRegular);
    fill(255,255,255);
    textSize(48);
    if(i+1==testSound){
      text("["+String.valueOf(smpMags[i])+"]",width*(i+1)/6,top+250);
    }else{
      text(String.valueOf(smpMags[i]),width*(i+1)/6,top+250);
    }
  }
  fill(255,255,255);
  textSize(48);
  textAlign(LEFT,TOP);
  top+=330;
  text("深度 (Depth)",left,top);
  int smpDepths[]={10,50,100,300,500};
  for(int i=0;i<5;i++){
    textFont(fontBold);
    strokeWeight(3);
    DrawCircle(width*(i+1)/6,top+150,7,smpDepths[i]);
  }
  for(int i=0;i<5;i++){
    textFont(fontBold);
    strokeWeight(3);
    DrawCircleText(width*(i+1)/6,top+150,7,smpDepths[i]);
    textAlign(CENTER,CENTER);
    textFont(fontRegular);
    fill(255,255,255);
    textSize(48);
    if(i+6==testSound){
      text("["+String.format("%dkm",smpDepths[i])+"]",width*(i+1)/6,top+250);
    }else{
      text(String.format("%dkm",smpDepths[i]),width*(i+1)/6,top+250);
    }
  }
}

void caption3(){
  textFont(fontRegular);
  fill(255,255,255);
  textSize(48);
  textAlign(LEFT,TOP);
  int top=55,left=50;
  text("制作：lxfly2000",left,top);
  textSize(36);
  top+=48*1.5;
  text("Made by: lxfly2000",left,top);
  color linkColor=color(255,227,8);
  top+=36*2;
  textSize(48);
  text("使用工具：ArcGIS, Processing, FFmpeg",left,top);
  textSize(36);
  top+=48*1.5;
  text("Using Tools: ArcGIS, Processing, FFmpeg",left,top);
  top+=36*2*1.5;
  textSize(48);
  text("参考视频 / Reference Video:\n日本の地震 Japan Earthquakes 2016-03-01",left,top);
  textSize(36);
  top+=48*2*1.5;
  fill(linkColor);
  text("https://youtu.be/1jCXdatTHNQ",left,top);
}
