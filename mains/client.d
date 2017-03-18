import mqttd;

import robo.iclient;
import robo.iserver;

import robo.client;
import robo.mqttlayer;

shared static this()
{
    import std.process : environment;
    import std.conv : to;

    import vibe.core.log;
    setLogLevel(LogLevel.debug_);

    auto settings = Settings();
    settings.clientId = "HackBack";
    settings.host = environment.get("MQTT_HOST", "127.0.0.1");
    settings.port = environment.get("MQTT_PORT", "1883").to!ushort;

    IRoboClient client = new RoboClient();
    auto mqttLayer = new MqttRoboLayer(settings, client);
    client.init(mqttLayer);
    mqttLayer.connect();
}
