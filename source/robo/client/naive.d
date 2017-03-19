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

import std.stdio;

class NaiveRoboClient : GeneralRoboClient {
    Nullable!Navigator currentNavigation;
    File naiveLog;

    this()
    {
        super();
        naiveLog = File("logs/raw_points.csv", "w");
    }

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
        if (!hasDumbedGame)
            return;
        if(!currentNavigation.isNull)
        {
            return executeNavigation;
        }

        // find new point
        auto points = state.game.points.enumerate.map!(
                p => tuple!("i", "dist")(p.index, state.distanceEuclidean(p.value))
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
            naiveLog.writefln("%d, %d", currentNavigation.p.x, currentNavigation.p.y);
            naiveLog.flush;
            executeNavigation;
        }
    }

    override void onRoboState(IRoboServer.RoboState roboState)
    {
        super.onRoboState(roboState);
        //logDebug("roboState: %s", state);
        executeOrPlan;
    }


    override void onGameState(GameState gameState)
    {
        super.onGameState(gameState);
        executeOrPlan;
    }
}
