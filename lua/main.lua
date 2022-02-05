local client = Client(
    arg[2], 
    "allosaber"
)
app = App(client)

local Menu = require("menu")

assets = {
    quit = ui.Asset.File("images/quit.png"),
    arrow = ui.Asset.File("images/arrow.png"),
    dot = ui.Asset.File("images/dot.png"),
}
app.assetManager:add(assets)

local mainView = Menu.createMenu()

app.mainView = mainView
app:connect()
app:run(1000)
