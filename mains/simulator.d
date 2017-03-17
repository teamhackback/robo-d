import robo.simserver;
import robo.client;
import robo.iclient;

import std.stdio;

void main()
{
    double START_X = 640;
    double START_Y = 480;
    double ROBOT_R = 15;

    //auto robot = TimeDecorator(HackBackSimulator(START_X, START_Y, ROBOT_R));
    auto robot = new HackBackSimulator(START_X, START_Y, ROBOT_R);
    IRoboClient client = new RoboClient();
    client.init(robot);

    foreach (i; 0..10_000)
    {
        writeln("i ", i);
        //sleep(TIMEOUT_SEC);
        //robot.tick();

        auto pos = robot.position();

        client.onRoboState(robot.state);
        client.onRoboPosition(robot.position);
    }
}
