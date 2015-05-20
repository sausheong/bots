require './bots'

module Bot
  # models the hexapod
  class Hexapod < Robot 
    attr_accessor :legs, :eng, :left, :right
  
    def initialize(type=:sim)
      @eng = engine type
      @legs = {}
      @legs[:front_left]   = Leg3DOF.new(:left, 1, 2, 3)
      @legs[:middle_left]  = Leg3DOF.new(:left, 4, 5, 6)
      @legs[:back_left]    = Leg3DOF.new(:left, 7, 8, 9)
      
      @legs[:front_right]  = Leg3DOF.new(:right, 32, 31, 30)
      @legs[:middle_right] = Leg3DOF.new(:right, 29, 28, 27)
      @legs[:back_right]   = Leg3DOF.new(:right, 26, 25, 24)
                
      @left_legs = [:front_left, :middle_right, :back_left]
      @right_legs = [:front_right, :middle_left, :back_right]
      
    end

    # move given leg by rotating the 3 servos by the given degrees
    def move(leg, c, f, t)
      execute legs[leg].actuate(c, f, t)
    end

    def lift_straight(leg)
      leg.actuate 90, 45, 110
    end

    def ground_straight(leg)
      leg.actuate 90, 100, 70
    end

    def lift_pull(leg)
      leg.actuate 120, 45, 110
    end
    
    def ground_pull(leg)
      leg.actuate 120, 100, 70
    end

    def tiptoe(leg)
      leg.actuate 90, 130, 90
    end
    
    def calibrate(leg)
      leg.actuate 90, 90, 90
    end
    
    def stand(leg)
      leg.actuate 90, 100, 70
    end

    def rest(leg)
      leg.actuate 90, 30, 30
    end

    def tripod_s1
      execute(@left_legs.map {|leg| lift_straight legs[leg] }.join + 
              @right_legs.map {|leg| ground_pull legs[leg] }.join, 400)
    end

    def tripod_s2
      execute(@left_legs.map {|leg| ground_straight legs[leg] }.join + 
              @right_legs.map {|leg| lift_pull legs[leg] }.join, 400)      
    end

    def tripod_s3
      execute(@left_legs.map {|leg| ground_pull legs[leg] }.join + 
              @right_legs.map {|leg| lift_straight legs[leg] }.join, 400)      
    end

    def tripod_s4
      execute(@left_legs.map {|leg| lift_pull legs[leg] }.join + 
              @right_legs.map {|leg| ground_straight legs[leg] }.join, 400)      
    end

    def walk(gait=:tripod, delay=0.5, steps=5)
      
      if gait == :tripod
        steps.times do 
          tripod_s1; sleep delay
          tripod_s2; sleep delay
          tripod_s3; sleep delay
          tripod_s4; sleep delay
        end
      end
    end
  
    
    private

    def all
      execute(legs.values.inject("") do |memo, leg|
        memo + yield(leg)
      end)
    end
  
    def execute(sequence, speed=100)
      @eng.write "#{sequence}T#{speed}\r\n"
    end    

    def wait(s=0)
      sleep(s) if s > 0
    end  
  end
  
end

hex = Bot::Hexapod.new(:sim)
hex.start
