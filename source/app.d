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

	SDL_Window* win = SDL_CreateWindow("tetris", SDL_WINDOWPOS_CENTERED,
			SDL_WINDOWPOS_CENTERED, WINDOW_WIDTH, WINDOW_HEIGHT, SDL_WINDOW_SHOWN);
	scope(exit) SDL_DestroyWindow(win);

	SDL_Renderer* renderer = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED);
	scope(exit) SDL_DestroyRenderer(renderer);

	auto blockImage = IMG_Load("views/block.bmp");

	auto board = new Block[10][20];
	
	board[0][0] = new Block(Block.BlockColor.aqua);
	board[1][1] = new Block(Block.BlockColor.yellow);
	board[2][2] = new Block(Block.BlockColor.blue);
	board[3][0] = new Block(Block.BlockColor.red);
	board[4][0] = new Block(Block.BlockColor.purple);
	board[5][0] = new Block(Block.BlockColor.green);
	board[6][0] = new Block(Block.BlockColor.orange);
	drawBoard(win, blockImage, board); 

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
	auto window_rect = new SDL_Rect(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);
	auto window_surface = SDL_GetWindowSurface(win);
	SDL_FillRect(window_surface, window_rect, SDL_MapRGB(window_surface.format, 0, 0, 0));

	auto rectInfo = new SDL_Rect(0, 0, 16, 16);
	auto rectPos = new SDL_Rect(0, 0);

	for(int i = 0; i < 20; i++)
	{
		writeln(i, "i");
		for(int j = 0; j < 10; j++)
		{
			if(!(board[i][j] is null))
			{
				rectInfo.x = 16 * board[i][j].getColor();
				rectPos.x = 16 * j;
				rectPos.y = 16 * i;
				SDL_BlitSurface(blockImage, rectInfo, window_surface, rectPos);
			}
			j.writeln;
		}
	}

	SDL_UpdateWindowSurface(win);
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


