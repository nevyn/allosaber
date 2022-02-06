local json = require("allo.json")

class.Game(ui.View)
-- https://bsmg.wiki/mapping/map-format.html#base-object-2
-- "_songName": "Beat Saber",
--     "_songSubName": "",
--     "_songAuthorName": "Jaroslav Beck",
--     "_levelAuthorName": "",
--     "_beatsPerMinute": 166,
--     "_songTimeOffset": 0,
--     "_shuffle": 0,
--     "_shufflePeriod": 1,
--     "_previewStartTime": 26,
--     "_previewDuration": 12,
--     "_songFilename": "song.ogg",
--     "_coverImageFilename": "cover.png",
--     "_environmentName": "BTSEnvironment",
--     "_allDirectionsEnvironmentName": "GlassDesertEnvironment",
-- 
-- _notes= {{
--     "_time": 8,
--     "_lineIndex": 2,
--     "_lineLayer": 0,
--     "_type": 1,
--     "_cutDirection": 1
-- }, ...}
-- "_obstacles": [
--     {
--         "_time": 68,
--         "_lineIndex": 0,
--         "_type": 1,
--         "_duration": 0.5,
--         "_width": 4
--     },

local laneWidth = 0.4
local layerHeight = 0.2

function Game:_init(song)
    self:super()
    self.song = song
    local songPath = "songs/"..song
    local metaPath = songPath.."/Info.dat"
    local levelPath = songPath.."/Hard.dat"
    local assetPath = songPath.."/song.ogg"
    self.meta = json.decode(utils.readfile(metaPath))
    self.dat = json.decode(utils.readfile(levelPath))
    self.songAsset = ui.Asset.File(assetPath)
    self.bpm = self.meta._beatsPerMinute
    self.bps = self.bpm/60.0
    self.introDelay = 1.0
    self.farDelay = 2.0
    self.fadeDelay = 0.2
    self.currentBeat = -self.introDelay * self.bps
    self.currentBeatAt = 0
    self.currentNoteIndex = 1
    self.currentObstacleIndex = 1
    self.noteBlocks = {}
    self.obstacleBlocks = {}

    local d = 6.0
    self.board = self:addSubview(ui.Cube(ui.Bounds(0, -1.0, -d/2 - 0.5,   laneWidth*4, 0.05, d)))
    self.board:setColor({0.7, 0.7, 0.7, 0.6})
end

function Game:awake()
    ui.View.awake(self)
    self.beatAction = app:scheduleAction(60.0/self.bpm, true, function()
        self:beat()
    end)
    self.frameAction = app:scheduleAction(1.0/30.0, true, function()
        self:frame()
    end) 
    self.app.assetManager:add(self.songAsset)
    self.speaker = ui.Speaker(nil, self.songAsset)
    self.speaker.startsAt = app:serverTime() + self.introDelay
    self.speaker.loopCount = 0
    self.speaker.volume = 0.8
    self:addSubview(self.speaker)
end

function Game:sleep()
    ui.View.sleep(self)
    print("sleeping game")
    if self.beatAction then
        self.beatAction:cancel()
        self.frameAction:cancel()
    end
end

function Game:beat()
    self.currentBeat = self.currentBeat + 1
    self.currentBeatAt = app:serverTime()
    print("Beat", self.currentBeat)

    -- when, in beats, we should load notes and obstacles for
    local farBeat = self.currentBeat + self.farDelay*self.bps

    self:trySpawnNote(farBeat)
    self:trySpawnObstacle(farBeat)

    if self.endBeat and self.currentBeat > self.endBeat then
        self:winGame()
    end
end

function Game:frame()
    self:updateBoardedNotes()
end

function Game:winGame()
    self.nav:push(Menu.createGameEnd(self.song, "You won!"))
end

function Game:trySpawnNote(farBeat)
    local nextNote = self.dat._notes[self.currentNoteIndex]
    if not nextNote then
        if not self.endBeat then
            self.endBeat = self.noteBlocks[#self.noteBlocks].meta._time + self.bps
            print("End of song is at beat", self.endBeat)
        end
        return
    end

    if nextNote._time <= farBeat then
        print("Spawning note", self.currentNoteIndex, "at", nextNote._time, "for farBeat", farBeat)
        self:spawnNote(nextNote)
        self.currentNoteIndex = self.currentNoteIndex + 1

        -- see if next note wants to be spawned too
        self:trySpawnNote(farBeat)
    end
end

function Game:trySpawnObstacle(farBeat)
    local nextObstacle = self.dat._obstacles[self.currentObstacleIndex]
    if not nextObstacle then
        return
    end

    if nextObstacle._time <= farBeat then
        print("Spawning obstacle", self.currentObstacleIndex, "at", nextObstacle._time, "for farBeat", farBeat)
        self:spawnObstacle(nextObstacle)
        self.currentObstacleIndex = self.currentObstacleIndex + 1

        -- see if next obstacle wants to be spawned too
        self:trySpawnObstacle(farBeat)
    end
end

function Game:spawnNote(noteMeta)
    local note = NoteBlock(noteMeta)
    note.game = self
    note:positionForBeat(self.currentBeat)
    self:addSubview(note)
    table.insert(self.noteBlocks, note)
    note:fadeIn()
end

function Game:spawnObstacle(obstacleMeta)
    local obstacle = ObstacleBlock(obstacleMeta, self)
    obstacle:positionForBeat(self.currentBeat)
    self:addSubview(obstacle)
    table.insert(self.obstacleBlocks, obstacle)
    obstacle:fadeIn()
end

function Game:removeNote(noteBlock, blockIndex)
    noteBlock:removeFromSuperview()
    table.remove(self.noteBlocks, blockIndex)
end

function Game:removeObstacle(obstacleBlock, blockIndex)
    obstacleBlock:removeFromSuperview()
    table.remove(self.obstacleBlocks, blockIndex)
end

function Game:preciseCurrentBeat()
    local delta = app:serverTime() - self.currentBeatAt
    return self.currentBeat + delta * self.bps
end

function Game:updateBoardedNotes()
    for i, block in ipairs(self.noteBlocks) do
        block:positionForBeat(self:preciseCurrentBeat())

        local disappearBeatDelay = self.fadeDelay * self.bps
        if self.currentBeat > block.meta._time + disappearBeatDelay then
            self:removeNote(block, i)
        end
    end

    for i, block in ipairs(self.obstacleBlocks) do
        block:positionForBeat(self:preciseCurrentBeat())

        local disappearBeatDelay = self.fadeDelay * self.bps
        if self.currentBeat > block.meta._time + block.meta._duration + disappearBeatDelay then
            self:removeObstacle(block, i)
        end
    end
end

class.NoteBlock(ui.Cube)
function NoteBlock:_init(meta)
    local s = laneWidth-0.05
    self:super(ui.Bounds(0,0,0,   s, s, s))
    self.meta = meta
    if meta._type == 0 then
        self.color = {1, 0, 0, 0}
    elseif meta._type == 1 then
        self.color = {0, 0, 1, 0}
    elseif meta._type == 3 then
        self.color = {0.4, 0.4, 0.4, 0}
    end
    self.arrow = self:addSubview(ui.Surface(ui.Bounds(0, 0, s/2+0.001,  s, s, s)))
    self.arrow:setTexture(assets.arrow)
    self.arrow.uvh = 0.95
    self.arrow.uvw = 0.95
    self.arrow.hasTransparency = true
    if self.meta._cutDirection == 1 then
        self.arrow.bounds:rotate(3.14, 0,0,1)
    elseif self.meta._cutDirection == 2 then
        self.arrow.bounds:rotate(3.14/2, 0,0,1)
    elseif self.meta._cutDirection == 3 then
        self.arrow.bounds:rotate(-3.14/2, 0,0,1)
    elseif self.meta._cutDirection == 8 then
        self.arrow:setTexture(assets.dot)
    end
    -- todo: more cut directions: 
    -- 4 	Up Left
    -- 5 	Up Right
    -- 6 	Down Left
    -- 7 	Down Right

    if self.meta._type == 3 then
        self.arrow:setTexture(assets.bomb)
    end
end

function NoteBlock:positionForBeat(beat)
    local targetBeat = self.meta._time
    local beatDistance = targetBeat - beat
    local metersPerSecond = 15.0
    local beatsPerSecond = self.game.bps
    local metersPerBeat = metersPerSecond/beatsPerSecond
    local distance = beatDistance * metersPerBeat
    

    self.bounds:moveToOrigin():move(
        self.meta._lineIndex * laneWidth - 2*laneWidth,
        self.meta._lineLayer * layerHeight - 2*layerHeight,
        -distance
    )
    self:setBounds()
end

function NoteBlock:fadeIn()
    self:doWhenAwake(function()
        self:addPropertyAnimation(PropertyAnimation{
            path= "material.color.3",
            from= 0,
            to=   1,
            duration = 0.3,
            easing= "quadIn",
        })    
    end)
    self.arrow:doWhenAwake(function()
        self.arrow:addPropertyAnimation(PropertyAnimation{
            path= "material.color.3",
            from= 0,
            to=   1,
            duration = 0.3,
            easing= "quadIn",
        })    
    end)
end

class.ObstacleBlock(ui.Cube)
function ObstacleBlock:_init(meta, game)
    self.isFullHeight = meta._type == 0
    self:super(ui.Bounds(
        0,
        self.isFullHeight and 0.01 or layerHeight,
        0,
        laneWidth * meta._width,
        layerHeight * (self.isFullHeight and 3 or 2),
        meta._duration*game.bps
    ))
    self.meta = meta
    self.game = game
    self.color = {0.7, 0.3, 0.3, 0}
end

function ObstacleBlock:positionForBeat(beat)
    local targetBeat = self.meta._time
    local beatDistance = targetBeat - beat
    local metersPerSecond = 15.0
    local beatsPerSecond = self.game.bps
    local metersPerBeat = metersPerSecond/beatsPerSecond
    local distance = beatDistance * metersPerBeat
    local boxWidth = self.meta._width*laneWidth
    
    self.bounds:moveToOrigin():move(
        (self.meta._lineIndex-2) * laneWidth + boxWidth/2,
        self.isFullHeight and 0.01 or layerHeight,
        -distance
    )
    self:setBounds()
end

function ObstacleBlock:fadeIn()
    self:doWhenAwake(function()
        self:addPropertyAnimation(PropertyAnimation{
            path= "material.color.3",
            from= 0,
            to=   0.9,
            duration = 0.3,
            easing= "quadIn",
        })    
    end)
end


return Game
