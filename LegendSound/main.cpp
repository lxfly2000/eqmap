#include <iostream>
#include <algorithm>

#include <Windows.h>
#include "AudioSample.hpp"

int main(int argc,char *argv[])
{
	if (argc < 2)
	{
		puts("Usage: LegendSound <Wave File>");
		return 1;
	}
	AudioSample sfx(argv[1]), am(2, 44100);
	am.Resize(44100 * 5);
	float depth[] = { 10.0f,50.0f,100.0f,300.0f,500.0f };
	float mag[] = { 3.0f,4.0f,5.0f,7.0f,8.7f };
	for (int i = 0; i < 5; i++)
	{
		int magCur = 44100 + 44100 / 4 * i;
		AudioSample smp = sfx;
		smp.Pan(0.25f * i);
		smp.Volume(std::min(200.0f, 3.54f * exp(0.45f * mag[i])) / 200.0f);
		smp.Speed(1.0f);
		am.Seek(magCur);
		am.Mix(&smp);
	}
	for (int i = 0; i < 5; i++)
	{
		int depCur = 44100 * 3 + 44100 / 4 * i;
		AudioSample smp = sfx;
		smp.Pan(0.25f * i);
		smp.Volume(std::min(200.0f, 3.54f * exp(0.45f * mag[3])) / 200.0f);
		smp.Speed(1.0f - 0.5f * 0.38f * sqrtf(80.0f * depth[i]) / 90.0f);
		am.Seek(depCur);
		am.Mix(&smp);
	}
	am.SaveToFile("legend.wav");
	puts("Wrote to legend.wav.");
	return 0;
}
