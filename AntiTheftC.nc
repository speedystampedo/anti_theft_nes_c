#include "Timer.h"
#include "RadioCountToLeds.h"
/**This include allows to visualize string messages on the screen*/
#include "printf.h"

module AntiTheftC{
    uses{
	interface Timer<TMilli> as check;
	interface Read<uint16_t> as Read;
	interface Leds;
	interface Boot;
    	interface Receive;
    	interface AMSend;
    	interface SplitControl as AMControl;
    	interface Packet;
    }
}implementation{

  /**We declare a radio buffer variable*/
  message_t packet;

  bool locked; /**acts like a MUTEX*/
  bool stolen = FALSE;
  uint8_t counter = 0; /**a simple counter*/
  char *msg2send ="Hello Antonio"; /**the message we want to transmit*/
  char *theftMsg2Send = "theft";
  char *releaseMsg2Send = "release";
  
  /**This event initializes the radio driver invoking command  AMControl.start()*/

  
  /**Once the radio is initialized, an event is triggered indicating the success
   or failure of the action*/
  event void AMControl.startDone(error_t err) {
    /**if the radio was successfully initialized err==SUCCESS*/
    if (err == SUCCESS) {
      /**We start a periodic timer with a frequency of 500ms*/
      call check.startPeriodic(500);
    }
    else {
      /**Else, we try again to initialize the radio*/
      call AMControl.start();
    }
  }

  /**THis event is called when the radio is stopped*/
  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  
  /**Since we have started the timer to run periodically, this event will be
   invoked every 500ms, however, asynchronously*/
  event void check.fired() {
    /**We increment the counter*/
    call Read.read();
    
  }
  task void send_message(){
    dbg("RadioCountToLedsC", "RadioCountToLedsC: timer fired, counter is %hu.\n", counter);
    /**if we are locked, i.e message being transmitted, we do nothing*/
    if (locked) {
      return;
    }
    else { /**else, we send a radio packet*/
      /**First we acquire the network/radio buffer to write the contents of our message*/
      radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));
      /**if the reserved region of memory is not valid we return (abort the operation)*/
      if (rcm == NULL) {
        return;
      }
      /**Otherwise, we write our message to the buffer*/
      rcm->counter = counter;
      /**here we copy our string message to the field ->data of the message structure*/
      strcpy((char*)rcm->data, msg2send);
      /**Here we can the radio driver to send the message wirelessly*/
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
        dbg("RadioCountToLedsC", "RadioCountToLedsC: packet sent.\n", counter);
        /**If the operation succeeded, we lock the MUTEX variable, to wait for a message completion
        event*/
        locked = TRUE;
      }
    }
  }
 /**This interface receives a packet that was transmitted to the node wirelessly.*/
  event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
    dbg("RadioCountToLedsC", "Received packet of length %hhu.\n", len);
    /**If the size of the message received is not the one we are expecting,
     we ignore the message*/
    if (len != sizeof(radio_count_msg_t)) {
      return bufPtr;
      
    } /**Otherwise, we process the message*/
    else {
      /**Here we do a TYPECAST, i.e, re-acquire the contents of the packets to map to our message structure*/
      radio_count_msg_t* rcm = (radio_count_msg_t*)payload;
      /**We try display a binary counter*/
      if (rcm->counter == 1) {
	       call Leds.led1On();
      }
      else if (rcm->counter == 0) {
         call Leds.led1Off();
      }     
      return bufPtr;
    }
  }

  /**This event is signaled upon completion of the send packet operation*/
  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      /**Since the packet transmitted pointer is pointing to the same region to the 
       succeeded event, we can unlock the MUTEX.*/
      locked = FALSE;
    }
  }
  event void Boot.booted( ){
     /**This command  will */
	call AMControl.start();

  }
  


  event void Read.readDone(error_t err, uint16_t data_value){
  	if(err == SUCCESS && data_value < 30){
      stolen = TRUE;
  		call Leds.led0Toggle(); //flash led0 when self is stolen
  		//Send a message to neighbours saying it is stolen
      counter = 1;
      post send_message();
  	}  
    else if(err == SUCCESS && data_value > 30 && stolen){
      stolen = FALSE;
      call Leds.led0Off(); //turn off LED here
      //send the release message
      counter = 0;
      post send_message();
    }

  }
}


