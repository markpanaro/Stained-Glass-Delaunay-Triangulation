# Stained Glass Generator: Multi-Colored Delaunay Triangulation

## [YouTube Link](https://youtu.be/SeUaqSHZChE)

<img width="500" alt="Delaunay Image" src="https://github.com/user-attachments/assets/0a8a8cbc-3834-4ae0-9334-7deca5a73810">


## PROJECT INTRODUCTION
Triangulation refers to the division of a set of points into non-overlapping triangles such that each triangle’s vertices are points from the set. This process ensures that the entire area within the convex hull of these points is covered by these triangles without any gaps. A Delaunay triangulation is a special type of triangulation where no points from the set lie within the circumcircle of any triangle. This property minimizes degenerate triangles, making Delaunay triangulation the best kind of triangulation for many purposes.  Triangulated data has many uses within the fields of computation geometry and computer graphics. Common examples being mesh generation, increasing rendering efficiency, and texture mapping. However, it can also be applied elsewhere in fields like robotics, medical imaging, and land surveying. The aim of this project was to implement a Delaunay triangulation and rasterize the result to create visually stimulating “stained glass” images.

## EXPERIMENTAL SETUP
The project was completed in Dlang with SDL used for graphical rendering. To run: cd to ~/project/ -> dub -- <File> (suggest points4.txt) 

## IMPLEMENTATION
The algorithm starts by creating a “super triangle” that encapsulates all of the points. From there, each point is iteratively added to the triangulation as a vertex. Existing triangles may become invalid, or “bad”, if the new vertex falls inside their circumcircle. These bad triangles are identified and removed, leaving a polygonal hole within the triangulation. This hole is then filled by connecting the new point to the vertices surrounding the hole. Once all points have been added to the triangulation, the super triangle is removed, and the completed triangulation is returned as a list of indices into the vertex buffer that holds the point data.

To color the triangles, standard triangle scanline rasterization was used. This method splits the triangle into a flat-bottom and flat-top triangle, which are easier to draw. First, the vertices are ordered top to bottom. The triangle is then split, and horizontal lines are drawn to fill the space of each triangle.

## EVALUATION
The resulting geometry app generates a Delaunay triangulation where all faces are rasterized with a random color. New points can be added by left clicking anywhere within the window. There is a slight delay built in for adding points and a simple check to prevent points from being added right on top of one another. While improvements could certainly be made, this accomplishes the original goal of the project.

## CONCLUSION AND FUTURE WORK
This project was satisfying to work on and greatly improved my understanding of Delaunay triangulation. It also helped solidify my grasp of core computational geometry concepts. I am now better able to visualize and explain triangulation, and I can think more critically about applications that use geometric algorithms. In terms of future work here a couple things come to mind. The implementation currently relies on a Triangle class, but it could be refractored to work entirely out of the vertex buffer to save space. The Voronoi diagram could be calculated in O(N) time from here, and each face could be give a color unique to that of its neighbors by solving a variation of the k-coloring problem.

## REFERENCES
•	https://www.mshah.io/
•	https://www.gorillasun.de/blog/bowyer-watson-algorithm-for-delaunay-triangulation/#the-super-triangle
•	https://stackoverflow.com/questions/38334081/how-to-draw-circles-arcs-and-vector-graphics-in-sdl
•	https://stackoverflow.com/questions/58116412/a-bowyer-watson-delaunay-triangulation-i-implemented-doesnt-remove-the-triangle
•	https://ianthehenry.com/posts/delaunay/
•	http://www.sunshine2k.de/coding/java/TriangleRasterization/TriangleRasterization.html
