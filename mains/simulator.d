import robo.simserver;
import robo.client;
import robo.iclient;
import robo.gamekeeper;

import std.random;

void main()
{
    import vibe.core.log;
    setLogLevel(LogLevel.debug_);

    double START_X = 640;
    double START_Y = 480;
    double ROBOT_R = 15;

    auto robo = new TimeDecorator(new HackBackSimulator(START_X, START_Y, ROBOT_R));
    //auto robo = new HackBackSimulator(START_X, START_Y, ROBOT_R);
    IRoboClient client = new NaiveRoboClient();
    client.init(robo);

    auto rnd = Random(42);

    // keep track of the world
    auto game = new Game!(typeof(rnd))(rnd);
    logDebug("points: %s", game.points);

    int maxTicks = 800; // 120 / 0.15

    // set robot to the center
    robo.position.x = game.xCenter;
    robo.position.y = game.yCenter;
    robo.position.r = game.radius;

    maxTicks = 2000;
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
    }
    logDebug("total score: %s", game.score);
}
