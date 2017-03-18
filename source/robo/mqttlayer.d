module robo.mqttlayer;

import mqttd;

import vibe.data.json;
import vibe.core.log;

import robo.iclient;
import robo.iserver;

import std.typecons : Nullable;

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
                if (payload["command"] == "start") {
                    publish(player_channel, `{"command", "start"}`);
                    logDebug("game started");
                }
                else if(payload["command"] == "finished")
                    logDebug("game finished");
                break;
            case player_channel_game:
                auto gameState = deserializeJson!GameState(payload);
                client.onGameState(gameState);
                break;
            case "robot/state":
                auto roboState = deserializeJson!(IRoboServer.RoboState)(payload);
                client.onRoboState(roboState);
                break;
            case "robot/error":
                logDebug("robot.error", payload);
                break;
            default:
                logDebug("topic: %s", packet.topic);
                logError("Unknown topic", payload);
        }
    }

    override void onConnAck(ConnAck packet) {
        logDebug("ConnAck");
        super.onConnAck(packet);

        this.subscribe([player_channel ~ "/#", "robot/state", "robot/error"]);

        logDebug("registering game with control");
        publish(player_channel, `{"command": "register"}`);
    }

    struct UserCommand
    {
        string command;
        Nullable!int args;
    }

    private void process(UserCommand command)
    {
        this.publish("robot/process", command.serializeToJsonString);
    }

    /**
    Move the robot forward by a given distance.
    Params:
        distance = the distance the robot should move forward.
    */
    void forward(int distance)
    {
        UserCommand command = {
            command: "forward",
            args: distance,
        };
        process(command);
    }

    /**
    Move the robot backward by a given distance.
    Params:
        distance = the distance the robot should move forward.
    */
    void backward(int distance)
    {
        UserCommand command = {
            command: "backward",
            args: distance,
        };
        process(command);
    }

    /**
    Turn the robot right by a given angle (degrees).
    Params:
        angle = the angle in degrees.
    */
    void right(int _angle)
    {
        UserCommand command = {
            command: "right",
            args: _angle,
        };
        process(command);
    }

    /**
    Turn the robot left by a given angle (degrees).
    Params:
        angle = the angle in degrees.
    */
    void left(int _angle)
    {
        UserCommand command = {
            command: "left",
            args: _angle,
        };
        process(command);
    }

    /**
    Sets the robot back to the staring position.
    */
    void reset()
    {
        UserCommand command = {
            command: "reset",
        };
        process(command);
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
        UserCommand command = {
            command: "stop",
        };
        process(command);
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
