## A possible level code format for Project Novae							

- Sections split by `|`
- Individual elements in sections split by `~`
- Subsections of elements split by `,`

First section: level size in tiles (x, y) e.g. `3~2|`

Second section: Level title (URL encoded) e.g. `|My%20Level|`

Third section: Tiles e.g. `|1,2,5,0,0,3~4,1,1,0,0,5|`

  Tiles are stored starting from the top left corner of the map.
  Treating this as an array (although in reality it would just
  be split by commas and separated by tildes), the first element
  would be how the tile interacts with the environment, a numerical
  value for a lookup chart. The second element would be the unique
  identifier of the sprite or animation to be used. The third
  element would be how long the tile is; e.g. how many times the
  tile should be repeated to the right. The fourth and fifth
  elements would be optional offsets – the tile will be offset
  from its default position within the grid by the given number
  of pixels. The rest of the elements would be used for tile-specific
  additional data, e.g. animation frame to start on, colour palette, etc.

Fourth section: Items e.g. `|4,6,0,0,This%20is%20a%20sign~4,6,100,300,Press%20right%20to%20move|` 

  Items are stored similarly to tiles, except absolute x and y coordinates
  are used rather than offsets from the grid. The first and second
  elements would be the same as for tiles. There would be no option
  for how many times to repeat the item, because that doesn’t really
  apply to items anyway. Instead, the third and fourth elements would
  be the x and y coordinates relative to the top left corner of the level,
  with item-specific data, e.g. sign messages if we implement that,
  starting from the fifth element. 

Fifth section: Music e.g. `|53|` (lookup table)

Sixth section: Screen effects such as blur, vignette e.g. `|4,2~1,10|`

  Stored as an array – first element would be the ID of the effect
  and the second would be the strength.

Seventh section: Checksum e.g. `|207D`

  Very simple checksum to make sure the level is valid – get the
  ASCII value of the previous sections, add them all together and
  take the lowest 2 bytes as hex characters, to make sure the level
  hasn’t been entered incorrectly, or, if we make a user level designer,
  hasn’t been tampered with – not really intended to be secure or anything.
  Can be generated with 5 lines of Python code:
  ```python
  string = "3~2|My%20Level|1,2,5,0,0,3~4,1,1,0,0,5|4,6,0,0,This%20is%20a%20sign~4,6,100,300,Press%20right%20to%20move|53|4,2~1,10|"
  output = 0
  for i in string:
    output += ord(i)
  print(hex(output).upper())
  ```
  (returns `0X207D`)

Final level code: `3~2|My%20Level|1,2,5,0,0,3~4,1,1,0,0,5|4,6,0,0,This%20is%20a%20sign~4,6,100,300,Press%20right%20to%20move|53|4,2~1,10|207D`
