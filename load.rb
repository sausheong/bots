#!/usr/bin/env ruby

# to use - ./load.rb xxx.seq 
# where xxx.seq is the name of the sequence file

require 'socket'
require 'childprocess'


def connect
  @sock = TCPSocket.new('localhost', 5555)
end

def disconnect
  @sock.close
end
  
def write(filename)
  line_num = 0
  text = File.open(filename).read
  text.gsub!(/\r\n?/, "\n")
  text.each_line do |line|
    line = line.gsub(/T.*$/, "")
    print "#{line_num += 1} #{line}"
    @sock.write line
    sleep 0.4
  end  
end

filename = ARGV[0]

puts "Starting simulator ..."
process = ChildProcess.build("./sim")
process.detach
process.start 
puts "Simulator started."
puts "Connecting to simulator ..."
sim_started = false
until sim_started
  begin
    connect
    sim_started = true
  rescue
    next
  end
end
puts "Connected."
puts "Loading sequence in #{filename} to simulator ..."
write filename
puts "Completed."

disconnect
puts "To quit the simulator, select the simulator and press ESC or 'q'."
