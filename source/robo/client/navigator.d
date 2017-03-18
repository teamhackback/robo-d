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
    size_t pointIndex;

    enum NavigatorState { Init, InRotation, InMovement, Finished}
    NavigatorState navState = NavigatorState.Init;
    IRoboServer.RoboState lastRoboState;
    int noChangeCount;

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
            noChangeCount++;
            if (noChangeCount >= 3)
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
}


