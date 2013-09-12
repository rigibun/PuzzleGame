import derelict.sdl2.sdl, derelict.sdl2.image;
import std.stdio, std.datetime, core.thread;

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
	StopWatch timer;
	uint frameCount = 0;
	uint dropInterval = 30;
	
	timer.start();
	//Event loop
	while(1)
	{
		SDL_Event e;
		if(SDL_PollEvent(&e))
		{
			if(e.type == SDL_QUIT) break;
		}

		if(timer.peek().to!("msecs", long) > 33)
		{
			frameCount++;
			if(frameCount >= dropInterval)
			{
				// Drop Block

				frameCount = 0;
			}

			drawBoard(win, blockImage, board);

			timer.reset();
			timer.start();
		}

		Thread.sleep( dur!("msecs")(1) );
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
	for(auto i = cast(int)board.length - 1; i >= 0; i--)
	{
		bool lineFullFlag = true;
		
		for(int j = 0; j < 10; j++)
		{
			writeln(i, ' ', j);
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

void clearLine(Block[10][] board, ulong n)
{
	auto lineTemp = board[n];
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
	
	foreach(ref e; lineTemp)
		e = null;
	board[n] = lineTemp;
}

int[2][4] getLeftRotatedPos(int[2][4] pos)
{
	for(int i = 0; i < 4; i++)
	{
		int temp = pos[i][0];
		pos[i][0] = pos[i][1];
		pos[i][1] = -temp;
	}
	return pos;
}

int[2][4] getRightRotatedPos(int[2][4] pos)
{
	for(int i = 0; i < 4; i++)
	{
		int temp = pos[i][0];
		pos[i][0] = -pos[i][1];
		pos[i][1] = temp;
	}
	return pos;
}

int[2][4] getDroppedPos(int[2][4] pos)
{
	for(int i = 0; i < 4; i++)
	{
		pos[i][0]++;
		pos[i][1]++;
	}
	return pos;
}

bool collCheck(int[2][4] pos, Block[10][] board)
{
	foreach(e; pos)
	{
		auto y = e[0];
		auto x = e[1];

		if(y < 0 || y >= board.length || x < 0 || x >= 10)
		{
			return true;
		}
		
		if( !(board[y][x] is null) )
		{
			return true;
		}
	}

	return false;
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

class Mino
{
	enum Type { J, Z, O, S, L, I, T };

	Type myType;
	int[2][4] blocksPos;
	int[2] myPos;

	public this(Type t, int[2] pos)
	{
		myType = t;
		genPos();
	}

	abstract void genPos();
	abstract void rotateLeft();
	abstract void rotateRight();
	abstract void drop();

	int[2][4] getPos()
	{
		return blocksPos;
	}
}
