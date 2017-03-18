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

    auto robot = new TimeDecorator(new HackBackSimulator(START_X, START_Y, ROBOT_R));
    //auto robot = new HackBackSimulator(START_X, START_Y, ROBOT_R);
    IRoboClient client = new NaiveRoboClient();
    client.init(robot);

    auto rnd = Random(42);

    // keep track of the world
    auto game = new Game!(typeof(rnd))(rnd);
    logDebug("points: %s", game.points);

    int maxTicks = 800; // 120 / 0.15

    // set robot to the center
    robot.position.x = game.xCenter;
    robot.position.y = game.yCenter;
    robot.position.r = game.radius;

    maxTicks = 100;
    foreach (i; 0..maxTicks)
    {
        robot.tick();

        auto pos = robot.position();

        GameState gameState = {
            robot: pos,
            points: game.points,
            world: game.world,
        };
        // only send ticks every 100 ms
        // a tick is 15ms
        if (i % 6)
        {
            client.onRoboState(robot.state);
            client.onGameState(gameState);
        }

        game.check(pos);
        //logDebug("robot: %s", pos);
    }
    logDebug("total score: %s", game.score);
}
