module robo.gamekeeper;

import robo.iclient;
import robo.iserver;
import robo.client.utils;

import std.algorithm;
import std.conv;
import std.math;

import vibe.core.log;

int WORLD_WIDTH = 1280;
int WORLD_HEIGHT = 960;

/**
The game engine -  master of the points and score
*/
class Game(Random)
{
    World world;
    int radius;
    double ratioAntiPoints;
    int xCenter, yCenter;
    double distance;
    int nrPoints;
    Point[] points;
    Random rnd;

    this(Random rnd, int nrPoints=50, double ratioAntiPoints=0.1, int radius=5, int maxX=WORLD_WIDTH, int maxY=WORLD_HEIGHT, int distance=100)
    {
        this.rnd = rnd;
        this.world = World(maxX, maxY);
        this.radius = radius;
        this.ratioAntiPoints = ratioAntiPoints;
        this.xCenter = cast(int) round(maxX / 2);
        this.yCenter = cast(int) round(maxY / 2);
        this.distance = distance;
        this.nrPoints = nrPoints;
        reset();
    }

    void reset()
    {
        points = createPoints(nrPoints);
    }

    Point createPoint()
    {
        import std.random : uniform;
        Point p = {
            x: uniform(radius * 2, world.maxX - radius * 2, rnd),
            y: uniform(radius * 2, world.maxY - radius * 2, rnd),
            r: this.radius,
        };
        return p;
    }

    Point[] createPoints(int nrPoints)
    {

        Point[] points;

        foreach (i; 0..nrPoints)
        {
            Point p = void;
            do
            {
                p = createPoint();
            }
            while (pow(p.x - xCenter, 2) + pow(p.y - yCenter, 2) < pow(distance, 2));
            points ~= p;
        }

        int nrAntiPoints = min((nrPoints * ratioAntiPoints).to!int, points.length);
        foreach (i; 0..nrAntiPoints)
            points[points.length - i - 1].score = -1;

        return points;
    }

    void check(IRoboServer.RoboPosition pos)
    {
        foreach (ref p; points)
        {
            if (!p.collected)
            {
                auto roboPointRadius = pos.r + p.r;
                auto distToPoint = distanceEuclidean(pos, p);
                if (distToPoint < pow(roboPointRadius, 2))
                {
                    // robot has found the point
                    p.collected = true;
                    logDebug("==HIT: %s", p);
                }
            }
        }
    }

    double score()
    {
        return points.filter!(p => p.collected).map!(p => p.score).sum;
    }
}
