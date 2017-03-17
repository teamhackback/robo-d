import mqttd;
import vibe.core.log;
import vibe.data.json;

string player_name = "HackBack";

class HackBackSimulator : MqttClient {

    // round x/y position
    int ROUND_DIGITS = 0
    // The radius of the robot in cm
    int RADIUS_CM = 7
    // factor robot distance (tacho counts) to cm (20 tacho counts ca. 1 cm)
    int TACHO_COUNT_CM_FACTOR = 20
    // factor between robot distance and x/y positional system
    // WORLD DISTANCE = POSITION FACTOR * ROBOT DISTANCE
    double POSITION_FACTOR = 3.328125


    string player_channel;
    string robot_channel = "robot/state";

    this(Settings settings) {
        player_channel = "players/" ~ player_name ~ "/#";
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

void main()
{
    auto settings = Settings();
    settings.clientId = "HackBack";
    settings.host = "127.0.0.1";

    auto mqtt = new HackBackRoboClient(settings);
    mqtt.connect();
}
