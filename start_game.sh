trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

http-server ~/hack/robo-challenge/challenges/rover/ui > /dev/null &
python ~/hack/robo-challenge/challenges/rover/framework/run_simulator.py 2> simulator.log &
python ~/hack/robo-challenge/challenges/rover/framework/run_gamemaster.py 2> gamemaster.log &
dub
