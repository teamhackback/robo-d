import robo.simserver;
import robo.client;
import robo.iclient;
import robo.gamekeeper;

void main()
{
    import vibe.core.log;
    setLogLevel(LogLevel.debug_);

    double START_X = 640;
    double START_Y = 480;
    double ROBOT_R = 15;

    //auto robot = TimeDecorator(HackBackSimulator(START_X, START_Y, ROBOT_R));
    auto robot = new HackBackSimulator(START_X, START_Y, ROBOT_R);
    IRoboClient client = new RoboClient();
    client.init(robot);

    // keep track of the world
    Game game = new Game();
    GameKeeper keeper = new GameKeeper(game);
    logDebug("points: %s", game.points);

    foreach (i; 0..10)
    {
        //sleep(TIMEOUT_SEC);
        //robot.tick();

        auto pos = robot.position();

        GameState gameState = {
            robot: robot.position,
            points: game.points,
            world: game.world,
        };
        client.onGameState(gameState);
        client.onRoboState(robot.state);
    }
}
