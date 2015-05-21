# Bots

A simple library for controlling robots using Ruby.

## What is this?

Bots is a simple library for controlling robots. You can use the library to create controller scripts that manipulate robots. The current version only controls [legged robots](http://en.wikipedia.org/wiki/Legged_robot). The example `hex.rb` controller script allow you to control a [hexapod robot](http://en.wikipedia.org/wiki/Hexapod_(robotics)).

Bots has a built-in [simulator](https://github.com/billhsu/hexapod-sim) created using the [Bullet Physics Library](http://bulletphysics.org). You can use the simulator to test run your controller scripts. You can either run it real-time or dump the output of your controller script to a sequence file to be loaded on the simulator.

[![Bots library simulator demo](http://img.youtube.com/vi/nNom1KyaSGU/0.jpg)](http://www.youtube.com/watch?v=nNom1KyaSGU)

This library uses the [hexapod simulator](https://github.com/billhsu/hexapod-sim) by [Bill Hsu](https://github.com/billhsu).

## How to use

To run this in simulator mode:

1. Clone this repository
2. Run `bundle install` to install the files
3. Create a robot controller file by requiring `bots.rb`
4. Run the robot controller file in REPL using pry `pry -r ./hex.rb`
5. To exit the REPL enter `!!!` and press enter


## How to create a robot controller 

Creating a robot controller is straightforward.

### Subclass `Bots::Controller` 

```ruby
class Hexapod < Bots::Controller 
  ...
end
```

### Create a constructor for your controller

You should call the constructor of your superclass with the type of engine, create legs and do whatever else you want to initialize the robot.

```ruby
def initialize(type=:sim)
  super(type)
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
```

### Do stuff with the robot!

In the example below we're creating a method to simplify moving the bot.

```ruby
def move(leg, c, f, t)
  execute @legs[leg].actuate(c, f, t)
end
```

the `Leg3DOF` has a method `actuate` that moves the 3 servos controlling the leg (coxa, femur and tibia) at the same time. In the `move` method we call actuate on the chosen leg, then execute the action. the `execute` method executes the leg actuation and creates the command that is then sent to the controller's engine.


For more information please read the source code for the sample hexapod `hex.rb`

