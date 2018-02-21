# Vania Helper

Vaniahelper is a tool for creating room layouts, and rooms at run-time. This
plugin is split into two parts: The Vaniamap editor, and the Vaniamap loading
node.

## The Vaniamap Editor

The Vaniamap Editor can be found on the bottom bar, next to the Debugger, Audio,
Animation, etc. The Vaniamap editor is used to edit Vaniamap files. I assume
that most people are familiar with how saving/loading files works, and if you
are, then you can skip the next few paragraphs. If not, then the following
paragraphs are here for your reference.

### Creating a new Vaniamap

A new Vaniamap can be created by pressing the "New" button.
Choose any file path that you want to save this map as, and note that the file
type for Vaniamap files is ".vmap". 

### Load an existing Vaniamap

To load an existing Vaniamap, press the "Load" button.

### Saving a Vaniamap

From here, a map can be saved by pressing the "Save" button at the top. The 
"Save As" button will save the map to a different location, and the 
"Save A Copy" button will save the map to a different location without changing
the path of the current editor.

### Closing a Vaniamap

When you are done editing, press the "Close" button to close the current editor.
You will be prompted whether or not you want to save your edits.

### Setting up a Vaniamap

Vaniamap runs under the assumption that your levels can all be arranged into a
grid of equally sized cells. However, each level can take up as many cells as it
wants, as long as it fits into a rectangular shape. You can change the size of
a cell by changing the width and height under "Global Properties," which appear
on the right-hand side of the editor. By default the width is 1024 and the 
height is 640, which are the defaults for Godot's window size. Changing these 
values will not affect the editor in any way, but will be important later when 
you start loading in levels from within the game.

### Tiles

The Vaniamap grid stores level into what are called "Tiles." A tile has a color, 
a width, a height, and scene path. To create a new tile, right click on where
you want to place the tile, and click on the "New Tile" button which appears in 
the context menu. Upon clicking this button, you will be prompted to select a
scene file. Once you do that, a new tile will be created which refers to the
scene that you selected

#### Changing tile properties

Clicking on a tile will select that tile. When a tile is selected, it will have
a white border. It will also open this tile's scene in the scene editor. On the
right-hand side above the Global Properties there will be the "Tile Properties."
Under the tile properties, you will see many properties for the tile that you
selected. Here is a table of properties that you can edit from within the tile
property editor.

| Name | Desription |
| :--- | :--------- |
| color | The color of this tile within the editor. Clicking on the color will allow you to change the color of this tile. |
| scene | The scene that this tile refers to. It can be changed by clicking on the folder icon, which will prompt you to select another file. |
| width | The width of this tile in grid cells. Change this if this level is actually wider than 1 grid cell. The tile will appear wider in the editor upon increasing this value. |
| height | The height of this tile in grid cells. Similar to the width of a tile, this property can be changed if a level is taller than 1 grid cell. |

#### Moving tiles

A tile can be moved by clicking on a tile, and while holding down the left mouse
button, moving the mouse to a new location. Upon releasing the left mouse
button, the tile will be placed where the mouse currently is.

#### Selecting multiple tiles

Multiple tiles can be selected by holding down shift while clicking on tiles.
While multiple tiles are selected, only the color property can be edited.

Multiple tiles can also be moved at the same time, simply by selecting multiple
tiles and moving tiles like you would move just one.

To deselect a tile, click on the tile again while holding shift.

#### Other tile operations

A tile can be deleted by right-clicking on it and then clicking on the "Delete"
button.

You can open the scene that a tile refers to by right-clicking on it and then
clicking on the "Open In Editor" button.

## The Vaniamap Node

Once a Vaniamap has been created, it is useful to be able to load the contents
of a Vaniamap into a game. To do this, you will need to use the "VaniaMap" node
which inherits "Node."

### Tiles

Tiles in the Vaniamap are represented by the `VaniaMap.Tile` type. An array of
all of the tiles in the VaniaMap are stored in the `VaniaMap.tile_list` 
property.

### Loading Rooms

You can then load in a VaniaMap by using the 
`VaniaMap.load_from(path)` function, which will load the contents of a VaniaMap
file into itself. Rooms can then be loaded into the VaniaMap node by using the
`VaniaMap.load_room(tile)`, which takes a `Tile` as an argument. Thus, in order
to load *all* rooms in a VaniaMap, you could use the following code:

```gdscript
extends Node

func _ready():
	$VaniaMap.load_from("res://path/to/map.vmap")
	for tile in $VaniaMap.tile_list:
		$VaniaMap.load_room(tile)
```

The code above assumes that you have a root node of type Node with the above
script attached to it, with a VaniaMap node under it. Note that you can't attach
the script to the VaniaMap node itself since with the current plugin system,
scripts can not be reasonably attached to custom nodes defined by plugins.

All rooms that are loaded in by the VaniaMap will be a child of said VaniaMap.
All rooms must have a root node that is a Node2D, or inherits Node2D, otherwise
VaniaMap will not be able to load the room into the correct position.

Note that a 'room' in this context refers to a scene that has been loaded in by
a Tile.

### Loading only necessary rooms

In some cases, you may find that you only want to load rooms that are nearby to
the player. The best way to do this, in my opinion, is to load only the room
that the player is in, and all rooms that are adjacent to the room that the
player is in. However, rooms will not be unloaded until the player is two rooms
away from that room, that way rooms aren't constantly loading and unloading
when the player rapidly enters and exits a room. A minimal example of this
concept can be seen here:

```gdscript
onready var map = $VaniaMap

var connections;
var load_position;

# Get all tiles that are 'depth' tiles away from the given tile.
# Keys in the resulting dictionary are Tiles.
# Values in the resulting dictionary are how many tiles the tile is away from
# the given tile.
# The given tile is also included in the dictionary with a value of 0.
func get_tile_nearby(tile, depth=1, data=null):
	if data == null:
		data = {}
		data[tile] = 0
	for t in connections[tile]:
		if not t in data:
			data[t] = depth
	if depth > 1:
		for t in data:
			if data[t] == depth:
				get_room_nearby(t, depth-1, data)
	return data

func _ready():
	map.load_from(map_file)
	connections = map.get_tile_connections()

# Load/Unload rooms based on the position of the player given by 'pos'
func set_load_position(pos):
	pos = map.pos_to_tilepos(pos)
	if pos != load_position:
		load_position = pos
		var tile = map.get_tile(pos)
		if tile != null:
			var connections = get_room_nearby(tile, 2)
			for unloadtile in map.loaded_rooms:
				if not unloadtile in connections:
					map.unload_room(unloadtile)
			for loadtile in connections:
				if connections[loadtile] <= 1:
					map.load_room(loadtile)
```

This code assumes that you are already familiar with the basics of gdscript.

This code also makes use of a few new functions that are available from 
VaniaMap: `map.get_tile_connections()`, `map.pos_to_tilepos(pos)`, and
`map.unload_room(tile)`, all of which will be explained in the API.

This code could be written using some form of concurrency to load in rooms
without blocking the main thread, however that is beyond the scope of this
document.

## API

This is the API for VaniaMap. Hopefully this will be useful for programmers who 
are using this plugin. If you are a level designer, you can safely ignore this section.

### Tile API

The API for the VaniaMap.Tile structure.

#### Properties

| Property | Description |
| :------- | :---------- |
| `id` | The unique ID of the tile. |
| `color` | The color of the tile. |
| `path` | The path to the scene that the tile refers to. |
| `width` | The width of the tile in grid cells. |
| `height` | The height of the tile in grid cells. |
| `position` | The position of the tile in grid cells. |

#### Functions

| Function | Description |
| :------- | :---------- |
| `calculate_nearby(map)` | Returns an array of tiles that are next to this tile. |

### VaniaMap API

The API for the VaniaMap node.

#### Properties

| Property | Description |
| :------- | :---------- |
| `tile_list` | Array of all tiles in the map |
| `tile_map` | Dictionary of tiles in the map, where keys are Vector2 positions and values are Tiles. |
| `room_width` | Width of a single grid cell in pixels. |
| `room_height` | Height of a single grid cell in pixels. |
| `loaded_rooms` | Dictionary of all rooms that have been loaded, where keys are
Tiles and values are Nodes. |

#### Functions (For normal use)

| Function | Description |
| :------- | :---------- |
| `load_room(tile)` | Loads a room into existence. The room that is loaded is based on the given Tile's path. |
| `unload_room(tile)` | Removes the given room from existence. |
| `pos_to_tilepos(pos)` | Takes a position in pixels, and converts it into a grid position that can be used to refer to tiles. |
| `tilepos_to_pos(pos)` | Inverse of `pos_to_tilepos`; Takes a grid position and converts it into a position in pixels. |
| `get_tile(pos)` | Gets the tile at the given grid position. Returns false if no tile exists at the given position. |
| `get_tile_connections()` | Get all tiles connections. Keys are references to
tiles, and values are arrays of tile references which represent all tiles that
are next to the given tile. |
| `load_from(path)` | Load a map from the given file. |

#### Functions (For editor development uses)

| Function | Description |
| :------- | :---------- |
| `_set_tile(pos, tile)` | Set the cell at the given grid position to the given tile. |
| `_push_tile(pos, tile)` | Put the given tile into the grid at the given grid position, taking the tile's width and height into account. |
| `_pop_tile(pos, tile)` | Removes the tile at the given grid position taking the tile's width and height into account, and returns the tile. Pop tile and push tile are meant to be used in conjunction to move tiles around the grid. |
| `can_move_tile(pos_from, pos_to, exceptions=null)` | Returns true if the tile at the grid position 'pos\_from' can be moved to the grid position 'pos\_to'. If the 'exceptions' argument is given, then this function will ignore tiles that occur within the 'exceptions' array. |
| `delete_tile(pos)` | Deletes the tile at the given grid position, completely removing it and its tile id from existence. This will change all tile IDs that occur after the ID of the tile that was deleted. Returns true if a tile exists at the given position and was removed. |
| `move_tile(pos_from, pos_to)` | Moves the tile from the given grid position to another location. Returns false if the tile could not be moved. |
| `move_tiles(tiles, offset)` | Moves all of the tiles in the given 'tiles' array by 'offset' grid positions. Returns false if the tile could not be moved. |
| `create_tile(pos, color=null, path=null)` | Create and return a new tile at the given grid position. Optionally, a color and a path can also be specified to
give to this tile. This function will return null if no tile could be created at
the given position. |
| `tile_set_width(pos, new_width)` | Sets the width of the tile at the given
grid position. Returns the new width of the tile, or 0 if no tile exists at the given position. If another tile occupies a position required for this tile to grow, then the new width may not match up to the given width; instead, this tile will only grow as much as it can. |
| `tile_set_height(pos, new_height)` | Similar to `tile_set_width`, but instead changes the height of the given tile. |
| `save_to(path)` | Save the map to the given file path. |
| `load_from_vX_X(data)` | Functions for loading specific versions of a map. For example, `load_from_v1_0` will load a map that is version 1.0. |
