require 'bundler'
Bundler.require
require 'socket'
require 'irb'

module Bot

  # Subclass the Robot class for your bot
  class Robot
    
    def to_s
      self.class.name
    end
    
    # start up the irb REPL
    def start
      suppress_warnings {
        IRB.setup nil
        IRB.conf[:AT_EXIT] << lambda {@engine.stop}
        IRB.conf[:PROMPT][:BOT_PROMPT] = {
          :PROMPT_I => "%m > ",
          :PROMPT_S => "%m ",
          :PROMPT_C => "%m* ",
          :RETURN => "%s\n" 
        }
        IRB.conf[:PROMPT_MODE] = :BOT_PROMPT
        IRB.conf[:MAIN_CONTEXT] = IRB::Irb.new.context
        require 'irb/ext/multi-irb'
        IRB.irb nil, self
      }
    end

    # select the engine -- either a simulator, the real robot or dump the commands to file
    def engine(type=:file)
      if @engine.nil?        
        if type == :rpi
          @engine = Serial.new '/dev/ttyAMA0', 9600
        elsif type == :bt
          @engine = Serial.new '/dev/tty.TenkuLabs-DevB', 9600
        elsif type == :sim
          @engine = TCPSim.new
        else
          @engine = FileSim.new
        end
      end
      return @engine
    end        
  end
  
  # Connect real-time to the simulator
  class TCPSim
    def initialize
      start      
      @sock = TCPSocket.new('localhost', 5555)      
    end
    
    def start
      @process = ChildProcess.build("./sim")
      @process.detach
      @process.start      
      sleep 1
    end
    
    def stop
      @process.stop
    end
    
    def write(seq)
      @sock.write seq
    end
  end

  # Dump movement commands to file
  class FileSim
    def initialize
      @file = "#{Time.now.to_i}.seq"
    end
    
    def write(seq)
      File.open(@file, 'a') do |file| 
        file.write(seq) 
      end
    end
  end

  # Models a leg on the hexapod
  class Leg3DOF
    attr_accessor :side, :coxa, :femur, :tibia
    
    def initialize(side, coxa, femur, tibia)
      @side = side
      @coxa = Servo.new coxa
      @femur = Servo.new femur
      @tibia = Servo.new tibia
    end
    

    # rotate the servo accordingly
    # c, f, t are in degrees, not radians
    def actuate(c, f, t)
      c, f, t = *convert(c, f, t)
      return @coxa.rotate(c) + @femur.rotate(f) + @tibia.rotate(t)
    end
    
    # if the leg is on the left side of the body, flip the degrees
    def convert(c, f, t)
      if @side == :right
        return [c, f, t]
      elsif @side == :left
        return [c, f, t].map {|deg| 180 - deg}
      end
    end

  end

  # models the servo
  class Servo
    attr_accessor :number, :serial
    
    def initialize(n)
      @number = n      
    end

    def rotate(deg)
      points = (2000 * deg.to_f/180) + 500
      "##{@number}P#{points.to_i}"
    end
  end
end

# Suppress warnings for IRB
module Kernel
  def suppress_warnings
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = original_verbosity
    return result
  end
end