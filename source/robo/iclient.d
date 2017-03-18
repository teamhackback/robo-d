module robo.iclient;

import vibe.data.json;
import robo.iserver;

struct GameState
{
    static struct World
    {
        @name("y_max") int yMax;
        @name("x_max") int xMax;
    }

    static struct Point
    {
        bool collected;
        int r;
        int x;
        int score;
        int y;
    }

    IRoboServer.RoboPosition robot;
    World world;
    Point[] points;
}


interface IRoboClient
{
    void init(IRoboServer server);
    void onRoboState(IRoboServer.RoboState state) @safe;
    void onGameState(GameState state) @safe;
}
