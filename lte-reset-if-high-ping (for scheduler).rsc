:local botToken "<API_TELEGRAM_TOKEN>"
:local chatId "<TELEGRAM_CHAT_ID>"
:local threadId "<TELEGRAM_TOPIC_ID>"
:local thresholdTime 1000
:local pingCount 3
:local pingTimeout 1000

# Calculate max Response time
:local maxRtt 0
:for i from=1 to=$pingCount do={
    :local result [/ping 8.8.8.8 count=1 as-value];
    :if ($result->"status" = "timeout") do={
        :set maxRtt $pingTimeout
    } else={
        :local pingTime ($result->"time");
        :local rtt ( ([:tonum [:pick $pingTime 6 8]] * 1000) + [:tonum [:pick $pingTime 9 12]] ); #convert time format to ms
        :if ($rtt > $maxRtt) do={
            :set maxRtt $rtt
        }
    }
}
:put $maxRtt; # if run from terminal you can check Max Response Time from script

# Checking for max RTT > 1000
:if ($maxRtt >= $thresholdTime) do={
    :local message ("<b>".[/system/identity/get name]." (".[ip/neighbor/get 0 identity]."):</b> Current response time $maxRtt ms higher then $thresholdTime ms. <b>🤷‍♂️Rebooting lte interface</b>" );
    /tool fetch url="https://api.telegram.org/bot$botToken/sendMessage?chat_id=$chatId&message_thread_id=$threadId&text=$message&parse_mode=HTML" keep-result=no;
    :log warning "High latency detected: $maxRtt ms. Restarting LTE interface lte1"
    /interface disable lte1
    :delay 3
    /interface enable lte1
    :delay 60
    :local pingTime ([/ping 8.8.8.8 count=1 as-value]->"time");
    :local rtt ( ([:tonum [:pick $pingTime 6 8]] * 1000) + [:tonum [:pick $pingTime 9 12]] ); #convert time format to ms
    :local message ("<b>".[/system/identity/get name]." (".[ip/neighbor/get 0 identity]."):</b> Current response time $rtt ms after LTE reset." );
    /tool fetch url="https://api.telegram.org/bot$botToken/sendMessage?chat_id=$chatId&message_thread_id=$threadId&text=$message&parse_mode=HTML" keep-result=no;
} else={
    :log info "LTE interface lte1 is operating normally with latency $maxRtt ms."
}
