shared static this()
{

    auto settings = Settings();
    settings.clientId = "HackBack";
    double TIMEOUT_SEC = 0.15;
    double KEEPALIVE_SEC = 60;

    double START_X = 640;
    double START_Y = 480;
    double ROBOT_R = 15;

    auto robot = TimeDecorator(HackBackSimulator(START_X, START_Y, ROBOT_R));

    auto mqtt = new HackBackSimulator(settings);
    // TODO: use keep_alive
    mqtt.connect();

    for (;;)
    {
        sleep(TIMEOUT_SEC);
        robot.tick()

        x, y, r = robot.position();

        client.publish("robot/state", json.dumps(robot.state()));
        client.publish("robot/position", json.dumps({'x': x, 'y': y, 'r': r}));
    }
}
