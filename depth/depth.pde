import processing.sound.SoundFile;
import java.util.GregorianCalendar;
import java.text.SimpleDateFormat;
import java.text.ParseException;

//Data related configurations
class Param{
  String bgMap;
  String dataSrc;
  int minutesPerFrame;
  String startDate,endDate;
  boolean showLogPoint;
  String timeZoneDesc;
  boolean showLogStr;
  float startLongitude,endLongitude,startLatitude,endLatitude;
  boolean recordMode;
  float minLogMagnitude;
  float minCircleMagnitude;
  float minCircleDigitMagnitude;
  Param(){
    JSONObject json=loadJSONObject("../eqmap_processing/data/eq.json");
    bgMap="../SDLEqMap/EastAsiaGeographNoInfo.png";
    dataSrc="../eqmap_processing/data/"+json.getString("dataSrc","eqdata.csv");
    minutesPerFrame=json.getInt("minutesPerFrame",180)*10;
    startDate=json.getString("startDate","2014/1/1");
    endDate=json.getString("endDate","2020/1/1");
    showLogPoint=json.getBoolean("showLogPoint",true);
    timeZoneDesc=json.getString("timeZoneDesc"," CST");
    showLogStr=json.getBoolean("showLogStr",true);
    startLongitude=json.getFloat("startLongitude",51.3f);
    endLongitude=json.getFloat("endLongitude",163.7f);
    startLatitude=json.getFloat("startLatitude",2.24f);
    endLatitude=json.getFloat("endLatitude",54.4f);
    minLogMagnitude=json.getFloat("minLogMagnitude",5.0f);
    minCircleMagnitude=json.getFloat("minCircleMagnitude",2.0f);
    minCircleDigitMagnitude=json.getFloat("minCircleDigitMagnitude",3.5f);
    recordMode=json.getBoolean("recordMode",false);
  }
}
Param param;

float MinHundredGreaterThan(float n){
  float h=0.0f;
  while(h<n){
    h+=100.0f;
  }
  return h;
}

//Program Data
class DepthRectCalc{
  float wmLeft,wmTop,wmRight,wmBottom;
  float xLeft,xRight,yTop,yBottom;
  boolean crossDate;
  void Init(){
    xLeft=0;
    xRight=width;
    yTop=120;
    yBottom=height;
    if(param.endLongitude<param.startLongitude){
      crossDate=true;
      param.endLongitude+=360.0f;
    }else{
      crossDate=false;
    }
    wmLeft=param.startLongitude;
    wmTop=0;
    wmRight=param.endLongitude;
    wmBottom=0;//?????????????????????
  }
  float toScreenX(float longitude){
    if(crossDate&&longitude<0.0f){
      longitude+=360.0f;
    }
    return xLeft+(longitude-wmLeft)*(xRight-xLeft)/(wmRight-wmLeft);
  }
  float toScreenY(float depth){
    depth=0.38f*sqrt(80.0f*depth)*wmBottom/90.0f;
    return yTop+(depth-wmTop)*(yBottom-yTop)/(wmBottom-wmTop);
  }
};
DepthRectCalc depthRectCalc;
ArrayList<SoundFile>sfx;//The sound is lower while the index grows larger
float maxLogStrPxWidth=0.0f;
class EqEntry{
  GregorianCalendar dateTime;
  float longitude,latitude;
  float depth;
  String unit;
  float magnitude;
  String location;
  String category;
  EqEntry(String s){
    String[]parts=s.split(",");
    try{
      dateTime=new GregorianCalendar();
      dateTime.setTime(new SimpleDateFormat("yyyy/M/d H:mm").parse(parts[0]));
    }catch(ParseException e){
      println(e.getLocalizedMessage());
      noLoop();
      return;
    }
    longitude=Float.parseFloat(parts[1]);
    latitude=Float.parseFloat(parts[2]);
    depth=Float.parseFloat(parts[3]);
    unit=parts[4];
    magnitude=Float.parseFloat(parts[5]);
    location=parts[6];
    category=parts[7];
    
    il_posX=(int)depthRectCalc.toScreenX(longitude);
    il_radius=3.54f*exp(0.45f*magnitude);
    il_rotation=0.38f*sqrt(80.0f*depth);
    il_alpha=255;
    il_red=(int)(255.0f*exp(depth*(-0.02f)));
    il_green=(int)(16.0f*exp(depth*(-0.02f)));
    il_blue=(int)(8.0f*exp(depth*(-0.02f)));
    il_frameLeft=90;
    if(magnitude>=param.minLogMagnitude){
      il_summary=String.format("%2d-%2d %2d:%02d%6.1f??%5.1f?? %s%3.1f %3.0fkm ",
      dateTime.get(GregorianCalendar.MONTH)+1,dateTime.get(GregorianCalendar.DAY_OF_MONTH),
      dateTime.get(GregorianCalendar.HOUR_OF_DAY),dateTime.get(GregorianCalendar.MINUTE),
      longitude,latitude,unit,magnitude,depth);
      maxLogStrPxWidth=max(maxLogStrPxWidth,textWidth(il_summary));
    }
    il_strMag=String.format("%.1f",magnitude);
    il_fszMag=il_radius*0.6;
  }
  void CalcILPosY(){
    il_posY=(int)depthRectCalc.toScreenY(depth);
  }
  
  int il_posX,il_posY;
  int il_red,il_green,il_blue,il_alpha;
  float il_radius;
  float il_rotation;//?????????
  int il_frameLeft;
  String il_summary;
  String il_strMag;
  float il_fszMag;
}
ArrayList<EqEntry>eq;
int eqIndex=0,eqDismissIndex=0;
GregorianCalendar nowDateTime,endDateTime;
PFont fontBold,fontRegular;
float fszTime=48.0f,fszCounter=36.0f,fszLogStr=24.0f;
PImage bg;
PGraphics statLine,statLineShadow,statPoint,gridImage,bgGradient;
String[]weekString={"(???/Sun)","(???/Mon)","(???/Tue)","(???/Wed)","(???/Thu)","(???/Fri)","(???/Sat)"};
float statLineLeft=40.0f,statLineRight=1260.0f,statLineTop=40.0f,statLineBottom=700.0f;
float logStrLeft=580.0f,logStrRight=1260.0f,logStrBottom=700.0f;
long totalMinutes,totalFrames;
long elapsedMinutes=0;
float lastStatLineX,lastStatLineY;
int frameLeftStrTotalCount=600;
int yOffsetCounter=-4;
int timeShadowDistance=4;
int counterShadowDistance=3;
int logShadowDistance=3;
ArrayList<Integer>logStrIndices;

void setup(){
  size(1280,720);
  //pixelDensity(displayDensity());
  param=new Param();
  depthRectCalc=new DepthRectCalc();
  depthRectCalc.Init();
  //Load Map
  bg=loadImage(param.bgMap);
  bg.resize(pixelWidth,pixelHeight);
  //Create Graphics
  statLine=createGraphics(width,height);
  statLineShadow=createGraphics(width,height);
  statPoint=createGraphics(width,height);
  //Load Font
  fontBold=createFont("???????????? HW Bold",48.0f);
  fontRegular=createFont("???????????? HW",36.0f);
  //Load SFX
  sfx=new ArrayList<SoundFile>();
  eq=new ArrayList<EqEntry>();
  for(int i=0;;i++){
    String n=String.format("sfx%d.wav",i);
    InputStream iss=createInput(n);
    if(iss==null){
      break;
    }
    try{
      iss.close();
    }catch(IOException e){
      break;
    }
    SoundFile snd=new SoundFile(this,n);
    sfx.add(snd);
  }
  //Load Data
  textFont(fontRegular);
  textSize(fszLogStr);
  BufferedReader reader=createReader(param.dataSrc);
  String line;
  do{
    try{
      line=reader.readLine();
      if(line==null){
        reader.close();
      }else if(Character.isDigit(line.charAt(0))){
        EqEntry e=new EqEntry(line);
        if(depthRectCalc.wmBottom<e.depth){
          depthRectCalc.wmBottom=e.depth;
        }
        //if(e.magnitude>=param.minCircleMagnitude){
          eq.add(0,e);
        //}
      }
    }catch(IOException e){
      line=null;
    }
  }while(line!=null);
  println("???????????????????????????"+depthRectCalc.wmBottom);
  depthRectCalc.wmBottom=MinHundredGreaterThan(depthRectCalc.wmBottom);
  for(int i=0;i<eq.size();i++){
    eq.get(i).CalcILPosY();
  }
  //Set Date Time
  nowDateTime=new GregorianCalendar();
  endDateTime=new GregorianCalendar();
  SimpleDateFormat dateFormat=new SimpleDateFormat("yyyy/M/d");
  try{
    nowDateTime.setTime(dateFormat.parse(param.startDate));
    endDateTime.setTime(dateFormat.parse(param.endDate));
  }catch(ParseException e){
    println(e.getLocalizedMessage());
    noLoop();
  }
  totalMinutes=(endDateTime.getTime().getTime()-nowDateTime.getTime().getTime())/60/1000;
  totalFrames=totalMinutes/param.minutesPerFrame;
  println("????????????"+totalFrames+"???"+totalFrames/3600+"???"+(totalFrames/60)%60+"??????");
  println("??????????????????MOV??????????????????FFmpeg????????????????????????");
  println("ffmpeg -i video.mov -vf vflip video.mp4");
  logStrIndices=new ArrayList<Integer>();
  lastStatLineX=(int)(statLineLeft+(statLineRight-statLineLeft)*elapsedMinutes/totalMinutes);
  lastStatLineY=statLineBottom-(statLineBottom-statLineTop)*eqIndex/eq.size();
  gridImage=createGraphics(width,height);
  bgGradient=createGraphics(width,height);
  gridImage.beginDraw();
  gridImage.stroke(255,255,255,128);
  gridImage.strokeWeight(1);
  gridImage.textFont(fontRegular);
  gridImage.textAlign(RIGHT,BOTTOM);
  bgX1=depthRectCalc.toScreenX(depthRectCalc.wmLeft);
  bgX2=depthRectCalc.toScreenX(depthRectCalc.wmRight);
  bgBottom=depthRectCalc.toScreenY(0.0f);
  float tw;
  float ds[]={0.0f,10.0f,30.0f,70.0f,100.0f,200.0f,300.0f,400.0f,500.0f,600.0f,depthRectCalc.wmBottom};
  for(int i=0;i<ds.length;i++){
    float y=depthRectCalc.toScreenY(ds[i]);
    gridImage.line(bgX1,y,bgX2,y);
    gridImage.fill(40, 40, 40, 150);
    gridImage.text(String.format("%.0fkm",ds[i]),bgX2+logShadowDistance,y+logShadowDistance);
    gridImage.fill(255,255,255,255);
    gridImage.text(String.format("%.0fkm",ds[i]),bgX2,y);
  }
  tw=gridImage.textWidth("000km");
  gridImage.textFont(fontBold);
  gridImage.fill(255,255,255,80);
  gridImage.textAlign(LEFT,BOTTOM);
  gridImage.text("???\n???",0,height);
  gridImage.textAlign(RIGHT,BOTTOM);
  gridImage.text("???\n???",width-tw,height);
  gridImage.endDraw();
  bgGradient.beginDraw();
  bgGradient.colorMode(HSB,360,100,100);
  bgGradient.noStroke();
  for(float d=0.0f;d<depthRectCalc.wmBottom;d+=10.0f){
    float y1=depthRectCalc.toScreenY(d),y2=depthRectCalc.toScreenY(d+10.0f);
    bgGradient.fill(40*d/depthRectCalc.wmBottom,90,90*d/depthRectCalc.wmBottom);
    bgGradient.rect(bgX1,y1,bgX2,y2);
  }
  bgGradient.endDraw();
}

float bgX1,bgX2,bgBottom;

void draw(){
  clear();
  //image(bgGradient,0,0,width,height);
  image(bg,bgX1,0,bgX2,bgBottom);
  while(eqIndex<eq.size()&&eq.get(eqIndex).dateTime.before(nowDateTime)){
    EqEntry eqe=eq.get(eqIndex);
    //Add a eq point.
    if(param.showLogPoint&&eqe.magnitude>=param.minCircleMagnitude){//??????param.minCircleMagnitude???????????????????????????
        statPoint.beginDraw();
        statPoint.noStroke();
        statPoint.fill(color(240, 240, 12, 128));
        statPoint.circle(eqe.il_posX,eqe.il_posY,2);
        statPoint.endDraw();
    }
    if(param.showLogStr){
      if(eqe.magnitude>=param.minLogMagnitude){//????????????param.minLogMagnitude????????????
        logStrIndices.add(eqIndex);
        if(logStrIndices.size()>5){
          logStrIndices.remove(0);
        }
      }
    }
    //??????????????????????????????param.minCircleMagnitude??????
    if(eqe.magnitude>=param.minCircleMagnitude&&sfx.size()>0){
      sfx.get(0).play(1.0f-0.5f*eqe.il_rotation/90.0f,2.0f*eqe.il_posX/width-1.0f,min(200.0f,eqe.il_radius)/200.0f);
    }
    eqIndex++;
  }
  //???????????????
  if(param.showLogPoint){
    image(statPoint,0,0);
  }
  //??????????????????
  //strokeWeight(2.5f);
  //??????????????????
  for(int i=eqDismissIndex;i<eqIndex;i++){
    EqEntry eqe=eq.get(i);
    eqe.il_alpha=255*min(50,eqe.il_frameLeft)/50;
    if(eqe.magnitude<param.minCircleMagnitude){
      continue;//??????param.minCircleMagnitude???????????????????????????
    }
    //??????
    strokeWeight(4.0f);
    translate(eqe.il_posX,eqe.il_posY);
    stroke(0,0,0,eqe.il_alpha/1.7f);
    fill(eqe.il_red,eqe.il_green,eqe.il_blue,eqe.il_alpha*0.25f);
    circle(0,0,eqe.il_radius*2.0f);
    noFill();
    circle(1,1,eqe.il_radius*2.0f);
    rotate(radians(eqe.il_rotation));
    line(1,1,eqe.il_radius,0);
    resetMatrix();
    //??????
    translate(eqe.il_posX,eqe.il_posY);
    stroke(255,255,255,eqe.il_alpha);
    circle(0,0,eqe.il_radius*2.0f);
    rotate(radians(eqe.il_rotation));
    line(0,0,eqe.il_radius,0);
    resetMatrix();
    //?????????
    strokeWeight(2.5f);
    translate(eqe.il_posX,eqe.il_posY);
    stroke(eqe.il_red,eqe.il_green,eqe.il_blue,eqe.il_alpha);
    circle(0,0,eqe.il_radius*2.0f);
    rotate(radians(eqe.il_rotation));
    line(0,0,eqe.il_radius,0);
    resetMatrix();
    noStroke();
    //fill(240,240,12,eqe.il_alpha);
    //circle(eqe.il_posX,eqe.il_posY,4);
  }
  //??????????????????
  textFont(fontBold);
  textAlign(CENTER,BASELINE);
  for(float magLow=0.0f;magLow<=9.75f;magLow+=0.25f){
    for(int i=eqDismissIndex;i<eqIndex;i++){
      EqEntry eqe=eq.get(i);
      if(eqe.magnitude>=magLow&&eqe.magnitude<magLow+0.25f){
        eqe.il_frameLeft-=10;
        if(eqe.il_frameLeft<=0){
          eqDismissIndex++;
        }
        if(eqe.magnitude<param.minCircleDigitMagnitude){
          continue;//??????param.minCircleDigitMagnitude???????????????????????????
        }
        textSize(eqe.il_fszMag);
        fill(32,32,6,eqe.il_alpha);
        text(eqe.il_strMag,eqe.il_posX+2,eqe.il_posY+2);
        fill(240,240,12,eqe.il_alpha);
        text(eqe.il_strMag,eqe.il_posX,eqe.il_posY);
      }
    }
  }
  image(gridImage,0,0);
  textAlign(LEFT,BASELINE);
  //?????????????????????
  textFont(fontBold);
  textSize(fszTime);
  String timeStr=String.format("?????? (Depth) %d???%2d???%2d??? %2d:%02d%s",
    nowDateTime.get(GregorianCalendar.YEAR),
    nowDateTime.get(GregorianCalendar.MONTH)+1,
    nowDateTime.get(GregorianCalendar.DAY_OF_MONTH),
    nowDateTime.get(GregorianCalendar.HOUR_OF_DAY),
    nowDateTime.get(GregorianCalendar.MINUTE),
    param.timeZoneDesc);
  fill(40, 40, 40, 150);
  text(timeStr,30+timeShadowDistance,60+timeShadowDistance);
  fill(255, 255, 255, 255);
  text(timeStr,30,60);
  if(frameCount>60&&endDateTime.after(nowDateTime)){
    nowDateTime.add(GregorianCalendar.MINUTE,param.minutesPerFrame);
    if(nowDateTime.after(endDateTime)){
      nowDateTime=endDateTime;
    }
    elapsedMinutes+=param.minutesPerFrame;
  }  
  if(frameCount%60==0){
    surface.setTitle(String.format("FPS: %.1f",frameRate));
  }
  if(param.recordMode&&frameCount<totalFrames+300){
    saveFrame("frames/f-#####.tga");
  }
  if(frameCount==totalFrames+300){
    println("???????????????");
  }
}
