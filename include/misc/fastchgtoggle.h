#ifndef _LINUX_FASTCHGTOGGLE_H
 #define _LINUX_FASTCHGTOGGLE_H
 
 #define FAST_CHARGE_DISABLED 0
 #define FAST_CHARGE_ENABLED 1
 
 extern int fast_chg_enabled;
 
 bool fast_chg_allowed(void);
 
 #endif
