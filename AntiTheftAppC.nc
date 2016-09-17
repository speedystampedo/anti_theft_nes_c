configuration AntiTheftAppC{
}implementation{
 components MainC,
            LedsC,
            AntiTheftC as App;
 components new TimerMilliC() as TimerC;
 components new HamamatsuS10871TsrC() as ReadC;
 
 App.Boot   -> MainC.Boot;
 App.Leds   -> LedsC;

 App.check  -> TimerC;

 /**To read/measure the light intesity sensor*/
 App.Read   -> ReadC; 

 /**Provides the Sender interface to the module*/
 components new AMSenderC(AM_RADIO_COUNT_MSG);
  
 /**Provides the receiver interface to the Module*/
 components new AMReceiverC(AM_RADIO_COUNT_MSG);
  
 /**Provides the Radio Driver intitialization interface to our program..*/
 components ActiveMessageC;
  
 /**Our receive interface depends on is provided by AMReceiverC*/
 App.Receive -> AMReceiverC;
 App.AMSend -> AMSenderC;
 App.AMControl -> ActiveMessageC;
 App.Packet -> AMSenderC;

}
