// Import D standard libraries
module app;
import std.stdio;
import std.string;

// Load the SDL2 library
import bindbc.sdl;
/// Module level constructor that runs exactly one type
/// for the entire program when we first launch the executable
shared static this(){
    import loader = bindbc.loader.sharedlib;
    // Load the SDL libraries from bindbc-sdl
    // NOTE: Windows users may need this
    version(Windows) const SDLSupport ret = loadSDL("SDL2.dll");
    // NOTE: Mac users may need this
    version(OSX){
        writeln("Searching for SDL on Mac");
        const SDLSupport ret = loadSDL();
    }
    // NOTE: Linux users probably need this
    version(linux) const SDLSupport ret = loadSDL();

    if(ret != sdlSupport){
        writeln("error loading SDL library");

        foreach( info; loader.errors){
            writeln(info.error,':', info.message);
        }
    }
    if(ret == SDLSupport.noLibrary){
        writeln("error no library");    
    }
    if(ret == SDLSupport.badLibrary){
        writeln("Eror badLibrary, missing symbols");
    }
}



/// Skeleton Framework, wrapping windowing library (e.g. SDL)
/// for development of geometry applications
struct App{
    // Run the main application  loop
    bool runApplication = true;
    SDL_Renderer* mRenderer;
    SDL_Window* mWindow;

    // Function pointers to make it so that we can
    // supply any function into the app for things like
    // handling events and display
    void function(SDL_Event e) PFNEventsHandler;
    void function() PFNKeyboardHandler;
    void function(SDL_Renderer*) PFNGraphicsHandler;


    /// constructor that initializes SDL 
    /// for the selected platform.
    this(uint w, uint h, const(char*) title){
        // Initialize SDL
        if(SDL_Init(SDL_INIT_EVERYTHING) !=0){
            writeln("SDL_Init: ", fromStringz(SDL_GetError()));
        }
        // Create an SDL mWindow
        mWindow = SDL_CreateWindow(title,
                SDL_WINDOWPOS_UNDEFINED,
                SDL_WINDOWPOS_UNDEFINED,
                w,
                h, 
                SDL_WINDOW_SHOWN);
        // It can be useful to 'clear' the errors beforehand in SDL
        SDL_ClearError();
        // On Mac's, it's possible that creating the mWindow will also create
        // the mRenderer, so we should check first.
        if(SDL_GetRenderer(mWindow)==null){
            mRenderer = SDL_CreateRenderer(mWindow, -1, SDL_RENDERER_ACCELERATED);
        }else{
            mRenderer = SDL_GetRenderer(mWindow);
        }
        // If there's still an error, then convert the const char* and write
        // out the string
        if(mRenderer==null){
            import std.conv;
            writeln("mRenderer ERROR: ", to!string(SDL_GetError()));
        }
    }

    /// Destructor 
    /// Uses RAII to make sure that we destroy or release
    /// any memory or resource that we have allocated
    ~this(){
        // Destroy our Renderer
        SDL_DestroyRenderer(mRenderer);
        // Destroy our mWindow
        SDL_DestroyWindow(mWindow);
        // Quit the SDL Application 
        SDL_Quit();

        writeln("Ending application--good bye!");
    }

    void QuitApplication(){
        runApplication = false;
    }

    /// Sets a function pointer to a function that is intended
    /// to handle SDL_Event by the user
    void SetEventHandler(void function(SDL_Event e) func){
        PFNEventsHandler= func;
    }

    /// Sets a function pointer to a function that is intended
    /// to handle keyboard key presses
    void SetKeyboardHandler(void function() func){
        PFNKeyboardHandler= func;
    }

    /// Sets a function pointer to a function that is intended
    /// to handle graphics/display events each frame
    void SetGraphicsHandler(void function(SDL_Renderer* ) func){
        PFNGraphicsHandler= func;
    }

    /// Main loop of the application
    void Loop(){
        version(OSX){
            // Note: On Mac's it's useful to poll an event to ensure a window shows up.
            //       It's been reported in the past that this is necessary on some versions of
            //       of Mac's to do this little trick.
            SDL_Event ev;
            SDL_PollEvent(&ev);
        }        

        while(runApplication){
            SDL_Event e;
            // Handle events
            while(SDL_PollEvent(&e) !=0){
               PFNEventsHandler(e); 
            }
            PFNKeyboardHandler();

            // Clear the screen 
            SDL_SetRenderDrawColor(mRenderer, 0x22,0x22,0x55,0xFF);
            SDL_RenderClear(mRenderer);

            PFNGraphicsHandler(mRenderer);

            SDL_RenderPresent(mRenderer);
            // Artificially slow things down
            // 16 is sixteen milliseconds -- around 60 FPS rendering
            SDL_Delay(16);
        }
    }

}
