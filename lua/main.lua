local client = Client(
    arg[2], 
    "allosaber"
)
app = App(client)

local Menu = require("menu")

assets = {
    quit = ui.Asset.File("images/quit.png"),
}
app.assetManager:add(assets)

local mainView = Menu.createMenu()


app.mainView = mainView
app:connect()
app:run()
