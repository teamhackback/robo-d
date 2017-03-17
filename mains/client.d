import mqttd;

import robo.client : HackBackRoboClient;

shared static this()
{
    import std.process : environment;
    import std.conv : to;

    auto settings = Settings();
    settings.clientId = "HackBack";
    settings.host = environment.get("MQTT_HOST", "127.0.0.1");
    settings.port = environment.get("MQTT_PORT", "1883").to!ushort;

    auto mqtt = new HackBackRoboClient(settings);
    mqtt.connect();
}
