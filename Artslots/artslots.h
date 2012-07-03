#include <stdarg.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <pthread.h>

typedef uint64_t UINT64;
typedef uint32_t offs_t;
typedef uint8_t UINT8;
typedef int8_t INT8;
typedef uint16_t UINT16;
typedef int16_t INT16;
typedef uint32_t UINT32;
typedef int32_t INT32;

#define INLINE
#define READ8_HANDLER(name) 	UINT8  name(offs_t offset)
#define WRITE8_HANDLER(name) 	void   name(offs_t offset, UINT8 data)
#define READ32_HANDLER(name) UINT32 name(offs_t offset, UINT32 mem_mask)

#include "i2cmem.h"
#include "i8051.h"
#include "ay8910.h"

/* Interrupt line constants */
enum
{
	/* line states */
	CLEAR_LINE = 0,				/* clear (a fired, held or pulsed) line */
	ASSERT_LINE,				/* assert an interrupt immediately */
	HOLD_LINE,					/* hold interrupt line until acknowledged */
	PULSE_LINE,					/* pulse interrupt line for one instruction */

	/* internal flags (not for use by drivers!) */
	INTERNAL_CLEAR_LINE = 100 + CLEAR_LINE,
	INTERNAL_ASSERT_LINE = 100 + ASSERT_LINE,

	/* input lines */
	MAX_INPUT_LINES = 32+3,
	INPUT_LINE_IRQ0 = 0,
	INPUT_LINE_IRQ1 = 1,
	INPUT_LINE_IRQ2 = 2,
	INPUT_LINE_IRQ3 = 3,
	INPUT_LINE_IRQ4 = 4,
	INPUT_LINE_IRQ5 = 5,
	INPUT_LINE_IRQ6 = 6,
	INPUT_LINE_IRQ7 = 7,
	INPUT_LINE_IRQ8 = 8,
	INPUT_LINE_IRQ9 = 9,
	INPUT_LINE_NMI = MAX_INPUT_LINES - 3,

	/* special input lines that are implemented in the core */
	INPUT_LINE_RESET = MAX_INPUT_LINES - 2,
	INPUT_LINE_HALT = MAX_INPUT_LINES - 1,

	/* output lines */
	MAX_OUTPUT_LINES = 32
};

#define CMOS_NVRAM_SIZE 0x1000
#define EEPROM_NVRAM_SIZE   0x200 // 4k Bit

void load_game_roms(NSArray *elt);
NSString *get_game_id(NSArray *elt);
NSString *get_game_name(NSArray *elt);
NSString *get_game_type(NSArray *elt);

NSMutableArray *get_games_arr(void);
void delete_nvram(NSArray *game);
void save_nvram();
void load_nvram();
void emu_init(void);

void die(char *str);

void peplus_load(NSArray *game);
void peplus_stop(void);
void add_game_buttons(UIView *v);
void handle_game_input(CGRect frameRect, CGRect screenRect, UITouch *t, CGPoint p);
void handle_game_output(UINT8 data);