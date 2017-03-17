module robo.iclient;

import robo.iserver;

interface IRoboClient
{
    void init(IRoboServer server);
    void onRoboState(IRoboServer.RoboState state);
    void onRoboPosition(IRoboServer.RoboPosition pos);
}
