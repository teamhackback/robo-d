module robo.client.naive;

import mqttd;
import vibe.core.log;
import std.algorithm;
import std.range;

import robo.iclient;
import robo.iserver;
import robo.client.utils;

class NaiveRoboClient : GeneralRoboClient {
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
            //logDebug("en route to  x: %d, y, %d",
                    //state.points[inMovementIndex].x, state.points[inMovementIndex].y);
            logDebug("robot x: %f, y, %f", state.robot.x, state.robot.y);
            if (!state.points[inMovementIndex].collected)
            {
                logDebug("still not reached the last point, ignoring state");
                return;
            }
        }

        foreach (i, const ref point; state.points.filter!(p => p.score > 0).enumerate) {
            server.navigateToPoint(point, this.state);
            inMovementIndex = i;
            break;
        }
    }
}
