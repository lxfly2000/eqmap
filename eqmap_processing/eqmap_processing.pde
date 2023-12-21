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
  float minLogIntensity;
  Param(){
    JSONObject json=loadJSONObject("eq.json");
    bgMap=json.getString("bgMap","bg.png");
    dataSrc=json.getString("dataSrc","eqdata.csv");
    minutesPerFrame=json.getInt("minutesPerFrame",180);
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
    minLogIntensity=json.getFloat("minLogIntensity",7.0f);
    recordMode=json.getBoolean("recordMode",false);
  }
}
Param param;

//Program Data
class WebMercatorCalc{
  float wmLeft,wmTop,wmRight,wmBottom;
  boolean crossDate;
  void Init(){
    if(param.endLongitude<param.startLongitude){
      crossDate=true;
      param.endLongitude+=360.0f;
    }else{
      crossDate=false;
    }
    wmLeft=(float)WebMercator.longitudeToX(param.startLongitude);
    wmTop=(float)WebMercator.latitudeToY(param.endLatitude);
    wmRight=(float)WebMercator.longitudeToX(param.endLongitude);
    wmBottom=(float)WebMercator.latitudeToY(param.startLatitude);
  }
  float toScreenX(float longitude){
    if(crossDate&&longitude<0.0f){
      longitude+=360.0f;
    }
    return (float)(WebMercator.longitudeToX(longitude)-wmLeft)*width/(wmRight-wmLeft);
  }
  float toScreenY(float latitude){
    return (float)(WebMercator.latitudeToY(latitude)-wmTop)*height/(wmBottom-wmTop);
  }
};
WebMercatorCalc webMercatorCalc;
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
  int intensity;
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
    intensity=calcMaxInt(magnitude,depth);
    
    il_posX=(int)webMercatorCalc.toScreenX(longitude);
    il_posY=(int)webMercatorCalc.toScreenY(latitude);
    il_radius=3.54f*exp(0.45f*magnitude);
    il_rotation=0.38f*sqrt(80.0f*depth);
    il_alpha=255;
    il_red=(int)(255.0f*exp(depth*(-0.02f)));
    il_green=(int)(16.0f*exp(depth*(-0.02f)));
    il_blue=(int)(8.0f*exp(depth*(-0.02f)));
    il_frameLeft=90;
    if(magnitude>=param.minLogMagnitude||intensity>=param.minLogIntensity){
      il_summary=String.format("%2d-%2d %2d:%02d%6.1f°%5.1f° %s%3.1f %3.0f㎞ %s ",
      dateTime.get(GregorianCalendar.MONTH)+1,dateTime.get(GregorianCalendar.DAY_OF_MONTH),
      dateTime.get(GregorianCalendar.HOUR_OF_DAY),dateTime.get(GregorianCalendar.MINUTE),
      longitude,latitude,unit,magnitude,depth,calcMaxIntStr(intensity));
      maxLogStrPxWidth=max(maxLogStrPxWidth,textWidth(il_summary));
    }
    il_strMag=String.format("%.1f",magnitude);
    il_fszMag=il_radius*0.6;
  }
  
  int il_posX,il_posY;
  int il_red,il_green,il_blue,il_alpha;
  float il_radius;
  float il_rotation;//角度制
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
PGraphics statLine,statLineShadow,statPoint;
String[]weekString={"(日/Sun)","(一/Mon)","(二/Tue)","(三/Wed)","(四/Thu)","(五/Fri)","(六/Sat)"};
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
final float logStrSlideVY=1.0f;
float logStrHeaderBottomToY;
float logStrHeaderBottomCurrentY;
final int maxLogStrIndices=5;
ArrayList<Float>logStrEntryY;
final float clipYOffset=2.0f;

int calcMaxInt(double magnitude, double depth){
  double a = 1.65 * magnitude;
  double b = depth < 10 ? 1.21 * Math.log10(10) : 1.21 * Math.log10(depth);
  return Math.min(Math.max(0,(int)Math.round(a / b)),12);
}

String calcMaxIntStr(int index){
  String[]strInt={"０","１","２","３","４","５","６","７","８","９","10","11","12"};
  return strInt[index];
}

void setup(){
  size(1280,720);
  //pixelDensity(displayDensity());
  param=new Param();
  webMercatorCalc=new WebMercatorCalc();
  webMercatorCalc.Init();
  //Load Map
  bg=loadImage(param.bgMap);
  bg.resize(pixelWidth,pixelHeight);
  //Create Graphics
  statLine=createGraphics(width,height);
  statLineShadow=createGraphics(width,height);
  statPoint=createGraphics(width,height);
  //Load Font
  fontBold=createFont("sarasa-mono-sc-bold.ttf",48.0f);
  fontRegular=createFont("sarasa-mono-sc-regular.ttf",36.0f);
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
        //if(e.magnitude>=param.minCircleMagnitude){
          eq.add(0,e);
        //}
      }
    }catch(IOException e){
      line=null;
    }
  }while(line!=null);
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
  println("总帧数："+totalFrames+"（"+totalFrames/3600+"分"+(totalFrames/60)%60+"秒）");
  println("注意：导出的MOV视频需要经过FFmpeg做一次翻转处理！");
  println("ffmpeg -i video.mov -vf vflip video.mp4");
  logStrIndices=new ArrayList<Integer>();
  logStrEntryY=new ArrayList<Float>();
  lastStatLineX=(int)(statLineLeft+(statLineRight-statLineLeft)*elapsedMinutes/totalMinutes);
  lastStatLineY=statLineBottom-(statLineBottom-statLineTop)*eqIndex/eq.size();
  logStrHeaderBottomCurrentY=logStrHeaderBottomToY=logStrBottom;
}

void draw(){
  background(bg);
  while(eqIndex<eq.size()&&eq.get(eqIndex).dateTime.before(nowDateTime)){
    EqEntry eqe=eq.get(eqIndex);
  	//Add a eq point.
  	if(param.showLogPoint&&eqe.magnitude>=param.minCircleMagnitude){//小于param.minCircleMagnitude级的就没必要显示了
        statPoint.beginDraw();
        statPoint.noStroke();
        statPoint.fill(color(240, 240, 12, 128));
        statPoint.circle(eqe.il_posX,eqe.il_posY,2);
        statPoint.endDraw();
  	}
    if(param.showLogStr){
      if(eqe.magnitude>=param.minLogMagnitude||eqe.intensity>=param.minLogIntensity){//显示大于param.minLogMagnitude级的记录
        logStrIndices.add(eqIndex);
        if(logStrEntryY.size()==0){
          logStrEntryY.add(logStrBottom+fszLogStr);
        }else{
          logStrEntryY.add(logStrEntryY.get(logStrEntryY.size()-1)+fszLogStr);
        }
        logStrHeaderBottomToY=logStrBottom-Math.min(maxLogStrIndices,logStrIndices.size())*fszLogStr;
      }
    }
    //播放声音，只播放大于param.minCircleMagnitude级的
    if(eqe.magnitude>=param.minCircleMagnitude&&sfx.size()>0){
      sfx.get(0).play(1.0f-0.5f*eqe.il_rotation/90.0f,2.0f*eqe.il_posX/width-1.0f,min(200.0f,eqe.il_radius)/200.0f);
    }
    eqIndex++;
  }
  //显示记录点
  if(param.showLogPoint){
    image(statPoint,0,0);
  }
  //显示记录曲线
  float slx=statLineLeft+(statLineRight-statLineLeft)*elapsedMinutes/totalMinutes;
  float sly=statLineBottom-(statLineBottom-statLineTop)*eqIndex/eq.size();
  statLine.beginDraw();
  statLine.stroke(color(240, 240, 12, 128));
  statLine.strokeWeight(2);
  statLine.line(lastStatLineX,lastStatLineY,slx,sly);
  statLine.endDraw();
  statLineShadow.beginDraw();
  statLineShadow.stroke(color(32, 32, 6, 128));
  statLineShadow.strokeWeight(2);
  statLineShadow.line(lastStatLineX,lastStatLineY,slx,sly);
  statLineShadow.endDraw();
  //下面两句挪到圆圈图形与文字之间的部分去了
  //image(statLineShadow,2,2);
  //image(statLine,0,0);
  lastStatLineX=slx;
  lastStatLineY=sly;
  //显示圆圈图示
  //strokeWeight(2.5f);
  //……图形部分
  for(int i=eqDismissIndex;i<eqIndex;i++){
    EqEntry eqe=eq.get(i);
    eqe.il_alpha=255*min(50,eqe.il_frameLeft)/50;
    if(eqe.magnitude<param.minCircleMagnitude){
      continue;//小于param.minCircleMagnitude级的就没必要显示了
    }
    //阴影
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
    //描边
    translate(eqe.il_posX,eqe.il_posY);
    stroke(255,255,255,eqe.il_alpha);
    circle(0,0,eqe.il_radius*2.0f);
    rotate(radians(eqe.il_rotation));
    line(0,0,eqe.il_radius,0);
    resetMatrix();
    //主图示
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
  image(statLineShadow,2,2);
  image(statLine,0,0);
  //……文字部分
  textFont(fontBold);
  textAlign(CENTER,BASELINE);
  for(float magLow=0.0f;magLow<=9.75f;magLow+=0.25f){
    for(int i=eqDismissIndex;i<eqIndex;i++){
      EqEntry eqe=eq.get(i);
      if(eqe.magnitude>=magLow&&eqe.magnitude<magLow+0.25f){
        eqe.il_frameLeft--;
        if(eqe.il_frameLeft<=0){
          eqDismissIndex++;
        }
        if(eqe.magnitude<param.minCircleDigitMagnitude){
          continue;//小于param.minCircleDigitMagnitude级的就没必要显示了
        }
        textSize(eqe.il_fszMag);
        fill(32,32,6,eqe.il_alpha);
        text(eqe.il_strMag,eqe.il_posX+2,eqe.il_posY+2);
        fill(240,240,12,eqe.il_alpha);
        text(eqe.il_strMag,eqe.il_posX,eqe.il_posY);
      }
    }
  }
  textAlign(LEFT,BASELINE);
  //显示左上角时间
  textFont(fontBold);
  textSize(fszTime);
  String timeStr=String.format("%d年%2d月%2d日%s\n%2d:%02d%s",
    nowDateTime.get(GregorianCalendar.YEAR),
    nowDateTime.get(GregorianCalendar.MONTH)+1,
    nowDateTime.get(GregorianCalendar.DAY_OF_MONTH),
    weekString[nowDateTime.get(GregorianCalendar.DAY_OF_WEEK)-1],
    nowDateTime.get(GregorianCalendar.HOUR_OF_DAY),
    nowDateTime.get(GregorianCalendar.MINUTE),
    param.timeZoneDesc);
  fill(40, 40, 40, 150);
  text(timeStr,30+timeShadowDistance,60+timeShadowDistance);
  fill(255, 255, 255, 255);
  text(timeStr,30,60);
  //显示右下角记录
  textFont(fontRegular);
  if(param.showLogStr){
    textSize(fszLogStr);
    for(int i=0;i<logStrIndices.size();i++){
      float y=logStrEntryY.get(i);
      EqEntry eqe=eq.get(logStrIndices.get(i));
      fill(40,40,40,150);
      clip(0,logStrBottom-maxLogStrIndices*fszLogStr+logShadowDistance+clipYOffset,width,maxLogStrIndices*fszLogStr);
      text(eqe.il_summary,logStrLeft+logShadowDistance,y+logShadowDistance);
      float strWidth=textWidth(eqe.il_summary);
      float locationWidth=textWidth(eqe.location);
      float spareWidth=logStrRight-logStrLeft-strWidth;
      float scaleWidth=spareWidth/locationWidth;
      if(locationWidth<=spareWidth){
        text(eqe.location,logStrLeft+strWidth+logShadowDistance,y+logShadowDistance);
      }else{
        translate(logStrLeft+strWidth+logShadowDistance,y+logShadowDistance);
        scale(scaleWidth,1.0f);
        text(eqe.location,0,0);
        resetMatrix();
      }
      fill(255,255,255,255);
      clip(0,logStrBottom-maxLogStrIndices*fszLogStr+clipYOffset,width,maxLogStrIndices*fszLogStr);
      text(eqe.il_summary,logStrLeft,y);
      if(locationWidth<=spareWidth){
        text(eqe.location,logStrLeft+strWidth,y);
      }else{
        translate(logStrLeft+strWidth,y);
        scale(scaleWidth,1.0f);
        text(eqe.location,0,0);
        resetMatrix();
      }
      noClip();
    }
  }
  //显示记录曲线上的数字
  textSize(fszCounter);
  String strCounter=String.valueOf(eqIndex);
  textAlign(RIGHT);
  fill(40,40,40,150);
  text(strCounter,slx,sly+yOffsetCounter);
  fill(255,255,255,255);
  text(strCounter,slx-counterShadowDistance,sly-counterShadowDistance+yOffsetCounter);
  textAlign(LEFT);
  if(frameCount>60&&endDateTime.after(nowDateTime)){
    nowDateTime.add(GregorianCalendar.MINUTE,param.minutesPerFrame);
    if(nowDateTime.after(endDateTime)){
      nowDateTime=endDateTime;
    }
    elapsedMinutes+=param.minutesPerFrame;
    if(frameLeftStrTotalCount>0){
      String strTotalCount="(地震计数/TotalCount)";
      fill(40,40,40,150*min(frameLeftStrTotalCount,60)/60);
      text(strTotalCount,slx,sly+yOffsetCounter);
      fill(255,255,255,255*min(frameLeftStrTotalCount,60)/60);
      text(strTotalCount,slx-counterShadowDistance,sly-counterShadowDistance+yOffsetCounter);
      frameLeftStrTotalCount--;
      //右下角表头
      if(param.showLogStr){
        textSize(fszLogStr);
        String hdrElements[]={"00-00","00:00","000.0°","00.0°","Ms0.0","000km","0000",""};
        String hdrCN[]={"日期","时间","经度","纬度","震级","深度","烈度","地点"};
        String hdrEN[]={"DATE","TIME","LONGITUDE","LATITUDE","MAGNITUDE","DEPTH","SCALE","LOCATION"};
        //y值，左起点为logStrLeft,阴影距为logShadowDistance
        float yCN=logStrHeaderBottomCurrentY-fszLogStr;
        float yEN=logStrHeaderBottomCurrentY;
        float curLeft=logStrLeft;
        for(int i=0;i<hdrElements.length;i++){
          textAlign(i+1==hdrElements.length?LEFT:CENTER,BASELINE);
          float hdrWidth=textWidth(hdrElements[i]);
          //中文阴影
          fill(40,40,40,150*min(frameLeftStrTotalCount,60)/60);
          text(hdrCN[i],curLeft+hdrWidth/2+logShadowDistance,yCN+logShadowDistance);
          //中文主字
          fill(255,255,255,255*min(frameLeftStrTotalCount,60)/60);
          text(hdrCN[i],curLeft+hdrWidth/2,yCN);
          float enHdrWidth=textWidth(hdrEN[i]);
          if(enHdrWidth>hdrWidth&&i+1<hdrElements.length){
            translate(curLeft+hdrWidth/2,yEN);
            scale(hdrWidth/enHdrWidth,1.0f);
            //英文阴影
            fill(40,40,40,150*min(frameLeftStrTotalCount,60)/60);
            text(hdrEN[i],logShadowDistance,logShadowDistance);
            //英文主字
            fill(255,255,255,255*min(frameLeftStrTotalCount,60)/60);
            text(hdrEN[i],0,0);
            resetMatrix();
          }else{
            //英文阴影
            fill(40,40,40,150*min(frameLeftStrTotalCount,60)/60);
            text(hdrEN[i],curLeft+hdrWidth/2+logShadowDistance,yEN+logShadowDistance);
            //英文主字
            fill(255,255,255,255*min(frameLeftStrTotalCount,60)/60);
            text(hdrEN[i],curLeft+hdrWidth/2,yEN);
          }
          curLeft+=hdrWidth+textWidth(" ");
        }
      }
    }
  }
  //右下角记录滚动
  if(logStrEntryY.size()>0){
    float dy=logStrSlideVY*Math.min(3.0f,(float)Math.ceil((logStrEntryY.get(logStrEntryY.size()-1)-logStrBottom)/fszLogStr));//Math.min(logStrSlideVY,logStrEntryY.get(logStrEntryY.size()-1)-logStrBottom);
    if(logStrHeaderBottomCurrentY>logStrHeaderBottomToY){
      logStrHeaderBottomCurrentY-=dy;
    }
    if(logStrEntryY.get(logStrEntryY.size()-1)>logStrBottom){
      for(int i=0;i<logStrEntryY.size();i++){
        logStrEntryY.set(i,logStrEntryY.get(i)-dy);
      }
      if(logStrEntryY.get(0)<=logStrBottom-fszLogStr*maxLogStrIndices){
        logStrIndices.remove(0);
        logStrEntryY.remove(0);
      }
    }
  }
  if(frameCount%60==0){
    surface.setTitle(String.format("FPS: %.1f logStrEntryY:%d logStrIndices:%d",frameRate,logStrEntryY.size(),logStrIndices.size()));
  }
  if(param.recordMode&&frameCount<totalFrames+300){
    saveFrame("frames/f-#####.tga");
  }
  if(frameCount==totalFrames+300){
    println("播放完毕。");
  }
}
