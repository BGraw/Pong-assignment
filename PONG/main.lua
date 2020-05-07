--Brennyn Gray Pong Remake


-- push is a library that will allow us to draw our game at a virtual
-- resolution, instead of however large our window is; used to provide
-- a more retro aesthetic
--
-- https://github.com/Ulydev/push
push = require 'push'

-- the "Class" library we're using will allow us to represent anything in
-- our game as code, rather than keeping track of many disparate variables and
-- methods
--
-- https://github.com/vrld/hump/blob/master/class.lua
Class = require 'class'

-- our Paddle class, which stores position and dimensions for each Paddle
-- and the logic for rendering them
require 'Paddle'

-- our Ball class, which isn't much different than a Paddle structure-wise
-- but which will mechanically function very differently
require 'Ball'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

-- speed at which we will move our paddle; multiplied by dt in update
PADDLE_SPEED = 200

--[[
    Runs when the game first starts up, only once; used to initialize the game.
]]
function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')

	--set the title of our application
	love.window.setTitle('Pong')

    -- "seed" the RNG so that calls to random are always random
    -- use the current time, since that will vary on startup every time
    math.randomseed(os.time())

    -- more "retro-looking" font object we can use for any text
    smallFont = love.graphics.newFont('font.ttf', 8)

	--large font 
	largeFont = love.graphics.newFont('font.ttf', 16)

	--font for drawing the score to the screen
	scoreFont = love.graphics.newFont('font.ttf', 32)

    -- set L�VE2D's active font to the smallFont object
    love.graphics.setFont(smallFont)

	--[[ set up our sounds table so that later we can inject our sounds
	into our code and call each entrys 'play' method]]
	sounds = {
		['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
		['score'] = love.audio.newSource('sounds/score.wav', 'static'),
		['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static'),
	}

    -- initialize window with virtual resolution
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
		--resizeable = true so the user can adjust window
        resizable = true,
        vsync = true
    })

	--initialize the player score variables
	player1Score = 0
	player2Score = 0

	--[[ either going to be 1 or 2, whomever is scored on gets to serve 
	the following turn]]
	servingPlayer = 1

    -- initialize our player paddles; make them global so that they can be
    -- detected by other functions and modules
    player1 = Paddle(10, 30, 5, 20)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)

    -- place a ball in the middle of the screen
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

    -- game state variable used to transition between different parts of the game
    -- (used for beginning, menus, main game, high score list, etc.)
    -- we will use this to determine behavior during render and update
    gameState = 'start'
end

--[[ add resizing function to allow the user to resize the indow accordingly
to their monitor as well as not distort the program]]
function love.resize(w, h)
	push:resize(w, h)
end


--[[
    Runs every frame, with "dt" passed in, our delta in seconds 
    since the last frame, which L�VE2D supplies us.
]]
function love.update(dt)
	if gameState == 'serve' then
		--[[ before switching to play, initialize ball's velocity based 
		on the player who last scored]]
		ball.dy = math.random(-50, 50)
			if servingPlayer == 1 then
				ball.dx = math.random(140, 200)
			else
				ball.dx = -math.random(140, 200)
			end
	elseif gameState == 'play' then
		--[[detect ball collision with paddles, reversing dx if true and
		-- slightly incresing dx, then altering the dy based on the position
		when the ball collides with the left paddle, using +5 (paddle width) will create the 
		"bounce" effect.]]
		if ball:collides(player1) then
			ball.dx = -ball.dx * 1.03
			ball.x = player1.x + 5

			--keep velocity going in the same direction, but randomize it
			if ball.dy < 0 then
				ball.dy = -math.random(10, 150)
			else
				ball.dy = math.random(10, 150)
			end

			sounds['paddle_hit']:play()
		end

		--[[ (-4) is used because the width of the ball is 4 pixels, to create
		the bouncing effect, when the ball collides with the paddle,the ball 
		will shift to the left side of the right paddle and "bounce"
		--]]
		if ball:collides(player2) then
			ball.dx = -ball.dx * 1.03
			ball.x = player2.x - 4

			--keep velocity going in the same direction but randomize it
			if ball.dy < 0 then
				ball.dy = -math.random(10, 150)
			else
				ball.dy = math.random(10, 150)
			end

			sounds['paddle_hit']:play()
		end

		-- detect upper edge screen boundary
		if ball.y <= 0 then
			ball.y = 0
			ball.dy = -ball.dy
			sounds['wall_hit']:play()
		end

		--  (-4) to account for ball size on the lower virtual screen
		if ball.y >= VIRTUAL_HEIGHT - 4 then
			ball.y = VIRTUAL_HEIGHT - 4
			ball.dy = -ball.dy
			sounds['wall_hit']:play()
		end

		--if we reach the left or right of the edge of the screen
		--go back to start and update the score and determine winner.
		--player 2 score
		if ball.x < 0 then
			servingPlayer = 1
			player2Score = player2Score + 1
			sounds['score']:play()
					
			if player2Score == 10 then
				winningPlayer = 2
				gameState = 'done'
			else			
				gameState = 'serve'
				ball:reset()
			end
		end

		--player 1 score
		if ball.x > VIRTUAL_WIDTH then
			servingPlayer = 2
			player1Score = player1Score + 1
			sounds['score']:play()
						
			if player1Score == 10 then
				winningPlayer = 1
				gameState = 'done'
			else
				gameState = 'serve'
				ball:reset()
			end
		end
	end

    -- player 1 movement
    --if love.keyboard.isDown('w') then
	--	player1.dy = -PADDLE_SPEED
    --elseif love.keyboard.isDown('s') then
    --    player1.dy = PADDLE_SPEED
    --else
    --    player1.dy = 0
    --end
	--[[ add code for AI operated Player 1]]
	if player1:moveDown(ball) then	
		player1.dy = -PADDLE_SPEED
	elseif player1:moveUp(ball) then
		player1.dy = PADDLE_SPEED
	else
		player.dy = 0
	end

    -- player 2 movement
    if love.keyboard.isDown('up') then
        player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        player2.dy = PADDLE_SPEED
    else
        player2.dy = 0
    end

    -- update our ball based on its DX and DY only if we're in play state;
    -- scale the velocity by dt so movement is framerate-independent
    if gameState == 'play' then
        ball:update(dt)
    end

    player1:update(dt)
    player2:update(dt)
end

--[[
    Keyboard handling, called by L�VE2D each frame; 
    passes in the key we pressed so we can access.
]]
function love.keypressed(key)
    -- keys can be accessed by string name
    if key == 'escape' then
        -- function L�VE gives us to terminate application
        love.event.quit()
    -- if we press enter during the start state of the game, we'll go into play mode
    -- during play mode, the ball will move in a random direction
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
			gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'
		end
		
		if gameState == 'done' then
			--game is simply reset when the game is done
            gameState = 'serve'
			
			--reset scores to 0
			player1Score = 0
			player2Score = 0

			-- ball's new reset method
			ball:reset()

			--decide serving player based on who won
			if winningPlayer == 1 then
				servingPlayer = 2
			else
				servingPlayer = 1
			end
        end
    end
end

--[[
    Called after update by L�VE2D, used to draw anything to the screen, 
    updated or otherwise.
]]
function love.draw()
    -- begin rendering at virtual resolution
    push:apply('start')

    -- clear the screen with a specific color; in this case, a color similar
    -- to some versions of the original Pong
    love.graphics.clear(40, 45, 52, 255)

    -- draw different things based on the state of the game
    love.graphics.setFont(smallFont)

	displayScore()


    if gameState == 'start' then
	--[[updated text that changes with the change of serve and changes 
	of gamestate]]
		love.graphics.setFont(smallFont)
        love.graphics.printf('Welcome to Pong!', 0, 10, VIRTUAL_WIDTH, 'center')
		love.graphics.printf('Press Enter to begin!', 0, 20, VIRTUAL_WIDTH, 'center')
    
	elseif gameState == 'serve' then
		love.graphics.setFont(smallFont)
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!",
			0, 10, VIRTUAL_WIDTH, 'center')
		love.graphics.printf('Press enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
	
	elseif gameState == 'play' then
		-- no message displayed during gameplay
	
	elseif gameState == 'done' then
		love.graphics.setFont(largeFont)
		love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!',
			0, 10, VIRTUAL_WIDTH, 'center')
		love.graphics.setFont(smallFont)
		love.graphics.printf('Press Enter to restart!', 0, 30, VIRTUAL_WIDTH, 'center')
    end

	
    -- render paddles, now using their class's render method
    player1:render()
    player2:render()

    -- render ball using its class's render method
    ball:render()

	--new function to display the FPS
	displayFPS()
	
    -- end rendering at virtual resolution
    push:apply('end')
end

function displayFPS()
	--simple FPS display across all states
	love.graphics.setFont(smallFont)
	love.graphics.setColor(0, 255, 0, 255)
	-- concatonation of a number to a string is used with ..
	love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
end

function displayScore()
	--[[ draw score on the left and right center of the screen need to
		switch font to draw before actually printing]]
	love.graphics.setFont(scoreFont)
	love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2-50,
		VIRTUAL_HEIGHT/3)
	love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2+30,
		VIRTUAL_HEIGHT/3)
end