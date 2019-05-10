	
	//graphics
	#define	GAME_LIST_ADDR	0x8000
	#define	CRSR_OFFSET_X	2
	#define	CRSR_TILE		0x3F
	#define	LIST_OFFSET_X	4
	#define	LIST_OFFSET_Y	4*32
	
	//joystick buttons
	#define JOY_A			0x01<<7
	#define JOY_B			0x01<<6
	#define JOY_SELECT		0x01<<5
	#define JOY_START		0x01<<4
	#define JOY_UP			0x01<<3
	#define JOY_DOWN		0x01<<2
	#define JOY_LEFT		0x01<<1
	#define JOY_RIGHT		0x01<<0
	
	//zero page variables
	#pragma bssseg(push,"ZEROPAGE")
	#pragma dataseg(push,"ZEROPAGE")
	unsigned char pos_in_gamelist;				
	unsigned char pos_of_cursor;				//cursor position
	unsigned char list_count;					//counts of list items
	unsigned char show_count;					//counts of list items on screen
	
	
	unsigned char j1_state;
	unsigned char flag_scr_rld;
	unsigned char i;						//cycle variable
	unsigned char x;						//cycle variable
	
	unsigned char polling_delay;	

	unsigned int cpu_rom_addr;				
	unsigned int ppu_ram_addr;

	//----------------------------------------------------------------------------------------
	void GetListCount()
	{
		list_count = 0;
		while(1)
		{
			cpu_rom_addr = GAME_LIST_ADDR + (list_count << 5);
			if(*((unsigned char*)cpu_rom_addr) == 0)break;
			list_count++;
		}
		return;
	}
	//-------------------------------------------------------------------------------------------
	/*[name (23) | mapper type(1) |offset(4) | prg len(2) | chr len(2)]*/
	void PrintGameList()
	{	
		show_count = 0;
		cpu_rom_addr = GAME_LIST_ADDR + (pos_in_gamelist << 5);
		for(i = 0;i<10;i++)
		{	
			ppu_ram_addr = 0x2000 + (i<<5) + (LIST_OFFSET_Y + LIST_OFFSET_X);
			
			if(*((unsigned char*)cpu_rom_addr) != 0)
				cpu_rom_addr = GAME_LIST_ADDR + (pos_in_gamelist << 5) + (i << 5);
			
			if(*((unsigned char*)cpu_rom_addr) != 0)
				show_count++;
			
			*((unsigned char*)0x2006) = ppu_ram_addr >> 8;
	        *((unsigned char*)0x2006) = ppu_ram_addr & 0xFF;

			for(x = 0;x < 23;x++)
			{
				ppu_ram_addr = cpu_rom_addr;
				if(*((unsigned char*)cpu_rom_addr) != 0)cpu_rom_addr+=x;
				if(*((unsigned char*)cpu_rom_addr) == 0)
					*((unsigned char*)0x2007) = 0x00;
				else 
					*((unsigned char*)0x2007) = *(unsigned char*)cpu_rom_addr;
				cpu_rom_addr = ppu_ram_addr;
			}
		}
		return;
	}
	//----------------------------------------------------------------------------------------
	void PrintCursor()
	{
		//delete old cursor 
		ppu_ram_addr = 0x2000 + (x << 5) + (LIST_OFFSET_Y + CRSR_OFFSET_X);
		*((unsigned char*)0x2006) = ppu_ram_addr >> 8;
	    *((unsigned char*)0x2006) = ppu_ram_addr & 0xFF;
		*((unsigned char*)0x2007) = 0x00;
		//print new cursor
		ppu_ram_addr = 0x2000 + (pos_of_cursor << 5) + (LIST_OFFSET_Y + CRSR_OFFSET_X);
		*((unsigned char*)0x2006) = ppu_ram_addr >> 8;
	    *((unsigned char*)0x2006) = ppu_ram_addr & 0xFF;
		*((unsigned char*)0x2007) = CRSR_TILE;
		return;
	}
	//----------------------------------------------------------------------------------------
	/*[name (23) | mapper type(1) |offset(4) | prg len(2) | chr len(2)]*/
	void LoadGame()
	{
		x = pos_in_gamelist + pos_of_cursor;
		cpu_rom_addr = GAME_LIST_ADDR + (x << 5) + 23;
		*((unsigned char*)0x4018) = *(unsigned char*)cpu_rom_addr;  //send mapper type
		cpu_rom_addr+=1;
		*((unsigned char*)0x4018) = *(unsigned char*)cpu_rom_addr;  //offset 0
		cpu_rom_addr+=1;
		*((unsigned char*)0x4018) = *(unsigned char*)cpu_rom_addr;  //offset 1
		cpu_rom_addr+=1;
		*((unsigned char*)0x4018) = *(unsigned char*)cpu_rom_addr;  //offset 2
		cpu_rom_addr+=1;
		*((unsigned char*)0x4018) = *(unsigned char*)cpu_rom_addr;  //offset 3
		cpu_rom_addr+=1;
		*((unsigned char*)0x4018) = *(unsigned char*)cpu_rom_addr;  //prg len low
		cpu_rom_addr+=1;
		*((unsigned char*)0x4018) = *(unsigned char*)cpu_rom_addr;  //prg len hight
		cpu_rom_addr+=1;
		*((unsigned char*)0x4018) = *(unsigned char*)cpu_rom_addr;  //chr len low
		cpu_rom_addr+=1;
		*((unsigned char*)0x4018) = *(unsigned char*)cpu_rom_addr;  //chr len hight
		return;
	}
	//----------------------------------------------------------------------------------------
	void read_joystick1()
	{
		*((unsigned char*)0x4016) = 0x01;
		*((unsigned char*)0x4016) = 0x00;
		for(i = 0;i<8;i++)
		{	
			j1_state<<=1;
			j1_state = j1_state | (*((unsigned char*)0x4016) & 01);
		}
		return;
	}
	//----------------------------------------------------------------------------------------
	void main()
	{	
		//init variable
		pos_in_gamelist = 0;
		pos_of_cursor   = 0;
		polling_delay   = 0;
		j1_state        = 0;
		flag_scr_rld    = 1;
		//disable ppu
		*((unsigned char*)0x2000) = 0;
		*((unsigned char*)0x2001) = 0;
		//clear vram
		*((unsigned char*)0x2006) = 0x20;
	    *((unsigned char*)0x2006) = 0x00;
		for(x = 0;x<4;x++)
		{
			for(i = 0;;i++)
			{	
				*((unsigned char*)0x2007) = 0x00;
				if(i == 0xFF) break;
			}
		}
		//ppu palette addr
	    *((unsigned char*)0x2006) = 0x3F;
	    *((unsigned char*)0x2006) = 0x00;
		//set palette color
	    *((unsigned char*)0x2007) = 0x10;
	    *((unsigned char*)0x2007) = 0x0C;
		*((unsigned char*)0x2007) = 0x0C;
		*((unsigned char*)0x2007) = 0x0C;
		
		GetListCount();
		if(list_count!=0)
		{
			PrintGameList();
			x = 0;	
			PrintCursor();
			*((unsigned char*)0x2005) = 0x00;
			*((unsigned char*)0x2005) = 0x00;
			//enable ppu
			*((unsigned char*)0x2000) = 0x80;
		}
	    while(1)
		{
		}
	}
	//----------------------------------------------------------------------------------------
	void ScrollList()
	{
		*((unsigned char*)0x2001) = 0;
		PrintGameList();
		*((unsigned char*)0x2005) = 0x00;
		*((unsigned char*)0x2005) = 0x00;
		polling_delay = 10;
		flag_scr_rld = 1;
	}
	//----------------------------------------------------------------------------------------
	void MoveCursor()
	{
		*((unsigned char*)0x2001) = 0;
		PrintCursor();
		*((unsigned char*)0x2005) = 0x00;
		*((unsigned char*)0x2005) = 0x00;
		polling_delay = 10;
		flag_scr_rld = 1;
		return;
	}
	//----------------------------------------------------------------------------------------
	void my_nmi()
	{
		*((unsigned char*)0x2000) = 0;
		if(flag_scr_rld)
		{
			*((unsigned char*)0x2001) = 0x0A;
			*((unsigned char*)0x2000) = 0x80;
			flag_scr_rld = 0x00;
			return;
		}
		
		j1_state = *((unsigned char*)0x2002);  //only read
		
		if(polling_delay == 0)
		{
			read_joystick1();
			if(j1_state & JOY_DOWN)
			{
				if(pos_of_cursor<9)
				{
					if( show_count - pos_of_cursor != 1)
					{
						x = pos_of_cursor;
						pos_of_cursor++;
						MoveCursor();
					}
				}
				else if(pos_in_gamelist < list_count)
				{
					x = 9;
					pos_of_cursor = 0;
					MoveCursor();
					pos_in_gamelist+=10;
					ScrollList();
				}
			}
			else if(j1_state & JOY_UP)
			{
				if(pos_of_cursor != 0)
				{
					x = pos_of_cursor;
					pos_of_cursor--;
					MoveCursor();
				}
				else if(pos_in_gamelist!=0)
				{
					pos_in_gamelist-=10;
					ScrollList();
				}
			}
			else if(j1_state & JOY_START)
			{
				LoadGame();
			}
		}
		if(polling_delay!=0)polling_delay--;
		*((unsigned char*)0x2000) = 0x80;
		return;
	}