/*
 *  RouterCommands.h
 *  µH Router
 *
 *  Created by Kok Chen on 5/19/06.
 */

//  Most significant two bits: ROUTER/KEYER/WRITE-ONLY KEYER
#define	ROUTERFUNCTION	0x80
#define	KEYERFUNCTION	0x40							//  Note: write-only KEYER is 0xc0
#define	INTERNAL		0x00

#define	CLOSEFUNCTION	0x20

#define	FUNCTIONMASK	0x1f
#define	WRITEONLY		0x80							//  v1.13 write only flag

//  Commands sent to the master port

#define	OPENMICROKEYER	( ROUTERFUNCTION + 0x01 )		//  get a port to the microKEYER router
#define	OPENCWKEYER		( ROUTERFUNCTION + 0x02 )		//  get a port to the CW KEYER router
#define	OPENDIGIKEYER	( ROUTERFUNCTION + 0x03 )		//  get a port to the DIGI KEYER router
#define	QUITIFNOKEYER	( ROUTERFUNCTION + 0x1f )		//  quit if there are no keyers
#define	QUITIFNOTINUSE	( ROUTERFUNCTION + 0x1e )		//  quit if not connected
#define	QUITALWAYS		( ROUTERFUNCTION + 0x1d )		//  quit
#define	OPENKEYER		( ROUTERFUNCTION + 0x08 )		//	get a port to keyer from following keyerID (char*)
#define	KEYERID			( ROUTERFUNCTION + 0x09 )		//	get Keyer ID (null terminated string) of the nth keyer (next byte after command)

//  Commands sent to the router ports (numbers are within FUNCTIONMASK)

#define	ROUTERPORT		( KEYERFUNCTION + 0x01 )			//  (reserved for router internal use)
#define	OPENRADIO		( KEYERFUNCTION + 0x02 )			//  get a RADIO port
#define	OPENCONTROL		( KEYERFUNCTION + 0x03 )			//  get a CONTROL port
#define	OPENPTT			( KEYERFUNCTION + 0x04 )			//  get a port to the PTT flag bit
#define	OPENCW			( KEYERFUNCTION + 0x05 )			//  get a port to the serial CW flag bit
#define OPENRTS			( KEYERFUNCTION + 0x06 )			//  get a port to the RTS flag bit
#define	OPENFSK			( KEYERFUNCTION + 0x07 )			//  get an FSK port
#define	OPENWINKEY		( KEYERFUNCTION + 0x08 )			//  get the WinKey port
#define	OPENFLAGS		( KEYERFUNCTION + 0x09 )			//  get the FLAGS port
#define	OPENEMULATOR	( KEYERFUNCTION + 0x0a )			//  get the WinKey Emulator port (only in ÂµH Router; not in microHAM keyers

//  v1.11u -- for testing
#define	OPENDEBUGRADIO	( KEYERFUNCTION + 0x12 )			//  get a debug RADIO port
#define	CLOSEDEBUGRADIO	( CLOSEFUNCTION + OPENDEBUGRADIO )	//  close a debug RADIO port

//  Ports that are reserved (but not yet used by microHAM) 
//  These are changed at v1.3

#define	OPENFSK2		( OPENFSK + 0x10 )					//  get an FSK port (not implement yet on any keyer)
#define	OPENPTT2		( OPENPTT + 0x10 )					//  get the second PTT port (not implement yet on any keyer)
#define	OPENCW2			( OPENCW  + 0x10 )					//  get the second serial CW port (not implement yet on any keyer)
#define	OPENRTS2		( OPENRTS + 0x10 )					//  get the second RTS port (not implement yet on any keyer)


#define	CLOSERADIO		( CLOSEFUNCTION + OPENRADIO )		//  close a RADIO port
#define	CLOSECONTROL	( CLOSEFUNCTION + OPENCONTROL )		//  close a CONTROL port
#define	CLOSEPTT		( CLOSEFUNCTION + OPENPTT )			//  close a port to the PTT flag bit
#define	CLOSECW			( CLOSEFUNCTION + OPENCW )			//  close a port to the serial CW flag bit
#define CLOSERTS		( CLOSEFUNCTION + OPENRTS )			//  close a port to the RTS flag bit
#define	CLOSEFSK		( CLOSEFUNCTION + OPENFSK )			//  close an FSK port
#define	CLOSEWINKEY		( CLOSEFUNCTION + OPENWINKEY )		//  close the WinKey port
#define	CLOSEFLAGS		( CLOSEFUNCTION + OPENFLAGS )		//  close the FLAGS port
#define	CLOSEEMULATOR	( CLOSEFUNCTION + OPENEMULATOR )	//  close the WinKey Emulator port

#define	CLOSEKEYER		( KEYERFUNCTION + FUNCTIONMASK ) 

//  The following are for internal Router use only
#define	_UPDATEKEYER_	( INTERNAL + 0x1f ) 
#define	_QUITKEYER_		( INTERNAL + 0x1e ) 

//  Bits in write FLAGS channel

#define	RTSFLAG				0x01
#define	EXTRTSFLAG			0x02
#define	PTTFLAG				0x04
#define	EXTPTTFLAG			0x08
#define	CWFLAG				0x40
#define	EXTCWFLAG			0x80

// Bits in read FLAGS channel

#define	CTSFLAG				0x01
#define	EXTCTSFLAG			0x02
#define	EXTFOOTSWITCHFLAG	0x04
#define	SQUELCHFLAG			0x10
#define	FSKBUSYFLAG			0x20
#define	ANYPTTFLAG			0x40
#define	FOOTSWITCHFLAG		0x80

