#import "RootViewController.h"
#import "Helper.h"
#import "SlotInputView.h"

void debuglog(const char *fmt, ... )
{
    return;
    va_list v;
    char buf[ 1024 ];
    va_start( v, fmt );
    vsnprintf( buf, 1023, fmt, v );
    va_end( v );
    fprintf(stderr,  "%s\n", buf );
}

void errorlog(const char *fmt, ... )
{
    va_list v;
    char buf[ 1024 ];
    va_start( v, fmt );
    vsnprintf( buf, 1023, fmt, v );
    va_end( v );
    fprintf(stderr,  "%s\n", buf );
}

void logerror(const char *fmt, ... )
{
    va_list v;
    char buf[ 1024 ];
    va_start( v, fmt );
    vsnprintf( buf, 1023, fmt, v );
    va_end( v );
    fprintf(stderr,  "%s\n", buf );
}

void die(char *str)
{
	fprintf(stderr, "%s\n", str);
	exit(1);
}

int irq_callback(int data)
{
	debuglog("irq_callback\n");
	return 0;
}

uint8_t program_rom[0x10000];
uint8_t user_rom[0x10000];
uint8_t gfx_rom[0x20000];
uint8_t color_prom[0x200];
uint8_t data_ram[0x10000];
uint8_t io_port[0x4];
uint8_t palette_ram[0x3000];
uint8_t palette_ram2[0x3000];

static UINT8 wingboard;
static UINT8 jumper_e16_e17;

/* Variables used instead of CRTC6845 system */
static UINT8 vid_register = 0;
static UINT8 vid_low = 0;
static UINT8 vid_high = 0;

/* Coin, Door, Hopper and EEPROM States */
static UINT32 last_cycles;
static UINT8 coin_state = 0;
static UINT32 last_door = 0;
static UINT8 door_open = 0;
static UINT8 hopper_full = 1;
static UINT8 low_battery = 1;
static UINT32 last_coin_out = 0;
static UINT8 coin_out_state = 0;
static int sda_dir = 0;

UINT8 eeprom_nvram[EEPROM_NVRAM_SIZE];
UINT8 input_touch_x = 0;
UINT8 input_touch_y = 0;
UINT8 input_sensor = 0;
UINT8 input_door = 0;
UINT8 input_bank_b = 0;
UINT8 input_bank_c = 0;
UINT8 output_bank_a = 0;
UINT8 output_bank_b = 0;
UINT8 output_bank_c = 0;

extern UINT64 i8051_total_cycles;
UINT8 palette_rgba[256][4];
UINT8 palette_rgb565[256][2];
UINT8 gfxtile_indexed[0x1000][64];
UINT8 gfxtile_rgba[0x1000][64*4];
UINT8 gfxtile_rgb565[0x1000][64*2];
UINT16 samplebuffer[9600000];
int sampleindex = 0;
UINT64 samplelastcycles = 0;
int clobber_sound = 0;

void *ay8910 = NULL;

#define INPUT_JACKPOT_RESET 1
#define INPUT_SELF_TEST 2
#define INPUT_DEAL_SPIN_START 1
#define INPUT_MAX_BET 2
#define INPUT_PLAY_CREDIT 4
#define INPUT_CASHOUT 5
#define INPUT_CHANGE_REQUEST 6
#define INPUT_BILL_ACCEPTOR 7


/* External RAM Callback for I8052 */
static READ32_HANDLER( peplus_external_ram_iaddr )
{
	if (mem_mask == 0xff) {
        debuglog("peplus_external_ram_iaddr 0x00ff %d", (io_port[2] << 8) | (offset & 0xff));
		return (io_port[2] << 8) | (offset & 0xff);
	} else {
        debuglog("peplus_external_ram_iaddr %d", offset);
		return offset;
	}
}

static READ8_HANDLER( peplus_crtc_display_r )
{
    debuglog("peplus_crtc_register_r %d %d", offset, vid_register);
    UINT16 vid_address = ((vid_high<<8) | vid_low) + 1;
    vid_high = (vid_address>>8) & 0x3f;
    vid_low = vid_address& 0xff;
    
    return 0x00;
}

static READ8_HANDLER( peplus_crtc_lpen1_r )
{
    errorlog("UNSUPPORTED peplus_crtc_status_r");
    return 0x40;
}

static READ8_HANDLER( peplus_crtc_lpen2_r )
{
        errorlog("peplus_crtc_lpen2_r");
    UINT8 ret_val = 0x00;
    UINT8 x_val = input_touch_x;
    UINT8 y_val = 0x19 - input_touch_y;
    UINT16 t_val = y_val * 0x28 + (x_val+1);
    
	switch(vid_register) {
		case 0x10:  /* Light Pen Address High */
			ret_val = (t_val >> 8) & 0x3f;
			break;
		case 0x11:  /* Light Pen Address Low */
			ret_val = t_val & 0xff;
			break;
        default:
            debuglog("UNSUPPORTED peplus_crtc_lpen2_r");
	}
    
    return ret_val;
}

static WRITE8_HANDLER( peplus_crtc_mode_w )
{
    debuglog("peplus_crtc_mode_w");
	/* Mode Control - Register 8 */
	/* Sets CRT to Transparent Memory Addressing Mode */
}

static WRITE8_HANDLER( peplus_crtc_register_w )
{
    vid_register = data;
    debuglog("peplus_crtc_address_w %d %d", data, vid_register);
}

static WRITE8_HANDLER( peplus_crtc_address_w )
{
    debuglog("peplus_crtc_register_w %d %d", data, vid_register);
	switch(vid_register) {
		case 0x12:  /* Update Address High */
			vid_high = data & 0x3f;
			break;
		case 0x13:  /* Update Address Low */
			vid_low = data;
			break;
        default:
            debuglog("UNSUPPORTED peplus_crtc_register_w %.2x %d", data, vid_register);
	}
}

static WRITE8_HANDLER( peplus_crtc_display_w )
{
	UINT16 vid_address = (vid_high<<8) | vid_low;
	data_ram[0x6000+vid_address] = data;
	palette_ram[vid_address] = io_port[1];
	palette_ram2[vid_address] = io_port[3];

    debuglog("peplus_crtc_display_w %.4x %.2x %.2x", vid_address, data, io_port[1]);
    if (vid_address < 1000) {
        extern unsigned char *videobuf;
        UINT8 *src = gfxtile_indexed[(io_port[1]&0xf)*256+data];
        UINT8 *dst = &videobuf[(((vid_address)/40)*320*8*2)+((vid_address)%40)*8*2];
        int i, j;
        for(i=0; i<8; i++) {
            for(j=0; j<8; j++) {
                *dst++ = palette_rgb565[(io_port[1]&0xf0)+*src][0];
                *dst++ = palette_rgb565[(io_port[1]&0xf0)+*src][1];
                src++;
            }
            dst += 39*8*2;
        }
    }
	peplus_crtc_display_r(0);
}

static READ8_HANDLER( peplus_io_r )
{
    debuglog("peplus_io_r %d %d", offset, io_port[offset]);
    return io_port[offset];
}

static WRITE8_HANDLER( peplus_io_w )
{
    debuglog("peplus_io_w %d %d", offset, data);
	io_port[offset] = data;
}

static READ8_HANDLER( peplus_duart_r )
{
    errorlog("UNSUPPORTED peplus_duart_r");
	// Used for Slot Accounting System Communication
	return 0xff;
}

static WRITE8_HANDLER( peplus_duart_w )
{
    errorlog("UNSUPPORTED peplus_duart_w");
	// Used for Slot Accounting System Communication
}

static void peplus_load_superdata(int region)
{
        debuglog("peplus_load_superdata %d", region);
    UINT8 *super_data = user_rom[region];

    memcpy(&data_ram[0x3000], &super_data[0x3000], 0x1000);
    memcpy(&data_ram[0x5000], &super_data[0x5000], 0x1000);
    memcpy(&data_ram[0x7000], &super_data[0x7000], 0x1000);
    memcpy(&data_ram[0xb000], &super_data[0xb000], 0x1000);
    memcpy(&data_ram[0xd000], &super_data[0xd000], 0x1000);
    memcpy(&data_ram[0xf000], &super_data[0xf000], 0x1000);
}

static WRITE8_HANDLER( peplus_output_bank_a_w )
{
    debuglog("peplus_output_bank_a_w %d %llu", data, i8051_total_cycles);
output_bank_a = data;
#if 0
	output_set_value("pe_bnka0",(data >> 0) & 1); /* Coin Lockout */
	output_set_value("pe_bnka1",(data >> 1) & 1); /* Diverter */
	output_set_value("pe_bnka2",(data >> 2) & 1); /* Bell */
	output_set_value("pe_bnka3",(data >> 3) & 1); /* N/A */
	output_set_value("pe_bnka4",(data >> 4) & 1); /* Hopper 1 */
	output_set_value("pe_bnka5",(data >> 5) & 1); /* Hopper 2 */
	output_set_value("pe_bnka6",(data >> 6) & 1); /* specific to a kind of machine */
	output_set_value("pe_bnka7",(data >> 7) & 1); /* specific to a kind of machine */
#endif
    coin_out_state = 0;
    if(((data >> 4) & 1) || ((data >> 5) & 1))
        coin_out_state = 3;
}

static WRITE8_HANDLER( peplus_output_bank_b_w )
{
    debuglog("peplus_output_bank_b_w %d", data);
    extern TouchInputView *inputView;
//    [inputView performSelectorOnMainThread:@selector(handleGameOutput:) withObject:[NSNumber numberWithUnsignedInt:data] waitUntilDone:YES];
    output_bank_b = data;
}

static WRITE8_HANDLER( peplus_output_bank_c_w )
{
    debuglog("peplus_output_bank_c_w %d", data);
    output_bank_c = data;
#if 0
    output_set_value("pe_bnkc0",(data >> 0) & 1); /* Coin In Meter */
	output_set_value("pe_bnkc1",(data >> 1) & 1); /* Coin Out Meter */
	output_set_value("pe_bnkc2",(data >> 2) & 1); /* Coin Drop Meter */
	output_set_value("pe_bnkc3",(data >> 3) & 1); /* Jackpot Meter */
	output_set_value("pe_bnkc4",(data >> 4) & 1); /* Bill Acceptor Enabled */
	output_set_value("pe_bnkc5",(data >> 5) & 1); /* SDS Out */
	output_set_value("pe_bnkc6",(data >> 6) & 1); /* N/A */
	output_set_value("pe_bnkc7",(data >> 7) & 1); /* Game Meter */
#endif
}

static WRITE8_HANDLER(i2c_nvram_w)
{
	i2cmem_write(0, I2CMEM_SCL, (data & 0x04) ? 1 : 0);
	sda_dir = (data & 0x02) ? 1 : 0;
	i2cmem_write(0, I2CMEM_SDA, (data & 0x01) ? 1 : 0);
    debuglog("i2c_nvram_w %d", data);
}

static READ8_HANDLER( peplus_bgcolor_r )
{
    errorlog("peplus_bgcolor_r %.2x", data_ram[0x6000]);
	return data_ram[0x6000];
}

static WRITE8_HANDLER( peplus_bgcolor_w )
{
    errorlog("peplus_bgcolor_w %d", data);
	int i;

	for (i = 0; i < 16; i++)
	{
		int bit0, bit1, bit2, r, g, b;
        
		/* red component */
		bit0 = (~data >> 0) & 0x01;
		bit1 = (~data >> 1) & 0x01;
		bit2 = (~data >> 2) & 0x01;
		r = 0x21 * bit2 + 0x47 * bit1 + 0x97 * bit0;
        
		/* green component */
		bit0 = (~data >> 3) & 0x01;
		bit1 = (~data >> 4) & 0x01;
		bit2 = (~data >> 5) & 0x01;
		g = 0x21 * bit2 + 0x47 * bit1 + 0x97 * bit0;
        
		/* blue component */
		bit0 = (~data >> 6) & 0x01;
		bit1 = (~data >> 7) & 0x01;
		bit2 = 0;
		b = 0x21 * bit2 + 0x47 * bit1 + 0x97 * bit0;
        
        UINT16 rgb = ((r >> 3) << 11) | (( g >> 2) << 5 ) | (( b >> 3 ) << 0 );
        memcpy(palette_rgb565[15 + (i*16)], &rgb, 2);
	}
    data_ram[0x6000] = data;
}

static READ8_HANDLER( peplus_dropdoor_r )
{
    errorlog("UNSUPPORTED peplus_dropdoor_r");
	return 0xff; // Drop Door 0x00=Closed 0x02=Open
}

static READ8_HANDLER( peplus_watchdog_r )
{
    debuglog("UNSUPPORTED peplus_watchdog_r");
	return 0x00;
}

static READ8_HANDLER( peplus_input_bank_bc_r )
{
    UINT8 val = (input_bank_b<<4)|input_bank_c;
    return ~val;
}

static READ8_HANDLER( peplus_input_bank_a_r )
{
/*
        Bit 0 = COIN DETECTOR A
        Bit 1 = COIN DETECTOR B
        Bit 2 = COIN DETECTOR C
        Bit 3 = COIN OUT
        Bit 4 = HOPPER FULL
        Bit 5 = DOOR OPEN
        Bit 6 = LOW BATTERY
        Bit 7 = I2C EEPROM SDA
*/
	UINT8 coin_optics = 0x00;
    UINT8 coin_out = 0x00;
	UINT64 curr_cycles = i8051_total_cycles;
	UINT16 door_wait = 3000;
    

	UINT8 sda = 0;
	if(!sda_dir)
	{
		sda = i2cmem_read(0, I2CMEM_SDA);
            debuglog("peplus_input_bank_a_r sda %d", sda);
	}

	if ((input_sensor>0) && (coin_state == 0)) {
        fprintf(stderr, "coin in\n");
        input_sensor--;
		coin_state = 1; // Start Coin Cycle
		last_cycles = i8051_total_cycles;
	} else {
		/* Process Next Coin Optic State */
		if (curr_cycles - last_cycles > 20000 && coin_state != 0) {
			coin_state++;
			if (coin_state > 5)
				coin_state = 0;
			last_cycles = i8051_total_cycles;
		}
	}

	switch (coin_state)
	{
		case 0x00: // No Coin
			coin_optics = 0x00;
			break;
		case 0x01: // Optic A
			coin_optics = 0x01;
			break;
		case 0x02: // Optic AB
			coin_optics = 0x03;
			break;
		case 0x03: // Optic ABC
			coin_optics = 0x07;
			break;
		case 0x04: // Optic BC
			coin_optics = 0x06;
			break;
		case 0x05: // Optic C
			coin_optics = 0x04;
			break;
	}

	if (wingboard)
		door_wait = 12345;

	if (curr_cycles - last_door > door_wait) {
		if (input_door) {
            door_open = 1;
        } else {
			door_open = (!door_open & 0x01);
//		} else {
//			door_open = 1;
        }
		last_door = i8051_total_cycles;
	}

	if (curr_cycles - last_coin_out > 600000 && coin_out_state != 0) { // Guessing with 600000/12
		if (coin_out_state != 2) {
            coin_out_state = 2; // Coin-Out Off
        } else {
            coin_out_state = 3; // Coin-Out On
        }

		last_coin_out = i8051_total_cycles;
	}

    switch (coin_out_state)
    {
        case 0x00: // No Coin-Out
	        coin_out = 0x00;
	        break;
        case 0x01: // First Coin-Out On
	        coin_out = 0x08;
	        break;
        case 0x02: // Coin-Out Off
	        coin_out = 0x00;
	        break;
        case 0x03: // Additional Coin-Out On
	        coin_out = 0x08;
	        break;
    }

	return (sda<<7) | (low_battery<<6) | (door_open<<5) | (hopper_full<<4) | coin_optics | coin_out;

/*    fprintf(stderr, "peplus_input_bank_a_r ");
    for(int i=7; i>=0; i--) {
        if (bank_a & (1<<i)) {
            fprintf(stderr, "1");
        } else {
            fprintf(stderr, "0");
        }
    }
    fprintf(stderr, "\n");*/
    
}

READ8_HANDLER(peplus_superboard_r)
{
	debuglog("superboard data_read_byte_8 %.4x %d", offset, data_ram[offset]);
	return user_rom[offset];
}

WRITE8_HANDLER(peplus_superboard_w)
{
	errorlog("superboard data_write_byte_8 %.4x %d", offset, data);
}

UINT8 peplus_other_r(offs_t offset, char *name)
{
	debuglog("UNSUPPORTED %s data_read_byte_8 %.4x %d", name, offset, data_ram[offset]);
	return 0xff;
}

void peplus_other_w(offs_t offset, UINT8 data, char *name)
{
	debuglog("UNSUPPORTED %s data_write_byte_8 %.4x %d", name, offset, data);
}

UINT8 cpu_readop(UINT16 pc)
{
	debuglog("cpu_readop %.4x %.2x", pc, program_rom[pc]);
	return program_rom[pc];
}

UINT8 cpu_readop_arg(UINT16 pc)
{
	debuglog("cpu_readop_arg %.4x %.2x", pc, program_rom[pc]);
	return program_rom[pc];
}

UINT8 program_read_byte_8le(offs_t offset)
{
    debuglog("program_read_byte_8 %.4x %.2x", offset, program_rom[offset]);
    return program_rom[offset];
}

UINT8 data_read_byte_8le(offs_t offset)
{
    if (offset < 0x2000) {
		debuglog("cmos data_read_byte_8 %.4x %d", offset, data_ram[offset]);
		return data_ram[offset];
	} else if (offset < 0x3000) {
		if (offset == 0x2080) {
			return peplus_crtc_lpen1_r(offset);
		} else if (offset == 0x2081) {
			return peplus_crtc_lpen2_r(offset);
		} else if (offset == 0x2083) {
			return peplus_crtc_display_r(offset);
		} else {
			return peplus_other_r(offset, "UNKNOWN");
		}
	} else if (offset < 0x4000) {
        return peplus_superboard_r(offset);
	} else if (offset < 0x5000) {
        if (offset == 0x4004) {
            return 0xff;
        } else {
            return peplus_other_r(offset, "UNKNOWN");
        }
	} else if (offset < 0x6000) {
		return peplus_superboard_r(offset);
	} else if (offset < 0x7000) {
		if (offset == 0x6000) {
			return peplus_bgcolor_r(offset);
		} else {
			return peplus_other_r(offset, "UNKNOWN");
		}
	} else if (offset < 0x8000) {
		return peplus_superboard_r(offset);
	} else if (offset < 0x9000) {
		if (offset == 0x8000) {
			return peplus_input_bank_a_r(offset);
		} else {
			return peplus_other_r(offset, "UNKNOWN");
		}
	} else if (offset < 0xa000) {
		if (offset == 0x9000) {
			return peplus_dropdoor_r(offset);
		} else {
			return peplus_other_r(offset, "UNKNOWN");
		}
	} else if (offset < 0xb000) {
		if (offset == 0xa000) {
			return peplus_input_bank_bc_r(offset);
		} else {
			return peplus_other_r(offset, "UNKNOWN");
		}
	} else if (offset < 0xc000) {
		return peplus_superboard_r(offset);
	} else if (offset < 0xd000) {
		if (offset == 0xc000) {
			return peplus_watchdog_r(offset);
		} else {
			return peplus_other_r(offset, "UNKNOWN");
		}
	} else if (offset < 0xe000) {
		return peplus_superboard_r(offset);
	} else if (offset < 0xf000) {
		if (offset == 0xe000) {
			return peplus_duart_r(offset);
		} else {
			return peplus_other_r(offset, "UNKNOWN");
		}
	} else if (offset <= 0xffff) {
		return peplus_superboard_r(offset);
	} else {
		return peplus_other_r(offset, "UNKNOWN");
	}
}
		

void data_write_byte_8le(offs_t offset, UINT8 data)
{
    if (input_bank_b && (offset >= 0x2000)) {
        debuglog("data_write_byte_8 %.4x %d", offset, data_ram[offset]);
    }
	if (offset < 0x2000) {
		debuglog("cmos data_write_byte_8 %.4x %d", offset, data);
        /* Test for Wingboard PAL Trigger Condition */
        if (offset == 0x1fff && wingboard && data < 5)
        {
            errorlog("peplus_load_superdata");
            peplus_load_superdata(data);
        }
		data_ram[offset] = data;
	} else if (offset < 0x3000) {
		if (offset == 0x2008) {
			peplus_crtc_mode_w(offset, data);
		} else if (offset == 0x2080) {
			peplus_crtc_register_w(offset, data);
		} else if (offset == 0x2081) {
			peplus_crtc_address_w(offset, data);
		} else if (offset == 0x2083) {
			peplus_crtc_display_w(offset, data);
		} else {
			peplus_other_w(offset, data, "UNKNOWN");
		}
	} else if (offset < 0x4000) {
		peplus_superboard_w(offset, data);
	} else if (offset < 0x5000) {
        if (offset == 0x4000) {
            ay8910_write_ym(ay8910, 0, data);
        } else if (offset == 0x4004) {
            ay8910_write_ym(ay8910, 1, data);
        } else {
            peplus_other_w(offset, data, "UNKNOWN");
        }
	} else if (offset < 0x6000) {
		peplus_superboard_w(offset, data);
	} else if (offset < 0x7000) {
		if (offset == 0x6000) {
			peplus_bgcolor_w(offset, data);
		} else {
			peplus_other_w(offset, data, "UNKNOWN");
		}
	} else if (offset < 0x8000) {
		peplus_superboard_w(offset, data);
	} else if (offset < 0x9000) {
		if (offset == 0x8000) {
			peplus_output_bank_c_w(offset, data);
		} else {
			peplus_other_w(offset, data, "UNKNOWN");
		}
	} else if (offset < 0xa000) {
		if (offset == 0x9000) {
			i2c_nvram_w(offset, data);
		} else {
			peplus_other_w(offset, data, "UNKNOWN");
		}
	} else if (offset < 0xb000) {
		if (offset == 0xa000) {
			peplus_output_bank_b_w(offset, data);
		} else {
			peplus_other_w(offset, data, "UNKNOWN");
		}
	} else if (offset < 0xc000) {
		peplus_superboard_w(offset, data);
	} else if (offset < 0xd000) {
		if (offset == 0xc000) {
			peplus_output_bank_a_w(offset, data);
		} else {
			return peplus_other_w(offset, data, "UNKNOWN");
		}
	} else if (offset < 0xe000) {
		return peplus_superboard_w(offset, data);
	} else if (offset < 0xf000) {
		if (offset == 0xe000) {
			return peplus_duart_w(offset, data);
		} else {
			return peplus_other_w(offset, data, "UNKNOWN");
		}
	} else if (offset <= 0xffff) {
		return peplus_superboard_w(offset, data);
	} else {
		return peplus_other_w(offset, data, "UNKNOWN");
	}
}

UINT8 io_read_byte(offs_t offset)
{
	debuglog("io_read_byte %d %.2x", offset, io_port[offset]);
	return io_port[offset];
}

void io_write_byte(offs_t offset, UINT8 data)
{
	debuglog("io_write_byte %d %.2x", offset, data);
	io_port[offset] = data;
}

/*
static void update_tile_in_bitmap(int tile_index)
{
	
	int pr = palette_ram[tile_index];
	int pr2 = palette_ram2[tile_index];
	int vr = videoram[tile_index];
	int code = ((pr & 0x0f)*256) | vr;
	int color = (pr>>4) & 0x0f;

	for(i=0; i<25; i++) {
		for(j=0; j<40; j++) {
			UINT8 *src = gfxtile_indexed[i*40+j];
			UINT8 *dst = gfxbitmap[i*40+j];
			for(k=0; k<8; k++) {
				memcpy(dst, src, 8);
				src += 8;
				dst += 40*8;
			}
		}
	}
	blit_tile_to_bitmap(tile_index);
	SET_TILE_INFO(0, code, color, 0);
}

void write_ppm_snapshot()
{
	int pr = palette_ram[tile_index];
	int pr2 = palette_ram2[tile_index];
	int vr = videoram[tile_index];
	int code = ((pr & 0x0f)*256) | vr;
	int color = (pr>>4) & 0x0f;

	// Access 2nd Half of CGs and CAP
	if (jumper_e16_e17 && (pr2 & 0x10) == 0x10)
	{
		code += 0x1000;
		color += 0x10;
	}

	SET_TILE_INFO(0, code, color, 0);
}
*/
void write_ppm_tiles(char *name)
{
	FILE *fp = fopen(name, "w");
	if (!fp) {
		fprintf(stderr, "unable to open '%s' for writing\n", name);
		return;
	}
	fprintf(fp, "P3\n");
	fprintf(fp, "8 8000\n");
	fprintf(fp, "255\n");
	int i, j;
	for(i=0; i<0x10000; i++) {
		UINT8 *src = gfxtile_rgba[i];
		for(j=0; j<64; j++) {
			fprintf(fp, "%d %d %d\n", src[0], src[1], src[2]);
			src += 4;
		}
	}
	fclose(fp);
}

void decode_gfxtile_rgba()
{
	int i, j;
	for(i=0; i<0x1000; i++) {
		UINT8 *src = gfxtile_indexed[i];
		UINT8 *dst = gfxtile_rgba[i];
		for(j=0; j<64; j++) {
			memcpy(dst, palette_rgba[*src], 4);
			src++;
			dst += 4;
		}
	}
}

void decode_gfxtile_indexed()
{
	UINT8 *p = gfx_rom;
	UINT8 *q = &gfx_rom[0x8000];
	UINT8 *r = &gfx_rom[0x10000];
	UINT8 *s = &gfx_rom[0x18000];
	int i, j, k;
	for(i=0; i<0x1000; i++) {
		UINT8 *dst =  gfxtile_indexed[i];
		for(j=0; j<8; j++) {
			for(k=7; k>=0; k--) {
				*dst = (((*p & (1<<k))>>k)&0x01)<<0;
				*dst |= (((*q & (1<<k))>>k)&0x01)<<1;
				*dst |= (((*r & (1<<k))>>k)&0x01)<<2;
				*dst |= (((*s & (1<<k))>>k)&0x01)<<3;
				dst++;
			}
			p++;
			q++;
			r++;
			s++;
		}
	}
}

void decode_palette()
{
/*  prom bits
    7654 3210
    ---- -xxx   red component.
    --xx x---   green component.
    xx-- ----   blue component.
*/
	int i;

	for (i = 0; i < 256;i++)
	{
		int bit0, bit1, bit2, r, g, b;

		/* red component */
		bit0 = (~color_prom[i] >> 0) & 0x01;
		bit1 = (~color_prom[i] >> 1) & 0x01;
		bit2 = (~color_prom[i] >> 2) & 0x01;
		r = 0x21 * bit2 + 0x47 * bit1 + 0x97 * bit0;

		/* green component */
		bit0 = (~color_prom[i] >> 3) & 0x01;
		bit1 = (~color_prom[i] >> 4) & 0x01;
		bit2 = (~color_prom[i] >> 5) & 0x01;
		g = 0x21 * bit2 + 0x47 * bit1 + 0x97 * bit0;

		/* blue component */
		bit0 = (~color_prom[i] >> 6) & 0x01;
		bit1 = (~color_prom[i] >> 7) & 0x01;
		bit2 = 0;
		b = 0x21 * bit2 + 0x47 * bit1 + 0x97 * bit0;
        
        UINT16 rgb = ((r >> 3) << 11) | (( g >> 2) << 5 ) | (( b >> 3 ) << 0 );
        memcpy(palette_rgb565[i], &rgb, 2);
    }
    data_ram[0x6000] = color_prom[15];
}

void memory_init()
{
	memset(data_ram, 0, 0x10000);
	memset(palette_ram, 0, 0x3000);
	memset(palette_ram2, 0, 0x3000);
	memset(eeprom_nvram, 0xff, EEPROM_NVRAM_SIZE);
    memset(samplebuffer, 0, 960000*sizeof(UINT16));
    samplelastcycles = 0;
    sampleindex = 0;
	i2cmem_init(0, I2CMEM_SLAVE_ADDRESS, 8, EEPROM_NVRAM_SIZE, eeprom_nvram);
}

void emu_init()
{
	memory_init();
	decode_palette();
	decode_gfxtile_indexed();
	decode_gfxtile_rgba();
	wingboard = 0;
	jumper_e16_e17 = 0;
    	i8051_set_eram_iaddr_callback(peplus_external_ram_iaddr);
    	/* EEPROM is a X2404P 4K-bit Serial I2C Bus */
    ay8910 = ay8910_start(NULL, 0, 20000000/12, NULL);
    ay8910_reset_ym(ay8910);
	i8752_init(0, 3686400*2, NULL, irq_callback);
	i8752_reset();
	debuglog("initialized");
}

void emu_update_sound(int register_update)
{
    UINT64 diff_cycles = i8051_total_cycles - samplelastcycles;
    int nsamples = diff_cycles / 96;
    if (!nsamples) {
        return;
    }
    extern pthread_mutex_t peplus_mutex;
    pthread_mutex_lock(&peplus_mutex);
    if (register_update) {
        NSLog(@"register update");
        if (clobber_sound > 0) {
            sampleindex = 0;
            clobber_sound--;
        }
    }
    UINT16 *buf[3];
    buf[0] = &samplebuffer[sampleindex];
    if (sampleindex + nsamples >= 960000) {
        if (sampleindex < 960000) {
            sampleindex += ay8910_update(ay8910, NULL, buf, 960000 - sampleindex);
        }
        samplelastcycles = i8051_total_cycles;
    } else {
        sampleindex += ay8910_update(ay8910, NULL, buf, nsamples);
        samplelastcycles = i8051_total_cycles;
    }
    static sampleindexmax = 0;
    if (sampleindex > sampleindexmax) {
        sampleindexmax = sampleindex;
        NSLog(@"sampleindexmax %d", sampleindexmax);
    }
    pthread_mutex_unlock(&peplus_mutex);
}

void emu_execute_frame()
{
    extern UINT64 i8051_start_cycles;
    i8051_start_cycles = i8051_total_cycles;
    i8752_execute(153600*10);
    emu_update_sound(0);
}

