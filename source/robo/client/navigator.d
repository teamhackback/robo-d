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
        this.p = p;
        this.state = state;
    }

    void adjustRotation()
    {
        //logDebug("robo x: %d, y, %d", state.game.robo.x, state.game.robo.y);
        //logDebug("target point.x: %d, point.y, %d, point.score: %d", p.x, p.y, p.score);

        // find the amount of rotation needed
        auto targetAngle = diffDegreeAngle(state.game.robo, p).round;
        auto currentAngle = state.robo.angle;
        auto angleDiff = (targetAngle - currentAngle).round;

        if (angleDiff.abs > 90)
        {
            goBackwards = true;
            targetAngle = -(180 - targetAngle.abs).copysign(targetAngle);
            angleDiff = (targetAngle - currentAngle).round;
        }

        //logDebug("targetAngle: %f deg", targetAngle);
        //logDebug("currentAngle: %d deg", currentAngle);
        //logDebug("angleDiff: %f", angleDiff);

        if(angleDiff < 0)
        {
            logDebug("CMD: LEFT by: %f deg", -angleDiff);
            server.left(-angleDiff);
        }
        else
        {
            logDebug("CMD: right by: %f deg", angleDiff);
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
            logDebug("CMD: backward for: %f", distance);
        }
        else
        {
            server.forward(distance.to!int);
            logDebug("CMD: forward for: %f", distance);
        }
    }

    void waitUntilFinished()
    {
        //logDebug("robo x: %d, y, %d, angle: %d", state.game.robo.x, state.game.robo.y, state.robo.angle);
        //logDebug("navState: %s", navState);
        with(NavigatorState)
        final switch(navState)
        {
            case Init:
                auto previousAngle = state.robo.angle;
                adjustRotation();
                if ((targetAngle - previousAngle).abs < 1)
                    goto case InRotation;
                else
                    navState = InRotation;
                break;
            case InRotation:
                // on degree of tolerance
                if (state.robo.angle >= targetAngle - 1)
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
                    if (pointIndex >= 0)
                        state.game.points[pointIndex].collected = true;
                    goto case Finished;
                }
                else
                {
                    checkForStalemate;
                }
                break;
            case Finished:
                server.stop();
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
                logDebug("stalemate detected at: %s", state.game.robo);
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
    import vibe.core.log;
    setLogLevel(LogLevel.debug_);

    // init world & server
    auto server = new HackBackSimulator();
    server.x = WORLD_WIDTH / 2;
    server.y = WORLD_HEIGHT / 2;
    server.r = 15;
    auto state = new ClientGameState();
    GameState gameState = {
        world: World(WORLD_WIDTH, WORLD_HEIGHT)
    };
    state.game = gameState;

    void gotoPoint(Point p)
    {
        auto nav = new Navigator(server, p, state);

        while (nav.navState != Navigator.NavigatorState.Finished)
        {
            // update robo
            state.game.robo = server.position;
            state.robo = server.state;

            nav.waitUntilFinished;
        }
    }

    gotoPoint(Point(525, 463, 5));
    assert(server.position.x == 525);
    assert(server.position.y == 464);

    gotoPoint(Point(390, 490, 5));
    assert(server.position.x == 391);
    assert(server.position.y == 490);
}
