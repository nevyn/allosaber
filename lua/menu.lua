class.Menu(ui.View)

function Menu.createMenu()
    return Menu(ui.Bounds(0, 1.6, -2,   0,0,0))
end

function Menu.createGameEnd(song, title)
    return GameEndMenu(song, title)
end

function Menu:_init(bounds)
    self:super(bounds)
    self.stand = self:addSubview(ui.Cube(ui.Bounds(0, -1.6, 0.0,   0.4, 0.02, 0.4)))
    self.stack = self:addSubview(ui.NavStack(ui.Bounds(0,0,0,   1,1,0.1)))
    self.stack:setShowsBackButton(false)

    self.stack:push(MainMenu())
end

class.MainMenu(ui.View)
function MainMenu:_init()
    self:super(ui.Bounds(0,0,-2,   1, 1, 0.1))

    self:addSubview(ui.Label{
        bounds= ui.Bounds(0,0.3,0,   1, 0.20, 0.01),
        text= "Allosaber",
        color= {0.6, 0.2, 0.8, 1}
    })

    self.playButton = self:addSubview(ui.Button(
        ui.Bounds(0,0,0,    0.6, 0.15, 0.05)
    ))
    self.playButton.label:setText("Play")
    self.playButton.onActivated = function(hand)
        local avatar = hand:getAncestor()
        self.nav:push(Game("Jaroslav Beck - Beat Saber", avatar))
    end

    local quitButton = self:addSubview(ui.Button(
        ui.Bounds(0,-0.4,0,    0.6, 0.15, 0.05)
    ))
    quitButton.label:setText("Quit")
    quitButton.onActivated = function()
        app:quit()
    end
end

function MainMenu:awake()
    ui.View.awake(self)

    -- for quick game start during debugging
    --self.playButton:onActivated()
end

class.GameEndMenu(ui.View)
function GameEndMenu:_init(song, title)
    self:super(ui.Bounds(0,0,-2,   1, 1, 0.1))

    self:addSubview(ui.Label{
        bounds= ui.Bounds(0,0.3,0,   1, 0.20, 0.01),
        text= title,
        color= {0.6, 0.2, 0.8, 1}
    })

    self.backButton = self:addSubview(ui.Button(
        ui.Bounds(0,0,0,    0.6, 0.15, 0.05)
    ))
    self.backButton.label:setText("Continue")
    self.backButton.onActivated = function()
        self.nav:popToBottom()
    end

    local replayButton = self:addSubview(ui.Button(
        ui.Bounds(0,-0.4,0,    0.6, 0.15, 0.05)
    ))
    replayButton.label:setText("Play again")
    replayButton.onActivated = function(hand)
        local player = hand:getAncestor()
        local nav = self.nav
        nav:popToBottom()
        nav:push(Game(song, player))
    end
end


return Menu
