COMPONENT=AntiTheftAppC
#This FLAGS allow to use the printf function...
CFLAGS += -I$(TOSDIR)/lib/printf
CFLAGS += -DPRINTF_BUFFER_SIZE=40



include $(MAKERULES)

