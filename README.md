# vrle

VR collision editor for a game I'm developing.
It generates txt files with minx,maxx,miny,maxy,minz,maxz for AABB collision detection
Can be extended to spit other level info too.

Create a "levels" folder inside the app directory and put your glb files in there.
Each glb filename must much the txt filename. eg. "Level1.txt" - "Level1.glb"
When you load a level choose the txt file, NOT the glb.

Use the right stick to move boxes around. Holding grip will scale them instead.
Use the left stick to move around the world.
Toggle the plane of moving/scaling with the "a" button (XY or XZ)
To fine tune placement/scaling of boxes use the corresponding UI buttons
