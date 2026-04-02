# gem install unimidi
# brew install portaudio
# gem install portaudio
# irb -r ./midi.rb

require './wav'
require 'unimidi'
require 'portaudio'

CMD_DOWN = 144
CMD_UP = 128

KEY_MAP = {
  48 => C3,
  49 => CS3,
  50 => D3,
  51 => DS3,
  52 => E3,
  53 => F3,
  54 => FS3,
  55 => G3,
  56 => GS3,
  57 => A3,
  58 => AS3,
  59 => B3,
  60 => C4,
  61 => CS4,
  62 => D4,
  63 => DS4,
  64 => E4,
  65 => F4,
  66 => FS4,
  67 => G4,
  68 => GS4,
  69 => A4,
  70 => AS4,
  71 => B4,
  72 => C5,
}

def make_sine_cycle(frequency, rate)
  time = 1.0/frequency.to_f
  num_samples = (time.to_f * rate.to_f).round
  return num_samples.times.map { |s|
    (MAX_V.to_f * Math.sin(frequency.to_f * (1.0/rate.to_f) * (2.0 * Math::PI * s.to_f))).round
  }
end

def make_tone_thread(key)
  return Thread.new {
    PortAudio.with_portaudio {
      while $tone_thread_is_running
        samples = make_sine_cycle(KEY_MAP[key], 44100)
        $stream.write(samples)
      end
    }
  }
end

$stream = nil
$tone_thread = nil
$tone_thread_is_running = false

input_thread = Thread.new {
  PortAudio.with_portaudio {
    # 1. Select the first available MIDI input device
    input = UniMIDI::Input.first

    # 2. Open the device and listen for messages
    input.open do |input|
      puts "Listening for MIDI input on #{input.name}..."
      loop do
        # Gets the next message from the buffer
        message = input.gets.first
        cmd, key, velocity = *message[:data]
        timestamp = message[:timestamp]
        puts "Received: #{cmd} #{key} #{velocity} #{timestamp}" if message

        if cmd == CMD_DOWN
          $tone_thread_is_running = true
          $tone_thread = make_tone_thread(key)
        elsif cmd == CMD_UP
          $tone_thread_is_running = false
        end
      end
    end
  }
}

output_thread = Thread.new {
  PortAudio.with_portaudio do
    output = PortAudio::Device.default_output
    raise "No default output device" unless output

    stream = PortAudio::BlockingStream.new(
      output: { device: output, channels: 1, format: :int16 },
      sample_rate: 44100,
      frames_per_buffer: 256
    )

    stream.start
    $stream = stream
    #stream.stop
    #stream.close
    puts "Stream initialized"
  end
}

[input_thread, output_thread].each(&:join)


exit(0)
