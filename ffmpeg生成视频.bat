::ָ��FFmpeg����λ��
set FFMPEG_PATH=D:\ffmpeg-master-latest-win64-gpl-shared
path %path%;%FFMPEG_PATH%\bin
::��һ��ͼƬΪ3�룬����ͼƬΪ5�룬���һ��ͼƬǰ��0.2�뵭��
ffmpeg -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 -loop 1 -f image2 -i Captions\frames\f-0.png -r 60 -t 3 -shortest cap0.mp4
ffmpeg -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 -loop 1 -f image2 -i Captions\frames\f-1.png -r 60 -t 5 -shortest cap1.mp4
::�����2������������Ƶ
LegendSound\LegendSound SDLEqMap\sfx0.wav
if not exist cap2_tmp md cap2_tmp
::��f-2����60��
for /l %%i in (0,1,59) do @copy Captions\frames\f-2.png cap2_tmp\%%i.png
::��f-3��7����15��
for /l %%i in (60,1,74) do @copy Captions\frames\f-3.png cap2_tmp\%%i.png
for /l %%i in (75,1,89) do @copy Captions\frames\f-4.png cap2_tmp\%%i.png
for /l %%i in (90,1,104) do @copy Captions\frames\f-5.png cap2_tmp\%%i.png
for /l %%i in (105,1,119) do @copy Captions\frames\f-6.png cap2_tmp\%%i.png
for /l %%i in (120,1,134) do @copy Captions\frames\f-7.png cap2_tmp\%%i.png
::f-2����45��
for /l %%i in (135,1,179) do @copy Captions\frames\f-2.png cap2_tmp\%%i.png
::��f-8��12����15��
for /l %%i in (180,1,194) do @copy Captions\frames\f-8.png cap2_tmp\%%i.png
for /l %%i in (195,1,209) do @copy Captions\frames\f-9.png cap2_tmp\%%i.png
for /l %%i in (210,1,224) do @copy Captions\frames\f-10.png cap2_tmp\%%i.png
for /l %%i in (225,1,239) do @copy Captions\frames\f-11.png cap2_tmp\%%i.png
for /l %%i in (240,1,254) do @copy Captions\frames\f-12.png cap2_tmp\%%i.png
::f-2����45��
for /l %%i in (255,1,299) do @copy Captions\frames\f-2.png cap2_tmp\%%i.png
::����Ƶƴ��
ffmpeg -f image2 -framerate 60 -i cap2_tmp\%%d.png -i legend.wav -shortest -af apad cap2.mp4
::���һ��ͼƬҪ0.2��ĵ���
ffmpeg -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 -loop 1 -f image2 -i Captions\frames\f-13.png -r 60 -t 5 -shortest -vf fade=in:0:12 cap3.mp4
::�����������Ҫ��ת��Ƶ��
ffmpeg -f image2 -framerate 60 -i eqmap_processing\frames\f-%%05d.tga -i SDLEqMap\audio.wav -shortest -af apad eqmap.mp4
ffmpeg -f image2 -framerate 60 -i depth\frames\f-%%05d.tga -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 -shortest depth.mp4
::ƴ����Ƶ
echo file 'cap0.mp4'>list.txt
echo file 'cap1.mp4'>>list.txt
echo file 'cap2.mp4'>>list.txt
echo file 'eqmap.mp4'>>list.txt
echo file 'depth.mp4'>>list.txt
echo file 'cap3.mp4'>>list.txt
ffmpeg -f concat -safe 0 -i list.txt -vcodec libx264 -preset veryslow -profile:v high -level:v 4.1 -pix_fmt yuv420p out.mp4
rd /s /q cap2_tmp
del list.txt
del legend.wav
del cap*.mp4
del eqmap.mp4
del depth.mp4
