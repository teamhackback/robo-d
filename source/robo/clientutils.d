module robo.clientutils;

import vibe.core.log;
import std.algorithm;
import std.math;
import std.conv : to;

import robo.iclient;
import robo.iserver;

@safe:

void navigateToPoint(IRoboServer server, const ref Point p, const ClientGameState state)
{
    logDebug("robot x: %f, y, %f", state.game.robot.x, state.game.robot.y);
    logDebug("target point.x: %d, point.y, %d, point.score: %f", p.x, p.y, p.score);

    if (p.collected || p.score == -1)
    {
        logDebug("ignoring point: collected or crater");
        return;
    }

    double xPrime = state.game.robot.x - p.x;
    double yPrime = state.game.robot.y - p.y;

    double distance = sqrt(xPrime * xPrime + yPrime * yPrime);
    logDebug("euclidean distance between robot and target: %f", distance);

    // find the amount of rotation needed
    double target_angle = 180 + (atan2(yPrime, xPrime) * 180 / PI);
    logDebug("target_angle: %f deg", target_angle);
    double current_angle = state.robo.angle;
    logDebug("current_angle: %f deg", current_angle);

    double diff = current_angle - target_angle;
    diff = min(360 - abs(diff), abs(diff));
    int val = floor(abs(diff)).to!int;

    if(diff < 0)
    {
        logDebug("turning left by: %d deg", val);
        server.left(val);
    }
    else
    {
        logDebug("turning right by: %d deg", val);
        server.right(val);
    }

    //logDebug("moving forward: %d tachons", cast(int)round(diff));
    server.forward(distance.to!int);

}

class ClientGameState
{
    GameState game;
    IRoboServer.RoboState robo;
}
