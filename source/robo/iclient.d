module robo.iclient;

import vibe.data.json;
import robo.iserver;

/**
A point in the game world. A point has a score which is
earned when the point was collected by the robot.
*/
struct Point
{
    int x;
    int y;
    int r;
    int score = 1;
    bool collected;

    string toString() @trusted
    {
        import std.format : format;
        if (score > 0)
            return format("Point(x: %d, y: %d, r: %d, hit: %s)", x, y, r, collected);
        else
            return format("Crater(x: %d, y: %d, r: %d, hit: %s)", x, y, r, collected);
    }
}

struct World
{
    @name("x_max") int maxX;
    @name("y_max") int maxY;
}

struct GameState
{
    @name("robot") IRoboServer.RoboPosition robo;
    World world;
    Point[] points;
}


interface IRoboClient
{
    void init(IRoboServer server);
    void onRoboState(IRoboServer.RoboState state) @safe;
    void onGameState(GameState state) @safe;
}
