module robo.mqttlayer;

import mqttd;

import vibe.data.json;
import vibe.core.log;

import robo.iclient;
import robo.iserver;

string player_name = "HackBack";

class MqttRoboLayer : MqttClient, IRoboServer {
    string player_channel;
    string robot_channel = "robot/state";
    IRoboClient client;

    this(Settings settings, IRoboClient client) {
        player_channel = "players/" ~ player_name ~ "/#";
        this.client = client;
        super(settings);
    }

    override void onPublish(Publish packet) {
        super.onPublish(packet);
        string payloadStr = () @trusted { return cast(string) packet.payload; }();
        Json payload = parseJsonString(payloadStr);
        logDebug("Received: %s", payload);
        if (packet.topic == player_channel)
        {
            logDebug("player");
        }
        else if (packet.topic == robot_channel)
        {
            logDebug("robot");
        }
        else
        {
            logError("Unknown topic");
        }
    }

    override void onConnAck(ConnAck packet) {
        logDebug("ConnAck");
        super.onConnAck(packet);

        this.subscribe([player_channel, robot_channel]);
        publish("chat", "I'm still here!!!");
    }

    /**
    Move the robot forward by a given distance.
    Params:
        distance = the distance the robot should move forward.
    */
    void forward(int distance)
    {

    }

    /**
    Move the robot backward by a given distance.
    Params:
        distance = the distance the robot should move forward.
    */
    void backward(int distance)
    {

    }

    /**
    Turn the robot right by a given angle (degrees).
    Params:
        angle = the angle in degrees.
    */
    void right(int _angle)
    {
    }

    /**
    Turn the robot left by a given angle (degrees).
    Params:
        angle = the angle in degrees.
    */
    void left(int _angle)
    {

    }

    /**
    Sets the robot back to the staring position.
    */
    void reset()
    {

    }

    /**
    The current position and radius (x,y,r) from the robot.
    Returns: the x, y coordinates and radius as tuple
    */
    IRoboServer.RoboPosition position()
    {
        return IRoboServer.RoboPosition.init;
    }

    /// stops the robot
    void stop()
    {

    }

    /**
    Returns the state of the robot (distance right / left motor and angle)
    Returns: map {'right_motor', 'lef_motor', 'angle'} with the current values distance
    left motor, distance right motor and current angle in degrees of the robot.
    The real angle from gyro is the current angle multiplied with -1
    */
    IRoboServer.RoboState state()
    {
        return IRoboServer.RoboState.init;
    }

}
