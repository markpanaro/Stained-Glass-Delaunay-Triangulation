module main;

// D standard library imports
import std.stdio;
// Third party and dependency imports
import bindbc.sdl;
// Imports from our project
import app;
// NOTE: This is found from 'importPaths' in dub relative to this directory. We then use the file directory structure to find the util.d which resides in 'common'
import util;
import std.math;
import std.algorithm;


// One global application
App myApp;

// One global set of vertices
Vector2f[] vertices;

/// Static module level constructor to create an app
shared static this(){
    myApp = App(640,480,"Stained Glass Delaunay Triangulation");

}

/// Function to draw a circle found on StackOverflow
void DrawCircle(SDL_Renderer * renderer, int centreX, int centreY, int radius)
{
   const int diameter = (radius * 2);

   int x = (radius - 1);
   int y = 0;
   int tx = 1;
   int ty = 1;
   int error = (tx - diameter);

   while (x >= y)
   {
      //  Each of the following renders an octant of the circle
      SDL_RenderDrawPoint(renderer, centreX + x, centreY - y);
      SDL_RenderDrawPoint(renderer, centreX + x, centreY + y);
      SDL_RenderDrawPoint(renderer, centreX - x, centreY - y);
      SDL_RenderDrawPoint(renderer, centreX - x, centreY + y);
      SDL_RenderDrawPoint(renderer, centreX + y, centreY - x);
      SDL_RenderDrawPoint(renderer, centreX + y, centreY + x);
      SDL_RenderDrawPoint(renderer, centreX - y, centreY - x);
      SDL_RenderDrawPoint(renderer, centreX - y, centreY + x);

      if (error <= 0)
      {
         ++y;
         error += ty;
         ty += 2;
      }

      if (error > 0)
      {
         --x;
         tx += 2;
         error += (tx - diameter);
      }
   }
}


/// Class to represent triangles
class Triangle {
    Vector2f a;
    Vector2f b;
    Vector2f c;
    Vector2f circumcenter;
    Vector2f[][3] edges;

    this(Vector2f a, Vector2f b, Vector2f c) {
        this.a = a;
	this.b = b;
	this.c = c;
	this.circumcenter = GetCircumcenter(a, b, c);
	this.edges = [[a, b], [b, c], [c, a]];
    }

    /// Check if this triangle's circumcenter contains a point
    bool pointInCircumcircle(Vector2f point) {
	return distance(this.a, this.circumcenter) > distance(point, this.circumcenter);
    }

    // Check if a given point is a vertex of this triangle
    bool containsVertex(Vector2f point) {
	return (this.a == point) || (this.b == point) || (this.c == point);
    }
}

/// Helper function to computer the distance between two points
float distance(Vector2f p1, Vector2f p2) {
    return sqrt((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y));
}

/// Helper function to check if two edges are the same
bool isEdgeEqual(Vector2f edge1, Vector2f edge2) {
    return(edge1.x == edge2.x && edge1.y == edge2.y) || (edge1.x == edge2.y && edge1.y == edge2.x);
}

/// Helper function to compute the circumcenter
Vector2f GetCircumcenter(Vector2f a, Vector2f b, Vector2f c) {
    double aDist = a.x * a.x + a.y * a.y;
    double bDist = b.x * b.x + b.y * b.y;
    double cDist = c.x * c.x + c.y * c.y;
    double determinant = 2 * (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y));
    double circumcenterX = (1 / determinant) * (aDist * (b.y - c.y) + bDist * (c.y - a.y) + cDist * (a.y - b.y));
    double circumcenterY = (1 / determinant) * (aDist * (c.x - b.x) + bDist * (a.x - c.x) + cDist * (b.x - a.x));
    return Vector2f(circumcenterX, circumcenterY);
}

/// Helper function to compute radius
float radius(Vector2f circumcenter, Vector2f point) {
    float dx = circumcenter.x - point.x;
    float dy = circumcenter.y - point.y;
    
    return sqrt(dx * dx + dy * dy);
}

/// Implements Bowyer-Watson Delaunay triangulation
size_t[] delaunayTriangulate(Vector2f[] vertices){   
    // Stores order of vertices for triangulation
    size_t[] triangulation;

    // Create super triangle to build from 
    Vector2f SuperA = Vector2f(-5000, -5000);
    Vector2f SuperB = Vector2f(0, 5000);
    Vector2f SuperC = Vector2f(5000, -5000);

    Triangle superTriangle = new Triangle(SuperA, SuperB, SuperC);

    Triangle[] triangles = [superTriangle];

    // Add each point
    foreach(vertex; vertices) {
        Triangle[] badTriangles;

	// Find bad triangles
        foreach(triangle; triangles) {
	    if (triangle.pointInCircumcircle(vertex)) {
		badTriangles ~= triangle;
	    }
	}	
    
        Vector2f[2][] polygon;

	// Remove bad triangles
        foreach (triangle; badTriangles) {
	    foreach (edge; triangle.edges) {
	        bool isShared = false;
		foreach (other; badTriangles) {
		    if(triangle == other) {
			continue;
		    }
		    foreach (otherEdge; other.edges) {
			
			if ((edge[0] == otherEdge[1] && edge[1] == otherEdge[0]) ||
                           (edge[0] == otherEdge[0] && edge[1] == otherEdge[1])) {
                           isShared = true;
			   break;
			}
		    }
			if (isShared) {
			    break;
			}
		}
	
	        if (!isShared) {
                    polygon ~= [edge[0], edge[1]];
                }
	    } 
	}

	// Fill polygonal hole	
	Triangle[] newTriangles;
        foreach (triangle; triangles) {
            if (!badTriangles.canFind(triangle)) {
                newTriangles ~= triangle;
            }
        }
        triangles = newTriangles;

	foreach (edge; polygon) {
            triangles ~= new Triangle(edge[0], edge[1], vertex);
        }

    }

    // Remove super triangle
    Triangle[] finalTriangles;
    foreach (triangle; triangles) {
        if (!triangle.containsVertex(SuperA) && !triangle.containsVertex(SuperB) && !triangle.containsVertex(SuperC)) {
            finalTriangles ~= triangle;
        }
    } 

    // Convert Triangle to buffer index
    foreach (triangle; finalTriangles) {
	int i = 0;
	foreach(vertex; vertices) {
	    
	    if (triangle.a.x == vertex.x && triangle.a.y == vertex.y){
	        triangulation ~= i;
		break;
	    } else {
	       	i += 1;
	    }
	}
        i = 0;	
	foreach(vertex; vertices) {
            if (triangle.b.x == vertex.x && triangle.b.y == vertex.y){
                triangulation ~= i;
                break;
            } else {
                i += 1;
            }
        }
	i = 0;
	foreach(vertex; vertices) {
            if (triangle.c.x == vertex.x && triangle.c.y == vertex.y){
                triangulation ~= i;
                break;
            } else {
                i += 1;
            }
        }
    }

    // Verify results
    foreach (triangle; finalTriangles) {
	foreach(vertex; vertices) {
	    if (triangle.pointInCircumcircle(vertex) && !triangle.containsVertex(vertex)) {
		writeln("Potentially invalid triangulation");
	    }
	}
    }
    return triangulation;
}

/// Helper funtion for loading vertices from a file
Vector2f[] LoadVerticesFromFile(string filename){
    Vector2f[] vertices;
    bool firstRead=true;
    File fs = File(filename);

    int segs;
    while(!fs.eof()){
        int x,y;
        if(firstRead){
            fs.readf!"%d\n"(segs);
            firstRead = false;
        }else{
            fs.readf!"%d %d\n"(x, y);
            if(segs>0){
                vertices~= Vector2f(x,y);
                segs--;
            }
            writeln("Read in: ", x, ",", y);
        }
    }

    return vertices;
}

/// Function for drawing larger points
void DrawPointScaled(SDL_Renderer* renderer, int x, int y, size_t size=1){
    for(int s = x; s < x+size; ++s){
        for(int t = y; t < y+size; ++t){
            SDL_RenderDrawPoint(renderer,s,t);
        }
    }
}

void HandleEvents(SDL_Event e){
    if(e.type == SDL_QUIT){
        myApp.QuitApplication(); 
    }
}

void HandleKeyboard(){

}

/// Helper function to swap two vectors
void swap(ref Vector2f a, ref Vector2f b) {
    Vector2f temp = a;
    a = b;
    b = temp;
}

const float MIN_DISTANCE = 10.0f; 
/// Helper function to determine how close a potential new point is to existing ones
bool isTooClose(Vector2f newVertex, Vector2f[] vertices) {
    foreach (vertex; vertices) {
        float distance = sqrt(pow(newVertex.x - vertex.x, 2) + pow(newVertex.y - vertex.y, 2));
        if (distance < MIN_DISTANCE) {
            return true;
        }
    }
    return false;
}

void HandleGraphics(SDL_Renderer* renderer){
    // Make sure to draw our vertices a specific color
    SDL_SetRenderDrawColor(renderer,255,255,255,SDL_ALPHA_OPAQUE);
        
    // Handle mouse input
    int mouseX,mouseY;
    Uint32 mouseState = SDL_GetMouseState(&mouseX,&mouseY);
    if(mouseState == SDL_BUTTON_LEFT){
	Vector2f newVertex = Vector2f(mouseX, mouseY);
	// Add new point if valid, add slight delay
	if (!isTooClose(newVertex, vertices)) {
            vertices ~= newVertex;
	    SDL_Delay(300);
	} else {
	    writeln("Attempted vertex too close to existing");
	}
    }

    for(size_t i=0; i < vertices.length; i++){
        SDL_RenderDrawPoint(renderer, 
                            cast(int)vertices[i].x,
                            cast(int)vertices[i].y);
    }

    // Compute triangulation    
    size_t[] triangles = delaunayTriangulate(vertices);

    // Colors to draw
    SDL_Color[] colors = [
        SDL_Color(255, 0, 0, SDL_ALPHA_OPAQUE),    // Red
        SDL_Color(0, 255, 0, SDL_ALPHA_OPAQUE),    // Green
        SDL_Color(0, 0, 255, SDL_ALPHA_OPAQUE),    // Blue
        SDL_Color(255, 255, 0, SDL_ALPHA_OPAQUE),  // Yellow
        SDL_Color(0, 255, 255, SDL_ALPHA_OPAQUE),  // Cyan
        SDL_Color(255, 0, 255, SDL_ALPHA_OPAQUE),  // Magenta
        SDL_Color(128, 0, 0, SDL_ALPHA_OPAQUE),    // Maroon
        SDL_Color(75, 0, 130, SDL_ALPHA_OPAQUE),   // Indigo
        SDL_Color(0, 0, 128, SDL_ALPHA_OPAQUE),    // Navy
        SDL_Color(128, 128, 200, SDL_ALPHA_OPAQUE),// Not Olive
        SDL_Color(173, 255, 47, SDL_ALPHA_OPAQUE), // Green Yellow
        SDL_Color(0, 255, 127, SDL_ALPHA_OPAQUE),  // Spring Green
        SDL_Color(192, 192, 192, SDL_ALPHA_OPAQUE),// Silver
        SDL_Color(255, 140, 0, SDL_ALPHA_OPAQUE)   // Dark Orange
    ];

    // Color triangles (scanline rasterization)
    for (size_t i = 0; i < triangles.length; i += 3) {
	size_t index1 = triangles[i];
	size_t index2 = triangles[i + 1];
	size_t index3 = triangles[i + 2];

	// Pick a color
	SDL_Color color = colors[i / 3 % colors.length];
	SDL_SetRenderDrawColor(renderer, color.r, color.g,color.b,color.a);

	Vector2f v1 = vertices[triangles[i]];
	Vector2f v2 = vertices[triangles[i + 1]];
	Vector2f v3 = vertices[triangles[i + 2]];

	// Sort vertices by y-coordinate
	if (v1.y > v2.y) {
	    swap(v1, v2);
	}
	if (v2.y > v3.y) {
	    swap(v2, v3);
	}
	if (v1.y > v2.y) {
	    swap(v1, v2);
	}

	// Draw upper triangle
	if (v2.y != v1.y) {
	    for (float y = v1.y; y <= v2.y; y++) {
		float alpha = (y - v1.y) / (v2.y - v1.y);
		float x1 = v1.x + alpha * (v2.x - v1.x);
		float x2 = v1.x + (y - v1.y) / (v3.y - v1.y) * (v3.x - v1.x);
		SDL_RenderDrawLine(renderer, 
				cast(int) x1, 
				cast(int) y, 
				cast(int) x2, 
				cast(int) y);
	    }
	}

	// Draw bottom triangle
        if (v3.y != v2.y) {
	    for (float y = v2.y; y <= v3.y; y++) {
		float alpha = (y - v2.y) / (v3.y - v2.y);
		float x1 = v2.x + alpha * (v3.x - v2.x);
		float x2 = v1.x + (y - v1.y) / (v3.y - v1.y) * (v3.x - v1.x);
		SDL_RenderDrawLine(renderer, 
				cast(int) x1, 
				cast(int) y, 
				cast(int) x2, 
				cast(int) y);
	    }
	}
    }

    SDL_SetRenderDrawColor(renderer,255,255,255,SDL_ALPHA_OPAQUE);

    // Draw triangulation
    for(size_t i = 0; i < triangles.length; i += 3) {	
	size_t index1 = triangles[i];
	size_t index2 = triangles[i + 1];
	size_t index3 = triangles[i + 2];
	
	SDL_RenderDrawLine(renderer,
			cast(int)vertices[index1].x,
			cast(int)vertices[index1].y, 
			cast(int)vertices[index2].x,
			cast(int)vertices[index2].y);
	SDL_RenderDrawLine(renderer, 
			cast(int)vertices[index2].x,
			cast(int)vertices[index2].y, 
			cast(int)vertices[index3].x, 
			cast(int)vertices[index3].y);
	SDL_RenderDrawLine(renderer, 
			cast(int)vertices[index3].x, 
			cast(int)vertices[index3].y, 
			cast(int)vertices[index1].x, 
			cast(int)vertices[index1].y);
	}
}

/// Entry point into a D applicaiton.
/// The 'name' of this functions is '_Dmain' if you are
/// otherwise searching for the entry in a debugger.
void main(string[] args)
{
    if(args.length < 2){
        writeln("Please provide 1 argument for the file you want to load");
        writeln("e.g. ./prog points.txt");
        return;
    }
    
    // Load our data
    vertices = LoadVerticesFromFile(args[1]);
    
    // Setup which functions to call to handle various events
    myApp.SetEventHandler(&HandleEvents); 
    myApp.SetKeyboardHandler(&HandleKeyboard); 
    myApp.SetGraphicsHandler(&HandleGraphics); 
    myApp.Loop();
}
