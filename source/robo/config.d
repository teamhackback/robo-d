module robo.config;

double DISTANCE_FACTOR = 1;

shared static this()
{
    import std.process : environment;
    import std.conv : to;

    auto roboProduction = environment.get("ROBO_PRODUCTION", "0").to!ushort;
    if (roboProduction)
    {
        DISTANCE_FACTOR = 10;
    }

}
