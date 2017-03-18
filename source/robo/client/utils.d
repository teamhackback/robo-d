module robo.client.utils;

import vibe.core.log;
import std.algorithm;
import std.math;
import std.conv : to;

import robo.iclient;
import robo.iserver;

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

void navigateToPoint(IRoboServer server, const ref Point p, const ClientGameState state)
{
    logDebug("robot x: %f, y, %f", state.game.robot.x, state.game.robot.y);
    logDebug("target point.x: %d, point.y, %d, point.score: %d", p.x, p.y, p.score);

    if (p.collected || p.score == -1)
    {
        logDebug("ignoring point: collected or crater");
        return;
    }

    double xDiff = state.game.robot.x - p.x;
    double yDiff = state.game.robot.y - p.y;

    double distance = sqrt(xDiff * xDiff + yDiff * yDiff);
    logDebug("euclidean distance between robot and target: %f", distance);

    // find the amount of rotation needed
    double targetAngle = 180 + (atan2(yDiff, xDiff) * 180 / PI);
    double currentAngle = state.robo.angle;
    double angleDiff = targetAngle - currentAngle;

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

    server.forward(distance.to!int);
}

class ClientGameState
{
    GameState game;
    IRoboServer.RoboState robo;
}
