require "tapping_device"
require "pry"


TracePoint.trace(:raise) do |tp|
  puts("!!!!!!!!")
  binding.irb
  ""
end

def foo(a)
  a + 10
end

foo("a")
