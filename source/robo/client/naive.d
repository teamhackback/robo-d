module robo.client.naive;

import mqttd;
import vibe.core.log;
import std.algorithm;
import std.range;
import std.array;
import std.typecons;

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

    override void onRoboState(IRoboServer.RoboState roboState)
    {
        this.state.robo = roboState;
        //logDebug("roboState: %s", state);
        executeNavigation;
    }


    override void onGameState(GameState gameState)
    {
        this.state.game = gameState;
        if(!currentNavigation.isNull)
        {
            return executeNavigation;
        }

        auto points = gameState.points.enumerate.map!(
                p => tuple!("i", "dist")(p.index, gameState.robo.distanceEuclidean(p.value))
            )
            .array
            .sort!((a, b) => a.dist < b.dist);
        foreach (p; points) {
            auto point = gameState.points[p.i];
            if (point.score > 0 && !point.collected)
            {
                currentNavigation = Navigator(server, p.i, this.state);
                break;
            }
        }

        executeNavigation;
    }
}
