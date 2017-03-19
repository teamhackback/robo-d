module robo.client.utils;

import vibe.core.log;
import vibe.data.serialization;
import std.algorithm;
import std.math;
import std.conv : to;

import robo.iclient;
import robo.iserver;
import std.typecons;

version(unittest) import std.stdio;

class GeneralRoboClient : IRoboClient {
    IRoboServer server;
    ClientGameState state;
    bool hasDumbedGame;

    this()
    {
        state = new ClientGameState();
    }

    void init(IRoboServer server)
    {
        this.server = server;
    }

    void onRoboState(IRoboServer.RoboState roboState)
    {
        roboState.angle = div(roboState.angle, 360).to!int;
        this.state.robo = roboState;
        if (hasDumbedGame)
            state.addNewMeasurement(state.game.robo.x, state.game.robo.y, state.robo.angle);
    }

    void onGameState(GameState gameState)
    {
        if (gameState.robo.x <= 0 || gameState.robo.y <= 0)
            return;

        this.state.game = gameState;
        state.addNewMeasurement(state.game.robo.x, state.game.robo.y, state.robo.angle);
        if (!hasDumbedGame)
        {
            hasDumbedGame = true;
            logDebug("game: %s", gameState);
        }
    }
}

@safe:

auto distanceEuclidean(P1, P2)(P1 p1, P2 p2)
{
    double xDiff = p2.x - p1.x;
    double yDiff = p2.y - p1.y;
    return xDiff * xDiff + yDiff * yDiff;
}

auto div(real a, real b)
{
    return ((a % b) + b) % b;
}

unittest
{
    assert(div(-8, 360) == 352);
}

unittest
{
    struct Point { double x, y; }

    assert(distanceEuclidean(Point(640, 480), Point(592, 777)).sqrt.approxEqual(300.854));
}

auto diffDegreeAngle(P1, P2)(P1 p1, P2 p2)
out(val)
{
    assert(val <= 360);
}
body
{
    auto e = atan2(p2.y - p1.y - 0.0, p2.x - p1.x - 0.0);
    if (e < 0)
        e += 2 * PI;
    return e * 180 / PI;
}

unittest
{
    struct Point { double x, y; }

    // move right
    //assert(diffDegreeAngle(Point(640, 480), Point(700, 480)).approxEqual(0));
    //// move left
    //assert(diffDegreeAngle(Point(640, 480), Point(600, 480)).approxEqual(-180));
    //// move up
    //assert(diffDegreeAngle(Point(640, 480), Point(640, 500)).approxEqual(-90));

    //// random points
    //assert(diffDegreeAngle(Point(640, 480), Point(592, 777)).approxEqual(-99.1805));
    //assert(diffDegreeAngle(Point(640, 480), Point(323, 284)).approxEqual(148.272));
    //assert(diffDegreeAngle(Point(640, 480), Point(0, 0)).approxEqual(143.13));
}

struct RoboHistory
{
    int x, y, angle;
}

int avgFilter(E)(E values)
{
    //logDebug("values: %s", values);
    auto val = (values.sum / values.length.to!int).to!int;
    //logDebug("val: %d", val);
    return val;
}

int weightedAVGFilter(E)(E values)
@trusted
{
    import std.array;
    import std.range;
    if (values.length == 1)
        return values[0];

    auto weights = [
        1, 3
    ];
    double totalSum = 0;
    foreach (val, w; lockstep(values, weights))
    {
        totalSum += w * val;
    }
    int val = (totalSum / weights.sum).to!int;
    //logDebug("val: %d", val);
    return val;
}

int lastFilter(E)(E values)
{
    return values.back;
}

class ClientGameState
{
    import std.stdio;
    import std.datetime;

    GameState game;
    IRoboServer.RoboState robo;
    RoboHistory[] history;
    File file;
    SysTime startTime;

    Nullable!int _x, _y, _angle;

    this()
    {
        file = File("logs/raw.csv", "w");
        startTime = Clock.currTime;
    }


    override string toString()
    {
        import std.format : format;
        return format("(game: %s, robo: %s)", game, robo);
    }

    int includeLastElements = 2;

    //alias historyFilter = avgFilter;
    alias historyFilter = weightedAVGFilter;
    //alias historyFilter = lastFilter;

    int x()
    {
        if (!_x.isNull)
            return  _x.get;
        auto prevElements = min(history.length, includeLastElements);
        _x = historyFilter(history[$ - prevElements .. $].map!`a.x`);
        return _x.get;
    }

    int y()
    {
        if (!_y.isNull)
            return  _y;
        auto prevElements = min(history.length, includeLastElements);
        _y = historyFilter(history[$ - prevElements .. $].map!`a.y`);
        return _y.get;
    }

    int angle()
    {
        if (!_angle.isNull)
            return _angle;
        auto prevElements = min(history.length, includeLastElements);
        _angle = historyFilter(history[$ - prevElements .. $].map!`a.angle`);
        return _angle.get;
    }

    void addNewMeasurement(int x, int y, int angle)
    {
        angle = -angle;
        angle = div(angle, 360).to!int;
        history ~= RoboHistory(x, y, angle);
        auto msecs = (Clock.currTime - startTime).split!("msecs").msecs;
        file.writefln("%s,%d,%d,%d", msecs, x, y, angle);
        file.flush;
        _x.nullify;
        _y.nullify;
        _angle.nullify;
    }
}
