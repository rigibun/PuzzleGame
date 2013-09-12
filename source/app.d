import derelict.sdl2.sdl, derelict.sdl2.image;
import std.stdio, std.datetime, std.random, std.conv, core.thread;

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
	ulong lineCount = 0;
	Mino currentMino = genNewMino();
	
	timer.start();
	//Event loop
	while(1)
	{
		SDL_Event e;
		if(SDL_PollEvent(&e))
		{
			if(e.type == SDL_QUIT) break;
			if(e.type == SDL_KEYDOWN)
				switch(e.key.keysym.sym)
				{
					case SDLK_DOWN:
						if( !collCheck( getDroppedPos(currentMino.getBlocksPos), board))
							currentMino.drop();
						break;
					case SDLK_UP:
						while( !collCheck( getDroppedPos(currentMino.getBlocksPos), board))
							currentMino.drop();
						break;
					case SDLK_LEFT:
						if( !collCheck( getMoveLeftPos(currentMino.getBlocksPos), board) )
							currentMino.moveLeft();
						break;
					case SDLK_RIGHT:
						if( !collCheck( getMoveRightPos(currentMino.getBlocksPos), board) )
							currentMino.moveRight();
						break;
					case SDLK_z:
						if( !collCheck( getRightRotatedPos(currentMino.getRawBlocksPos,
										currentMino.getPos() ),
									board) )
							currentMino.rotateRight();
						break;
					case SDLK_x:
						if( !collCheck( getLeftRotatedPos(currentMino.getRawBlocksPos,
										currentMino.getPos() ),
									board) )
							currentMino.rotateLeft();
						break;
					default:
						break;
				}
		}

		if(timer.peek().to!("msecs", long) > 33)
		{
			frameCount++;
			if(frameCount >= dropInterval)
			{
				// Drop Block
				if( collCheck( getDroppedPos(currentMino.getBlocksPos()), board) )
				{
					putMino(currentMino, board);
					lineCount += checkBoard(board);
					currentMino = genNewMino();
					if( collCheck(currentMino.getBlocksPos(), board) )
					{
						auto message = "You cleared " ~ lineCount.to!string ~ " line.";
						SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, cast(char*)"Game Over",
								cast(char*)message, null);
						break;
					}
				}
				else
				{
					currentMino.drop();
				}

				frameCount = 0;
			}


			drawBoard(win, blockImage, board);
			if( !(currentMino is null) )
				drawMino(win, blockImage, currentMino);

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

void drawMino(SDL_Window* win, SDL_Surface* blockImage, Mino mino)
{
	auto windowSurface = SDL_GetWindowSurface(win);
	auto rectInfo = new SDL_Rect(0, 0, 16, 16);
	auto rectPos = new SDL_Rect(0, 0);

	auto blocksPos = mino.getBlocksPos();
	auto color = cast(Block.BlockColor)(mino.getType());
	rectInfo.x = 16 * color;

	for(int i = 0; i < 4; i++)
	{
		auto y = blocksPos[i][0];
		auto x = blocksPos[i][1];

		rectPos.x = 16 * x;
		rectPos.y = 16 * y;
		SDL_BlitSurface(blockImage, rectInfo, windowSurface, rectPos);
	}

	SDL_UpdateWindowSurface(win);
}

ulong checkBoard(Block[10][] board)
{
	ulong erasedLine = 0;
	for(auto i = cast(int)board.length - 1; i >= 0; i--)
	{
		bool lineFullFlag = true;
		
		for(int j = 0; j < 10; j++)
		{
			//writeln(i, ' ', j);
			if(board[i][j] is null)
				lineFullFlag = false;
		}
		
		if(lineFullFlag)
		{
			erasedLine++;
			eraseLine(board, i);
			i++;
		}
	}
	return erasedLine;
}

void eraseLine(Block[10][] board, ulong n)
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

void putMino(Mino mino, Block[10][] board)
{
	auto color = cast(Block.BlockColor)(mino.getType);
	auto blocksPos = mino.getBlocksPos;
	foreach(pos; blocksPos)
	{
		board[pos[0]][pos[1]] = new Block(color);
	}
}

int[2][4] getMoveLeftPos(int[2][4] pos)
{
	for(int i = 0; i < 4; i++)
	{
		pos[i][1]--;
	}
	return pos;
}

int[2][4] getMoveRightPos(int[2][4] pos)
{
	for(int i = 0; i < 4; i++)
	{
		pos[i][1]++;
	}
	return pos;
}

int[2][4] getLeftRotatedPos(int[2][4] blocksPos, int[2] pos)
{
	for(int i = 0; i < 4; i++)
	{
		int temp = blocksPos[i][0];
		blocksPos[i][0] = blocksPos[i][1] + pos[0];
		blocksPos[i][1] = -temp + pos[1];

	}

	return blocksPos;
}

int[2][4] getRightRotatedPos(int[2][4] blocksPos, int[2] pos)
{
	for(int i = 0; i < 4; i++)
	{
		int temp = blocksPos[i][0];
		blocksPos[i][0] = -blocksPos[i][1] + pos[0];
		blocksPos[i][1] = temp + pos[1];
	}
	return blocksPos;
}

int[2][4] getDroppedPos(int[2][4] pos)
{
	for(int i = 0; i < 4; i++)
	{
		pos[i][0]++;
	}
	return pos;
}

bool collCheck(int[2][4] blockPos, Block[10][] board)
{
	foreach(e; blockPos)
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

Mino genNewMino()
{
	auto rnd = Random(unpredictableSeed);
	auto num = cast(Mino.Type)(uniform(0, 7, rnd));
	Mino mino;

	switch(num)
	{
		case Mino.Type.O:
			mino = new MinoNotSpin(num, [1, 4]);
			break;
		case Mino.Type.J, Mino.Type.L, Mino.Type.T:
			mino = new MinoNormal(num, [1, 4]);
			break;
		case Mino.Type.Z:
			mino = new MinoFlipFlop(num, [1, 4]);
			break;
		case Mino.Type.S:
			mino = new MinoFlipFlop(num, [1, 5]);
			break;
		case Mino.Type.I:
			mino = new MinoFlipFlop(num, [0, 5]);
			break;
		default:
			goto case Mino.Type.O;
	}

	return mino;
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

	public Type getType()
	{
		return myType;
	}

	int[2][4] getBlocksPos()
	{
		auto retPos = blocksPos;
		foreach(ref pos; retPos)
		{
			pos[0] += myPos[0];
			pos[1] += myPos[1];
		}
		return retPos;
	}

	int[2][4] getRawBlocksPos()
	{
		return blocksPos;
	}

	int[2] getPos()
	{
		return myPos;
	}

	abstract void genPos();
	abstract void rotateLeft();
	abstract void rotateRight();

	void moveLeft()
	{
		myPos[1]--;
	}

	void moveRight()
	{
		myPos[1]++;
	}
	
	void drop()
	{
		myPos[0]++;
	}
}

class MinoNotSpin : Mino
{
	this(Type t, int[2] pos)
	{
		myType = t;
		myPos = pos;
		genPos();
	}

	override void genPos()
	{
		blocksPos[0] = [0, 0];
		blocksPos[1] = [-1, 0];
		blocksPos[2] = [0, 1];
		blocksPos[3] = [-1, 1];
	}

	override void rotateLeft(){}
	override void rotateRight(){}
}

class MinoFlipFlop : Mino
{
	bool verticalFlag = false;

	this(Type t, int[2] pos)
	{
		myType = t;
		myPos = pos;
		genPos();
	}

	override void genPos()
	{
		switch(myType)
		{
			case Type.S:
				blocksPos[0] = [0, 0];
				blocksPos[1] = [0, -1];
				blocksPos[2] = [1, 0];
				blocksPos[3] = [-1, -1];
				break;
			case Type.Z:
				blocksPos[0] = [0, 0];
				blocksPos[1] = [0, 1];
				blocksPos[2] = [-1, 0];
				blocksPos[3] = [-1, -1];
				break;
			case Type.I:
				blocksPos[0] = [0, 0];
				blocksPos[1] = [0, 1];
				blocksPos[2] = [0, -1];
				blocksPos[3] = [0, -2];
				break;
			default:
				writeln("MinoFlipFlop was construct with Type.", myType);
				break;
		}
	}

	override void rotateLeft()
	{
		if(!verticalFlag)
			rotateRight();
		else
		{
			for(int i = 0; i < 4; i++)
			{
				int temp = blocksPos[i][0];
				blocksPos[i][0] = blocksPos[i][1];
				blocksPos[i][1] = -temp;
			}
			verticalFlag = false;
		}

	}

	override void rotateRight()
	{
		if(verticalFlag)
			rotateLeft();
		else
		{
			for(int i = 0; i < 4; i++)
			{
				int temp = blocksPos[i][0];
				blocksPos[i][0] = -blocksPos[i][1];
				blocksPos[i][1] = temp;
			}
			verticalFlag = true;
		}
	}
}

class MinoNormal : Mino
{
	this(Type t, int[2] pos)
	{
		myType = t;
		myPos = pos;
		genPos();
	}

	override void genPos()
	{
		switch(myType)
		{
			case Type.J:
				blocksPos[0] = [0, 0];
				blocksPos[1] = [0, -1];
				blocksPos[2] = [0, 1];
				blocksPos[3] = [-1, -1];
				break;
			case Type.L:
				blocksPos[0] = [0, 0];
				blocksPos[1] = [0, 1];
				blocksPos[2] = [0, -1];
				blocksPos[3] = [-1, 1];
				break;
			case Type.T:
				blocksPos[0] = [0, 0];
				blocksPos[1] = [0, 1];
				blocksPos[2] = [0, -1];
				blocksPos[3] = [-1, 0];
				break;
			default:
				writeln("MinoNormal was construct with Type.", myType);
				break;
		}
	}

	override void rotateLeft()
	{
		for(int i = 0; i < 4; i++)
		{
			int temp = blocksPos[i][0];
			blocksPos[i][0] = blocksPos[i][1];
			blocksPos[i][1] = -temp;
		}
	}

	override void rotateRight()
	{
		for(int i = 0; i < 4; i++)
		{
			int temp = blocksPos[i][0];
			blocksPos[i][0] = -blocksPos[i][1];
			blocksPos[i][1] = temp;
		}
	}
}
