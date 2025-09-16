module common.utils.timing;
/**
 *
 */
import std.datetime.stopwatch   : StopWatch;
import std.format               : format;

final class Timing {
private:
    uint period;
    uint depth;
    ulong[] totals;
    uint[] counts;
    ulong[] lowests;
    ulong[] highests;
    StopWatch watch;
public:
    double average(uint i) {
        if(counts[i]==0) return 0;
        return (cast(double)totals[i]/counts[i])/1000000.0;
    }
    double lowest(uint i) {
        return (cast(double)lowests[i]/period)/1000000.0;
    }
    double highest(uint i) {
        return (cast(double)highests[i]/period)/1000000.0;
    }

    this(uint period, uint depth) {
        this.period = period;
        this.depth  = depth;
        this.totals.length = depth;
        this.counts.length = depth;
        this.lowests.length = depth;
        this.highests.length = depth;
        reset();
    }
    void reset() {
        lowests[]  = ulong.max;
        highests[] = 0;
        counts[]   = 0;
        totals[]   = 0;
    }
    void startFrame() {
        watch.reset();
        watch.start();
    }
    void endFrame() {
        watch.stop();
        endFrame(watch.peek().total!"nsecs");
    }
    void endFrame(ulong nsecs) {
        recurse(nsecs, 0);
    }
    override string toString() {
        string s = "";
        if(depth>1) s ~= "(";
        for(auto i=0; i<depth; i++) {
            string tmp;
            if(i<depth-1)
                tmp ~= "%.1f";
            else
                tmp ~= "%.2f";
            if(i>0) {
                if(i==depth-1) s ~= ")";
                s ~= " ";
            }
            s ~= tmp.format(average(i));
        }
        return s ~ " ms";
    }
private:
    void recurse(ulong runtime, uint i) {

        ulong min(ulong a, ulong b) {
            return a<b ? a : b;
        }
        ulong max(ulong a, ulong b) {
            return a>b ? a : b;
        }

        if(counts[i]<period) {
            totals[i] += runtime;
            counts[i] += 1;
        } else {
            lowests[i]  = min(lowests[i], totals[i]);
            highests[i] = max(highests[i], totals[i]);

            totals[i] = runtime;
            counts[i] = 1;

            if(i+1<depth) {
                ulong average = totals[i]/counts[i];
                recurse(average, i+1);
            }
        }
    }
}




