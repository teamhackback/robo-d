module robo.client;

import mqttd;
import vibe.core.log;

import robo.iclient;
import robo.iserver;

class RoboClient : IRoboClient {
    IRoboServer server;
    Point[] points;

    void init(IRoboServer server)
    {
        this.server = server;
    }

    void onRoboState(IRoboServer.RoboState state)
    {
        logDebug("roboState: %s", state);
    }

    void onGameState(GameState state)
    {
        points = state.points;
        //logDebug("gameState: %s", state);
        server.forward(50);
    }
}
