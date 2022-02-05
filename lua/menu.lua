class.Menu(ui.View)

function Menu.createMenu()
    return Menu(ui.Bounds(0, 1.6, -2,   0,0,0))
end

function Menu:_init(bounds)
    self:super(bounds)
    self.stack = self:addSubview(ui.NavStack(ui.Bounds(0,0,0,   1,1,0.1)))

    self.stack:push(MainMenu())
end

class.MainMenu(ui.View)
function MainMenu:_init()
    self:super(ui.Bounds(0,0,0,   1, 1, 0.1))

    self:addSubview(ui.Label{
        bounds= ui.Bounds(0,0.3,0,   1, 0.20, 0.01),
        text= "Allosaber",
        color= {0.6, 0.2, 0.8, 1}
    })

    local playButton = self:addSubview(ui.Button(
        ui.Bounds(0,0,0,    0.6, 0.15, 0.05)
    ))
    playButton.label:setText("Play")
end


return Menu
