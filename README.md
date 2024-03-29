# Scroobanizer

    NAME
      scroobanizer.sh --- Show AIX LPAR Network Traffic Information

    SYNOPSIS
      scroobanizer.sh [ options ]

    DESCRIPTION
      This script will show the network activity of an LPAR.

    OPTIONS
      -b, --busy-only Display only busy IP addresses.
      -B, --no-boxes  Do not display 'box' grid in output.
      -t, --trace=TRACEFILE
                      Location to store tcpdump file The default value is /tmp/trace.scroob.sh.20210502-225249.out.
      -o, --outputdir=OUTPUTFILE
                      Directory to redirect the report itself. The default value is .
      -s, --sleep=SLEEP
                      Length in seconds to measure network traffic. The default value is 10.
      -S, --simple-boxes
                      Use simple box ASCII.

    IMPLEMENTATION
      author          David Little <david.n.little@gmail.com>
      copyright       Free to use and modify - Use at own risk.
      license         The MIT License (MIT)

Example Output:

    ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │ scroobanizer: v1.0.0: By David Little                                                                    │
    │ Starting Trace, outputting to /tmp/trace.scroobanizer.sh.20151030-114414.out                             │
    │ 0513-059 The iptrace Subsystem has been started. Subsystem PID is 19661018.                              │
    │ Sleeping for 10 seconds                                                                                  │
    │ Stopping Trace                                                                                           │
    │ 0513-044 The iptrace Subsystem was requested to stop.                                                    │
    ├──────────────────────────────────────────────────────────────────────────────────────────────────────────┤
    │ Generating IP Report and gathering information                                                           │
    │ Report completed.                                                                                        │
    │ Sample Length (seconds): 10                                                                              │
    │ Total Packets In: 3896                                                                                   │
    │ Total Packets Out: 5494                                                                                  │
    │ Discarded Results: 0                                                                                     │
    ├──────────────────────────────────────────────────────────────────────────────────────────────────────────┤
    │ Direction  │ :LPort │        Remote IP:RPort │     IN# │    IN% │    OUT# │   OUT% │> IN%     %OUT <│    │
    │ BOTH       │ :32813 │      10.246.3.24:51001 │     308 │   7.91 │     666 │  12.12 │               <│Busy│
    │ BOTH       │ :32819 │      10.246.3.27:51001 │      45 │   1.16 │      95 │   1.73 │                │    │
    │ BOTH       │ :32822 │     10.192.30.42:50004 │     480 │  12.32 │     373 │   6.79 │>               │    │
    │ BOTH       │ :32823 │      10.246.3.31:51001 │     565 │  14.50 │    1126 │  20.50 │>             <<│Busy│
    │ BOTH       │ :32824 │      10.246.3.32:51001 │     463 │  11.88 │     919 │  16.73 │>              <│Busy│
    │ BOTH       │ :32825 │      10.246.3.33:51001 │      49 │   1.26 │      96 │   1.75 │                │    │
    │ BOTH       │ :32826 │      10.246.3.30:51001 │     461 │  11.83 │     920 │  16.75 │>              <│Busy│
    │ BOTH       │ :32873 │     10.200.30.42:50101 │     312 │   8.01 │     209 │   3.80 │                │    │
    │ BOTH       │ :32897 │      10.246.3.25:51001 │     167 │   4.29 │     366 │   6.66 │                │    │
    │ BOTH       │ :32898 │      10.246.3.26:51001 │     190 │   4.88 │     409 │   7.44 │                │    │
    │ BOTH       │ :50001 │     10.196.30.10:58511 │      63 │   1.62 │      36 │   0.66 │                │    │
    │ BOTH       │ :50002 │     10.196.30.40:43627 │       2 │   0.05 │       4 │   0.07 │                │    │
    │ BOTH       │ :50003 │     10.196.30.25:56845 │      22 │   0.56 │      20 │   0.36 │                │    │
    │ BOTH       │ :50004 │     10.200.30.42:48849 │       2 │   0.05 │       1 │   0.02 │                │    │
    │ BOTH       │ :50005 │     10.200.30.42:48851 │      27 │   0.69 │      10 │   0.18 │                │    │
    │ BOTH       │ :50101 │     10.192.30.42:42042 │     735 │  18.87 │     242 │   4.40 │>               │Busy│
    │ BOTH       │ :8972  │     10.20.200.58:50804 │       4 │   0.10 │       2 │   0.04 │                │    │
    │ INCOMING   │ :22    │    10.20.200.149:58561 │       1 │   0.03 │       0 │   0.00 │                │    │
    ├──────────────────────────────────────────────────────────────────────────────────────────────────────────┤
    │ Busy IP Analysis                                                                                         │
    ├──────────────────────────────────────────────────────────────────────────────────────────────────────────┤
    │   IP: 10.192.30.42:42042                                                                                 │
    │    Network Traffic In: 18.87% Out: 4.40%                                                                 │
    │     Process Found:                                                                                       │
    │          PID: 8388716                                                                                    │
    │          CMD: <REDACTED>                                                                                 │
    │         USER: <REDACTED>                                                                                 │
    │         NAME: 10.196.30.42:50101->10.192.30.42:42042                                                     │
    │         ARGS: <REDACTED>                                                                                 |
    ├──────────────────────────────────────────────────────────────────────────────────────────────────────────┤
    │   IP: 10.246.3.24:51001                                                                                  │
    │    Network Traffic In: 7.91% Out: 12.12%                                                                 │
    │     Process Found:                                                                                       │
    │          PID: 10289212                                                                                   │
    │          CMD: <REDACTED>                                                                                 │
    │         USER: <REDACTED>                                                                                 │
    │         NAME: 10.196.30.42:32813->10.246.3.24:51001                                                      │
    │         ARGS: <REDACTED>                                                                                 │
    ├──────────────────────────────────────────────────────────────────────────────────────────────────────────┤
    │   IP: 10.246.3.30:51001                                                                                  │
    │    Network Traffic In: 11.83% Out: 16.75%                                                                │
    │     Process Found:                                                                                       │
    │          PID: 10485824                                                                                   │
    │          CMD: <REDACTED>                                                                                 │
    │         USER: <REDACTED>                                                                                 │
    │         NAME: 10.196.30.42:32826->10.246.3.30:51001                                                      │
    │         ARGS: <REDACTED>                                                                                 │
    ├──────────────────────────────────────────────────────────────────────────────────────────────────────────┤
    │   IP: 10.246.3.31:51001                                                                                  │
    │    Network Traffic In: 14.50% Out: 20.50%                                                                │
    │     Process Found:                                                                                       │
    │          PID: 10616900                                                                                   │
    │          CMD: <REDACTED>                                                                                 │
    │         USER: <REDACTED>                                                                                 │
    │         NAME: 10.196.30.42:32823->10.246.3.31:51001                                                      │
    │         ARGS: <REDACTED>                                                                                 │
    ├──────────────────────────────────────────────────────────────────────────────────────────────────────────┤
    │   IP: 10.246.3.32:51001                                                                                  │
    │    Network Traffic In: 11.88% Out: 16.73%                                                                │
    │     Process Found:                                                                                       │
    │          PID: 10747976                                                                                   │
    │          CMD: <REDACTED>                                                                                 │
    │         USER: <REDACTED>                                                                                 │
    │         NAME: 10.196.30.42:32824->10.246.3.32:51001                                                      │
    │         ARGS: <REDACTED>                                                                                 │
    ├──────────────────────────────────────────────────────────────────────────────────────────────────────────┤
    │ Removing /tmp/trace.scroobanizer.sh.20151030-114414.out                                                  │
    └──────────────────────────────────────────────────────────────────────────────────────────────────────────┘
