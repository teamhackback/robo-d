module robo.client.naive;

import mqttd;
import vibe.core.log;
import std.algorithm;
import std.range;
import std.array;
import std.typecons;
import std.math;
import std.conv;

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

    void executeOrPlan() @safe
    {
        if(!currentNavigation.isNull)
        {
            return executeNavigation;
        }

        // find new point
        auto points = state.game.points.enumerate.map!(
                p => tuple!("i", "dist")(p.index, state.game.robo.distanceEuclidean(p.value))
            )
            .array
            .sort!((a, b) => a.dist < b.dist);
        foreach (p; points) {
            auto point = state.game.points[p.i];
            if (point.score > 0 && !point.collected)
            {
                currentNavigation = Navigator(server, point, this.state, p.i);
                break;
            }
        }

        if (!currentNavigation.isNull)
        {
            logDebug("Selected: %s", currentNavigation.p);
            executeNavigation;
        }
    }

    override void onRoboState(IRoboServer.RoboState roboState)
    {
        roboState.angle = remainder(roboState.angle, 360).to!int;
        this.state.robo = roboState;
        //logDebug("roboState: %s", state);
        executeOrPlan;
    }


    override void onGameState(GameState gameState)
    {
        this.state.game = gameState;
        executeOrPlan;
    }
}
