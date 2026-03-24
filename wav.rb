# Raw wav renderer
# https://ccrma.stanford.edu/courses/422-winter-2014/projects/WaveFormat

MIN_V = -32768
MAX_V = 32767

def render_stereo_16(samples)
  render(2, 44100, 16, samples)
end

def render(channels, sample_rate, bits_per_sample, samples=[])
  chunk_id = hexbytes([0x52, 0x49, 0x46, 0x46]) # "RIFF"
  chunk_size = le4bytes(36 + subchunk2size(samples.count, channels, bits_per_sample))
  fmt = hexbytes([0x57, 0x41, 0x56, 0x45]) # "WAVE"
  subchunk1_id = hexbytes([0x66, 0x6d, 0x74, 0x20]) # "fmt "
  subchunk1_size = le4bytes(16)
  audio_format = le2bytes(1) # PCM
  num_channels = le2bytes(channels)
  sample_rt = le4bytes(sample_rate)
  byte_rate = le4bytes(byterate(sample_rate, channels, bits_per_sample))
  block_align = le2bytes(blockalign(channels, bits_per_sample))
  bps = le2bytes(bits_per_sample)
  subchunk2_id = hexbytes([0x64, 0x61, 0x74, 0x61]) # "data"
  subchunk2_size = le4bytes(subchunk2size(samples.count, channels, bits_per_sample))

  File.open("out.wav", "wb") do |file|
    [
      chunk_id,
      chunk_size,
      fmt,
      subchunk1_id,
      subchunk1_size,
      audio_format,
      num_channels,
      sample_rt,
      byte_rate,
      block_align,
      bps,
      subchunk2_id,
      subchunk2_size
    ].each do |field|
      file.write(field)
    end

    # naively render the samples, assuming 2 ch 16 bit little endian
    samples.each do |sample|
      file.write(le2bytes(sample.first)) # left channel
      file.write(le2bytes(sample.last)) # right channel
    end
  end
end

def subchunk2size(num_samples, channels, bits_per_sample)
  return num_samples * channels * bits_per_sample / 8
end

def byterate(sample_rate, channels, bits_per_sample)
  return sample_rate * channels * bits_per_sample / 8
end

def blockalign(channels, bits_per_sample)
  return channels * bits_per_sample / 8
end

def hexbytes(hex_arr)
  return hex_arr.pack("C*")
end

def le4bytes(int)
  return [int].pack('V')
end

def le2bytes(int)
  return [int].pack('v')
end

def make_sine(frequency, time, rate)
  num_samples = (time.to_f * rate.to_f).round
  return num_samples.times.map { |s|
    (MAX_V.to_f * Math.sin(frequency.to_f * (1.0/rate.to_f) * (2.0 * Math::PI * s.to_f))).round
  }
end

def make_sine_stereo(frequency, time, rate)
  smp = make_sine(frequency, time, rate)
  return smp.map { |s|
    [s, s]
  }
end

########### SOUNDS

ONE_SEC_RANDOM = 44100.times.map { |t|
  [rand(MIN_V..MAX_V), rand(MIN_V..MAX_V)]
}

ONE_SEC_A = make_sine_stereo(440, 1, 44100)


C4 = 261.63
CS4 = 277.18
D4 = 293.66
DS4 = 311.13
E4 = 329.63
F4 = 349.23
FS4 = 369.99
G4 = 392.00
GS4 = 415.30
A4 = 440.00
AS4 = 466.16
B4 = 493.88
C5 = 523.25
CS5 = 554.37
D5 = 587.33


HBD1 = make_sine_stereo(D4, 0.3, 44100)
HBD2 = make_sine_stereo(D4, 0.25, 44100)
HBD3 = make_sine_stereo(E4, 0.5, 44100)
HBD4 = make_sine_stereo(D4, 0.5, 44100)
HBD5 = make_sine_stereo(G4, 0.5, 44100)
HBD6 = make_sine_stereo(FS4, 1, 44100)

HBD7 = make_sine_stereo(D4, 0.3, 44100)
HBD8 = make_sine_stereo(D4, 0.25, 44100)
HBD9 = make_sine_stereo(E4, 0.5, 44100)
HBD10 = make_sine_stereo(D4, 0.5, 44100)
HBD11 = make_sine_stereo(A4, 0.5, 44100)
HBD12 = make_sine_stereo(G4, 1, 44100)

HBD13 = make_sine_stereo(D4, 0.3, 44100)
HBD14 = make_sine_stereo(D4, 0.25, 44100)
HBD15 = make_sine_stereo(D5, 0.5, 44100)
HBD16 = make_sine_stereo(B4, 0.5, 44100)
HBD17 = make_sine_stereo(G4, 0.5, 44100)
HBD18 = make_sine_stereo(FS4, 0.5, 44100)
HBD19 = make_sine_stereo(E4, 1, 44100)

HBD20 = make_sine_stereo(C5, 0.3, 44100)
HBD21 = make_sine_stereo(C5, 0.25, 44100)
HBD22 = make_sine_stereo(B4, 0.5, 44100)
HBD23 = make_sine_stereo(G4, 0.5, 44100)
HBD24 = make_sine_stereo(A4, 0.5, 44100)
HBD25 = make_sine_stereo(G4, 1, 44100)

HBD = [
  HBD1,
  HBD2,
  HBD3,
  HBD4,
  HBD5,
  HBD6,

  HBD7,
  HBD8,
  HBD9,
  HBD10,
  HBD11,
  HBD12,

  HBD13,
  HBD14,
  HBD15,
  HBD16,
  HBD17,
  HBD18,
  HBD19,

  HBD20,
  HBD21,
  HBD22,
  HBD23,
  HBD24,
  HBD25,
].reduce([]) { |all, samples| all + samples }

render_stereo_16(HBD)

