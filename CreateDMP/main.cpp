#pragma comment (linker,"/ENTRY:main")
#pragma comment(lib,"Shlwapi.lib")
#include <windows.h>
#include <Shlwapi.h> 
#include <stdio.h>

#define	MAPPER_NONE	 0x00
#define MAPPER_MMC1	 0x01
#define	MAPPER_MMC3	 0x04
#define	MAPPER_AOROM 0x07

#define	STR_ENTRY_LEN 23
#define	MAX_ENTRIES_CNT 100

struct GameDumpT
{
	HANDLE hGame;
	HANDLE hDump;
	BYTE *GameData;
	int	GameSize;
	int EntryCnt;
	int OffsetInDump;
}GameDump;

/*[name (23) | mapper type(1) |offset(4) | prg len(2) | chr len(2)]*/
struct GameEntryT
{
	BYTE GameName[23];
	BYTE MapperType;
	DWORD Offset;
	WORD PrgLen;
	WORD ChrLen;
	BYTE EndList;
}GameEntry;

void AddGameToDump(char *cPath);
void FindFile(char *Path);
bool CreateDump();
void CloseDump();
//---------------------------------------------------------------------------------
void FindFile(char *Path)
{
	WIN32_FIND_DATAA t;
	HANDLE file;
	memset(&t,0,sizeof(WIN32_FIND_DATAA));
    file=FindFirstFileA(Path,&t);
	if(file==INVALID_HANDLE_VALUE){return;}
	do
	{ 
		if (!strcmp(t.cFileName, ".") || !strcmp(t.cFileName, "..")){continue;}
	    if(t.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
		{	
			char *next =(char*)LocalAlloc(0,strlen(Path)+strlen(t.cFileName)+5);
			if(!next)continue;
			strcpy(next,Path);
			strcpy(&next[strlen(next)-3],t.cFileName);
			strcat(next,"\\*.*");
			FindFile(next);
			LocalFree(next);
		}
        else
		{    
			int i=0;
			char *extens=strrchr(t.cFileName,'.');
			if(extens==NULL)continue;
			extens+=1;
			if(strcmp(extens,"nes")!=0)continue;
			//create path to file
            char *PathToFile = (char*)LocalAlloc(0,strlen(Path)+strlen(t.cFileName)+2);
			if(!PathToFile)continue;
			strcpy(PathToFile,Path);
            strcpy(&PathToFile[strlen(PathToFile)-3],t.cFileName);
			AddGameToDump(PathToFile);
			LocalFree(PathToFile);
		}
	}
	while(FindNextFileA(file,&t));
    FindClose(file);
	return;
}
//---------------------------------------------------------------------------------
bool CreateDump()
{
	GameDump.EntryCnt = 0;
	GameDump.hDump = CreateFileA("D:\\FPGA_NES\\loader\\dump.hex", GENERIC_WRITE, 0, NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL);
	if(GameDump.hDump==INVALID_HANDLE_VALUE)return false;
	GameDump.hGame = CreateFileA("D:\\FPGA_NES\\loader\\loader.nes", GENERIC_READ, 0, NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL);
	if(GameDump.hGame==INVALID_HANDLE_VALUE)
	{
		CloseHandle(GameDump.hDump);
		return false;
	}
	GameDump.GameSize=GetFileSize(GameDump.hGame,0);
	if(GameDump.GameSize==0)
	{
		CloseHandle(GameDump.hDump);
		CloseHandle(GameDump.hGame);
		return false;
	}
    GameDump.GameData = (BYTE*)VirtualAlloc(NULL,GameDump.GameSize,MEM_COMMIT,PAGE_READWRITE);
    if(GameDump.GameData==NULL)
	{
		CloseHandle(GameDump.hDump);
		CloseHandle(GameDump.hGame);
		return false;
	}
	DWORD tmp;
	SetFilePointer(GameDump.hGame,0,0,FILE_BEGIN);
	ReadFile(GameDump.hGame,GameDump.GameData,GameDump.GameSize,&tmp,NULL);
	GameDump.GameSize-=16;
	SetFilePointer(GameDump.hDump,0,0,FILE_BEGIN);
	WriteFile(GameDump.hDump,&GameDump.GameData[16],GameDump.GameSize,&tmp,NULL);
	VirtualFree(GameDump.GameData,0,MEM_RELEASE);
	CloseHandle(GameDump.hGame);
	GameDump.OffsetInDump+=GameDump.GameSize;
	return true;
}
//---------------------------------------------------------------------------------
void CloseDump()
{
	CloseHandle(GameDump.hDump);
	return;
}
//---------------------------------------------------------------------------------
/*[name (23) | mapper type(1) |offset(4) | prg len(2) | chr len(2)]*/
void AddGameToDump(char *cPath)
{
	//open game dump
	GameDump.hGame = CreateFileA(cPath, GENERIC_READ, 0, NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL);
	if(GameDump.hGame==INVALID_HANDLE_VALUE)return;
	GameDump.GameSize=GetFileSize(GameDump.hGame,0);
	if(GameDump.GameSize==0)
	{
		CloseHandle(GameDump.hGame);
		return;
	}
	GameDump.GameData = (BYTE*)VirtualAlloc(NULL,GameDump.GameSize,MEM_COMMIT,PAGE_READWRITE);
    if(GameDump.GameData==NULL)
	{
		CloseHandle(GameDump.hGame);
		return;
	}
	DWORD tmp;
	SetFilePointer(GameDump.hGame,0,0,FILE_BEGIN);
	ReadFile(GameDump.hGame,GameDump.GameData,GameDump.GameSize,&tmp,NULL);
	GameDump.GameSize-=16;
	//check signature NES
	if(*(DWORD*)GameDump.GameData != 0x1A53454E)
	{
		VirtualFree(GameDump.GameData,0,MEM_RELEASE);
		CloseHandle(GameDump.hGame);
		return;
	}
	//check mapper type
	BYTE mapper_type = *(BYTE*)&GameDump.GameData[6] >> 4;
	if( mapper_type!=MAPPER_NONE &&
		mapper_type!=MAPPER_MMC1 &&
		mapper_type!=MAPPER_MMC3 &&
		mapper_type!=MAPPER_AOROM )
	{
		VirtualFree(GameDump.GameData,0,MEM_RELEASE);
		CloseHandle(GameDump.hGame);
		return;
	}
	//fill entry game struct
	WORD prg_len = (*(BYTE*)&GameDump.GameData[4] << 5);
	WORD chr_len = (*(BYTE*)&GameDump.GameData[5] << 4);
	memset(GameEntry.GameName,0,sizeof(GameEntryT));
	GameEntry.MapperType = mapper_type;
	GameEntry.Offset = GameDump.OffsetInDump;
	GameEntry.PrgLen = prg_len;
	GameEntry.ChrLen = chr_len;
	GameEntry.EndList = 0;
	char *name_ptr = strrchr(cPath,'\\')+1;
	char *extens_ptr = strrchr(cPath,'.');
	int name_length = extens_ptr - name_ptr;
	for(int i = 0;i<name_length;i++)
	{
		char symb = name_ptr[i];
		if(symb >=0x41 && symb<=0x5A)symb = symb - 0x41 + 1;
		else if(symb >=0x61 && symb<=0x7A)symb = symb - 0x61 + 0x1B;
		else if(symb >=0x30 && symb<=0x39)symb = symb - 0x30 + 0x35;
		else symb = 0x00;
		GameEntry.GameName[i] = symb;
	}
	//add game entry
	SetFilePointer(GameDump.hDump, GameDump.EntryCnt * 32,0,FILE_BEGIN);
	WriteFile(GameDump.hDump,&GameEntry,33,&tmp,NULL);
	//add game to dump
	SetFilePointer(GameDump.hDump,0,0,FILE_END);
	WriteFile(GameDump.hDump,&GameDump.GameData[16],GameDump.GameSize,&tmp,NULL);
	GameDump.EntryCnt +=1;
	GameDump.OffsetInDump+=GameDump.GameSize;
	//close game dump
	VirtualFree(GameDump.GameData,0,MEM_RELEASE);
	CloseHandle(GameDump.hGame);
	return;
}
//---------------------------------------------------------------------------------
void main()
{
	if(!CreateDump())
	{
		MessageBoxA(0,"InitDump failed","error",0);
	}
	FindFile("D:\\FPGA_NES\\Games\\*.*");
	CloseDump();
	return;
}