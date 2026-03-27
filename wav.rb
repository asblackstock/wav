# Raw wav renderer
# https://ccrma.stanford.edu/courses/422-winter-2014/projects/WaveFormat

# TODO
# define sweeps (pass a range into the oscillator's sine fn and interpolate as the sample moves forward)

MIN_V = -32768
MAX_V = 32767

########### SOUNDS

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

BASE_OCTAVE = [C4,CS4,D4,DS4,E4,F4,FS4,G4,GS4,A4,AS4,B4]
BASE_OCTAVE_SYM = [:C4,:CS4,:D4,:DS4,:E4,:F4,:FS4,:G4,:GS4,:A4,:AS4,:B4]

# todo: use const_set('CONST', value) in a class
def define_ns(n, mult)
  BASE_OCTAVE.each_with_index { |c, ix|
    eval("#{BASE_OCTAVE_SYM[ix].to_s.gsub(/\d/, n.to_s)} = #{c * mult.to_f}")
  }
end

# Define frequencies for octaves 0 - 8 (don't kill me, theory dudes)
define_ns(0, 1.0/16.0)
define_ns(1, 1.0/8.0)
define_ns(2, 1.0/4.0)
define_ns(3, 1.0/2.0)
define_ns(5, 2.0)
define_ns(6, 4.0)
define_ns(7, 8.0)
define_ns(8, 16.0)

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

########### OSCILLATORS

def make_silence(time, rate)
  num_samples = (time.to_f * rate.to_f).round
  return num_samples.times.map { |s| 0 }
end

def make_noise(time, rate)
  num_samples = (time.to_f * rate.to_f).round
  return num_samples.times.map { |s| rand(MIN_V..MAX_V) }
end

def make_sine(frequency, time, rate)
  num_samples = (time.to_f * rate.to_f).round
  return num_samples.times.map { |s|
    (MAX_V.to_f * Math.sin(frequency.to_f * (1.0/rate.to_f) * (2.0 * Math::PI * s.to_f))).round
  }
end

def make_square(frequency, time, rate)
  num_samples = (time.to_f * rate.to_f).round
  return num_samples.times.map { |s|
    height = Math.sin(frequency.to_f * (1.0/rate.to_f) * (2.0 * Math::PI * s.to_f))
    height >= 0 ? MAX_V : MIN_V
  }
end

def make_saw(frequency, time, rate)
  num_samples = (time.to_f * rate.to_f).round
  samples_per_cycle = (rate.to_f / frequency.to_f).round
  sample_counter = 0

  return num_samples.times.map { |s|
    pct_thru_cycle = sample_counter.to_f / samples_per_cycle.to_f
    sample_counter = (sample_counter + 1) % samples_per_cycle
    ((MAX_V.to_f * 2.0 * pct_thru_cycle) - MAX_V.to_f).round
  }
end


########### PROCESSING

def make_stereo(samples)
  return samples.map { |s| [s, s] }
end

def sum(sample_arrays)
  output_length = sample_arrays.map(&:count).max
  output_samples = []

  (0...output_length).each do |i|
    sample_count = 0
    sample_sum = 0
    sample_arrays.each do |arr|
      if i < arr.count
        sample_count += 1
        sample_sum += arr[i]
      end
    end
    output_samples << (sample_sum.to_f / sample_count.to_f).round
  end
  return output_samples
end

########### OUTPUT

def make_melody_daw(tempo, note_array, pitch_shift=1, tempo_shift=1)
  # notes are e.g. [E5, 4] - an e5 quarter note
  quarter_note_time = 60.0 / tempo.to_f
  note_time_array = note_array.map do |nv|
    quarter_note_ratio = 4.0 / nv.last.to_f
    [nv.first, nv[1], quarter_note_time * quarter_note_ratio]
  end

  return make_melody(note_time_array, pitch_shift, tempo_shift)
end

def make_melody(note_time_array, pitch_shift=1, tempo_shift=1)
  samples = note_time_array.map do |nt|
    note = nt.first
    waveform = nt[1]
    time = nt.last
    note == nil ?
      make_silence(time * tempo_shift, 44100) :
      send("make_#{waveform}",note * pitch_shift, time * tempo_shift, 44100)
  end.reduce([]) { |all, samples| all + samples }
  render_stereo_16(make_stereo(samples))
  return samples
end

def render_stereo_16(samples)
  render(2, 44100, 16, samples)
end



##### TEST STUFF!

=begin
DU_HAST = [
  [E5, 0.15],
  [D5, 0.15],
  [A4 , 0.15],
  [nil, 0.15],
  [C5, 0.15],
  [nil, 0.15],
  [B4, 0.15],
  [nil, 0.15],
  [E4, 0.15],
  [nil, 0.15],

  [A4, 0.15],
  [C5, 0.15],
  [D5, 0.15],
  [nil, 0.15],
  [B4, 0.15],

  [nil, 0.3],

  [E5, 0.15],
  [D5, 0.15],
  [A4, 0.15],
  [C5, 0.15],
  [B4, 0.15],

  [E4, 0.15],
  [A4, 0.15],
  [C5, 0.15],
  [D5, 0.15],
  [B4, 0.15],
]
make_melody(DU_HAST, 2, 0.8)
=end


OLD_MCD = [
  [F4, "sine", 4],
  [F4, "sine", 4],
  [F4, "sine", 4],
  [C4, "sine", 4],
  [D4, "sine", 4],
  [D4, "sine", 4],
  [C4, "sine", 4],
  [nil, nil, 4],
  [A4, "sine", 4],
  [A4, "sine", 4],
  [G4, "sine", 4],
  [G4, "sine", 4],
  [F4, "sine", 1],
]

AWHHOH_MEL = [
  [C5, "sine", 2],
  [D5, "sine", 8],
  [C5, "sine", 8],
  [AS4, "sine", 8],
  [A4, "sine", 8],
  [AS4, "sine", 2],

  [C5, "sine", 8],
  [AS4, "sine", 8],
  [A4, "sine", 8],
  [G4, "sine", 8],
  [A4, "sine", 2],

  [AS4, "sine", 8],
  [A4, "sine", 8],
  [G4, "sine", 8],
  [F4, "sine", 8],

  # simulate dotted quarter
  [G4, "sine", 4],
  [G4, "sine", 8],
  [C4, "sine", 8],
  [C4, "sine", 2],

  [F4, "sine", 4],
  [G4, "sine", 4],
  [A4, "sine", 4],
  [AS4, "sine", 4],
  [A4, "sine", 2],
  [G4, "sine", 2],
  [F4, "sine", 1],
]

AWHHOH_HAR = [
  [C5, "sine", 8],
  [AS4, "sine", 8],
  [A4, "sine", 8],
  [G4, "sine", 8],

  [F4, "sine", 8],
  [G4, "sine", 8],
  [A4, "sine", 8],
  [F4, "sine", 8],
#############
  [AS4, "sine", 8],
  [A4, "sine", 8],
  [G4, "sine", 8],
  [F4, "sine", 8],

  [E4, "sine", 8],
  [F4, "sine", 8],
  [G4, "sine", 8],
  [E4, "sine", 8],
#############
  [A4, "sine", 8],
  [G4, "sine", 8],
  [F4, "sine", 8],
  [E4, "sine", 8],

  [D4, "sine", 8],
  [E4, "sine", 8],
  [F4, "sine", 8],
  [D4, "sine", 8],

#############
  [G4, "sine", 4],
  [G4, "sine", 8],
  [C4, "sine", 8],
  [C4, "sine", 4],
#############
  [C5, "sine", 4],
  [C5, "sine", 8],
  [AS4, "sine", 8],
  [A4, "sine", 8],
  [G4, "sine", 8],
  [F4, "sine", 4],
  [AS4, "sine", 4],

  [A4, "sine", 8],
  [AS4, "sine", 8],
  [C5, "sine", 8],
  [A4, "sine", 8],
  [G4, "sine", 4],
  [G4, "sine", 8],
  [F4, "sine", 8],
  [F4, "sine", 1],
]

line1 = make_melody_daw(120, AWHHOH_MEL)
line2 = make_melody_daw(120, AWHHOH_HAR)

render_stereo_16(make_stereo(sum([line1, line2])))
