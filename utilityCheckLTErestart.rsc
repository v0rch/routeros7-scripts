# ROS7 Script
# Author: Ivan Vassilyev (@v0rch1g)

:local checkDuration 10; # В течение 10 секунд проверяется интерфейс.
:local threshold 10000000;  # Если скорость ниже 10 Мбит/с, то lte интерфейс будет перезагружен
:local maxRetries 3; # Максимальное количество перезагрузок LTE интерфейсов
:local retryCount 0; # Счётчик перезагрузок
:local botToken ""; # Telegram bot token
:local chatId ""; # Telegram Chat ID
:local threadId ""; # Telegram thread ID

:global lteRestartedCount;  # Счётчик перезагрузок LTE
:if ([:typeof $lteRestartedCount] = "nothing") do={
    :set lteRestartedCount 0;
}

:local lteBefore [/interface/lte/monitor lte1 once as-value]

:local speed 0
:for i from=1 to=$checkDuration do={
    :set speed ($speed + ([interface/monitor-traffic lte1 once as-value]->"tx-bits-per-second"))
    :delay 1s;
}

:local avgSpeed ($speed / 10)
:if ( $avgSpeed < $threshold ) do {
  :if ($lteRestartedCount < $maxRetries) do={
    #Если скорость ниже, то перезагружаем lte интерфейс и сообщаем новые данные
    :log info ("Restarting LTE interface because speed ". ($avgSpeed / 1000). "Kbps it's below than ".($threshold/1000)."Kbps");
    /interface/lte/disable 0;
    delay 3s;
    /interface/lte/enable 0;
    delay 30s;
    :set lteRestartedCount ($lteRestartedCount + 1);
    :log info ("LTE has been restarted ". $lteRestartedCount ." time(s)");
    :local lteAfter [/interface/lte/monitor lte1 once as-value]
    :local speedMessage ("average speed <b>". ($avgSpeed / 1000). "Kbps</b> was 🔻bellow than ".($threshold/1000)."Kbps")
    :local message ("<b>". [/system/identity/get name] . " (". [ip/neighbor/get 0 identity] . "): </b>😒 LTE interface has been restarted by SpeedCheck Scheduler because ".  $speedMessage ."%0A SXT uptime: <b>" . [system/resource/get uptime]. "</b>. %0A <b>📶LTE params (before reset ➡️ current)</b> %0A  " . ($lteBefore->"earfcn").($lteBefore->"primary-band")." ➡️ ". ($lteAfter->"earfcn"). ($lteAfter->"primary-band"). " %0A SINR " . ($lteBefore->"sinr") . "db ➡️ ". ($lteAfter->"sinr"). "db %0A RSRP " . ($lteBefore->"rsrp") . "dBm ➡️ ". ($lteAfter->"rsrp"). "dBm %0A RSRQ  " . ($lteBefore->"rsrq") . "dBm ➡️". ($lteAfter->"rsrq"). "dBm");
    /tool fetch url="https://api.telegram.org/bot$botToken/sendMessage?chat_id=$chatId&message_thread_id=$threadId&text=$message&parse_mode=HTML" keep-result=no;
  } else={
       # Если достигнуто максимальное количество перезагрузок
        :log warning ("LTE interface restart limit reached (" . $maxRetries . " attempts). No further restarts will be performed.");
        :local message ("<b>". [/system/identity/get name] . " (". [ip/neighbor/get 0 identity] . "): </b> 🛑 LTE interface restart limit reached. No further restarts will be performed. Average speed: <b>" . ($avgSpeed / 1000). "Kbps</b>");
        /tool fetch url="https://api.telegram.org/bot$botToken/sendMessage?chat_id=$chatId&message_thread_id=$threadId&text=$message&parse_mode=HTML" keep-result=no;
  }
}
