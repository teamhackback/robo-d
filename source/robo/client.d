module robo.client;

import mqttd;
import vibe.core.log;
import vibe.data.json;

import robo.iclient;
import robo.iserver;

string player_name = "HackBack";

class RoboClient : IRoboClient {
    IRoboServer server;

    void init(IRoboServer server)
    {
        this.server = server;
    }

    void onRoboState(IRoboServer.RoboState state)
    {
    }

    void onRoboPosition(IRoboServer.RoboPosition pos)
    {

    }
}

class HackBackRoboMqttClient : MqttClient {
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
}
