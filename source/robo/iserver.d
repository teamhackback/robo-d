module robo.iserver;

import vibe.data.json;

@safe:

interface IRoboServer
{
    /**
    Move the robot forward by a given distance.
    Params:
        distance = the distance the robot should move forward.
    */
    void forward(int distance);

    /**
    Move the robot backward by a given distance.
    Params:
        distance = the distance the robot should move forward.
    */
    void backward(int distance);

    /**
    Turn the robot right by a given angle (degrees).
    Params:
        angle = the angle in degrees.
    */
    void right(int _angle);

    /**
    Turn the robot left by a given angle (degrees).
    Params:
        angle = the angle in degrees.
    */
    void left(int _angle);

    /**
    Sets the robot back to the staring position.
    */
    void reset();

    struct RoboPosition
    {
        double x, y, r;
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
        @name("right_motor") double rightMotor;
        @name("left_motor") double leftMotor;
        double angle;
    }

    /**
    Returns the state of the robot (distance right / left motor and angle)
    Returns: map {'right_motor', 'lef_motor', 'angle'} with the current values distance
    left motor, distance right motor and current angle in degrees of the robot.
    The real angle from gyro is the current angle multiplied with -1
    */
    RoboState state();
}
