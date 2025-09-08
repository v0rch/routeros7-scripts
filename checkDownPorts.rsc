:local targetPorts [:toarray "ether1,ether5,ether24"]; #Target ports to check
:global rebootInfo; # global variable
:if ([:len $rebootInfo]=0) do={ # check global var if not defined
   :global rebootInfo {init="init"};
}

:foreach portName in=$targetPorts do={
  :local interfaceId [/interface ethernet find where name=$portName]
  :if ([:len $interfaceId] > 0) do={
    :local interfaceComment [/interface ethernet get $interfaceId comment]; # take comment for port
    :if (![/interface ethernet get $interfaceId running]) do={
        :if ([/system clock get date] != ($rebootInfo->$portName)) do={ # if current date not equal reboot info date for this port rebooting port
          /interface ethernet set $portName disabled=yes
          delay 2s;
          /interface ethernet set $portName disabled=no
          :set ($rebootInfo->$portName) [/system clock get date];
          :log warning ("Port ". $portName.": ". $interfaceComment." was rebooted")
          :put ("Port " . $portName.": ". $interfaceComment ." is down. Rebooting");
       } else={ #
          :log warning ("Port ". $portName.": ". $interfaceComment." is NOT rebooted, because it was rebooted early.")
       }
    }
  }
}
