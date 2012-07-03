//
//  roms.c
//  Artslots
//
//  Created by arthur on 27/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include <stdio.h>

#include "Helper.h"

extern UINT8 color_prom[];
extern UINT8 gfx_rom[];
extern UINT8 program_rom[];
extern UINT8 user_rom[];
extern UINT8 data_ram[];
extern UINT8 eeprom_nvram[];

extern NSArray *loaded;

void load_rom_file(NSString *name, size_t size, void *ptr)
{
	FILE *fp = fopen(getCString(getPathInDocs(name)), "rb");
	if (!fp) {
		die("unable to open file");
	}
	int n = fread(ptr, 1, size, fp);
	if (n != size) {
		die("unable to read enough bytes");
	}
	fclose(fp);
}

void load_game_roms(NSArray *elt)
{
    NSString *(^func)(int index) = ^(int index) {
        return [elt objectAtIndex:index];
    };
    loaded = elt;
    load_rom_file(func(2), 0x10000, &program_rom[0]);
    if ([func(3) length]) {
        load_rom_file(func(3), 0x10000, &user_rom[0]);
    }
    load_rom_file(func(4), 0x8000, &gfx_rom[0]);
    load_rom_file(func(5), 0x8000, &gfx_rom[0x8000]);
    load_rom_file(func(6), 0x8000, &gfx_rom[0x10000]);
    load_rom_file(func(7), 0x8000, &gfx_rom[0x18000]);
    load_rom_file(func(8), 0x100, &color_prom[0]);
}

NSString *get_game_id(NSArray *elt)
{
    return [elt objectAtIndex:0];
}

NSString *get_game_name(NSArray *elt)
{
    return [elt objectAtIndex:1];
}

NSString *get_game_type(NSArray *elt)
{
    return [elt objectAtIndex:9];
}

NSMutableArray *get_games_arr()
{
    static NSMutableArray *arr = nil;
    if (arr) {
        return arr;
    }
    
    arr = [[NSMutableArray alloc] init];
    void (^func)(NSString *s1, NSString *s2, NSString *s3, NSString *s4, NSString *s5, NSString *s6, NSString *s7, NSString *s8, NSString *s9, NSString *s10) = ^(NSString *s1, NSString *s2, NSString *s3, NSString *s4, NSString *s5, NSString *s6, NSString *s7, NSString *s8, NSString *s9, NSString *s10) {
        NSArray *elt = [NSArray arrayWithObjects:s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, nil];
        [arr addObject:elt];
    };
/*    func(@"peset038",
         @"IGT - Player's Edge Plus (PESET038) Set Chip",
         @"set038.u68",
         @"",
         @"mro-cg740.u72",
         @"mgo-cg740.u73",
         @"mbo-cg740.u74",
         @"mxo-cg740.u75",
         @"cap740.u50");*/
/*    func(@"pepp0043",
         @"IGT - Player's Edge Plus (PP0043) 10's or Better",
         @"pp0043.u68",
         @"",
         @"mro-cg2004.u72",
         @"mgo-cg2004.u73",
         @"mbo-cg2004.u74",
         @"mxo-cg2004.u75",
         @"cap740.u50",
         @"poker");*/
/*    func(@"pepp0065",
         @"IGT - Player's Edge Plus (PP0065) Jokers Wild Poker",
         @"pp0065.u68",
         @"",
         @"mro-cg740.u72",
         @"mgo-cg740.u73",
         @"mbo-cg740.u74",
         @"mxo-cg740.u75",
         @"cap740.u50",
         @"poker");*/
    func(@"pepp0158",
         @"4 of a Kind Bonus Poker (IGT Player's Edge Plus PP0158)",
         @"pp0158.u68",
         @"",
         @"mro-cg740.u72",
         @"mgo-cg740.u73",
         @"mbo-cg740.u74",
         @"mxo-cg740.u75",
         @"cap740.u50",
         @"poker");
/*    func(@"pepp0188",
         @"IGT - Player's Edge Plus (PP0188) Standard Draw Poker",
         @"pp0188.u68",
         @"",
         @"mro-cg740.u72",
         @"mgo-cg740.u73",
         @"mbo-cg740.u74",
         @"mxo-cg740.u75",
         @"cap740.u50",
         @"poker");*/
/*    func(@"pepp0250",
         @"IGT - Player's Edge Plus (PP0250) Double Down Stud Poker",
         @"pp0250.u68",
         @"",
         @"mro-cg740.u72",
         @"mgo-cg740.u73",
         @"mbo-cg740.u74",
         @"mxo-cg740.u75",
         @"cap740.u50",
         @"poker");*/
/*    func(@"pepp0447",
         @"IGT - Player's Edge Plus (PP0447) Standard Draw Poker",
         @"pp0447.u68",
         @"",
         @"mro-cg740.u72",
         @"mgo-cg740.u73",
         @"mbo-cg740.u74",
         @"mxo-cg740.u75",
         @"cap740.u50",
         @"poker");*/
    func(@"pepp0516",
         @"Double Bonus Poker (IGT Player's Edge Plus PP0516)",
         @"pp0516.u68",
         @"",
         @"mro-cg740.u72",
         @"mgo-cg740.u73",
         @"mbo-cg740.u74",
         @"mxo-cg740.u75",
         @"cap740.u50",
         @"poker");
/*    func(@"pebe0014",
         @"IGT - Player's Edge Plus (BE0014) Blackjack",
         @"be0014.u68",
         @"",
         @"mro-cg2036.u72",
         @"mgo-cg2036.u73",
         @"mbo-cg2036.u74",
         @"mxo-cg2036.u75",
         @"cap707.u50",
         @"blackjack");*/
/*    func(@"peke1012",
         @"IGT - Player's Edge Plus (KE1012) Keno",
         @"ke1012.u68",
         @"",
         @"mro-cg1267.u72",
         @"mgo-cg1267.u73",
         @"mbo-cg1267.u74",
         @"mxo-cg1267.u75",
         @"cap1267.u50",
         @"keno");*/
    func(@"peps0014",
         @"Super Joker Slots (IGT Player's Edge Plus PS0014)",
         @"ps0014.u68",
         @"",
         @"mro-cg0916.u72",
         @"mgo-cg0916.u73",
         @"mbo-cg0916.u74",
         @"mxo-cg0916.u75",
         @"cap0916.u50",
         @"slots");
    func(@"peps0022",
         @"Red White & Blue Slots (IGT Player's Edge Plus PS0022)",
         @"ps0022.u68",
         @"",
         @"mro-cg0960.u72",
         @"mgo-cg0960.u73",
         @"mbo-cg0960.u74",
         @"mxo-cg0960.u75",
         @"cap0960.u50",
         @"slots");
    func(@"peps0043",
         @"Double Diamond Slots (IGT Player's Edge Plus PS0043)",
         @"ps0043.u68",
         @"",
         @"mro-cg1003.u72",
         @"mgo-cg1003.u73",
         @"mbo-cg1003.u74",
         @"mxo-cg1003.u75",
         @"cap1003.u50",
         @"slots");
    func(@"peps0045",
         @"Red White & Blue Slots (IGT Player's Edge Plus PS0045)",
         @"ps0045.u68",
         @"",
         @"mro-cg0960.u72",
         @"mgo-cg0960.u73",
         @"mbo-cg0960.u74",
         @"mxo-cg0960.u75",
         @"cap0960.u50",
         @"slots");
    func(@"peps0308",
         @"Double Jackpot Slots (IGT Player's Edge Plus PS0308)",
         @"ps0308.u68",
         @"",
         @"mro-cg0911.u72",
         @"mgo-cg0911.u73",
         @"mbo-cg0911.u74",
         @"mxo-cg0911.u75",
         @"cap0911.u50",
         @"slots");
    func(@"peps0615",
         @"Chaos Slots (IGT Player's Edge Plus PS0615) ",
         @"ps0615.u68",
         @"",
         @"mro-cg2246.u72",
         @"mgo-cg2246.u73",
         @"mbo-cg2246.u74",
         @"mxo-cg2246.u75",
         @"cap0960.u50",
         @"slots");
    func(@"peps0716",
         @"River Gambler Slots (IGT Player's Edge Plus PS0716)",
         @"ps0716.u68",
         @"",
         @"mro-cg2266.u72",
         @"mgo-cg2266.u73",
         @"mbo-cg2266.u74",
         @"mxo-cg2266.u75",
         @"cap2266.u50",
         @"slots");
    func(@"pex2069p",
         @"* Double Double Bonus Poker (IGT Player's Edge Plus X002069P)",
         @"xp000038.u67",
         @"x002069p.u66",
         @"mro-cg2185.u77",
         @"mgo-cg2185.u78",
         @"mbo-cg2185.u79",
         @"mxo-cg2185.u80",
         @"capx1321.u43",
         @"poker");
    func(@"pexp0019",
         @"* Deuces Wild Poker (IGT Player's Edge Plus XP000019)",
         @"xp000019.u67",
         @"x002025p.u66",
         @"mro-cg2185.u77",
         @"mgo-cg2185.u78",
         @"mbo-cg2185.u79",
         @"mxo-cg2185.u80",
         @"capx2234.u43",
         @"poker");
    func(@"pexp0112",
         @"* White Hot Aces Poker (IGT Player's Edge Plus XP000112)",
         @"xp000112.u67",
         @"x002035p.u66",
         @"mro-cg2324.u77",
         @"mgo-cg2324.u78",
         @"mbo-cg2324.u79",
         @"mxo-cg2324.u80",
         @"capx2174.u43",
         @"poker");
    func(@"pexs0006",
         @"* Triple Triple Diamond Slots (IGT Player's Edge Plus XS000006)",
         @"xs000006.u67",
         @"x000998s.u66",
         @"mro-cg2361.u77",
         @"mgo-cg2361.u78",
         @"mbo-cg2361.u79",
         @"mxo-cg2361.u80",
         @"capx2361.u43",
         @"slots");
/*    func(@"pexmp006",
         @"IGT - Player's Edge Plus (XMP00006) Multi-Poker",
         @"xmp00006.u67",
         @"xm00002p.u66",
         @"mro-cg2174.u77",
         @"mgo-cg2174.u78",
         @"mbo-cg2174.u79",
         @"mxo-cg2174.u80",
         @"capx2174.u43",
         @"poker");*/
/*    func(@"pexmp017",
         @"IGT - Player's Edge Plus (XMP00017)",
         @"xmp00017.u67",
         @"x000055p.u66",
         @"mro-cg2298.u77",
         @"mgo-cg2298.u78",
         @"mbo-cg2298.u79",
         @"mxo-cg2298.u80",
         @"capx2298.u43",
         @"poker");*/
/*    func(@"pexmp024",
         @"IGT - Player's Edge Plus (XMP00024)",
         @"xmp00024.u67",
         @"xm00005p.u66",
         @"mro-cg2240.u77",
         @"mgo-cg2240.u78",
         @"mbo-cg2240.u79",
         @"mxo-cg2240.u80",
         @"capx2174.u43",
         @"poker");*/
    return arr;
}

NSString *get_nvram_filename(NSArray *game)
{
    if (!game)
        return @"null.nvram";
    return [NSString stringWithFormat:@"%@.nvram", get_game_id(game)];
}

void delete_nvram(NSArray *game)
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm removeItemAtPath:getPathInDocs(get_nvram_filename(game)) error:nil]) {
        NSLog(@"deleted nvram");
    } else {
        NSLog(@"unable to delete nvram");
    }
}

void save_nvram()
{
    if (!loaded)
        return;
    
	FILE *fp;
	fp = fopen(getCString(getPathInDocs(get_nvram_filename(loaded))), "w");
	if (!fp) {
		die("unable to save nvram");
	}
	fwrite(data_ram, 1, 0x1000, fp);
	fwrite(eeprom_nvram, 1, EEPROM_NVRAM_SIZE, fp);
	fclose(fp);
}

void load_nvram()
{
    if (!loaded)
        return;
    
    int err = 0;
    FILE *fp;
    fp = fopen(getCString(getPathInDocs(get_nvram_filename(loaded))), "r");
    if (!fp) {
        fp = fopen(getCString(getPathInBundle(get_nvram_filename(loaded))), "r");
    }
    if (fp) {
        int n;
        n = fread(data_ram, 1, 0x1000, fp);
        if (n != 0x1000) {
            err = 1;
        } else {
            n = fread(eeprom_nvram, 1, EEPROM_NVRAM_SIZE, fp);
            if (n != EEPROM_NVRAM_SIZE) {
                err = 1;
            }
        }
        fclose(fp);
    }
    if (err) {
        memset(data_ram, 0, 0x1000);
        memset(eeprom_nvram, 0xff, EEPROM_NVRAM_SIZE);
    }
}
