# gem install unimidi
# brew install portaudio
# gem install portaudio
# irb -r ./midi.rb

require './wav'
require 'unimidi'
require 'portaudio'

$stream = nil

input_thread = Thread.new {
  PortAudio.with_portaudio do
    # 1. Select the first available MIDI input device
    input = UniMIDI::Input.first

    # 2. Open the device and listen for messages
    input.open do |input|
      puts "Listening for MIDI input on #{input.name}..."
      loop do
        # Gets the next message from the buffer
        m = input.gets
        # 'm' is an array of bytes, e.g., [144, 60, 100] for Note On
        puts "Received: #{m.inspect}" if m

        samples = Array.new(256).map{|i| rand(MIN_V..MAX_V) }
        100.times { $stream.write(samples) }
      end
    end
  end
}

output_thread = Thread.new {
  PortAudio.with_portaudio do
    output = PortAudio::Device.default_output
    raise "No default output device" unless output

    stream = PortAudio::BlockingStream.new(
      output: { device: output, channels: 1, format: :int16 },
      sample_rate: output.default_sample_rate,
      frames_per_buffer: 256
    )


    samples = Array.new(256).map{|i| rand(MIN_V..MAX_V) }

    stream.start

    $stream = stream
    #100.times { stream.write(samples) }
    #stream.stop
    #stream.close
    puts "Stream initialized"
  end
}

[input_thread, output_thread].each(&:join)


exit(0)
