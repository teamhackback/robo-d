module robo.client;

import mqttd;
import vibe.core.log;
import std.algorithm;
import std.math;
import std.conv : to;

import robo.iclient;
import robo.iserver;
import robo.clientutils;

class RoboClient : IRoboClient {
    ClientRoboState state;
    int inMovementIndex = -1;

    this()
    {
        state = new ClientRoboState();
    }

    void init(IRoboServer server)
    {
        this.server = server;
    }

    void onRoboState(IRoboServer.RoboState state)
    {
        state.roboState = state;
        logDebug("roboState: %s", state);
    }


    void onGameState(GameState state)
    {
        state.gameState = state;
        if(inMovementIndex != -1)
        {
            logDebug("en route to  x: %d, y, %d",
                    state.points[inMovementIndex].x, state.points[inMovementIndex].y);
            logDebug("robot x: %f, y, %f", state.robot.x, state.robot.y);
            if (!state.points[inMovementIndex].collected)
            {
                logDebug("still not reached the last point, ignoring state");
                return;
            }
        }

        foreach (int idx, point; state.points) {
            server.navigateToPoint(point, state);
            inMovementIndex = idx;
            break;
        }
    }
}
