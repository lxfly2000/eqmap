#include <vector>
#include <algorithm>
#include <fstream>

#ifdef min
#undef min
#endif

#define PI 3.141592653545

struct WaveStructure
{
	char strRIFF[4];
	int chunkSize;
	char strFormat[4];
	char strFmt[4];
	int subchunk1Size;
	short audioFormat;
	short numChannels;
	int sampleRate;
	int byteRate;
	short blockAlign;
	short bpsample;//Bits per sample
	char strData[4];
	int subchunk2Size;//Data size（字节数）
};

class AudioSample
{
public:
	AudioSample(int channels, int hz) :m_bit(16), m_smpPos(0)
	{
		m_channels = channels;
		m_hz = hz;
	}

	AudioSample(const char* filePath) :AudioSample(0, 0)
	{
		std::ifstream f(filePath, std::ios::binary);
		WaveStructure w;
		f.read((char*)&w, sizeof(WaveStructure));
		m_channels = w.numChannels;
		m_hz = w.sampleRate;
		Resize(w.subchunk2Size / w.numChannels / (w.bpsample / 8));
		for (int j = 0; j < buffer[0].size(); j++)
		{
			for (int i = 0; i < m_channels; i++)
				f.read((char*)&buffer[i][j], w.bpsample / 8);
		}
	}

	void Resize(int samples)
	{
		for (int i = 0; i < std::min(2, m_channels); i++)
			buffer[i].resize(samples);
	}

	AudioSample* Seek(int sample)
	{
		m_smpPos = std::min((int)buffer[0].size(), sample);
		return this;
	}

	AudioSample* Mix(AudioSample* src)
	{
		//https://blog.csdn.net/zwz1984/article/details/50395053
		for (int j = 0; j < std::min(src->GetSampleLength(), (int)buffer[0].size() - m_smpPos); j++)
		{
			for (int i = 0; i < std::min(2, m_channels); i++)
			{
				int data1 = buffer[i][m_smpPos + j];
				int data2 = src->GetSample(i, j);
				if (data1 < 0 && data2 < 0)
					buffer[i][m_smpPos + j] = data1 + data2 - (data1 * data2 / -(pow(2, 16 - 1) - 1));
				else
					buffer[i][m_smpPos + j] = data1 + data2 - (data1 * data2 / (pow(2, 16 - 1) - 1));
			}
		}
		return this;
	}

	int SaveToFile(const char* path)
	{
		WaveStructure wavfileheader =
		{
			'R', 'I', 'F', 'F',//strRIFF
			0,//chunkSize，待计算，等于36+subchunk2Size
			'W', 'A', 'V', 'E',//strFormat
			'f', 'm', 't', ' ',//strFmt
			16,//subchunk1Size
			WAVE_FORMAT_PCM,//audioFormat
			(short)m_channels,//numChannels
			m_hz,//sampleRate
			m_hz * m_channels * (m_bit / 8),//byteRate
			(short)(m_channels * (m_bit / 8)),//blockAlign
			(short)m_bit,//bpsample
			'd', 'a', 't', 'a',//strData
			0//subchunk2Size，待计算
		};
		wavfileheader.subchunk2Size = buffer[0].size() * sizeof(buffer[0][0]) + buffer[1].size() * sizeof(buffer[1][0]);
		wavfileheader.chunkSize = 36 + wavfileheader.subchunk2Size;
		std::ofstream f(path, std::ios::binary);
		f.write((char*)&wavfileheader, sizeof(WaveStructure));
		for (int j = 0; j < buffer[0].size(); j++)
		{
			for (int i = 0; i < m_channels; i++)
				f.write((char*)&buffer[i][j], wavfileheader.bpsample / 8);
		}
		return 0;
	}
	//[-1.0f, 1.0f]
	AudioSample* Pan(float p)
	{
		//https://dsp.stackexchange.com/questions/21691/algorithm-to-pan-audio
		float angle = p * PI / 4;
		float ampA = sqrtf(2.0f) / 2 * (cosf(angle) - sinf(angle));//left
		float ampB = sqrtf(2.0f) / 2 * (cosf(angle) + sinf(angle));//right
		for (int i = 0; i < buffer[0].size(); i++)
		{
			if (m_channels == 1)
				buffer[1].push_back(buffer[0][i] * ampB);
			else
				buffer[1][i] *= ampB;
			buffer[0][i] *= ampA;
		}
		m_channels = 2;
		return this;
	}
	//[0.0f, 1.0f]
	AudioSample* Volume(float v)
	{
		for (int j = 0; j < std::min(2, m_channels); j++)
		{
			for (int i = 0; i < buffer[j].size(); i++)
				buffer[j][i] = (short)(buffer[j][i] * v);
		}
		return this;
	}
	//(0.0f, +UNLMT]
	AudioSample* Speed(float v)
	{
		int oldSize = buffer[0].size();
		int insertSize = (int)(oldSize / v);
		for (int i = 0; i < insertSize; i++)
		{
			float oldI = i * v;
			for (int j = 0; j < std::min(2, m_channels); j++)
			{
				float ceilI = ceilf(oldI);
				float floorI = floorf(oldI);
				if (ceilI == floorI)
					buffer[j].push_back(buffer[j][oldI]);
				else
					//https://stackoverflow.com/questions/44818752/programmatically-change-the-speed-of-an-audio-file-in-real-time
					buffer[j].push_back((oldI - floorI) * (buffer[j][ceilI] - buffer[j][floorI]) / (ceilI - floorI) + buffer[j][floorI]);
			}
		}
		for (int i = 0; i < std::min(2, m_channels); i++)
			buffer[i].erase(buffer[i].begin(), buffer[i].begin() + oldSize);
		return this;
	}

	int GetSampleLength()
	{
		return (int)buffer[0].size();
	}

	short GetSample(int channel, int sample)
	{
		return buffer[std::min(1, channel)][sample];
	}

	int GetChannelCount()
	{
		return m_channels;
	}

	int GetHz()
	{
		return m_hz;
	}
private:
	std::vector<short>buffer[2];
	int m_channels, m_hz, m_bit;
	int m_smpPos;
};
