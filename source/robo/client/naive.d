module robo.client.naive;

import mqttd;
import vibe.core.log;
import std.algorithm;
import std.range;
import std.typecons : Nullable;

import robo.iclient;
import robo.iserver;
import robo.client.navigator;
import robo.client.utils;

class NaiveRoboClient : GeneralRoboClient {
    Nullable!Navigator currentNavigation;

    void executeNavigation() @safe
    {
        if(!currentNavigation.isNull)
        {
            currentNavigation.waitUntilFinished();
            if (currentNavigation.navState == currentNavigation.NavigatorState.Finished)
                currentNavigation.nullify;
        }
    }

    override void onRoboState(IRoboServer.RoboState state)
    {
        this.state.robo = state;
        logDebug("roboState: %s", state);
        executeNavigation;
    }


    override void onGameState(GameState state)
    {
        this.state.game = state;
        if(!currentNavigation.isNull)
        {
            return executeNavigation;
        }

        foreach (i, point; state.points) {
            if (point.score > 0)
            {
                currentNavigation = Navigator(server, i, this.state);
                break;
            }
        }

        executeNavigation;
    }
}
