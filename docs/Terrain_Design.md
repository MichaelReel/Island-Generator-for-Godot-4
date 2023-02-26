# Terrain Generator Design Notes

## General notes

The project was initially created as [Terrain Scratch 2023](https://github.com/MichaelReel/Terrain_Scratch_2023), which was created using triangles with an equalateral footprint. Taking most of the inspiration from the [TriBlobs.gd](https://github.com/MichaelReel/2DMapGen_2023/blob/main/PixelDrawn/TriBlobs.gd) script, but re-implementing in 3D.

These notes are pretty much copied verbatim from Terrain Scratch 2023 so there may be some inaccurracies as code progresses and is updated to match the new GDScript.

### Create the Grid/Mesh

There are some important calculations involved in positioning of vertices, ordering of edges and ordering of polygons so make surfaces indexable.

#### The x/z positioning of vertices

The vertices will be places in the horzontal plane as equally as possible, in a triangle tessilation:

```text
____\/____\/____\/____\/____
    /\    /\    /\    /\    
\  /  \  /  \  /  \  /  \  /
_\/____\/____\/____\/____\/_
 /\    /\    /\    /\    /\ 
/  \  /  \  /  \  /  \  /  \
____\/____\/____\/____\/____
    /\    /\    /\    /\    
\  /  \  /  \  /  \  /  \  /
 \/____\/____\/____\/____\/_
 /\    /\    /\    /\    /\ 
```

The difference between points on the x axis will simply be the length of the side (`s`) of a triangle.
The difference between the lateral lines (in the grid above) will be the height (`h`) of a triangle.

The height can be calculate as the root of three quarters by the length of the side:

`h = sqrt(0.75) * s`

```text
 |\         h^2 + (s/2)^2 = s^2
 | \        h^2 = s^2 - (s/2)^2
 |  \s      h^2 = s^2 - (s^2 / 4)
h|   \      h^2 = (1 - 1/4) * s^2
 |    \     h^2 = ( 3/4 * s^2 )
 |_____\      h = sqrt(3/4 * s^2)
  (s/2)       h = sqrt(3/4) * s
```

#### Indexing of edges

The rules here are important to understand for the polygon creation, as this affects the ordering.

The initial set of vertices are created first. The ordering by row and then column is fairly straight forward:

```text
row  |
 0   | 0_____1_____2_____3_____4
     |  \    /\    /\    /\    /
     |   \  /  \  /  \  /  \  /
 1   |   0\/___1\/___2\/___3\/
     |    /\    /\    /\    /\
     |   /  \  /  \  /  \  /  \
 2   | 0/___1\/___2\/___3\/___4\
     |  \    /\    /\    /\    /
     |   \  /  \  /  \  /  \  /
 3   |   0\/___1\/___2\/___3\/
```

The connections between vertices form the edges, and these are created in the specific order for each vertex that is: a) Not on row 0 b) Not on column 0:

1) Connect from the vertex of the lower column index on the same row (to the left)
2) Connect to one of the vertices in the row with lower index (above), with the same column index as the current point:
  a) On an `even` row this will be to the top right, if it exists.
  b) On an `odd` row this will be to the top left, if it exists.
3) Connect to the other vertex in the row with lower index (above), the column index will depend in the parity of the current row index:
  a) On an `even` row this will be to the top left, with column index less than the column index of this point in this column, if that point exists.
  b) On an `odd` row this will be to the top right, with column index greater than the column index of this point, if the point exists.

```text
            Odd point connections:                    Even point connections: 
                           
         (x,z-1) *           * (x+1,z-1)         (x-1,z-1) *           * (x,z-1)
                  \         /                               \         /      
                   \       /                                 \       /       
                   [1]   [2]                                 [2]   [1]       
                     \   /                                     \   /         
                      \ /                                       \ /          
   (x-1,z) *----[0]----O (x,z)               (x-1,z) *----[0]----O (x,z)       
```

#### Indexing of Triangles/Polygons

The edges created in the previous stage will be used to form the triangles. 
The triangles will be arranged in rows and have their own grid coordinations.

Each row will have a line of triangles alternating in orientation:

```text
                      point columns
             0         1         2         3   
         ,-------. ,-------. ,-------. ,-------. 
        |         |         |         |         | 
    0--    ______________________________________
           \        /\        /\        /\       
            \(0,0) /  \(2,0) /  \(4,0) /  \(6,0)  
             \    /    \    /    \    /    \    /   - Triangle row 0
              \  /(1,0) \  /(3,0) \  /(5,0) \  / 
    1--        \/________\/________\/________\/  
p              /\        /\        /\        /\  
o             /  \(1,1) /  \(3,1) /  \(5,1) /  \ 
i            /    \    /    \    /    \    /    \   - Triangle row 1
n           /(0,1) \  /(2,1) \  /(4,1) \  /(6,1)  
t   2--    /________\/________\/________\/_______
           \        /\        /\        /\       
r           \(0,2) /  \(2,2) /  \(4,2) /  \(6,2)  
o            \    /    \    /    \    /    \    /   - Triangle row 2
w             \  /(1,2) \  /(3,2) \  /(5,2) \  / 
s   3--        \/________\/________\/________\/  
               /\        /\        /\        /\  
              /  \(1,3) /  \(3,3) /  \(5,3) /  \ 
             /    \    /    \    /    \    /    \   - Triangle row 3
            /(0,3) \  /(2,3) \  /(4,3) \  /(6,3)  
    4--    /________\/________\/________\/_______
           \        /\        /\        /\       

               ^    ^    ^    ^    ^    ^    ^
               0    1    2    3    4    5    6
                       Triangle columns
```

For each row of points there will be a row of triangles, except for the last row of points.
For each column of points there will be 2 columns of triangles, except the last row for which there'll be none if all the points rows are the same length.

- `triangle_rows = points_row - 1`
- `triangles_per_row = (points_per_row - 1) * 2`

For each triangle with the coordinates `(tx,tz)`, the first (`px0, pz0`) second (`px1, pz1`) and third (`px2, pz2`) points will be the clockwise rotational positions, and this will depend on the parity of the row and column.

> Godot [SurfaceTool](https://docs.godotengine.org/en/stable/classes/class_surfacetool.html#surfacetool) uses clockwise winding order.  

Assume all division is integer division such that the result of `a/b` is the same as `floor(a/b)`.

|     | column (`tx`) | row (`tz`) |(`px0`,    | `pz0`)|(`px1`,    |  `pz1`)|(`px2`,    |  `pz2`)|
| --- | ------------- | ---------- |-----------|-------|-----------|--------|-----------|--------|
| a)  | even          | even       |(`tx/2`,   | `tz` )|(`tx/2+1`, | `tz`  )|(`tx/2`,   | `tz+1`)|
| b)  | odd           | even       |(`tx/2+1`, | `tz` )|(`tx/2+1`, | `tz+1`)|(`tx/2`,   | `tz+1`)|
| c)  | even          | odd        |(`tx/2`,   | `tz` )|(`tx/2+1`, | `tz+1`)|(`tx/2`,   | `tz+1`)|
| d)  | odd           | odd        |(`tx/2`,   | `tz` )|(`tx/2+1`, | `tz`  )|(`tx/2+1`, | `tz+1`)|

```text
a)                  b)                 c)                d)                 
  p0____________p1          p0                 p0          p0____________p1 
    \          /            /\                 /\            \          /   
     \(tx, ty)/            /  \               /  \            \(tx, ty)/    
      \      /            /    \             /    \            \      /     
       \    /            /      \           /      \            \    /      
        \  /            /(tx, ty)\         /(tx, ty)\            \  /       
         \/            /__________\       /__________\            \/        
         p2          p2            p1   p2            p1          p2        
```

#### Sanity checking the above with examples

The Triangle at position t(4,2) should have the points: `[p(2,2), p(3,2), p(2,3)]`

- `p0 = (4/2, 2)`
- `p1 = (4/2+1, 2)`
- `p2 = (4/2, 2+1)`

```text
p(2,2)\/________\p(3,2)
      /\        /\ 
        \t(4,2)/   
         \    /    
          \  /     
          _\/__
           /p(2,3)
```

The Triangle at position t(3,2) should have the points: `[p(2,2), p(2,3), p(1,3)]`

- `p0 = (3/2+1, 2)`
- `p1 = (3/2+1, 2+1)`
- `p2 = (3/2, 2+1)`

```text
     p(2,2)\/_
           /\   
          /  \  
         /    \ 
        /t(3,2)\       
      \/________\/______
 p(1,3)\        /p(2,3)
```

The Triangle at position t(4,3) should have the points: `[p(2,3), p(3,4), p(2,4)]`

- `p0 = (4/2, 3)`
- `p1 = (4/2+1, 3+1)`
- `p2 = (4/2, 3+1)`

```text
     p(2,3)\/_
           /\   
          /  \  
         /    \ 
        /t(4,3)\       
      \/________\/______
 p(2,4)\        /p(3,4)
```

The Triangle at position (5,3) should have the points: `[p(2,3), p(3,3), p(3,4)]`

- `p0 = (5/2, 3)`
- `p1 = (5/2+1, 3)`
- `p2 = (5/2+1, 3+1)`

```text
p(2,3)\/________\p(3,3)
      /\        /\ 
        \t(5,3)/   
         \    /    
          \  /     
          _\/__
           /p(3,4)
```

### Creating an Island

Rather than using noise for the height map, this will begin with finding an outline for the island to act as a coast. The approach take is to create an expanding front of polygons, from the center of the grid, that upon filling a certain number of triangles will be outlined and filled for gaps.

- The initial island `region` starts with a single cell (a triangle) and a frontier list of 3 adjacent cells.
- For each step, a cell is randomly taken from the frontier list, its non-region neighbours are added to the frontier, and the cell itself is added to the region.
- Expansion stops when the number of cells in the region are equal or greater than the max.

```text
  Start with 1 cell (#) and        Select a frontier cell      Add new neighbours to frontier
    3 frontier cells (?)                randomly (X)            and the random cell to region
____\/____\/____\/____\/____    ____\/____\/____\/____\/____    ____\/____\/____\/____\/____
    /\    /\    /\    /\            /\    /\    /\    /\            /\    /\    /\    /\    
\  /  \  /  \  /  \  /  \  /    \  /  \  /  \  /  \  /  \  /    \  /  \  /  \  /? \  /  \  /
_\/____\/____\/____\/____\/_    _\/____\/____\/____\/____\/_    _\/____\/____\/____\/____\/_
 /\    /\ ?  /\  ? /\    /\      /\    /\ ?  /\  X /\    /\      /\    /\ ?  /\####/\    /\ 
/  \  /  \  /##\  /  \  /  \    /  \  /  \  /##\  /  \  /  \    /  \  /  \  /##\##/ ?\  /  \
____\/____\/####\/____\/____    ____\/____\/####\/____\/____    ____\/____\/####\/____\/____
    /\    /\    /\    /\            /\    /\    /\    /\            /\    /\    /\    /\    
\  /  \  /  \? /  \  /  \  /    \  /  \  /  \? /  \  /  \  /    \  /  \  /  \? /  \  /  \  /
 \/____\/____\/____\/____\/_     \/____\/____\/____\/____\/_     \/____\/____\/____\/____\/_
 /\    /\    /\    /\    /\      /\    /\    /\    /\    /\      /\    /\    /\    /\    /\ 
 Cells = 1, Frontier = 3         Cells = 1, Frontier = 2         Cells = 2, Frontier = 4
```

There is some complexity around the outlining and gap finding. This is done by:

  1. Find the perimeter edges:
    - For every edge on every cell in the region:
      - if the edge has a cell outside the region cells, this edge is a perimeter edge.
  2. Chain the edges together into continuous arrays (there might end up only one):
    - This is very complex to explain at the minute, see the [code](lib/terrain/Utils.gd#L11) for details.
  3. We assume any chains that are not in the longest chain are internal:
    - Frontier cells in these chains are assimilated, using a similar mechanism to the expansion.
    - Non-region neighbour cells to the assimilated frontier cells are added to the frontier.
    - Expanding into the gaps continues until there are no frontier cells left that are not on the longest perimeter chain.
  
The result should be a region made up of cells with a single continuous perimeter and no internal gaps.

### Creating regions in which to create the lakes

This uses a similar approach to the above island region expansion:

- The initial `region` are all started with a single cell within the bounds of the parent `island_region`.
- Each region starts with a single unique cell and 3 frontier cells.
- For each step, a cell from the frontier is chosen, its `island_region` neighbours are added to the local regions frontier and the cell is added to the local region.
- The regions take turns performing the assimilation step.
- Expansion stops when non of the regions are able to expand anymore - there are no `island_region` cells left.

There are some further steps in the region creation. Firstly a margin creation step is performed:

- For each region:
  - Find all the edge cells in the local region
  - Move all the edge cells back from this local region to the parent `island_region`.
  - Also, re-add the newly returned cells to the frontier for the local region.

This can leave small detached cells separate from the main region, so we perform a similar perimeter finding exercise as above:

  1. Find the perimeter edges:
    - For every edge on every cell in the region:
      - if the edge has a cell outside the region cells, this edge is a perimeter edge.
  2. Chain the edges together into continuous arrays (there might end up only one):
    - This is very complex to explain at the minute, see the [code](lib/terrain/Utils.gd#L11) for details.
  3. Unlike the code above, we now assume that each smaller chain encircles a detached group of region cells.
    - Go through the frontier cells and filter out any that aren't on the main perimeter.
    - Merge all the smaller chains into a single list of edges.
    - Get a list of the cells still in the region that are against the small perimeters.
    - Use the list as a frontier and as we remove a cell from the region, add any region neighbours we might have missed to the frontier.

This will leave us with a set of regions that are each a single continuous region within the bounds of the `island_region`.

### Creating the lakes

Lakes shall be regions within the region shapes. These will use the same mechanism to taking up space in the regions that the regions use to populate the `island_region`.

The lakes will be used by the height map stage to form the landscape by marking where the terrain should cup to form pools.

### Getting the height map

- First the coastal points are determined using the perimeter of the `island_region` and each point is set at sea-level.
- 2 fronts are then setup, one for the downhill slope going outwards from the perimeter and one for the upward slope going into the island.
- 2 height variables are established, one for going downhill and one for going uphill, set to sea level.
- The initial downhill points are processed first. For each "step" outward:
  - The downward height variable is lowered.
  - All the points that are currently in the front are given the current downward height.
  - A new front is created containing all the adjacent points to the front in the downhill direction.
- While there are no downward points to process, the uphill front is processed. For each "step" uphill:
  - The uphill height variable is raised.
  - All the points that are currently in the front are given the current upward height.
  - A new front is created containing all the adjacent points to the front in the uphill direction.
  - If one of the new uphill front points is in the region of a lake:
    - Mark this point on the lake as an "exit point" for that lake (this is used later for rivers).
    - Set the height of the lake (also used later).
    - Get the outer perimeter points of the lake and add all of them to the uphill frontier.
    - Get all the points just inside the perimeter of the lake and add them to the *downhill* frontier.
    - Set the downhill height variable to just below the current uphill height.
    - Return to the mechanism above that processes the downhill points.

### Creating the river paths

- The first part is to create a set of river "heads":
  - Each "exit point" of each lake will make up a river head.
  - Some other random points are are not in a lake or river already.
- For each selected river head:
  - Get the neighbour point which is: lowest, not in a lake river or sea.
  - Continue extending the river to the next lowest neighbour not in a lake, river or sea.
  - Stop when the river eventually reaches a lake, river or sea - include the last leg to terminate the river.
  - If the river runs any distance, then add it to the collection of rivers.

### Creating the Settlements and Roads

The Civil stage will mark every potential settlement locations that:

- Is not in a water body
- Is flat
- Is beside a water body

The process to create the roads between settlements requires a bit more effort.

- Each settlement is assigned a road weight of zero.
- Outwards from each settlement, each search cell is given:
  - A direction to the nearest settlement.
  - A weight of effort to get to that settlement, things that affect the weight are:
    - Distance in cells.
    - Slope of cells.
    - Passage over rivers.
  - Cells that pass inside water bodies are not considered.
  - Cells may be re-weighed if they can be given a more favourable weight.
- When each valid search cell has been given a weight, find the best paths between settlements:
  - The middle is where the 2 lowest weighted cells from the opposites cells meet.
  - Paths are exended from the middle until they meet the settlements

### Exagerating Cliff Features

- To be Described