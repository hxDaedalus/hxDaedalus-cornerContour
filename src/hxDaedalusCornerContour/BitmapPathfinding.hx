package hxDaedalusCornerContour;

import cornerContour.io.Float32Array;
import cornerContour.io.ColorTriangles2D;
import cornerContour.io.IteratorRange;
import cornerContour.io.Array2DTriangles;
// contour code
import cornerContour.Sketcher;
import cornerContour.Pen2D;
import cornerContour.StyleSketch;
import cornerContour.StyleEndLine;
import cornerContour.ai.ContourDaedalus;

// SVG path parser
import justPath.*;
import justPath.transform.ScaleContext;
import justPath.transform.ScaleTranslateContext;
import justPath.transform.TranslationContext;

import js.html.webgl.RenderingContext;
import js.html.CanvasRenderingContext2D;

// html stuff
import cornerContour.web.Sheet;
import cornerContour.web.DivertTrace;

import htmlHelper.tools.AnimateTimer;
import cornerContour.web.Renderer;
import cornerContour.web.RendererTexture;

// webgl gl stuff
import cornerContour.web.ShaderColor2D;
import cornerContour.web.HelpGL;
import cornerContour.web.BufferGL;
import cornerContour.web.GL;
import cornerContour.web.ImageLoader;
import cornerContour.shape.Quads;

// js webgl 
import js.html.webgl.Buffer;
import js.html.webgl.RenderingContext;
import js.html.webgl.Program;
import js.html.webgl.Texture;

// js generic
import js.Browser;
import js.html.MouseEvent;
import js.html.Event;
import js.html.ImageElement;
import js.html.Image;

import hxDaedalus.ai.EntityAI;
import hxDaedalus.ai.PathFinder;
import hxDaedalus.ai.trajectory.LinearPathSampler;
import hxDaedalus.data.Mesh;
import hxDaedalus.data.Object;
import hxDaedalus.factories.BitmapObject;
import hxDaedalus.factories.RectMesh;

// from  hxDaedalus
import hxPixels.Pixels;

function main(){
    new BitmapPathfinding();
}

class BitmapPathfinding {
    var title = 'Contour hxDaedalus BitmapPathfinding';
    // cornerContour specific code
    var sketcher:                Sketcher;
    var pen2Dtexture:            Pen2D;
    var pen2D:                   Pen2D;
    var rendererTexture:         RendererTexture; 
    var renderer:                Renderer;
    
    // WebGL/Html specific code
    public var gl:               RenderingContext;
    // general inputs
    final vertexPosition         = 'vertexPosition';
    final vertexColor            = 'vertexColor';
    // image hash names
    final triangulationImage     = 'triangulationImage';
    final visualImage            = 'visualImage';
    
    // general
    public var width:            Int;
    public var height:           Int;
    public var mainSheet:        Sheet;
    var divertTrace:             DivertTrace;
    
    public var imageLoader:      ImageLoader;
    
    var monoChromeImage =        Image;
    var colorImage =             Image;
    var pixels:                  Pixels;
    
    var mesh:                    Mesh;
    var view:                    ContourDaedalus;
    var object:                  Object;
    var g:                       Sketcher;
    ///
    var entityAI:                EntityAI;
    var pathfinder:              PathFinder;
    var path:                    Array<Float>;
    var pathSampler:             LinearPathSampler;
    var newPath                  = false;
    var x                        = 0.;
    var y                        = 0.;
    public function new(){
        divertTrace = new DivertTrace();
        trace( title );
        initRenderLayers();
        // load images before further setup
        getImageAssets( setup );
    }
    inline
    function initRenderLayers(){
        width  = 1024;
        height = 768;
        creategl();
        // use Pen to draw to Array
        initContours();
        renderer =          { gl:     gl
                            , pen:    pen2D
                            , width:  width
                            , height: height
                            };
        rendererTexture =   { gl:     gl
                            , pen:    pen2Dtexture
                            , width:  width
                            , height: height };
    }
    inline
    function creategl( ){
        mainSheet = new Sheet();
        mainSheet.create( width, height, true );
        gl = mainSheet.gl;
    }
    inline
    function getImageAssets( loadedCallback: Void->Void ){
        imageLoader = new ImageLoader( []
                                     , loadedCallback
                                     , true );
        imageLoader.loadEncoded( 
             [ GalapagosBW.png, GalapagosColor.png ]
            ,[ triangulationImage, visualImage ]
            );
    }
    public
    function initContours(){
        pen2D = new Pen2D( 0xFFffFFff );
        pen2D.currentColor = 0xFFffFFff;
        pen2Dtexture = new Pen2D( 0xFFffFFff );
        pen2Dtexture.currentColor = 0xFFffFFff;
        sketcher = new Sketcher( pen2D, StyleSketch.Fine, StyleEndLine.no );
    }
    inline
    function getPixels( img: Image ){
        var w =         img.width;
        var h =         img.height;
        var cx =        mainSheet.cx;
        cx.drawImage( img, 0, 0, 512, 384 );//img.width, img.height );
        var imageData = cx.getImageData( 0, 0, w, h );
        var pixels_ =   Pixels.fromImageData( imageData );
        // weird it returns the bitmap as RGBA but triangulation seems to work.
        // pixels_= pixels_.convertTo( PixelFormat.ARGB );
        
        cx.clearRect( 0, 0, w, h );
        return pixels_;
    }
    inline
    function imageOnCanvas(img: Image ){
        var w =         img.width;
        var h =         img.height;
        var cx =        mainSheet.cx;
        cx.drawImage( img, 0, 0, img.width, img.height );
    }
    public function initDraw(){
        textureMask();
        
        drawingShape();
        drawingTexture();
        rendererTexture.rearrangeData();
        rendererTexture.setup();
        rendererTexture.modeEnable();
        renderer.rearrangeData();
        renderer.setup();
        renderer.modeEnable();
        setAnimate();
        mainSheet.initMouseGL();
        
    }
    inline 
    function drawingTexture(){
        allRangeTexture = new Array<IteratorRange>();
        pen2Dtexture.pos = 0;
        pen2Dtexture.arr = new Array2DTriangles();
        var st = Std.int( pen2Dtexture.pos );
        // cornerContour.shape.Quad2D
        rectangle( pen2Dtexture, 0, 0, width, height, 0xFFffFFff );
        allRangeTexture.push( st...Std.int( pen2Dtexture.pos - 1 ) );
    }
    inline
    function textureMask(){
        rendererTexture.img            = cast colorImage;
        rendererTexture.withAlpha();
        rendererTexture.hasImage       = true;
        rendererTexture.transformUVArr = [ 2.,0.,0.
                                         , 0.,2.,0.
                                         , 0.,0.,2. ];
    }
    var allRange = new Array<IteratorRange>();
    var allRangeTexture = new Array<IteratorRange>();
    inline
    function render(){
        // DON'T clear the canvas it's much faster!!
        //clearAll( gl, width, height, 1., 1., 1., 1. );
        
        //clearAll( gl, width, height, .9, .9, .9, 1. );
        // for black.
        //clearAll( gl, width, height, 0., 0., 0., 1. );
        // draw order irrelevant here
        drawingTexture();
        drawingShape();
        // you can adjust draw order
        renderTexture();
        renderShape();
    }
    inline 
    function renderTexture(){
        rendererTexture.modeEnable();
        rendererTexture.rearrangeData(); // destroy data and rebuild
        rendererTexture.updateData();    // update
        var textureQuad = allRangeTexture[0].start...allRangeTexture[0].max;
        rendererTexture.drawTextureShape( textureQuad, 0xFFFFFFFF );
    }
    inline
    function renderShape(){
        //if( mainSheet.isDown ){
        renderer.modeEnable();
        renderer.rearrangeData(); // destroy data and rebuild
        renderer.updateData();    // update
        renderer.drawData( allRange[0].start...allRange[0].max );
            //}
    }
    inline
    function setAnimate(){
        AnimateTimer.create();
        AnimateTimer.onFrame = function( v: Int ) render();
    }
    public function setup(){
        var images =      imageLoader.images;
        monoChromeImage = cast imageLoader.imageArr[0];//images.get( triangulationImage );
        colorImage =      cast imageLoader.imageArr[1];//images.get( visualImage );
        pixels =          cast getPixels( cast monoChromeImage );
        initDaedalus();
        drawingShape();
        initDraw();
    }
    inline
    function initDaedalus(){
        view = new ContourDaedalus();
        /*
        view.edgesWidth = 0.5;
        view.constraintsWidth = 1.;
        view.faceWidth = 1.;
        view.pathsWidth = 1.;
        */
        buildMeshFromBitmap();
        createPathEntity();
        configurePathFinder();
        configurePathSampler();
        mouseInteraction();
    }
    inline // setup mouse interaction
    function mouseInteraction(){
        mainSheet.dragPositionChange = dragPositionChange;
        mainSheet.mouseDown          = mouseDown;
        mainSheet.mouseUp            = mouseUp;
    }
    inline
    function buildMeshFromBitmap(){
        // build a rectangular 2 polygons mesh
        mesh = RectMesh.buildRectangle( 512, 384 );//1024, 780 );
        // create viewports
        var object = BitmapObject.buildFromBmpData( cast pixels, 1.8 );
        object.x = 0;
        object.y = 0;
        mesh.insertObject( object );
    }
    inline
    function createPathEntity(){
        entityAI = new EntityAI();
        entityAI.radius = 4;// set radius size for your entity
        entityAI.x = 50;// set a position
        entityAI.y = 50;
    }
    inline // now configure the pathfinder
    function configurePathFinder(){
        pathfinder = new PathFinder();
        pathfinder.entity = entityAI; // set the entity
        pathfinder.mesh = mesh; // set the mesh
        path = new Array<Float>(); // vector to store the path
    }
    inline  // configure the path sampler
    function configurePathSampler(){
        pathSampler = new LinearPathSampler();
        pathSampler.entity = entityAI;
        pathSampler.samplingDistance = 10;
        pathSampler.path = path;
    }
    inline
    function mouseDown() newPath = true;
    inline
    function mouseUp() newPath = false;
    inline
    function dragPositionChange(){
        x = mainSheet.mouseX;
        y = mainSheet.mouseY;
    }
    var afterMesh: Float = 0.;
    // SET TO FALSE IF YOU WANT TO SEE THE MESH and TRUE if you want to hide!!
    var firstShape = false;
    inline
    function drawingShape(){
        var s = 0;
        g = sketcher;
        if( firstShape == false ){
            // only need to draw mesh first time.
            var s = Std.int( pen2D.pos );
            pen2D.pos = 0;
            pen2D.arr = new Array2DTriangles();
            view.drawMesh( g, mesh );// show result mesh on screen
            firstShape = true;
            afterMesh = pen2D.pos;
        } else {
            pen2D.pos = afterMesh;
        }
        if( newPath ){
            pathfinder.findPath( x, y, path ); // find path !
            view.drawPath( g, path ); // show path on screen
            view.drawEntity( g, entityAI );  // show entity position on screen
            pathSampler.reset(); // reset path sampler for new generated path
        }
        // animate !// move entity
        if( pathSampler.hasNext ) pathSampler.next();
        // show entity position on screen
        view.drawEntity( g, entityAI );
        allRange.push( s...Std.int( pen2D.pos - 1 ) );
    }
}