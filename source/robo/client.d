module robo.client;

import mqttd;
import vibe.core.log;
import std.algorithm;
import std.math;
import std.conv : to;

import robo.iclient;
import robo.iserver;
import robo.clientutils;

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

class RoboClient : GeneralRoboClient {
    size_t inMovementIndex = -1;

    override void onRoboState(IRoboServer.RoboState state)
    {
        this.state.robo = state;
        logDebug("roboState: %s", state);
    }


    override void onGameState(GameState state)
    {
        this.state.game = state;
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

        foreach (i, const ref point; state.points) {
            server.navigateToPoint(point, this.state);
            inMovementIndex = i;
            break;
        }
    }
}
