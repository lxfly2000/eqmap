::ָ��FFmpeg����λ��
set FFMPEG_PATH=E:\ffmpeg-4.4-full_build
path %path%;%FFMPEG_PATH%\bin
::��һ��ͼƬΪ3�룬����ͼƬΪ5�룬���һ��ͼƬǰ��0.2�뵭��
ffmpeg -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 -loop 1 -f image2 -i Captions\frames\f-0.png -r 60 -t 3 -shortest cap0.mp4
ffmpeg -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 -loop 1 -f image2 -i Captions\frames\f-1.png -r 60 -t 5 -shortest cap1.mp4
ffmpeg -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 -loop 1 -f image2 -i Captions\frames\f-2.png -r 60 -t 5 -shortest cap2.mp4
::���һ��ͼƬҪ0.2��ĵ���
ffmpeg -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 -loop 1 -f image2 -i Captions\frames\f-3.png -r 60 -t 5 -shortest -vf fade=in:0:12 cap3.mp4
::�����������Ҫ��ת��Ƶ��
ffmpeg -f image2 -framerate 60 -i eqmap_processing\frames\f-%%05d.tga -i SDLEqMap\audio.wav -shortest -af apad eqmap.mp4
::ƴ����Ƶ
(echo file 'cap0.mp4'&echo file 'cap1.mp4'&echo file 'cap2.mp4'&echo file 'eqmap.mp4'&echo file 'cap3.mp4')>list.txt
ffmpeg -f concat -safe 0 -i list.txt -vcodec libx264 -preset veryslow -profile:v high -level:v 4.1 -pix_fmt yuv420p out.mp4
del list.txt
del cap*.mp4
del eqmap.mp4
