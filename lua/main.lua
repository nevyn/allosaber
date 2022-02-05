local client = Client(
    arg[2], 
    "allosaber"
)
app = App(client)

Menu = require("menu")
Game = require("game")

assets = {
    quit = ui.Asset.File("images/quit.png"),
    arrow = ui.Asset.File("images/arrow.png"),
    dot = ui.Asset.File("images/dot.png"),
    bomb = ui.Asset.File("images/bomb.png"),
}
app.assetManager:add(assets)

local mainView = Menu.createMenu()

app.mainView = mainView
app:connect()
app:run(1000)
