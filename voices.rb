VIOLIN_A_FRQ = [440,880,1334,1780,2222,2660,3102,3546,4000,4440,4880,5320,5770,6200,6662,7092,7552,8000,8440,8868]
VIOLIN_A_PWR = [0.7,0.62,0.66,0.68,0.69,0.57,0.7,0.59,0.54,0.5,0.54,0.48,0.44,0.37,0.51,0.55,0.4,0.43,0.43,0.24]

VIOLIN_D_FRQ = [293,587,887,1181,1481,1775,2070,2365,2660,2961,3249,3546,3852,4144,4437,4729,5039,5344,5641,5928]
VIOLIN_D_PWR = [0.73,0.69,0.62,0.67,0.63,0.41,0.61,0.6,0.39,0.54,0.51,0.46,0.46,0.59,0.44,0.36,0.49,0.44,0.25,0.46]

def make_string(frequency, time, rate, harmonic_depth=20)
  frq = harmonic_depth.times.map { |i| frequency.to_f * (i+1).to_f}
  # note: power curves vary slightly between notes, use the 'A' curve as canon
  pwr = VIOLIN_A_PWR
  pwr_s = pwr.map{ |v| v / pwr.max }

  sines = harmonic_depth.times.map do |i|
    make_sine(frq[i], time, rate, pwr_s[i])
  end

  return sum(sines)
end
