source(g_currentModDirectory .."src/gui/AnimalInputScreen.lua")
source(g_currentModDirectory .."src/controllers/AnimalScreenTrailerStorage.lua")
--source(g_currentModDirectory .."src/controllers/events/AnimalInputEvent.lua")
source(g_currentModDirectory .."src/storageExtension/AnimalInputExtension.lua")
source(g_currentModDirectory .."src/triggers/AnimalInputTrigger.lua")

g_animalInputScreen = AnimalInputScreen.new()
g_gui:loadProfiles(g_currentModDirectory .. "xml/gui/guiProfiles.xml")
g_gui:loadGui(g_currentModDirectory .. "xml/gui/AnimalInputScreen.xml", "AnimalInputScreen", g_animalInputScreen)