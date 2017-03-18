import robo.simserver;
import robo.client;
import robo.iclient;

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

    foreach (i; 0..10_000)
    {
        //sleep(TIMEOUT_SEC);
        //robot.tick();

        auto pos = robot.position();

        client.onRoboState(robot.state);
        client.onRoboPosition(robot.position);
    }
}
