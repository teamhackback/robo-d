import robo.simserver;
import robo.client;
import robo.iclient;
import robo.gamekeeper;

import std.algorithm;
import mir.random;
import std.conv;
import vibe.core.log;
import std.stdio;

auto run(int n)
{
    double START_X = 640;
    double START_Y = 480;
    double ROBOT_R = 15;

    auto rnd = Random(n);

    //auto robo = new TimeDecorator(new HackBackSimulator(START_X, START_Y, ROBOT_R));
    auto robo = new TimeDecorator(n, new HackBackSimulator(START_X, START_Y, ROBOT_R));
    robo.withRandom = true;

    //auto robo = new HackBackSimulator(START_X, START_Y, ROBOT_R);
    IRoboClient client = new NaiveRoboClient();
    client.init(robo);

    // keep track of the world
    static import std.random;
    auto rnd2 = std.random.Random(n);
    auto game = new Game!(typeof(rnd2))(rnd2);
    //logDebug("points: %s", game.points);

    int maxTicks = 800; // 120 / 0.15

    // set robot to the center
    robo.position.x = game.xCenter;
    robo.position.y = game.yCenter;
    robo.position.r = game.radius;

    logDebug("points: %s", game.points);

    maxTicks = 800;
    //maxTicks = 20;
    foreach (i; 0..maxTicks)
    {
        robo.tick();

        auto pos = robo.position();

        GameState gameState = {
            robo: pos,
            points: game.points,
            world: game.world,
        };
        // only send ticks every 100 ms
        // a tick is 15ms
        if (i % 6)
        {
            client.onRoboState(robo.state);
            client.onGameState(gameState);
        }

        // check the game board for reached points
        game.check(pos);
        //logDebug("robot: %s", pos);

        if (game.points.filter!(p => p.score > 0 && !p.collected).empty)
            break;
    }
    logDebug("total score: %s", game.score);
    return game.score;
}

auto runLoop()
{
    import logger;
    int n = 500;
    int offset = 0;
    //offset = 100_000;
    double[] scores;
    {
        useLogger = false;
        scope(exit) useLogger = true;
        foreach (i; 0..n)
        {
            scores ~= run(offset + i.to!int);
        }
    }

    //logDebug("Scores: %s", scores);
    auto val = scores.sum / scores.length;
    //logDebug("AVG score: %s", val);
    return val;
}

void testParameter()
{
    import robo.config;
    import std.parallelism;
    import std.range;
    foreach (i; iota(1, 60, 3).parallel(1))
    {
        FREE_VARIABLE = i;
        writefln("%d: %f", i, runLoop());
    }
}

void main()
{
    //teStParameter;
    writefln("AVG: %f", runLoop);
    //run(42);
}
