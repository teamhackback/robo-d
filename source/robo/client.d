module robo.client;

import mqttd;
import vibe.core.log;

import robo.iclient;
import robo.iserver;

class RoboClient : IRoboClient {
    IRoboServer server;

    void init(IRoboServer server)
    {
        this.server = server;
    }

    void onRoboState(IRoboServer.RoboState state)
    {
        logDebug("roboState: %s", state);
    }

    void onRoboPosition(IRoboServer.RoboPosition pos)
    {
        logDebug("roboPos: %s", pos);
        server.forward(1);
    }
}
