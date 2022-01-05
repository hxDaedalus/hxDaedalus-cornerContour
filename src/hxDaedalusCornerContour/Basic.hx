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

// webgl gl stuff
import cornerContour.web.ShaderColor2D;
import cornerContour.web.HelpGL;
import cornerContour.web.BufferGL;
import cornerContour.web.GL;

// js webgl 
import js.html.webgl.Buffer;
import js.html.webgl.RenderingContext;
import js.html.webgl.Program;
import js.html.webgl.Texture;

import hxDaedalus.data.ConstraintSegment;
import hxDaedalus.data.Mesh;
import hxDaedalus.data.Object;
import hxDaedalus.data.Vertex;
import hxDaedalus.factories.RectMesh;

function main(){
    new Basic();
}

class Basic {
    // cornerContour specific code
    var sketcher:       Sketcher;
    var pen2D:          Pen2D;
    // WebGL/Html specific code
    public var gl:               RenderingContext;
        // general inputs
    final vertexPosition         = 'vertexPosition';
    final vertexColor            = 'vertexColor';
    // general
    public var width:            Int;
    public var height:           Int;
    public var mainSheet:        Sheet;
    var divertTrace:             DivertTrace;
    var renderer:                Renderer;
    
    public function new(){
        divertTrace = new DivertTrace();
        trace('Contour Test');
        width = 1024;
        height = 768;
        creategl();
        // use Pen to draw to Array
        initContours();
        renderer = { gl: gl, pen: pen2D, width: width, height: height };
        initDaedalus();
        drawDaedalus();
        renderer.rearrangeData();
        renderer.setup();
        setAnimate();
    }
    var _mesh:      Mesh;
    var _view:      ContourDaedalus;
    var _object:    Object;
    var g:          Sketcher; 
    //inline
    function initDaedalus(){
        _view = new ContourDaedalus();
        // build a rectangular 2 polygons mesh of 600x400
        _mesh = RectMesh.buildRectangle(600, 400);
        // SINGLE VERTEX INSERTION / DELETION
        // insert a vertex in mesh at coordinates (550, 50)
        var vertex : Vertex = _mesh.insertVertex(550, 50);
        
        // SINGLE CONSTRAINT SEGMENT INSERTION / DELETION
        // insert a segment in mesh with end points (70, 300) and (530, 320)
        var segment : ConstraintSegment = _mesh.insertConstraintSegment(70, 300, 530, 320);
        
        // CONSTRAINT SHAPE INSERTION / DELETION
        // insert a shape in mesh (a crossed square)
        var shape = _mesh.insertConstraintShape( [
                         50.,  50., 100.,  50.,      /* 1st segment with end points (50, 50) and (100, 50)       */
                        100.,  50., 100., 100.,      /* 2nd segment with end points (100, 50) and (100, 100)     */
                        100., 100.,  50., 100.,      /* 3rd segment with end points (100, 100) and (50, 100)     */
                         50., 100.,  50.,  50.,      /* 4rd segment with end points (50, 100) and (50, 50)       */
                         20.,  50., 130., 100.       /* 5rd segment with end points (20, 50) and (130, 100)      */
                                                ] );
                                                
        // OBJECT INSERTION / TRANSFORMATION / DELETION
        // insert an object in mesh (a cross)
        var objectCoords : Array<Float> = new Array<Float>();

        _object = new Object();
        _object.coordinates = [ -50.,   0.,  50.,  0.,
                                  0., -50.,   0., 50.,
                                -30., -30.,  30., 30.,
                                 30., -30., -30., 30.
                                ];
        _mesh.insertObject( _object );  // insert after coordinates are setted

        // you can transform objects with x, y, rotation, scaleX, scaleY, pivotX, pivotY
        _object.x = 400;
        _object.y = 200;
        _object.scaleX = 2;
        _object.scaleY = 2;
    }
    inline
    function creategl( ){
        mainSheet = new Sheet();
        mainSheet.create( width, height, true );
        gl = mainSheet.gl;
    }
    public
    function initContours(){
        pen2D = new Pen2D( 0xFF0000FF );
        pen2D.currentColor = 0xff0000FF;
        sketcher = new Sketcher( pen2D, StyleSketch.Fine, StyleEndLine.no );
    }
    public function drawDaedalus(){
        var s = Std.int( pen2D.pos );
        // redefine sketcher simplest?
        // need to reset pen2D.pos and overwrite old data
        pen2D.pos = 0;
        pen2D.arr = new Array2DTriangles();
        g = sketcher;
        _object.rotation += 0.05;
        _mesh.updateObjects();  // don't forget to update
        _view.drawMesh( g, _mesh );
        allRange.push( s...Std.int( pen2D.pos - 1 ) );
    }

    var allRange = new Array<IteratorRange>();
    inline
    function render(){
        drawDaedalus();
        clearAll( gl, width, height, 0., 0., 0., 1. );
        renderer.rearrangeData(); // destroy data and rebuild
        renderer.updateData(); // update
        renderer.drawData( allRange[0].start...allRange[0].max );
    }
    inline
    function setAnimate(){
        AnimateTimer.create();
        AnimateTimer.onFrame = function( v: Int ) render();
    }
}