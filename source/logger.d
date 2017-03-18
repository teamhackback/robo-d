import vibe.core.log;
import std.stdio;

final class StdoutLogger : Logger {

    private {
        File m_curFile;
    }

    this(File outFile = stderr)
    {
        this.m_curFile = outFile;
    }

    override void beginLine(ref LogLine msg)
        @trusted // FILE isn't @safe (as of DMD 2.065)
        {
		string pref;
		final switch (msg.level) {
			case LogLevel.trace: pref = "trc"; break;
			case LogLevel.debugV: pref = "dbv"; break;
			case LogLevel.debug_: pref = "dbg"; break;
			case LogLevel.diagnostic: pref = "dia"; break;
			case LogLevel.info: pref = "INF"; break;
			case LogLevel.warn: pref = "WRN"; break;
			case LogLevel.error: pref = "ERR"; break;
			case LogLevel.critical: pref = "CRITICAL"; break;
			case LogLevel.fatal: pref = "FATAL"; break;
			case LogLevel.none: assert(false);
		}
            auto tm = msg.time;
            static if (is(typeof(tm.fracSecs))) auto msecs = tm.fracSecs.total!"msecs"; // 2.069 has deprecated "fracSec"
            else auto msecs = tm.fracSec.msecs;
            //m_curFile.writef("[%08X:%08X %d.%02d.%02d %02d:%02d:%02d.%03d %s] ",
                    //msg.threadID, msg.fiberID,
                    //tm.year, tm.month, tm.day, tm.hour, tm.minute, tm.second, msecs,
                    //pref);

            m_curFile.writef("[%s:%d %d.%02d.%02d %02d:%02d:%02d.%03d %s] ",
                    msg.file, msg.line, tm.year, tm.month, tm.day, tm.hour, tm.minute, tm.second, msecs,
                    pref);
        }

    override void put(scope const(char)[] text)
    {
        m_curFile.write(text);
    }

    override void endLine()
    {
        m_curFile.writeln();
        m_curFile.flush();
    }
}
