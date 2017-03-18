module robo.mqttlayer;

import mqttd;

import vibe.data.json;
import vibe.core.log;

import robo.iclient;
import robo.iserver;

const string player_name = "HackBack";

class MqttRoboLayer : MqttClient, IRoboServer {
    static const player_channel = "players/" ~ player_name;
    static const player_channel_incoming = player_channel ~ "/incoming";
    static const player_channel_game = "players/" ~ player_name ~ "/game";
    IRoboClient client;

    this(Settings settings, IRoboClient client) {
        this.client = client;
        super(settings);
    }

    override void onPublish(Publish packet) {
        super.onPublish(packet);
        string payloadStr = () @trusted { return cast(string) packet.payload; }();
        Json payload = parseJsonString(payloadStr);
        logDebug("Received: %s", payload);
        switch (packet.topic)
        {
            case player_channel:
                logDebug("player", payload);
                break;
            case player_channel_incoming:
                logDebug("player.incoming", payload);
                break;
            case player_channel_game:
                logDebug("player.game", payload);
                break;
            case "robot/state":
                logDebug("robot.state", payload);
                break;
            case "robot/process":
                logDebug("robot.process", payload);
                break;
            case "robot/error":
                logDebug("robot.error", payload);
                break;
            default:
                logError("Unknown topic");
        }
    }

    override void onConnAck(ConnAck packet) {
        logDebug("ConnAck");
        super.onConnAck(packet);

        this.subscribe([player_channel ~ "/#", "robot/#"]);
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
