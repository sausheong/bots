require 'bundler'
Bundler.require
require 'socket'

module Bots

  # Subclass the Controller class for your bot
  class Controller
    attr :engine_type
    
    def initialize(type=:sim)
      @engine_type = engine type
    end

    # select the engine -- either a simulator, the real robot or dump the commands to file
    def engine(type=:file)
      if @engine_type.nil?        
        if type == :rpi
          @engine_type = Serial.new '/dev/ttyAMA0', 9600
        elsif type == :bt
          @engine_type = Serial.new '/dev/tty.TenkuLabs-DevB', 9600
        elsif type == :sim
          @engine_type = TCPSim.new
        else
          @engine_type = FileSim.new
        end
      end
      return @engine_type
    end   
    
    def execute(sequence, speed=100)
      engine.write "#{sequence}T#{speed}\r\n"
    end             
  end
  
  # Connect real-time to the simulator
  class TCPSim
    def initialize
      @process = ChildProcess.build("./sim")
      @process.detach
      @process.start      

      sim_started = false
      until sim_started
        begin
          connect
          sim_started = true
        rescue
          next
        end
      end

      Pry.config.hooks.add_hook(:after_session, :stop_engine) do
        @process.stop
      end  
    end
    
    def connect
      @sock = TCPSocket.new('localhost', 5555)
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
    
    def initialize(n)
      @number = n      
    end

    def rotate(deg)
      points = (2000 * deg.to_f/180) + 500
      "##{@number}P#{points.to_i}"
    end
  end
end
