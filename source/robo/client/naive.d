module robo.client.naive;

import mqttd;
import vibe.core.log;
import std.algorithm;
import std.range;
import std.typecons : Nullable;

import robo.iclient;
import robo.iserver;
import robo.client.utils;

class NaiveRoboClient : GeneralRoboClient {
    Nullable!Navigator currentNavigation;

    override void onRoboState(IRoboServer.RoboState state)
    {
        this.state.robo = state;
        logDebug("roboState: %s", state);
    }


    override void onGameState(GameState state)
    {
        this.state.game = state;
        if(!currentNavigation.isNull)
        {
            currentNavigation.waitUntilFinish();
        }

        foreach (i, const ref point; state.points.filter!(p => p.score > 0).enumerate) {
            server.navigateToPoint(point, this.state);
            inMovementIndex = i;
            break;
        }
    }
}
