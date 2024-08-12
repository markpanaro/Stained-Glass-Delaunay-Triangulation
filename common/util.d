/// Mathematical utilities
module util;

// Phobos Library dependencies
import std.math;


/// The Dlang operator % seems to be a remainder.
/// This helper function provides a more traditional modulo.
int mod(float a, float b) {
    float result = a - floor(a / b) * b;
    return cast(int) result;
}

/// Helper function that will 'wrap-around' a data structure given a 
/// provided index. Adapted from provided code, inspired by Two-Bit Coding.
T GetItem(T)(T[] array, long index){
    // Retrieve the size of our vector
    size_t len = array.length;

    // Most of the time, we'd hope to be within the bounds
    // of our data structure, so a simple test.
    if(index < len && index >= 0){
	return array[index];
    }

    // If our index is greater than the size, we need to wrap around
    // Most often this happens when accessing the (last_element + 1)
    if(index >= len){
        return array[mod(index, len)];
    }

    // If the index is smaller than 0, then we need to wrap to the
    // last entry.
    // Note: A negative value % len returns a negative value.
    //       We then add the length of our collection, to wrap us
    //       back up to a positive value within the collection.
    if(index < 0){
        return array[mod(index, len) + len];
    }

    // Default case
    return array[index];
}

/// Vector2f for floating point in D
/// Note: In D, floats initial values are NaN -- so we make sure to initialize them.
struct Vector2f{
        
    float x=0.0f;
    float y=0.0f;

    /// Two argument constructor
    this(float _x, float _y){
        x = _x;
        y = _y;
    }

    /// Copy Constructor
    /// Not truly needed, but in general I like to implement copy constructor explicitly so you know that copies are indeed allowed
    this(ref return scope Vector2f rhs){
        x = rhs.x;
        y = rhs.y;
	}

    void Print(string text){
        import std.stdio;
        writeln(text, ": ", x, ",", y);
    }

    /// Copy assignment operator
    void opAssign(Vector2f rhs){
        if(this is rhs){
            return;
        }
        x = rhs.x;
        y = rhs.y;
    }
    /// Unary Negation operator flips sign of vector.
    void opUnary(string op)(){
		x = -x;
		y = -y;	
    }

	/// Handle cases like "+", "-", etc. doing a 
	/// member-wise operation and returning a new vector.
	Vector2f opBinary(string op)(Vector2f rhs)
	{	
		Vector2f result;
 		mixin("result.x = x"~op~"rhs.x;"); 
 		mixin("result.y = y"~op~"rhs.y;"); 
		return result;
	}

	/// Handle cases like "+=", "-=", etc. doing a 
	/// member-wise operation.
	void opOpAssign(string op)(Vector2F rhs)
	{
 		mixin("x "~op~"= rhs.x;"); 
 		mixin("y "~op~"= rhs.y;"); 
	}

    // Normalize
    void Normalize(){
        float len = Magnitude();
        assert(len != 0.0f && "We actually found a float that is 0 (or maybe close), uh oh!");
        x = x / len;
        y = y / len;
    }

    // Magnitude or "Length"
    float Magnitude(){
        return sqrt(x*x + y*y);	
    }
}

/// Produce a new normalized vector
/// NOTE: Since this produces a new vector,
///       the naming is 'NormalizedRetrieve'.
Vector2f NormalizedRetrieve(Vector2f v){
			Vector2f result;
			float len = v.Magnitude();
			result.x = v.x / len;
			result.y = v.y / len;

			return result;
}

/// Dot product of two Vector2's
float Dot(const ref Vector2f a, const ref Vector2f b){
    return (a.x * b.x) + (a.y * b.y);
}

/// 2D cross product (wedge product/bivector)
/// If you are in a left-handed or right-handed 
/// the resulting 'float' (being positive or negative) changes!
float Cross(const ref Vector2f a, const ref Vector2f b){
    float result = (a.x * b.y) - (a.y * b.x);
    return result; 
}


/// Create a new midpoint from two vectors
Vector2f CreateMidpoint(const ref Vector2f a, const ref Vector2f b){
		Vector2f result;
		result.x = (a.x+b.x)/2;
		result.y = (a.y+b.y)/2;
	return result;
}

/// Compute if a point 'p2' is to the left of the segment
/// formed by a and b
int isLeft(const ref Vector2f a, const ref Vector2f b, const ref Vector2f P2 )
{
    return cast(int)( (b.x - a.x) * (P2.y - a.y) - (P2.x - a.x) * (b.y - a.y) );
}

/// Point in Triangle another strategy
bool PointInTriangle2(const ref Vector2f v, const ref Vector2f a, const ref Vector2f b, const ref Vector2f c){
	int first  = isLeft(a,b,v);	
	int second = isLeft(b,c,v);	
	int third  = isLeft(c,a,v);	

	return (first>0 && second>0 && third>0);
}

/// Point in Triangle
bool PointInTriangle(const ref Vector2f v, const ref Vector2f a, const ref Vector2f b, const ref Vector2f c){

    return true;
}


unittest{
    Vector2f v1;
    v1.x = 1;
    v1.y = 7;
    assert(v1.x == 2 && v1.y == 7);
    
    Vector2f v2;
    v2.x = 2;
    v2.y = 2;
    v1 = v2;
    assert(v1.x == 2 && v1.y == 2);


    v1.Normalize();
}
