module robo.client.utils;

import vibe.core.log;
import vibe.data.serialization;
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
    auto v = atan2(p2.y - p1.y - 0.0, p2.x - p1.x - 0.0) * 180 / PI;
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
    size_t pointIndex;

    enum NavigatorState { Init, InRotation, InMovement, Finished}
    NavigatorState navState = NavigatorState.Init;
    IRoboServer.RoboState lastRoboState;

    this(IRoboServer server, size_t i, ClientGameState state)
    {
        this.server = server;
        this.pointIndex = i;
        this.p = state.game.points[i];
        this.state = state;
    }

    void adjustRotation()
    {
        () @trusted {
            logDebug("state: %s", state);
        }();
        logDebug("robo x: %d, y, %d", state.game.robo.x, state.game.robo.y);
        logDebug("target point.x: %d, point.y, %d, point.score: %d", p.x, p.y, p.score);

        // find the amount of rotation needed
        auto targetAngle = diffDegreeAngle(state.game.robo, p);
        auto currentAngle = state.robo.angle;
        auto angleDiff = (targetAngle - currentAngle).abs.round;

        if (angleDiff.abs > 90)
        {
            goBackwards = true;
            angleDiff = 180 - angleDiff;
        }

        logDebug("targetAngle: %f deg", targetAngle);
        logDebug("currentAngle: %d deg", currentAngle);
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
        auto distance = distanceEuclidean(state.game.robo, p);
        logDebug("euclidean distance between robot and target: %f", distance);
        if (goBackwards)
            server.backward(distance.to!int);
        else
            server.forward(distance.to!int);
    }

    void waitUntilFinished()
    {
        logDebug("robo x: %d, y, %d, angle: %d", state.game.robo.x, state.game.robo.y, state.robo.angle);
        logDebug("navState: %s", navState);
        with(NavigatorState)
        final switch(navState)
        {
            case Init:
                adjustRotation();
                navState = InRotation;
                break;
            case InRotation:
                if (state.robo.angle >= targetAngle)
                {
                    move();
                    navState = InMovement;
                }
                else
                {
                    checkForStalemate;
                }
                break;
            case InMovement:
                if (state.game.points[pointIndex].collected)
                {
                    navState = Finished;
                }
                else
                {
                    checkForStalemate;
                }
                break;
            case Finished:
                break;
        }
        lastRoboState = state.robo;
    }

    void checkForStalemate()
    {
        if (lastRoboState == state.robo)
        {
            logDebug("stalemate detected!");
            navState = NavigatorState.Finished;

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
