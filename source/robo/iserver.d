module robo.iserver;

import vibe.data.json;

import std.conv : to;

@safe:

interface IRoboServer
{
    /**
    Move the robot forward by a given distance.
    Params:
        distance = the distance the robot should move forward.
    */
    void forward(int distance)
    in
    {
        assert(distance >= 0);
        assert(distance <= 50000);
    };
    final void forward(double angle)
    {
        forward(angle.to!int);
    }

    /**
    Move the robot backward by a given distance.
    Params:
        distance = the distance the robot should move forward.
    */
    void backward(int distance)
    in
    {
        assert(distance >= 0);
        assert(distance <= 50000);
    };
    final void backward(double angle)
    {
        backward(angle.to!int);
    }

    /**
    Turn the robot right by a given angle (degrees).
    Params:
        angle = the angle in degrees.
    */
    void right(int _angle)
    in
    {
        assert(_angle >= 0);
        assert(_angle <= 360);
    };
    final void right(double angle)
    {
        right(angle.to!int);
    }

    /**
    Turn the robot left by a given angle (degrees).
    Params:
        angle = the angle in degrees.
    */
    void left(int _angle)
    in
    {
        assert(_angle >= 0);
        assert(_angle <= 360);
    };
    final void left(double angle)
    {
        left(angle.to!int);
    }

    /**
    Sets the robot back to the staring position.
    */
    void reset();

    struct RoboPosition
    {
        int x, y, r;
    }

    /**
    The current position and radius (x,y,r) from the robot.
    Returns: the x, y coordinates and radius as tuple
    */
    RoboPosition position();

    /// stops the robot
    void stop();

    struct RoboState
    {
        @name("right_motor") int rightMotor;
        @name("left_motor") int leftMotor;
        int angle;
    }

    /**
    Returns the state of the robot (distance right / left motor and angle)
    Returns: map {'right_motor', 'lef_motor', 'angle'} with the current values distance
    left motor, distance right motor and current angle in degrees of the robot.
    The real angle from gyro is the current angle multiplied with -1
    */
    RoboState state();
}
