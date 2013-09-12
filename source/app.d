import derelict.sdl2.sdl, derelict.sdl2.image;
import std.stdio;

static const int WINDOW_WIDTH = 160;
static const int WINDOW_HEIGHT = 320;

void main()
{
	//Loading DerelictSDL2
	DerelictSDL2.load();
	DerelictSDL2Image.load();

	scope(exit) SDL_Quit();

	SDL_Window* win = SDL_CreateWindow("PuzzleGame", SDL_WINDOWPOS_CENTERED,
			SDL_WINDOWPOS_CENTERED, WINDOW_WIDTH, WINDOW_HEIGHT, SDL_WINDOW_SHOWN);
	scope(exit) SDL_DestroyWindow(win);

	SDL_Renderer* renderer = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED);
	scope(exit) SDL_DestroyRenderer(renderer);

	auto blockImage = IMG_Load("views/block.bmp");

	auto board = new Block[10][20];
	
	//Event loop
	while(1)
	{
		//drawBoard(win, blockImage, board); 
		SDL_Event e;
		if(SDL_PollEvent(&e))
		{
			if(e.type == SDL_QUIT) break;
		}
	}
}

void drawBoard(SDL_Window* win, SDL_Surface* blockImage, Block[10][] board)
{
	auto windowRect = new SDL_Rect(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);
	auto windowSurface = SDL_GetWindowSurface(win);
	SDL_FillRect(windowSurface, windowRect, SDL_MapRGB(windowSurface.format, 0, 0, 0));

	auto rectInfo = new SDL_Rect(0, 0, 16, 16);
	auto rectPos = new SDL_Rect(0, 0);

	for(int i = 0; i < 20; i++)
	{
		for(int j = 0; j < 10; j++)
		{
			if(!(board[i][j] is null))
			{
				rectInfo.x = 16 * board[i][j].getColor();
				rectPos.x = 16 * j;
				rectPos.y = 16 * i;
				SDL_BlitSurface(blockImage, rectInfo, windowSurface, rectPos);
			}
		}
	}

	SDL_UpdateWindowSurface(win);
}

bool checkBoard(Block[10][] board)
{
	bool vanishFlag;
	for(int i = 19; i >= 0; i--)
	{
		bool lineFullFlag = true;
		
		for(int j = 0; j < 10; j++)
		{
			if(board[i][j] is null)
				lineFullFlag = false;
		}
		
		if(lineFullFlag)
		{
			vanishFlag = true;
			clearLine(board, i);
			i++;
		}
	}
	return vanishFlag;
}

void clearLine(Block[10][] board, int n)
{
	while(n > 0)
	{
		board[n] = board[n - 1];
		bool empty = true;
		for(int i = 0; i < board[n].length; i++)
			if(!(board[n][i] is null))
				empty = false;
		if(empty)
			break;
		n--;
	}
}

class Block
{
	enum BlockColor {blue, red, yellow, green, orange, aqua, purple};
	BlockColor myColor;

	public this(BlockColor color)
	{
		myColor = color;
	}

	public BlockColor getColor()
	{
		return myColor;
	}
}

