module robo.client.navigator;

import vibe.core.log;
import std.algorithm;
import std.math;
import std.conv : to;

import robo.iclient;
import robo.iserver;
import robo.client.utils;
import robo.config;

@safe:

struct Navigator {
    IRoboServer server;
    Point p;
    ClientGameState state;
    int targetAngle;
    // 1: right, -1: left
    int rotationDirection;
    ptrdiff_t pointIndex = -1;

    enum NavigatorState { Init, InRotation, InMovement, Finished}
    NavigatorState navState = NavigatorState.Init;
    RoboHistory lastRoboValue;
    int noChangeCount;
    double drivenDistance = 0;
    double lastDistanceAtRotation = 0;

    this(IRoboServer server, Point p, ClientGameState state, size_t i = -1)
    {
        this.server = server;
        this.pointIndex = i;
        this.p = p;
        this.state = state;
        if (state.history.length > 0)
            lastRoboValue = state.history[$ - 1];
    }

    void planRotation()
    {
        //logDebug("robo x: %d, y, %d", state.x, state.y);
        //logDebug("target point.x: %d, point.y, %d, point.score: %d", p.x, p.y, p.score);

        // find the amount of rotation needed
        auto targetAngle = diffDegreeAngle(state, p).round;
        auto angleDiff = (targetAngle - state.angle).round;

        if (angleDiff.abs > 90)
        {
            targetAngle = -(180 - targetAngle.abs).copysign(targetAngle);
        }

        rotationDirection = sgn(targetAngle - state.angle).to!int;
        logDebug("targetAngle: %f deg", targetAngle);
        logDebug("currentAngle: %d deg", state.robo.angle);
        logDebug("angleDiff: %f", angleDiff);

        this.targetAngle = targetAngle.round.to!int;
    }

    void rotate()
    {
        auto angleDiff = (targetAngle - state.angle).round;
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
    }

    void move()
    {
        import robo.simserver : POSITION_FACTOR;
        auto distance = distanceEuclidean(state, p).sqrt;
        distance *= POSITION_FACTOR * DISTANCE_FACTOR;
        auto targetAngle = diffDegreeAngle(state, p);
        auto angleDiff = (targetAngle - state.angle).abs;

        logDebug("targetAngle: %f deg", targetAngle);
        logDebug("currentAngle: %d deg", state.robo.angle);
        logDebug("angleDiff: %f", angleDiff);
        bool goBackwards = angleDiff > 90;
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

    import vibe.core.core;
    import core.time : msecs;
    import std.typecons;
    Nullable!Timer fallbackTimer;

    void fallbackHandler()
    {
        logDebug("Fallback handler activated");
        //move();
    }

    void waitUntilFinished()
    {
        logDebug("robo x: %d, y, %d, angle: %d", state.x, state.y, state.angle);
        logDebug("navState: %s", navState);
        logDebug("distToTarget: %f", distanceEuclidean(p, state).sqrt);
        drivenDistance += distanceEuclidean(state, lastRoboValue).sqrt;

        // TODO: kill fallback timer
        if (!fallbackTimer.isNull)
        {
            fallbackTimer.stop;
        }

        with(NavigatorState)
        final switch(navState)
        {
            case Init:
                server.stop();
                auto previousAngle = state.angle;
                planRotation();
                if ((targetAngle - previousAngle).abs < 2)
                    goto case InRotation;
                else
                {
                    rotate();
                    navState = InRotation;
                }
                break;
            case InRotation:
                // on degree of tolerance
                logDebug("rotationDirection: %d", rotationDirection);
                logDebug("angleDiff: %d", targetAngle - state.angle);
                // cut-off calculated by manual testing
                if (rotationDirection * (targetAngle - state.angle) < 4)
                {
                    noChangeCount = 0;
                    server.stop;
                    move();
                    navState = InMovement;
                    fallbackTimer = setTimer(500.msecs, &fallbackHandler, false);
                }
                else
                {
                    checkForStalemate;
                }
                break;
            case InMovement:
                if (pointIndex >= 0 && state.game.points[pointIndex].collected || isNearTarget)
                {
                    noChangeCount = 0;
                    navState = Finished;
                    if (pointIndex >= 0)
                        state.game.points[pointIndex].collected = true;
                    goto case Finished;
                }
                else
                {
                    checkForStalemate;
                    checkForCorrectCourse;
                }
                break;
            case Finished:
                server.stop();
                break;
        }
        lastRoboValue = RoboHistory(state.x, state.y, state.angle);
    }

    void checkForStalemate()
    {
        //if (lastRoboValue.x == state.x &&
            //lastRoboValue.y == state.y &&
            //lastRoboValue.angle == state.angle)
        //{
            noChangeCount++;
            if (navState == NavigatorState.InRotation && noChangeCount >= 40 ||
                noChangeCount >= 50)
            {
                logDebug("stalemate detected at: %s", lastRoboValue);
                navState = NavigatorState.Finished;
                noChangeCount = 0;
            }
        //}
        //else
        //{
        //}
    }

    void checkForCorrectCourse()
    {
        if (!isOnCorrectPathByDistance && !isOnCorrectPathByAngle)
        {
            lastDistanceAtRotation = drivenDistance;
            logDebug("Auto-correct after distance of: %s", lastDistanceAtRotation);
            navState = NavigatorState.Init;
            server.stop;
            noChangeCount = 0;
            waitUntilFinished;
        }
    }

    bool isOnCorrectPathByAngle()
    {
        //// more auto-corrects are better on the simulator
        //// values were found by experimental simulation
        // sole 20 is best
        return (state.angle - targetAngle).abs <= 4;
        //&& drivenDistance - lastDistanceAtRotation > 10;
    }

    bool isOnCorrectPathByDistance()
    {
        auto dists = state.history.map!(e => distanceEuclidean(e, this.p).sqrt);
        if (dists.length > 6)
        {
            auto prevDist = dists[$ - 6 .. $ - 2].sum / 4;
            auto curDist = dists[$ - 2 .. $].sum / 2;
            logDebug("prevDist: %f, curDist: %f", prevDist, curDist);
            if (prevDist + 10 < curDist)
            {
                return false;
            }
        }
        return true;
    }

    bool isNearTarget()
    {
        if (pointIndex >= 0)
            return false;

        // 6 is for safety in case of miscalculation
        auto roboPointRadius = (state.game.robo.r + p.r) / 2;
        auto distToPoint = distanceEuclidean(state, p);
        if (distToPoint < roboPointRadius * roboPointRadius)
        {
            logDebug("distToPoint: %f", distToPoint);
            logDebug("roboPointRadius: %d", roboPointRadius);
            logDebug("roboPointRadius: %d", roboPointRadius * roboPointRadius);
            return true;
        }
        return false;
    }
}


@system:

unittest
{
    import robo.simserver;
    import robo.gamekeeper;

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
            state.addNewMeasurement(server.position.x, server.position.y, server.state.angle);

            nav.waitUntilFinished;
        }
    }

    gotoPoint(Point(525, 463, 5));
    assert(server.position.x == 525);
    assert(server.position.y == 464);

    gotoPoint(Point(390, 490, 5));
    assert(server.position.x == 390);
    assert(server.position.y == 490);
}
