module robo.simulator;

import robo.iserver : RoboServer;

import vibe.core.log;
import vibe.data.json;

import std.math;
import std.typecons : Nullable;

int MAX_DIST = 5000;
int MIN_DIST = 0;
int MAX_ANGLE = 360;
int MIN_ANGLE = 0;

auto radians(V)(V v)
{
    return sin(v * (PI / 180));
}

class HackBackSimulator : RoboServer
{
    // round x/y position
    int ROUND_DIGITS = 0;
    // The radius of the robot in cm
    int RADIUS_CM = 7;
    // factor robot distance (tacho counts) to cm (20 tacho counts ca. 1 cm)
    int TACHO_COUNT_CM_FACTOR = 20;
    // factor between robot distance and x/y positional system
    // WORLD DISTANCE = POSITION FACTOR * ROBOT DISTANCE
    double POSITION_FACTOR = 3.328125;

    string robot_channel = "robot/state";

    // state variables
    double x, y, r, angle;
    double start_x, start_y, start_r, start_angle;
    double left_distance, right_distance;

    this(double x=0, double y=0, double r=15, double angle=0) {
        this.x = this.start_x = x;
        this.y = this.start_x = y;
        this.r = this.start_r = r;
        this.angle = this.start_angle = angle;
    }

    /**
    Move the robot forward by a given distance.
    Params:
        distance = the distance the robot should move forward.
    */
    void forward(int distance)
    {
        auto movedX = cos(radians(angle)) * distance / POSITION_FACTOR;
        auto movedY = sin(radians(angle)) * distance / POSITION_FACTOR;
        x += movedX;
        y += movedY;
        left_distance += distance;
        right_distance += distance;
    }

    /**
    Move the robot backward by a given distance.
    Params:
        distance = the distance the robot should move forward.
    */
    void backward(int distance)
    {
        auto movedX = cos(radians(angle)) * distance / POSITION_FACTOR;
        auto movedY = sin(radians(angle)) * distance / POSITION_FACTOR;
        x -= movedX;
        y -= movedY;
        left_distance -= distance;
        right_distance -= distance;
    }

    /**
    Turn the robot right by a given angle (degrees).
    Params:
        angle = the angle in degrees.
    */
    void right(int _angle)
    {
        angle -= _angle;
        auto distance = calc_distance_with_angle(_angle);
        right_distance -= distance;
        left_distance += distance;
    }

    /**
    Turn the robot left by a given angle (degrees).
    Params:
        angle = the angle in degrees.
    */
    void left(int _angle)
    {
        angle += _angle;
        auto distance = calc_distance_with_angle(_angle);
        right_distance += distance;
        left_distance -= distance;
    }


    /**
    Sets the robot back to the staring position.
    */
    void reset()
    {
        x = start_x;
        y = start_y;
        angle = start_angle;
        right_distance = 0;
        left_distance = 0;
    }

    /**
    The current position adn radius (x,y,r) from the robot.
    Returns: the x, y coordinates and radius as tuple
    */
    auto position() {
        import std.typecons : tuple;
        return tuple(x, y, r);
        //return int(round(self.__x, self.ROUND_DIGITS)), int(round(self.__y, self.ROUND_DIGITS)), self.__r
    }

    /// stops the robot
    void stop() {}

    /**
    Returns the state of the robot (distance right / left motor and angle)
    Returns: map {'right_motor', 'lef_motor', 'angle'} with the current values distance
    left motor, distance right motor and current angle in degrees of the robot.
    The real angle from gyro is the current angle multiplied with -1
    */
    auto state()
    {
        return [
            "right_motor": right_distance,
            "left_motor": left_distance,
            "angle": -angle
        ];
    }

    /**
    Calculate the distance when the robot turns a given angle in degree.
    Params:
        angle = angle in degree
    Returns: distance in tacho counts
    */
    private auto calc_distance_with_angle(double angle)
    {
        //return round(2 * self.RADIUS_CM * math.pi * angle / 360 * self.TACHO_COUNT_CM_FACTOR)
        return 0.0;
    }

    override string toString()
    {
        import std.string : format;
        return format("x: %s, y: %s, angle: %s", x, y, angle);
    }
}

/**
Decorator for the Simulator, extends the Simulator with dimension time.
*/
class TimeDecorator
{
    HackBackSimulator simulator;
    NextCommand nextCommand;
    int tachoPerTick;

    struct NextCommand
    {
        Nullable!string command;
        Nullable!double args;
    }

    this(HackBackSimulator simulator, int tachoPerTick = 20)
    {
        this.simulator = simulator;
        this.tachoPerTick = tachoPerTick;
        nextCommand = NextCommand();
    }

    void forward(double distance)
    {
        nextCommand.command = "forward";

        if (distance <= tachoPerTick)
        {
            simulator.forward(distance);
            nextCommand.value.nullify;
        }
        else
        {
            simulator.forward(tachoPerTick);
            nextCommand.value = distance - tachoPerTick;
        }
    }

    void backward(double distance)
    {
        nextCommand.command = "backward";

        if (distance <= tachoPerTick)
        {
            simulator.backword(distance);
            nextCommand.value.nullify;
        }
        else
        {
            simulator.backword(tachoPerTick);
            nextCommand.value = distance - tachoPerTick;
        }
    }

    void reset()
    {
        nextCommand = NextCommand();
        simulator.reset();
    }

    void stop()
    {
        nextCommand = NextCommand();
    }

    void left(double angle)
    {
        simulator.left(angle);
        nextCommand = NextCommand();
    }

    void right(double angle)
    {
        simulator.right(angle);
        nextCommand = NextCommand();
    }

    override string toString()
    {
        return self.simulator.toString;
    }

    void tick()
    {
        if (nextCommand.command == "forward")
        {
            forward(nextCommand.value.get);
        }

        if (nextCommand.command == "backward")
        {
            forward(nextCommand.value.get);
        }
    }
}
