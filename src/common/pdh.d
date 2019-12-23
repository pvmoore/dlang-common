module common.pdh;
/**
 * Performance Data Helper.
 *
 * Example counters:
 * \Processor(0)\% Processor Time
 * \Processor(1)\% Processor Time
 * \Processor(_Total)\% Processor Time
 * \PETE-DESKTOP\Process(bin-test)\Thread Count
 * \Process(bin-test)\IO Read Bytes/sec
 * \Process(bin-test)\IO Write Bytes/sec
 */
version(Win64) {

import common.all;
import std.parallelism : totalCPUs;
import core.sys.windows.windows;

final class PDH {
private:
    HMODULE pdhHandle;
    HANDLE query;
    PDH_HCOUNTER[] counters;
    uint numCores;
    double[] values;
    Semaphore semaphore;
    uint pollingFrequencyMillis;
    bool running = true;
public:
    this(uint pollingFrequencyMillis=1000) {
        this.pollingFrequencyMillis = pollingFrequencyMillis;
        this.numCores = totalCPUs;
        this.counters.length = numCores;
        this.values   = new double[numCores+1];
        this.values[] = 0;
        this.semaphore = new Semaphore;
        auto t = new Thread(&loop);
        t.isDaemon = true;
        t.name = "PDH Polling Thread";
        t.start();

        loadDLL();
        PDH_STATUS status = PdhOpenQueryW(null, 0, &query);
        if(status != ERROR_SUCCESS) {
            writefln("Can't open PDH query: %s", status);
        } else {
            for(auto i=0; i<numCores; i++) {
                wstring s = "\\Processor(%s)\\%% Processor Time"w.format(i);
                check(PdhAddEnglishCounterW(query, s.ptr, 0, counters.ptr+i),
                    "PdhAddEnglishCounterW");
            }

//            check(PdhAddEnglishCounterW(query, "\\Process(bin-test)\\Thread Count"w.ptr, 0, counters.ptr+8),
//                "PdhAddEnglishCounterW");
            check(PdhCollectQueryData(query),
                "PdhCollectQueryData");
        }
    }
    void destroy() {
        running = false;
        if(query) PdhCloseQuery(query);
        if(pdhHandle) FreeLibrary(pdhHandle);
    }
    double getCPUTotalPercentage() {
        return values[$-1];
    }
    double[] getCPUPercentagesByCore() {
        return values[0..$-1];
    }
    void dumpPaths(wstring wildcardPath) {
        DWORD len;
        PDH_STATUS status = PdhExpandWildCardPathW(
            null,
            wildcardPath.ptr,
            null,
            &len,
            0
        );
        if(status==PDH_MORE_DATA) {
            wchar* chars = new wchar[len].ptr;
            writefln("more data len=%s", len);
            status = PdhExpandWildCardPathW(
                null,
                wildcardPath.ptr,
                chars,
                &len,
                0
            );
            wchar* p = chars;
            while(*p) {
                auto w = fromWStringz(p);
                writefln("path=%s", w);
                p += w.length+1;
            }
        }
        writefln("status=%x", status);
    }
    override string toString() {
        return "[CPUUsage cpus=%s]".format(totalCPUs);
    }
private:
    void loadDLL() {
        pdhHandle = LoadLibraryA("Pdh");
        if(pdhHandle) {
            *(cast(void**)&PdhOpenQueryW) = GetProcAddress(pdhHandle, "PdhOpenQueryW"); assert(PdhOpenQueryW);
            *(cast(void**)&PdhCloseQuery) = GetProcAddress(pdhHandle, "PdhCloseQuery"); assert(PdhCloseQuery);
            *(cast(void**)&PdhAddCounterW) = GetProcAddress(pdhHandle, "PdhAddCounterW"); assert(PdhAddCounterW);
            *(cast(void**)&PdhCollectQueryData) = GetProcAddress(pdhHandle, "PdhCollectQueryData"); assert(PdhCollectQueryData);
            *(cast(void**)&PdhGetFormattedCounterValue) = GetProcAddress(pdhHandle, "PdhGetFormattedCounterValue"); assert(PdhGetFormattedCounterValue);
            *(cast(void**)&PdhAddEnglishCounterW) = GetProcAddress(pdhHandle, "PdhAddEnglishCounterW"); assert(PdhAddEnglishCounterW);
            *(cast(void**)&PdhExpandWildCardPathW) = GetProcAddress(pdhHandle, "PdhExpandWildCardPathW"); assert(PdhExpandWildCardPathW);
            *(cast(void**)&PdhGetFormattedCounterArrayW) = GetProcAddress(pdhHandle, "PdhGetFormattedCounterArrayW"); assert(PdhGetFormattedCounterArrayW);

        } else {
            throw new Error("Unable to load Pdh library");
        }
    }
    /**
     * https://msdn.microsoft.com/en-us/library/windows/desktop/aa373046(v=vs.85).aspx
     */
    PDH_STATUS check(PDH_STATUS status, string func) {
        if(status != ERROR_SUCCESS) {
            string msg =
                status == 0xc0000bc6 ? "PDH_INVALID_DATA"
                : "%x".format(status);
            writefln("%s failed: %s", func, msg);
        }
        return status;
    }
    void loop() {
        while(true) {
            semaphore.wait(dur!"msecs"(pollingFrequencyMillis));
            if(!running) break;

            poll();
        }
    }
    void poll() {
        //StopWatch w; w.start();
        check(PdhCollectQueryData(query),
            "PdhCollectQueryData");
        double total = 0;
        double[] values = new double[numCores+1];
        PDH_FMT_COUNTERVALUE value;
        foreach(i, c; counters) {
            check(PdhGetFormattedCounterValue(
                counters[i],
                PDH_FMT_DOUBLE,
                null,
                &value), "PdhGetFormattedCounterValue");
            values[i] = value.u.doubleValue;
            total += values[i];
        }
        values[$-1] = total / 8;
        this.values = values;
        //w.stop();
        //writefln("collect: %s ms", w.peek().nsecs/100000.0);
        // 1.6 -> 4.6 ms
        // 23 ms for thread count
    }
}

//======================================================

struct PDH_FMT_COUNTERVALUE {
    DWORD CStatus;
    union Value_u {
        LONG        longValue;
        double      doubleValue;
        LONGLONG    largeValue;
        LPCSTR      AnsiStringValue;
        LPCWSTR     WideStringValue;
    };
    Value_u u;
}
struct PDH_FMT_COUNTERVALUE_ITEM_W {
    wchar*                  szName;
    PDH_FMT_COUNTERVALUE    FmtValue;
}

//pragma(lib, "pdh.lib");

alias PDH_STATUS   = LONG;
alias PDH_HQUERY   = HANDLE;
alias PDH_HCOUNTER = HANDLE;

const uint PDH_FMT_DOUBLE = 0x00000200;
const uint PDH_FMT_LARGE  = 0x00000400;
const uint PDH_MORE_DATA  = 0x800007D2;

extern(Windows) {
@nogc DWORD GetProcessId(HANDLE Process) @system nothrow;

__gshared PDH_STATUS function(
        const(wchar)* szDataSource,
        DWORD_PTR     dwUserData,
        PDH_HQUERY*   phQuery
    ) PdhOpenQueryW;
__gshared PDH_STATUS function(
        PDH_HQUERY hQuery
    ) PdhCloseQuery;
__gshared PDH_STATUS function(
          PDH_HQUERY     hQuery,
          const(wchar)*  szFullCounterPath,
          DWORD_PTR      dwUserData,
          PDH_HCOUNTER*  phCounter
      ) PdhAddCounterW;
__gshared PDH_STATUS function(
          PDH_HQUERY     hQuery,
          const(wchar)*  szFullCounterPath,
          DWORD_PTR      dwUserData,
          PDH_HCOUNTER*  phCounter
      ) PdhAddEnglishCounterW;
__gshared PDH_STATUS function(
          PDH_HQUERY hQuery
      ) PdhCollectQueryData;
__gshared PDH_STATUS function(
          PDH_HCOUNTER          hCounter,
          DWORD                 dwFormat,
          LPDWORD               lpdwType,
          PDH_FMT_COUNTERVALUE* pValue
      ) PdhGetFormattedCounterValue;
__gshared PDH_STATUS function(
              LPCWSTR szDataSource,
              LPCWSTR szWildCardPath,
              wchar* mszExpandedPathList,
              LPDWORD pcchPathListLength,
              DWORD   dwFlags
          ) PdhExpandWildCardPathW;
__gshared PDH_STATUS function(
          PDH_HCOUNTER hCounter,
          DWORD        dwFormat,
          LPDWORD      lpdwBufferSize,
          LPDWORD      lpdwItemCount,
          PDH_FMT_COUNTERVALUE_ITEM_W* ItemBuffer
      ) PdhGetFormattedCounterArrayW;
}
} // Win64