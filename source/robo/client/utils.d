module robo.client.utils;

import vibe.core.log;
import std.algorithm;
import std.math;
import std.conv : to;

import robo.iclient;
import robo.iserver;

version(unittest) import std.stdio;

class GeneralRoboClient : IRoboClient {
    IRoboServer server;
    ClientGameState state;

    this()
    {
        state = new ClientGameState();
    }

    void init(IRoboServer server)
    {
        this.server = server;
    }

    abstract void onRoboState(IRoboServer.RoboState state);
    abstract void onGameState(GameState state);
}

@safe:

auto distanceEuclidean(P1, P2)(P1 p1, P2 p2)
{
    double xDiff = p2.x - p1.x;
    double yDiff = p2.y - p1.y;
    return sqrt(xDiff * xDiff + yDiff * yDiff);
}

unittest
{
    struct Point { double x, y; }

    assert(distanceEuclidean(Point(640, 480), Point(592, 777)).approxEqual(300.854));
}

auto diffDegreeAngle(P1, P2)(P1 p1, P2 p2)
{
    auto v = atan2(p2.y - p1.y, p2.x - p1.x) * 180 / PI;
    v = -v;
    return v;
}

unittest
{
    struct Point { double x, y; }

    // move right
    assert(diffDegreeAngle(Point(640, 480), Point(700, 480)).approxEqual(0));
    // move left
    assert(diffDegreeAngle(Point(640, 480), Point(600, 480)).approxEqual(-180));
    // move up
    assert(diffDegreeAngle(Point(640, 480), Point(640, 500)).approxEqual(-90));

    // random points
    assert(diffDegreeAngle(Point(640, 480), Point(592, 777)).approxEqual(-99.1805));
    assert(diffDegreeAngle(Point(640, 480), Point(323, 284)).approxEqual(148.272));
}

struct Navigator {
    IRoboServer server;
    Point p; 
    ClientGameState state;
    int targetAngle;
    bool goBackwards;
    
    void adjustRotation()
    {
        () @trusted {
            logDebug("state: %s", state);
        }();
        logDebug("robot x: %f, y, %f", state.game.robot.x, state.game.robot.y);
        logDebug("target point.x: %d, point.y, %d, point.score: %d", p.x, p.y, p.score);

        // find the amount of rotation needed
        auto targetAngle = diffDegreeAngle(state.game.robot, p);
        auto currentAngle = state.robo.angle;
        auto angleDiff = (targetAngle - currentAngle).abs.round;
        
        if (angleDiff.abs > 90)
        {
            goBackwards = true;
            angleDiff = 180 - angleDiff;
        }

        logDebug("targetAngle: %f deg", targetAngle);
        logDebug("currentAngle: %f deg", currentAngle);
        logDebug("angleDiff: %f", angleDiff);

        if(angleDiff < 0)
        {
            logDebug("turning left by: %f deg", -angleDiff);
            server.left(-angleDiff);
        }
        else
        {
            logDebug("turning right by: %f deg", angleDiff);
            server.right(angleDiff);
        }

        this.targetAngle = targetAngle.round.to!int;
    }

    void move()
    {
        auto distance = distanceEuclidean(state.game.robot, p);
        logDebug("euclidean distance between robot and target: %f", distance);
        if (goBackwards)
            server.backward(distance.to!int);
        else
            server.forward(distance.to!int);
    }

    void waitUntilFinished()
    {
        logDebug("robot x: %f, y, %f", state.robot.x, state.robot.y);
        if (!state.points[inMovementIndex].collected)
        {
            logDebug("still not reached the last point, ignoring state");
            return;
        }
    }
}

class ClientGameState
{
    GameState game;
    IRoboServer.RoboState robo;

    override string toString()
    {
        import std.format : format;
        return format("(game: %s, robo: %s)", game, robo);
    }
}
