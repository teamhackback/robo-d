module robo.client.navigator;

import vibe.core.log;
import std.algorithm;
import std.math;
import std.conv : to;

import robo.iclient;
import robo.iserver;
import robo.client.utils;

@safe:

struct Navigator {
    IRoboServer server;
    Point p;
    ClientGameState state;
    int targetAngle;
    bool goBackwards;
    ptrdiff_t pointIndex = -1;

    enum NavigatorState { Init, InRotation, InMovement, Finished}
    NavigatorState navState = NavigatorState.Init;
    IRoboServer.RoboState lastRoboState;
    int noChangeCount;

    this(IRoboServer server, Point p, ClientGameState state, size_t i = -1)
    {
        this.server = server;
        this.pointIndex = i;
        this.state = state;
    }

    void adjustRotation()
    {
        logDebug("robo x: %d, y, %d", state.game.robo.x, state.game.robo.y);
        logDebug("target point.x: %d, point.y, %d, point.score: %d", p.x, p.y, p.score);

        // find the amount of rotation needed
        auto targetAngle = diffDegreeAngle(state.game.robo, p).round;
        auto currentAngle = state.robo.angle;
        auto angleDiff = (targetAngle - currentAngle).round;

        if (angleDiff.abs > 90)
        {
            goBackwards = true;
            angleDiff = -(180 - angleDiff).copysign(angleDiff);
            targetAngle = -(180 - targetAngle.abs).copysign(targetAngle);
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
        auto distance = distanceEuclidean(state.game.robo, p).sqrt;
        if (goBackwards)
        {
            server.backward(distance.to!int);
            logDebug("moving backward for: %f", distance);
        }
        else
        {
            server.forward(distance.to!int);
            logDebug("moving forward for: %f", distance);
        }
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
                if (pointIndex >= 0 && state.game.points[pointIndex].collected || isNearTarget)
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
            noChangeCount++;
            if (noChangeCount >= 5)
            {
                logDebug("stalemate detected!");
                navState = NavigatorState.Finished;
            }
        }
        else
        {
            noChangeCount = 0;
        }
    }

    bool isNearTarget()
    {
        auto roboPointRadius = state.game.robo.r + p.r;
        auto distToPoint = distanceEuclidean(state.game.robo, p);
        if (distToPoint < pow(roboPointRadius, 2))
            return true;
        return false;
    }
}


@system:

unittest
{
    import robo.simserver;
    import robo.gamekeeper;
    import std.stdio;

    auto server = new HackBackSimulator();
    auto state = new ClientGameState();
    auto world = World(WORLD_WIDTH, WORLD_HEIGHT);
    GameState gameState = {
            robo: server.position,
            //points: ,
            world: world,
    };
    state.game = gameState;

    auto p1 = Point(525, 463);
    auto nav = new Navigator(server, p1, state);

    while (nav.navState != Navigator.NavigatorState.Finished)
    {
        // update robo
        state.game.robo = server.position;
        state.robo = server.state;

        nav.waitUntilFinished;
    }

    writeln(server.position);
}
