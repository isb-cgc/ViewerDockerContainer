/*
Copyright (C) 2012 Shaohuan Li <shaohuan.li@gmail.com>, Ashish Sharma <ashish.sharma@emory.edu>
This file is part of Biomedical Image Viewer developed under the Google of Summer of Code 2012 program.
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/


var annotools = function( options) {
    
    this.AnnotationStore = new AnnotationStore(options.iid);
   
    this.annotationActive = isAnnotationActive();

    this.ratio = options.ratio || 0.005; //One pixel equals to the length in real situation. Will be used in the measurement tool
    this.maxWidth = options.maxWidth || 4000; //MaxWidth of the Image
    this.maxHeight = options.maxHeight || 800; ////MaxHeight of the Image
    this.initialized = false;
    this.color = options.color || 'lime'; //Default Annotation Color



    this.iidDecoded = decodeURI(options.iid);
    this.canvas = options.canvas; //The canvas Element that The Use will be drawing annotatoins on.
    this.iid = options.iid || null; //The Image ID
    this.annotVisible = true; //The Annotations are Set to be visible at the First Loading
    this.mode = 'default'; //The Mode is Set to Default

    this.viewer = options.viewer;
    this.imagingHelper = this.viewer.imagingHelper;
    this.mpp = options.mpp;
    this.mppx = parseFloat(this.mpp["mpp-x"]);
    this.mppy = parseFloat(this.mpp["mpp-y"]);
    this.x1 = 0.0;
    this.x2 = 1.0;
    this.y1 = 0.0;
    this.y2 = 1.0;

    this.annotationHandler = options.annotationHandler || new AnnotoolsOpenSeadragonHandler();
    /*
     * OpenSeaDragon events
     */
    this.viewer.addHandler('animation-finish', function (event) {


        var self = this;
        self.getMultiAnnot();

    }.bind(this));
    this.viewer.addHandler('animation-start', function (event) {
        
        var markup_svg = document.getElementById("markups");
        if (markup_svg) {
            //console.log("destroying");
            markup_svg.destroy();
            //console.log("destroyed");
        }
    });


    window.addEvent("domready", function () {
        /*temp*/
        var self = this;
        self.setupHandlers();

        //this.getAnnot();
        //ToolBar.createButtons();
    }.bind(this)); //Get the annotation information and Create Buttons
   
    if(this.annotationActive){
        //this.getAnnot();
    }
    this.imagingHelper.addHandler('image-view-changed',function (event)
    {
        //this.getAnnot();
    }.bind(this));

    this.messageBox = new Element('div', {
        'id': 'messageBox'
    }).inject(document.body); //Create A Message Box
    

    this.showMessage("Press white space to toggle annotations");
    /*
    this.drawLayer = jQuery('<div>', {
        html: "",
        styles: {
            position: 'absolute', 
            'z-index': 1
        }
    });
    jQuery("body").append(this.drawLayer);
    */
    
    this.drawLayer = new Element('div', {
        html: "",
        styles: {
            position: 'absolute',
            'z-index': 1
        }
    }).inject(document.body); //drawLayer will hide by default
    
    //this.drawCanvas = jQuery('<canvas></canvas>');
    //this.drawCanvas.css({"position": "absolute", "z-index": 1});
    //this.drawLayer.append(this.drawCanvas);

    this.drawCanvas = new Element('canvas').inject(this.drawLayer);
    //this.drawLayer.hide();
    /*
    this.magnifyGlass = new Element('div', {
        'class': 'magnify'
    }).inject(document.body); //Magnify glass will hide by default
    this.magnifyGlass.hide();
    */
    this.magnifyGlass = jQuery("<div>", {
        'class': 'magnify'
    });
    jQuery("body").append(this.magnifyGlass);
    this.magnifyGlass.hide();


};

annotools.prototype.destroyMarkups = function(viewer) {

    var markup_svg = document.getElementById("markups");
    if (markup_svg) {
        //console.log("destroying");
        markup_svg.destroy();
        //console.log("destroyed");
    }

}


annotools.prototype.getMultiAnnot = function(viewer) {


    var opa = [];

    var val1 = "";
    var val2 = "";
    var val3 = "";
    
    var algorithms = [];

    if (jQuery("#tree").attr("algotree")) {
    var selalgos = jQuery("#tree").fancytree('getTree').getSelectedNodes();
    //console.log(selalgos);
    for (i = 0; i < selalgos.length; i++) {
        algorithms.push(selalgos[i].refKey);
       //opa["Val" + (i + 1).toString()] = selalgos[i].refKey;
        }
    }
    var self =this;
    this.x1 = this.imagingHelper._viewportOrigin["x"] ;
    this.y1 = this.imagingHelper._viewportOrigin["y"];
    this.x2 = this.x1 + this.imagingHelper._viewportWidth;
    this.y2 = this.y1 + this.imagingHelper._viewportHeight;

    boundX1 = this.imagingHelper.physicalToLogicalX(200);
    boundY1 = this.imagingHelper.physicalToLogicalY(20);
    boundX2 = this.imagingHelper.physicalToLogicalX(20);
    boundY2 = this.imagingHelper.physicalToLogicalY(20);
    var boundX = boundX1 - this.x1;
    var boundY = boundX;
    
    var max = new OpenSeadragon.Point(this.imagingHelper.physicalToDataX(0.2), this.imagingHelper.physicalToDataY(0.2));
    var origin = new OpenSeadragon.Point(this.imagingHelper.physicalToDataX(0), this.imagingHelper.physicalToDataY(0));
    var area = (max.x - origin.x) * (max.y - origin.y);
    algorithms.push("test");

    var t1 = 0;
    if(algorithms.length){
        this.toolBar.titleButton.hide();
        this.toolBar.ajaxBusy.show();
        this.annotations = this.AnnotationStore.fetchAnnotations(this.x1, this.y1, this.x2, this.y2, area, algorithms, function(data){
            //console.log(data);
            self.annotations = data;
            self.displayGeoAnnots();
            self.setupHandlers();
            var t2 = 10;

            self.toolBar.titleButton.show();
            self.toolBar.ajaxBusy.hide();

        });
    } else {
        self.setupHandlers();
        self.destroyMarkups();
        //destroy canvas
    }
   


}



annotools.prototype.getAnnot= function (viewer) //Get Annotation from the API
{
    var self =this;
    this.x1 = this.imagingHelper._viewportOrigin["x"] ;
    this.y1 = this.imagingHelper._viewportOrigin["y"];
    this.x2 = this.x1 + this.imagingHelper._viewportWidth;
    this.y2 = this.y1 + this.imagingHelper._viewportHeight;

    boundX1 = this.imagingHelper.physicalToLogicalX(200);
    boundY1 = this.imagingHelper.physicalToLogicalY(20);
    boundX2 = this.imagingHelper.physicalToLogicalX(20);
    boundY2 = this.imagingHelper.physicalToLogicalY(20);
    var boundX = boundX1 - this.x1;
    var boundY = boundX;

    var max = new OpenSeadragon.Point(this.imagingHelper.physicalToDataX(4), this.imagingHelper.physicalToDataY(4));
    var origin = new OpenSeadragon.Point(this.imagingHelper.physicalToDataX(0), this.imagingHelper.physicalToDataY(0));
    var area = (max.x - origin.x) * (max.y - origin.y);

    //var t1 = performance.now();
    this.annotations = this.AnnotationStore.getAnnotations(this.x1, this.y1, this.x2, this.y2, area, boundX, boundY, boundX, boundY, function(data){
        self.annotations = data;
        self.displayGeoAnnots();
        self.setupHandlers();
        //var t2 = performance.now();
        //console.log("Performance: "+(t2-t1));
    });

};

annotools.prototype.getAnnotFilter= function (author,grade,multi) //Get Annotation from the API
{
    if(this.initialized)
    {
        this.x1 = this.imagingHelper._viewportOrigin["x"];
        this.y1 = this.imagingHelper._viewportOrigin["y"];
        this.x2 = this.x1 + this.imagingHelper._viewportWidth;
        this.y2 = this.y1 + this.imagingHelper._viewportHeight;
    }

    this.initialized = true;
    


    var jsonRequest = new Request.JSON({
        //url: IP + 'api/getAnnotSpatial.php',
        url: 'api/Data/getAnnotSpatialFilter.php',
        onSuccess: function (e) {
            if (e == null) this.annotations = new Array();
            else this.annotations = e;
            this.convertAllToNative();
    this.displayAnnot(); //Display The Annotations
    this.relativeToGlobal();
            this.setupHandlers();
            //console.log("successfully get annotations");
        }.bind(this),
        onFailure: function (e) {
            this.showMessage("cannot get the annotations,please check your getAnnot function");
            this.annotations = new Array();
        }.bind(this)
    }).get({
        'iid': this.iid,
        'x':this.x1,
        'y':this.y1,
        'x1':this.x2,
        'y1':this.y2,
        'author':author,
        'grade':grade,
        'multi':multi
    });
};

annotools.prototype.keyPress= function (code) //Key Down Events Handler
{
    switch (code) {
        case 84:
            //press t to toggle tools
            this.tool.toggle();
            break;
/* ASHISH Disable quit
        case 81:
            //press q to quit current mode and return to the default mode
            this.quitMode();
            this.quitbutton.hide();
            break;
*/
        case 72:
            //press white space to toggle annotations
            this.toggleMarkups();
            break;
        case 82:
            //1 for rectangle mode
            this.mode = 'rect';
            this.drawMarkups();
            break;
        case 67:
            // 2 for ellipse mode
            this.mode = 'ellipse';
            this.drawMarkups();
            break;
        case 80:
            // 3 for polyline mode
            this.mode = 'polyline';
            this.drawMarkups();
            break;
        case 70:
            // 4 for pencil mode
            this.mode = 'pencil';
            this.drawMarkups();
            break;
        case 77:
            // 5 for measurement mode
            this.mode = 'measure';
            this.drawMarkups();
            break;
        case 69:
            // 6 for magnify mode
            this.mode = 'magnify';
            this.magnify();
            break;
    }
};

annotools.prototype.drawMarkups =  function () //Draw Markups
{
        this.showMessage(); //Show Message
        this.drawCanvas.removeEvents('mouseup');
        this.drawCanvas.removeEvents('mousedown');
        this.drawCanvas.removeEvents('mousemove');
        this.drawLayer.show(); //Show The Drawing Layer
        /* ASHISH Disable quit
            this.quitbutton.show(); //Show The Quit Button
        */
        this.magnifyGlass.hide(); //Hide The Magnifying Tool
        //this.container = document.id(this.canvas); //Get The Canvas Container
        this.container = document.getElementsByClassName(this.canvas)[0]; //Get The Canvas Container
        //this.container = document.getElementById('container'); //Get The Canvas Container
        if (this.container) {
            //var left = parseInt(this.container.offsetLeft), //Get The Container Location
            var left = parseInt(this.container.getLeft()), //Get The Container Location
                top = parseInt(this.container.offsetTop),
                width = parseInt(this.container.offsetWidth),
                height = parseInt(this.container.offsetHeight),
                oleft = left,
                otop = top,
                owidth = width,
                oheight = height;
            //console.log("left: " + left + " top: " + top + " width: " + width + " height: " + height);
            if (left < 0) {
                left = 0;
                width = window.innerWidth;
            } //See Whether The Container is outside The Current ViewPort
            if (top < 0) {
                top = 0;
                height = window.innerHeight;
            }
            //Recreate The CreateAnnotation Layer Because of The ViewPort Change Issue.
            this.drawLayer.set({
                'styles': {
                    left: left,
                    top: top,
                    width: width,
                    height: height
                }
            });
            //Create Canvas on the CreateAnnotation Layer
            this.drawCanvas.set({
                width: width,
                height: height
            });
            //The canvas context
            var ctx = this.drawCanvas.getContext("2d");
            //Draw Markups on Canvas
            switch (this.mode) {
                case "rect":
                    this.drawRectangle(ctx);
            break;
                case "ellipse":
                    this.drawEllipse(ctx);
            break;
                case "pencil":
            this.drawPencil(ctx);
            break;
                case "polyline":
                    this.drawPolyline(ctx);
            break;
                case "measure":
                    this.drawMeasure(ctx);
            break;
            }
        } else this.showMessage("Container Not SET Correctly Or Not Fully Loaded Yet");
        
}



/*
annotools.prototype.drawMarkups= function () //Draw Markups
{
    this.showMessage(); //Show Message
    //this.drawCanvas.off();
    this.removeMouseEvents();
    //this.drawCanvas.removeEvents('mouseup');
    //this.drawCanvas.removeEvents('mousedown');
    //this.drawCanvas.removeEvents('mousemove');
    this.drawLayer.show(); //Show The Drawing Layer
/* ASHISH Disable quit
    this.quitbutton.show(); //Show The Quit Button

    this.magnifyGlass.hide(); //Hide The Magnifying Tool
    //this.container = document.id(this.canvas); //Get The Canvas Container
    this.container = document.getElementsByClassName(this.canvas)[0]; //Get The Canvas Container
    //this.container = document.getElementById('container'); //Get The Canvas Container
    if (this.container) {
        //var left = parseInt(this.container.offsetLeft), //Get The Container Location
        var left = parseInt(this.container.getLeft()), //Get The Container Location
            top = parseInt(this.container.offsetTop),
            width = parseInt(this.container.offsetWidth),
            height = parseInt(this.container.offsetHeight),
            oleft = left,
            otop = top,
            owidth = width,
            oheight = height;
        //console.log("left: " + left + " top: " + top + " width: " + width + " height: " + height);
        if (left < 0) {
            left = 0;
            width = window.innerWidth;
        } //See Whether The Container is outside The Current ViewPort
        if (top < 0) {
            top = 0;
            height = window.innerHeight;
        }
        //Recreate The CreateAnnotation Layer Because of The ViewPort Change Issue.
        //console.log(this.drawLayer);
        this.drawLayer.css({
                left: left,
                top: top,
                width: width,
                height: height
        });
        /*
        this.drawLayer.set({
            'styles': {
                left: left,
                top: top,
                width: width,
                height: height
            }
        });

        this.drawCanvas.css({
            width: width, 
            height: height
        });
        //Create Canvas on the CreateAnnotation Layer
        /*
        this.drawCanvas.set({
            width: width,
            height: height
        });

        //The canvas context
        var ctx = this.drawCanvas[0].getContext("2d");
        //console.log(this.mode);
        //Draw Markups on Canvas
        switch (this.mode) {
            case "rect":
                this.drawRectangle(ctx);
        break;
            case "ellipse":
                this.drawEllipse(ctx);
        break;
            case "pencil":
        this.drawPencil(ctx);
        break;
            case "polyline":
                this.drawPolyline(ctx);
        break;
            case "measure":
                this.drawMeasure(ctx);
        break;
        }
    } else this.showMessage("Container Not SET Correctly Or Not Fully Loaded Yet");
    
};
*/
annotools.prototype.magnify= function () //Magnify Tool
{
/* ASHISH Disable quit
    this.quitbutton.show();
*/
    this.drawLayer.hide();
    this.magnifyGlass.hide();
    this.magnifyGlass.set({
        html: ''
    });
    var content = new Element('div', {
        'class': "magnified_content",
        styles: {
            width: document.getSize().x,
            height: document.getSize().y
        }
    });
    content.set({
        html: document.body.innerHTML
    });
    content.inject(this.magnifyGlass);
    var scale = 2.0;
    var left = parseInt(this.magnifyGlass.style.left);
    var top = parseInt(this.magnifyGlass.style.top);
    this.magnifyGlass.set({
        'styles': {
            left: left,
            top: top
        }
    });
    content.set({
        'styles': {
            left: -scale * left,
            top: -scale * top
        }
    });
    this.magnifyGlass.show();
    this.magnifyGlass.makeDraggable({
        onDrag: function (draggable) {
            this.showMessage("drag the magnifying glass");
            var left = parseInt(this.magnifyGlass.style.left);
            var top = parseInt(this.magnifyGlass.style.top);
            this.magnifyGlass.set({
                'styles': {
                    left: left,
                    top: top
                }
            });
            content.set({
                'styles': {
                    left: -scale * left,
                    top: -scale * top
                }
            });
        }.bind(this)
/*ASHISH DIsable quit
        ,onDrop: function (draggable) {
            this.showMessage("Press q to quit");
        }.bind(this)
*/
    });
};

annotools.prototype.selectColor= function () //Pick A Color
{

    this.colorContainer = new Element('div').inject(this.tool);
    var blackColor = new Element('img', {
        'class': 'colorButton',
        'title': 'black',
        'styles': {
            'background-color': 'black'
        },
        'events': {
            'click': function () {
                this.color = 'black';
                this.colorContainer.destroy();
            }.bind(this)
        }
    }).inject(this.colorContainer);
    var redColor = new Element('img', {
        'class': 'colorButton',
        'title': 'Default',
        'styles': {
            'background-color': 'red'
        },
        'events': {
            'click': function () {
                this.color = 'red';
                this.colorContainer.destroy();
            }.bind(this)
        }
    }).inject(this.colorContainer);
    var blueColor = new Element('img', {
        'class': 'colorButton',
        'title': 'blue',
        'styles': {
            'background-color': 'blue'
        },
        'events': {
            'click': function () {
                this.color = 'blue';
                this.colorContainer.destroy();
            }.bind(this)
        }
    }).inject(this.colorContainer);
    var greenColor = new Element('img', {
        'class': 'colorButton',
        'title': 'lime',
        'styles': {
            'background-color': 'lime'
        },
        'events': {
            'click': function () {
                this.color = 'lime';
                this.colorContainer.destroy();
            }.bind(this)
        }
    }).inject(this.colorContainer);
    var purpleColor = new Element('img', {
        'class': 'colorButton',
        'title': 'purple',
        'styles': {
            'background-color': 'purple'
        },
        'events': {
            'click': function () {
                this.color = 'purple';
                this.colorContainer.destroy();
            }.bind(this)
        }
    }).inject(this.colorContainer);
    var orangeColor = new Element('img', {
        'class': 'colorButton',
        'title': 'orange',
        'styles': {
            'background-color': 'orange'
        },
        'events': {
            'click': function () {
                this.color = 'orange';
                this.colorContainer.destroy();
            }.bind(this)
        }
    }).inject(this.colorContainer);
    var yellowColor = new Element('img', {
        'class': 'colorButton',
        'title': 'yellow',
        'styles': {
            'background-color': 'yellow'
        },
        'events': {
            'click': function () {
                this.color = 'yellow';
                this.colorContainer.destroy();
            }.bind(this)
        }
    }).inject(this.colorContainer);
    var pinkColor = new Element('img', {
        'class': 'colorButton',
        'title': 'pink',
        'styles': {
            'background-color': 'pink'
        },
        'events': {
            'click': function () {
                this.color = 'pink';
                this.colorContainer.destroy();
            }.bind(this)
        }
    }).inject(this.colorContainer);
    var colorButtons = document.getElements(".colorButton");
    for (var i = 0; i < colorButtons.length; i++) {
        colorButtons[i].addEvents({
            'mouseenter': function () {
                this.addClass('selected')
            },
            'mouseleave': function () {
                this.removeClass('selected')
            }
        });
    }
};

annotools.prototype.addnewAnnot= function (newAnnot) //Add New Annotations
{
    //console.log(this);
    //newAnnot.iid = this.iid;
    //newAnnot.annotIdi = MD5(new Date().toString());
    //console.log(newAnnot);
    this.annotations.push(newAnnot);
    this.saveAnnot(newAnnot);
    //console.log("saved annotation");


    this.displayGeoAnnots();
};
/*ASHISH DIsable quit
quitMode: function () //Return To the Default Mode
{
    this.drawLayer.hide();
    this.magnifyGlass.hide();
},
*/
annotools.prototype.toggleMarkups= function () //Toggle Markups
{
    if (this.svg) {
        if (this.annotVisible) {
            this.annotVisible = false;
            this.svg.hide();
            document.getElements(".annotcontainer").hide();
        } else {
            this.annotVisible = true;
            this.displayGeoAnnots();
            document.getElements(".annotcontainer").show();
        }
    } else {
        this.annotVisible = true;
        
        this.displayGeoAnnots();
    }
    this.showMessage("annotation toggled");
};
/*analyze: function(ctx)
{
    this.removeMouseEvents();
    this.showMessage(); //Show Message
    this.drawLayer.show(); //Show The Drawing Layer
    this.magnifyGlass.hide(); //Hide The Magnifying Tool
    this.container = document.getElementsByClassName(this.canvas)[0]; //Get The Canvas Container
        var left = parseInt(this.container.getLeft()), //Get The Container Location
            top = parseInt(this.container.offsetTop),
            width = parseInt(this.container.offsetWidth),
            height = parseInt(this.container.offsetHeight),
            oleft = left,
            otop = top,
            owidth = width,
            oheight = height;
        if (left < 0) {
            left = 0;
            width = window.innerWidth;
        } //See Whether The Container is outside The Current ViewPort
        if (top < 0) {
            top = 0;
            height = window.innerHeight;
        }
        //Recreate The CreateAnnotation Layer Because of The ViewPort Change Issue.
        this.drawLayer.set({
            'styles': {
                left: left,
                top: top,
                width: width,
                height: height
            }
        });
        //Create Canvas on the CreateAnnotation Layer
        this.drawCanvas.set({
            width: width,
            height: height
        });
        //The canvas context
        var ctx = this.drawCanvas.getContext("2d");
var started = false;
var min_x,min_y,max_x,max_y,w,h;
var startPosition;
this.drawCanvas.addEvent('mousedown',function(e)
{
    started = true;
    startPosition = OpenSeadragon.getMousePosition(e.event);
    x = startPosition.x;
    y = startPosition.y;
});

this.drawCanvas.addEvent('mousemove',function(e)
{
    if(started)
    {
    ctx.clearRect(0,0,this.drawCanvas.width, this.drawCanvas.height);
    var currentMousePosition = OpenSeadragon.getMousePosition(e.event);

    min_x = Math.min(currentMousePosition.x,startPosition.x);
    min_y = Math.min(currentMousePosition.y,startPosition.y);
    max_x = Math.max(currentMousePosition.x,startPosition.x);
    max_y = Math.max(currentMousePosition.y,startPosition.y);
    w = Math.abs(max_x - min_x);
    h = Math.abs(max_y - min_y);
    ctx.strokeStyle = "red";
    ctx.strokeRect(min_x,min_y,w,h);
    }
}.bind(this));

this.drawCanvas.addEvent('mouseup',function(e)
{
    started = false;
    var finalMousePosition = new OpenSeadragon.getMousePosition(e.event);

        min_x = Math.min(finalMousePosition.x,startPosition.x);
        min_y = Math.min(finalMousePosition.y,startPosition.y);
        max_x = Math.max(finalMousePosition.x,startPosition.x);
        max_y = Math.max(finalMousePosition.y,startPosition.y);

    var startRelativeMousePosition = new OpenSeadragon.Point(min_x,min_y).minus(OpenSeadragon.getElementOffset(viewer.canvas));
    var endRelativeMousePosition = new OpenSeadragon.Point(max_x,max_y).minus(OpenSeadragon.getElementOffset(viewer.canvas));
    var analysisBox = {
        x: startRelativeMousePosition.x,
        y: startRelativeMousePosition.y,
        w: w,
        h: h,
            type: "rect"
    };

    var globalNumbers = JSON.parse(this.convertFromNative(analysisBox, endRelativeMousePosition));

    analysisBox.x = globalNumbers.nativeX;
    analysisBox.y = globalNumbers.nativeY;
    analysisBox.w = globalNumbers.nativeW;
    analysisBox.h = globalNumbers.nativeH;
        this.promptForAnalysis(this, analysisBox);
        this.drawLayer.hide();
}.bind(this));
},*/
annotools.prototype.showMessage= function (msg) //Show Messages
{
/*ASHISH DIsable quit
    if (!(msg)) msg = this.mode + " mode,press q to quit";
*/
    this.messageBox.set({
        html: msg
    });
    var myFx = new Fx.Tween('messageBox', {
        duration: 'long',
        transition: 'bounce:out',
        link: 'cancel',
        property: 'opacity'
    }).start(0, 1).chain(function () {
        this.start(0.5, 0);
    });
};
annotools.prototype.relativeToGlobal= function() 
{
        for (var i = 0; i < $('viewport').getChildren().length; i++) {
            var object = $('viewport').getChildren()[i];

            if (object.tagName == "ellipse") {
                var originalCoord = {};
                console.log("relativeToGlobal: " + viewer.viewport.getZoom() + "  " + this.annotationHandler.zoomBase);
                originalCoord.cx = object.getAttribute('cx');
                originalCoord.cy = object.getAttribute('cy');
                if (viewer.viewport.getZoom() != this.annotationHandler.zoomBase ) {

                    originalCoord.rx = object.getAttribute('rx') * this.annotationHandler.zoomBase; 
                    originalCoord.ry = object.getAttribute('ry') * this.annotationHandler.zoomBase;

                } else {

                    originalCoord.rx = object.getAttribute('rx');
                    originalCoord.ry = object.getAttribute('ry');

                }
                originalCoord.zoom = viewer.viewport.getZoom();
                this.annotationHandler.originalCoords[object.id] = originalCoord;
                var bbox = object.getBBox();

                var objectCenterPt = new OpenSeadragon.Point(bbox.x+bbox.width/2, bbox.y+bbox.height/2);
                var objectCenterRelPt = this.viewer.viewport.pointFromPixel(objectCenterPt);

                // SBA
                originalCoord.cx = objectCenterRelPt.x;
                originalCoord.cy = objectCenterRelPt.y;

                this.annotationHandler.objectCenterPts[i] = objectCenterRelPt;
            } else if (object.tagName == "rect"){
                var originalCoord = {};
                originalCoord.x     = object.getAttribute('x');
                originalCoord.y     = object.getAttribute('y');
                originalCoord.width = object.getAttribute('width');
                originalCoord.height = object.getAttribute('height');
                originalCoord.zoom = viewer.viewport.getZoom();
                this.annotationHandler.originalCoords[object.id] = originalCoord;
                var bbox = object.getBBox();
                var objectCenterPt = new OpenSeadragon.Point(bbox.x+bbox.width/2, bbox.y+bbox.height/2);
                var objectCenterRelPt = this.viewer.viewport.pointFromPixel(objectCenterPt);
                this.annotationHandler.objectCenterPts[i] = objectCenterRelPt;

            }
            else {
                var bbox = object.getBBox();
                var objectCenterPt = 
                    new OpenSeadragon.Point(
                        bbox.x+bbox.width/2, 
                        bbox.y+bbox.height/2
                );
                console.log("bbox: " + bbox);
                var objectCenterRelPt = 
                    this.viewer.viewport.pointFromPixel(objectCenterPt);
                this.annotationHandler.objectCenterPts[i] = objectCenterRelPt;
                var originalCoord = {};
                originalCoord.cx     =  objectCenterPt.x;
                originalCoord.cy     =  objectCenterPt.y;
                var points = 
                    String.split(object.getAttribute("points").trim(), ' ');

                var distances = [];
                for (var j = 0; j < points.length; j++) {
                    var pointPair = String.split(points[j], ",");
                    var point = 
                            new OpenSeadragon.Point(
                                parseFloat(pointPair[0]),
                                    parseFloat(pointPair[1])
                            );
                    var relPt = this.viewer.viewport.pointFromPixel(point);
                    var dist = relPt.minus(objectCenterRelPt); 
                    distances.push(dist);

                }

                this.annotationHandler.originalCoords[object.id] = {
                    center: objectCenterRelPt, 
                    distances: distances};


            }

        };

};
    
annotools.prototype.setupHandlers= function() 
{
    console.log("setting up handlers"); 
                
    var root = document.getElementsByTagName('svg')[0]; 
    //console.log(root); 
    if (root != undefined) {
        if(navigator.userAgent.toLowerCase().indexOf('webkit') >= 0) {
            window.addEventListener('mousewheel',   this.annotationHandler.handleMouseWheel, false); // Chrome/Safari
            //window.addEventListener('mousewheel',   this.getAnnot(), false); // Chrome/Safari
        } else {
          window.addEventListener('DOMMouseScroll', this.annotationHandler.handleMouseWheel, false); // Others
            //window.addEventListener('DOMMouseScroll', this.getAnnot(), false); // Others
        }
        //console.log(root);
        this.addMouseEvents();
    }
    //console.log("...");
    for (var i = 0; i < this.viewer.buttons.buttons.length; i++) {
        var button = this.viewer.buttons.buttons[i];

        if (button.tooltip.toLowerCase() == "go home") {
            var onHomeRelease = button.onRelease;
            var annot = this;
            button.onRelease = function(args){

                $$('svg')[0].setStyle('opacity', 0);
                onHomeRelease(args);
                setTimeout(annotationHandler.goHome, annotationHandler.animateWaitTime, annot);
            };
        }
    }

};


annotools.prototype.displayTip= function (id) //Display Tips
{

    //var container = document.id(this.canvas);
    var container = document.getElementsByClassName(this.canvas)[0]; //Get The Canvas Container
    var width = parseInt(container.offsetWidth),
        height = parseInt(container.offsetHeight),
        annot = this.annotations[id];
    var d = new Element("div", {
        "class": 'annotip',
        styles: {
            position: 'absolute',
            left: Math.round(width * annot.x),
            top: Math.round(height * annot.y)
        },
        html: annot.text
    }).inject(container);
    this.showMessage("Double Click to Edit");
};
annotools.prototype.destroyTip= function () //Destroy Tips
{
    //var container = document.id(this.canvas);
    var container = document.getElementsByClassName(this.canvas)[0]; //Get The Canvas Container
    container.getElements(".annotip").destroy();
};
annotools.prototype.editTip= function (id) //Edit Tips
{
    this.removeMouseEvents();
    var annotools = this;
    var annotation = this.annotations[id];
    var annotationTextJson = annotation.text;
    var content = "";
    for (var key in annotationTextJson) {
        content += "<p class='labelText'>"+key+": "+annotationTextJson[key]+"</p>";
    }
    content += "<p class='labelText'>Created by: "+this.annotations[id].username+"</p>";
    var SM = new SimpleModal();
    SM.addButton("Edit Annotation", "btn primary", function() {
        annotools.promptForAnnotation(annotation, "edit", annotools, null);
    });
    SM.addButton("Edit Markup", "btn primary", function() {
        annotools.addMouseEvents();
        this.hide();
    });
    SM.addButton("Delete", "btn primary", function() {
        var NSM = new SimpleModal();
        NSM.addButton("Confirm", "btn primary", function() {
            annotools.deleteAnnot(id);
            annotools.addMouseEvents();
            this.hide();
        });
        NSM.addButton("Cancel", "btn cancel", function() {
            annotools.addMouseEvents();
            this.hide();
        });
        NSM.show({
            "model":"modal",
            "title":"Confirm deletion",
            "contents":"Are you sure you want to delete this annotation?"
        });
    });
    SM.addButton("Cancel", "btn secondary", function() {
        annotools.addMouseEvents();
        this.hide();
    });
    SM.show({
        "model":"modal",
        "title":"Annotation",
        "contents":content
    });
};
annotools.prototype.deleteAnnot= function (id) //Delete Annotations
{
    var testAnnotId = this.annotations[id].annotId;	
    this.annotations.splice(id,1);
    //########### Do the delete using bindaas instead of on local list.
    if(this.iid)
    {
        var jsonRequest = new Request.JSON({
                url: 'api/Data/deleteAnnot.php',
                async:false,
                onSuccess: function(e){
                    this.showMessage("deleted from server");
            }.bind(this),
                onFailure:function(e){
                    this.showMessage("Error deleting the Annotations, please check your deleteAnnot php");
            }
            .bind(this)}
        ).get({'annotId':testAnnotId});
    }
    this.displayAnnot();
};
annotools.prototype.updateAnnot= function (annot) //Save Annotations
{
        var jsonRequest = new Request.JSON({
            url:  'api/Data/updateAnnot.php',
            onSuccess: function (e) {
                this.showMessage("saved to the server");
            }.bind(this),
            onFailure: function (e) {
                this.showMessage("Error Saving the Annotations,please check you saveAnnot funciton");
            }.bind(this)
        }).post({
            'iid': this.iid,
            'annot': annot
        });
    this.displayAnnot();
};
annotools.prototype.saveAnnot= function (annotation) //Save Annotations
{
        console.log("Save annotation function");
        console.log(annotation);
        jQuery.ajax({
            "type": "POST",
            url: "api/Data/getAnnotSpatial.php",
            data: annotation,
            success: function(res, err){
                //console.log("response: ");
                console.log(res);
                console.log(err);
                 
                console.log("succesfully posted");
            }
        });

        /*
        var jsonRequest = new Request.JSON({
            //url: IP + '/api/annotation_relative.php',
            url:  'api/Data/getAnnotSpatial.php',
            async:false,
            onSuccess: function (e) {
                console.log(e);
                console.log("success");
                this.showMessage("saved to the server");
            }.bind(this),
            onFailure: function (e) {
                console.log(e);
                console.log("fail");
                this.showMessage("Error Saving the Annotations,please check you saveAnnot funciton");
            }.bind(this)
        }).post({
            'iid': this.iid,
            'annot': this.annotations
        });
        */
};

annotools.prototype.convertToNative= function (annot)
{
    if(annot.type == "rect" || annot.type == "ellipse")
    {
        var x = annot.x;
        var y = annot.y;
        var w = annot.w;
        var h = annot.h;

        var nativeW = this.imagingHelper.logicalToPhysicalDistance(w);
        var nativeH = this.imagingHelper.logicalToPhysicalDistance(h);
        var nativeX = this.imagingHelper.logicalToPhysicalX(x);
        var nativeY = this.imagingHelper.logicalToPhysicalY(y);
        var nativeNumbers = JSON.encode({nativeW:nativeW,nativeH:nativeH,nativeX:nativeX,nativeY:nativeY});
        return nativeNumbers;
    }

    else if(annot.type == "polyline" || annot.type == "pencil" || annot.type == "line")
    {
        var x = annot.x;
        var y = annot.y;
        var w = annot.w;
        var h = annot.h;
        var point = annot.points;

        var nativeW = this.imagingHelper.logicalToPhysicalDistance(w);
        var nativeH = this.imagingHelper.logicalToPhysicalDistance(h);
        var nativeX = this.imagingHelper.logicalToPhysicalX(x);
        var nativeY = this.imagingHelper.logicalToPhysicalY(y);
            
        var poly_first_split = String.split(point,' ');
        var points  = "";
        for(var k = 0; k < poly_first_split.length - 1; k++)
        {
        var poly_second_split = String.split(poly_first_split[k], ',');

        var polyPoint = new OpenSeadragon.Point(parseFloat(poly_second_split[0]),parseFloat(poly_second_split[1]));

        points += this.imagingHelper.logicalToPhysicalX(polyPoint.x) + ',' + this.imagingHelper.logicalToPhysicalY(polyPoint.y) + ' ';	
        }

        var last_poly_split = String.split(poly_first_split[k],',');

        var lastPolyPoint = new OpenSeadragon.Point(parseFloat(last_poly_split[0]),parseFloat(last_poly_split[1]));

        points += this.imagingHelper.logicalToPhysicalX(lastPolyPoint.x) + ',' + this.imagingHelper.logicalToPhysicalY(lastPolyPoint.y);
      
        var nativeNumbers = JSON.encode({nativeW:nativeW,nativeH:nativeH,nativeX:nativeX,nativeY:nativeY,nativePoints:points});
        return nativeNumbers;
    }

    else
        return JSON.encode(annot);
};

annotools.prototype.convertFromNative= function(annot,end)
{
if(annot.type == "rect" || annot.type == "ellipse")
{
    var x = annot.x;
    var y = annot.y;
    var w = annot.w;
    var h = annot.h;
    var x_end = end.x;
    var y_end = end.y;

    var nativeX_end = this.imagingHelper.physicalToLogicalX(x_end);
    var nativeY_end = this.imagingHelper.physicalToLogicalY(y_end);
    var nativeX = this.imagingHelper.physicalToLogicalX(x);
    var nativeY = this.imagingHelper.physicalToLogicalY(y);
    var nativeW = nativeX_end - nativeX;
    var nativeH = nativeY_end - nativeY;

    var globalNumber = JSON.encode({nativeW: nativeW, nativeH: nativeH, nativeX: nativeX, nativeY: nativeY});

    return globalNumber;
}

else if(annot.type == "polyline" || annot.type == "pencil" || annot.type == "line")
{
    var x = annot.x;
    var y = annot.y;
    var w = annot.w;
    var h = annot.h;
    var point = annot.points;
    var poly_first_split = String.split(point,' ');
    var points  = "";
    for(var k = 0; k < poly_first_split.length - 1; k++)
    {
    var poly_second_split = String.split(poly_first_split[k], ',');

    var polyPoint = new OpenSeadragon.Point(parseFloat(poly_second_split[0]),parseFloat(poly_second_split[1]));

    points += this.imagingHelper.physicalToLogicalX(polyPoint.x) + ',' + this.imagingHelper.physicalToLogicalY(polyPoint.y) + ' ';	
    }

    var last_poly_split = String.split(poly_first_split[k],',');

    var lastPolyPoint = new OpenSeadragon.Point(parseFloat(last_poly_split[0]),parseFloat(last_poly_split[1]));

    points += this.imagingHelper.physicalToLogicalX(lastPolyPoint.x) + ',' + this.imagingHelper.physicalToLogicalY(lastPolyPoint.y);
    var x_end = end.x;
    var y_end = end.y;

    var nativeX_end = this.imagingHelper.physicalToLogicalX(x_end);
    var nativeY_end = this.imagingHelper.physicalToLogicalY(y_end);
    var nativeX = this.imagingHelper.physicalToLogicalX(x);
    var nativeY = this.imagingHelper.physicalToLogicalY(y);
    var nativeW = nativeX_end - nativeX;
    var nativeH = nativeY_end - nativeY;
    var nativePoints = points;

    var globalNumber = JSON.encode({nativeW: nativeW, nativeH:nativeH, nativeX:nativeX, nativeY:nativeY,points: nativePoints});

    return globalNumber;
}

else
    return JSON.encode(annot);
};

annotools.prototype.convertAllToNative= function()
{
    for(index = 0; index < this.annotations.length; index++)
    {
        //unparsed = this.convertToNative(this.annotations[index]);
        newannot = JSON.parse(this.convertToNative(this.annotations[index]));
        this.annotations[index].x = newannot.nativeX;
        this.annotations[index].y = newannot.nativeY;
        this.annotations[index].w = newannot.nativeW;
        this.annotations[index].h = newannot.nativeH;
    }
};

annotools.prototype.drawEllipse= function(ctx)
{
    console.log("ellipsing!");
    this.removeMouseEvents();
    var started = false;
    var min_x,min_y,max_x,max_y,w,h;
    var startPosition;
    this.drawCanvas.bind("mousedown", function(e){
        started = true;
        startPosition = OpenSeadragon.getMousePosition(e.event);
        x = startPosition.x;
        y = startPosition.y;       
    });
    /*
    this.drawCanvas.addEventListener('mousedown',function(e)
    {
        started = true;
        startPosition = OpenSeadragon.getMousePosition(e.event);
        x = startPosition.x;
        y = startPosition.y;
    });
    */
    this.drawCanvas.bind("mousemove", function(e){
        

        if(started)
        {
            ctx.clearRect(0,0,this.drawCanvas.width,this.drawCanvas.height);
            var currentMousePosition = OpenSeadragon.getMousePosition(e.event);

            min_x = Math.min(currentMousePosition.x,startPosition.x);
            min_y = Math.min(currentMousePosition.y,startPosition.y);
            max_x = Math.max(currentMousePosition.x,startPosition.x);
            max_y = Math.max(currentMousePosition.y,startPosition.y);
            w = Math.abs(max_x - min_x);
            h = Math.abs(max_y - min_y);

            var kappa = .5522848;
            var ox = (w/2) *kappa;
            var oy = (h/2) *kappa;
            var xe = min_x + w;
            var ye = min_y + h;
            var xm = min_x + w/2;
            var ym = min_y + h/2;

            ctx.beginPath();
            ctx.moveTo(min_x,ym);
            ctx.bezierCurveTo(min_x,ym - oy,xm - ox, min_y, xm, min_y);
            ctx.bezierCurveTo(xm + ox, min_y, xe, ym - oy, xe, ym);
            ctx.bezierCurveTo(xe, ym + oy, xm + ox, ye, xm, ye);
            ctx.bezierCurveTo(xm - ox, ye, min_x, ym + oy, min_x, ym);
            ctx.closePath();
            ctx.strokeStyle = this.color;
            ctx.stroke();
        }

    }.bind(this));   

    this.drawCanvas.bind('mouseup', function (e)
    {
        started = false;
        var finalMousePosition = new OpenSeadragon.getMousePosition(e.event);
        min_x = Math.min(finalMousePosition.x,startPosition.x);
        min_y = Math.min(finalMousePosition.y,startPosition.y);
        max_x = Math.max(finalMousePosition.x,startPosition.x);
        max_y = Math.max(finalMousePosition.y,startPosition.y);

        var startRelativeMousePosition = new OpenSeadragon.Point(min_x,min_y).minus(OpenSeadragon.getElementOffset(viewer.canvas));
        var endRelativeMousePosition = new OpenSeadragon.Point(max_x,max_y).minus(OpenSeadragon.getElementOffset(viewer.canvas));
        var newAnnot = {
            x: startRelativeMousePosition.x,
            y: startRelativeMousePosition.y,
            w: w,
            h: h,
            type: "ellipse",
            color: this.color,
            loc: new Array()
        };

        var globalNumbers = JSON.parse(this.convertFromNative(newAnnot, endRelativeMousePosition));

        newAnnot.x = globalNumbers.nativeX;
        newAnnot.y = globalNumbers.nativeY;
        newAnnot.w = globalNumbers.nativeW;
        newAnnot.h = globalNumbers.nativeH;
        var loc = new Array();
        loc[0] = parseFloat(newAnnot.x);
        loc[1] = parseFloat(newAnnot.y);
        newAnnot.loc = loc;
            this.promptForAnnotation(newAnnot, "new", this, ctx);
    }.bind(this));
};

annotools.prototype.drawRectangle= function(ctx)
{
    console.log("drawing rectangle");
    this.removeMouseEvents();
    var started = false;
    var min_x,min_y,max_x,max_y,w,h;
    var startPosition;
    this.drawCanvas.addEvent('mousedown',function(e)
    {
        started = true;
        startPosition = OpenSeadragon.getMousePosition(e.event);
        x = startPosition.x;
        y = startPosition.y;
    });

    this.drawCanvas.addEvent('mousemove',function(e)
    {
        if(started)
        {
        ctx.clearRect(0,0,this.drawCanvas.width, this.drawCanvas.height);
        var currentMousePosition = OpenSeadragon.getMousePosition(e.event);

        min_x = Math.min(currentMousePosition.x,startPosition.x);
        min_y = Math.min(currentMousePosition.y,startPosition.y);
        max_x = Math.max(currentMousePosition.x,startPosition.x);
        max_y = Math.max(currentMousePosition.y,startPosition.y);
        w = Math.abs(max_x - min_x);
        h = Math.abs(max_y - min_y);
        ctx.strokeStyle = this.color;
        ctx.strokeRect(min_x,min_y,w,h);
        }
    }.bind(this));

    this.drawCanvas.addEvent('mouseup',function(e)
    {
        started = false;
        var finalMousePosition = new OpenSeadragon.getMousePosition(e.event);

            min_x = Math.min(finalMousePosition.x,startPosition.x);
            min_y = Math.min(finalMousePosition.y,startPosition.y);
            max_x = Math.max(finalMousePosition.x,startPosition.x);
            max_y = Math.max(finalMousePosition.y,startPosition.y);

        
        var startRelativeMousePosition = new OpenSeadragon.Point(min_x,min_y).minus(OpenSeadragon.getElementOffset(viewer.canvas));
        var endRelativeMousePosition = new OpenSeadragon.Point(max_x,max_y).minus(OpenSeadragon.getElementOffset(viewer.canvas));
        var newAnnot = {
            x: startRelativeMousePosition.x,
            y: startRelativeMousePosition.y,
            w: w,
            h: h,
            type: "rect",
            color: this.color,
            loc: new Array()
        };

        var globalNumbers = JSON.parse(this.convertFromNative(newAnnot, endRelativeMousePosition));

        newAnnot.x = globalNumbers.nativeX;
        newAnnot.y = globalNumbers.nativeY;
        newAnnot.w = globalNumbers.nativeW;
        newAnnot.h = globalNumbers.nativeH;
        var loc = new Array();
        loc[0] = parseFloat(newAnnot.x);
        loc[1] = parseFloat(newAnnot.y);
        newAnnot.loc = loc;

        //convert to geojson 
        var geoNewAnnot = this.convertRectToGeo(newAnnot);
        //geoNewAnnot = newAnnot;
        this.promptForAnnotation(geoNewAnnot, "new", this, ctx);
    }.bind(this));
};

annotools.prototype.drawPencil= function(ctx)
{
    this.removeMouseEvents();
var started = false;
var pencil = [];
var newpoly = [];
this.drawCanvas.addEvent('mousedown',function(e)
{
    started = true;
    var startPoint = OpenSeadragon.getMousePosition(e.event);
    var relativeStartPoint = startPoint.minus(OpenSeadragon.getElementOffset(viewer.canvas));
    newpoly.push({
    "x":relativeStartPoint.x,
    "y":relativeStartPoint.y
    });
    ctx.beginPath();
    ctx.moveTo(relativeStartPoint.x, relativeStartPoint.y)
    ctx.strokeStyle = this.color;
    ctx.stroke();
}.bind(this));

this.drawCanvas.addEvent('mousemove',function(e)
{
    var newPoint = OpenSeadragon.getMousePosition(e.event);
    var newRelativePoint = newPoint.minus(OpenSeadragon.getElementOffset(viewer.canvas));
    if(started)
    {
    newpoly.push({
        "x":newRelativePoint.x,
        "y":newRelativePoint.y
        });

    ctx.lineTo(newRelativePoint.x,newRelativePoint.y);
    ctx.stroke();
    }
});

this.drawCanvas.addEvent('mouseup',function(e)
{
    started = false;
    pencil.push(newpoly);
    newpoly = [];
    numpoint = 0;
    var x,y,w,h;
    x = pencil[0][0].x;
    y = pencil[0][0].y;

    var maxdistance = 0;
    var points = "";
    var endRelativeMousePosition;
    for(var i = 0; i < pencil.length; i++)
    {
    newpoly = pencil[i];
    for(j = 0; j < newpoly.length - 1; j++)
    {
        points += newpoly[j].x + ',' + newpoly[j].y + ' ';
        if(((newpoly[j].x - x) * (newpoly[j].x - x) + (newpoly[j].y -y) * (newpoly[j].y-y)) > maxdistance)
        {
        maxdistance = ((newpoly[j].x - x) * (newpoly[j].x - x) + (newpoly[j].y -y) * (newpoly[j].y-y));
        var endMousePosition = new OpenSeadragon.Point(newpoly[j].x, newpoly[j].y);
        endRelativeMousePosition = endMousePosition.minus(OpenSeadragon.getElementOffset(viewer.canvas));
        }
    }

    points = points.slice(0,-1);
    points += ';';
    }

    points = points.slice(0,-1);

    var newAnnot = {
        x:x,
        y:y,
        w:w,
        h:h,
        type: 'pencil',
        points: points,
        color: this.color,
        loc: new Array()
    };

    var globalNumbers = JSON.parse(this.convertFromNative(newAnnot, endRelativeMousePosition));
    newAnnot.x = globalNumbers.nativeX;
    newAnnot.y = globalNumbers.nativeY;
    newAnnot.w = globalNumbers.nativeW;
    newAnnot.h = globalNumbers.nativeH;
    newAnnot.points = globalNumbers.points;
    var loc = new Array();
    loc[0] = parseFloat(newAnnot.x);
    loc[1] = parseFloat(newAnnot.y);
    newAnnot.loc = loc;
    console.log(newAnnot);
    var geojsonAnnot = this.convertPencilToGeo(newAnnot);
    this.promptForAnnotation(geojsonAnnot, "new", this, ctx);
}.bind(this));
};

annotools.prototype.drawMeasure= function(ctx)
{
    this.removeMouseEvents();
var started = false;
var x0,y0,x1,y1;
var length;

this.drawCanvas.addEvent('mousedown',function (e) 
{
    if(!started)
    {
    var startPosition = OpenSeadragon.getMousePosition(e.event);
    var startRelativeMousePosition = startPosition.minus(OpenSeadragon.getElementOffset(viewer.canvas));
    x0 = startRelativeMousePosition.x;
    y0 = startRelativeMousePosition.y;
    started = true;
    }

    else
    {
    var endPosition = OpenSeadragon.getMousePosition(e.event);
    var endRelativePosition = endPosition.minus(OpenSeadragon.getElementOffset(viewer.canvas));
    x1 = endRelativePosition.x;
    y1 = endRelativePosition.y;
    ctx.beginPath();
    ctx.moveTo(x0,y0);
    ctx.lineTo(x1,y1);
    ctx.strokeStyle = this.color;
    ctx.stroke();
    ctx.closePath();

    var minX, minY = 0;
    var maxX, maxY = 0
    if(x1 > x0)
    {
        minX = x0;
        maxX = x1;
    }

    else
    {
        minX = x1;
        maxX = x0;
    }
    if(y1 > y0)
    {
        minY = y0;
        maxY = y1;
    }

    else
    {
        minY = y1;
        maxY = y0;
    }

    var x_dist = ((this.imagingHelper.physicalToDataX(x0)) - (this.imagingHelper.physicalToDataX(x1)));
    var y_dist = ((this.imagingHelper.physicalToDataY(y0)) - (this.imagingHelper.physicalToDataY(y1)));

    var x_micron = this.mppx * x_dist;
    var y_micron = this.mppy * y_dist;

    var length = Math.sqrt(x_micron.pow(2) + y_micron.pow(2));
    points = (x1 + "," + y1);
    var w = 0;
    var h = 0;
    var newAnnot = 
    {
        x:x0,
        y:y0,
        w:w,
        h:h,
        type:"line",
        points: points,
        color: this.color,
        loc: new Array(),
                length: length
    };
    var finalPosition = new OpenSeadragon.Point(maxX,maxY);
    var finalRelativePosition = finalPosition.minus(OpenSeadragon.getElementOffset());

    var globalNumbers = JSON.parse(this.convertFromNative(newAnnot,finalRelativePosition));
    newAnnot.x = globalNumbers.nativeX;
    newAnnot.y = globalNumbers.nativeY;
    newAnnot.w = globalNumbers.nativeW;
    newAnnot.h = globalNumbers.nativeH;
    newAnnot.points = globalNumbers.points;
    var loc = new Array();
    loc[0] = parseFloat(newAnnot.x);
    loc[1] = parseFloat(newAnnot.y);
    newAnnot.loc = loc;
            this.promptForAnnotation(newAnnot, "new", this, ctx);
    started = false;
    }
}.bind(this));

this.drawCanvas.addEvent('mousemove', function (e)
{
    if(started)
    {
    ctx.clearRect(0,0, this.drawCanvas.width, this.drawCanvas.height);
    var currentPosition = OpenSeadragon.getMousePosition(e.event);
    var currentRelativePosition = OpenSeadragon.getMousePosition(e.event);

    x1 = currentRelativePosition.x;
    y1 = currentRelativePosition.y;

    ctx.beginPath();
    ctx.moveTo(x0,y0);
    ctx.lineTo(x1,y1);
    ctx.strokeStyle = this.color;
    ctx.stroke();
    ctx.closePath();
    }
}.bind(this));
};

annotools.prototype.drawPolyline= function(ctx)
{
    this.removeMouseEvents();
var started = true;
var newpoly = [];
var numpoint = 0;
this.drawCanvas.addEvent('mousedown',function(e)
{
    if(started)
    {
        var  newPoint = OpenSeadragon.getMousePosition(e.event);
        var newRelativePoint = newPoint.minus(OpenSeadragon.getElementOffset(viewer.canvas));
        ctx.fillStyle = this.color;
        ctx.beginPath();
        ctx.arc(e.event.layerX, e.event.layerY, 2, 0, Math.PI* 2, true);
        ctx.closePath();
        ctx.fill;
        newpoly.push({"x" : newRelativePoint.x,
        "y": newRelativePoint.y});

        if(numpoint > 0)
        {
        ctx.beginPath();
        ctx.moveTo(newpoly[numpoint].x, newpoly[numpoint].y);
        ctx.lineTo(newpoly[numpoint - 1].x, newpoly[numpoint-1].y);
        ctx.strokeStyle = this.color;
        ctx.stroke();
        }

    numpoint++;
    }
}.bind(this));

this.drawCanvas.addEvent('dblclick',function(e)
{
    started = false;
    ctx.beginPath();
    ctx.moveTo(newpoly[numpoint-1].x, newpoly[numpoint-1].y);
    ctx.lineTo(newpoly[0].x,newpoly[0].y);
    ctx.stroke();
    var x,y,w,h;

    x = newpoly[0].x;
    y = newpoly[0].y;

    var maxdistance = 0;

    //var tip = prompt("Please Enter Some Description","");

    var points = "";

    var endMousePosition;
    for(var i = 0; i < numpoint -1; i++)
    {
    points += newpoly[i].x + ',' + newpoly[i].y + ' ';
    if(((newpoly[i].x -x) *( newpoly[i].x - x) + (newpoly[i].y - y) * (newpoly[i].y - y)) > maxdistance)
    {
        maxdistance = ((newpoly[i].x - x) * (newpoly[i].x - x) + (newpoly[i].y - y) * (newpoly[i].y - y));

        endMousePosition = new OpenSeadragon.Point(newpoly[i].x,newpoly[i].y);
        w = Math.abs(newpoly[i].x - x);
        h = Math.abs(newpoly[i].y - y);
    }
    }

    points += newpoly[i].x + ',' + newpoly[i].y;

    var endRelativeMousePosition = endMousePosition.minus(OpenSeadragon.getElementOffset(viewer.canvas));

    var newAnnot = {
        x: x,
        y: y,
        w: w,
        h: h,
        type: 'polyline',
        points: points,
        color: this.color,
        loc: new Array()
    };

    var globalNumbers = JSON.parse(this.convertFromNative(newAnnot,endRelativeMousePosition));

    newAnnot.x = globalNumbers.nativeX;
    newAnnot.y = globalNumbers.nativeY;
    newAnnot.w = globalNumbers.nativeW;
    newAnnot.h = globalNumbers.nativeH;
    newAnnot.points = globalNumbers.points;
    var loc = new Array();
    loc[0] = newAnnot.x;
    loc[1] = newAnnot.y;
    newAnnot.loc = loc;
        this.promptForAnnotation(newAnnot, "new", this, ctx);
}.bind(this));
};
annotools.prototype.saveState= function () {
    if (this.iid) {
        var jsonRequest = new Request.JSON({
            //url: IP + 'api/state.php',
            url:  'api/Data/state.php',
            onSuccess: function (e) {
                this.showMessage("saved to the server");
            }.bind(this),
            onFailure: function (e) {
                this.showMessage("Error Saving the state,please check you saveState funciton");
            }.bind(this)
        }).post({
            'iid': this.iid,
            'zoom': iip.view.res,
            'left': iip.view.x,
            'top': iip.view.y
        });

    } else this.showMessage("Sorry, This Function is Only Supported With the Database Version");
};
annotools.prototype.retrieveTemplate= function() {
var jsonReturn = "";
    /*
     * Ganesh
     */
    
    var jsonRequest = new Request.JSON({
    url: 'api/Data/retreiveTemplate.php', //Ameen, fix your spelling!
    async:false,
    onSuccess: function(e){
            jsonReturn = JSON.parse(e)[0];
            console.log(jsonReturn);
    }.bind(this),
    onFailure:function(e){
    this.showMessage("Error retrieving AnnotationTemplate, please check your retrieveTemplate.php");
    }.bind(this)
    }).get();
 
    /*
    var jsonRequest = jQuery.ajax({
        url: "api/Data/retreiveTemplate.php",
        success: function(e){
            console.log(e);
            jsonReturn  = JSON.parse(e)[0];
            console.log(jsonReturn);
        },
        async: false
    });
    */
return jsonReturn;
};
annotools.prototype.retrieveSingleAnnot= function(annotId) {
    var jsonReturn;
    var jsonRequest = new Request.JSON({
        url: 'api/Data/retreiveSingleAnnot.php', //Ameen, fix your spelling! Again!
        async:false,
        onSuccess: function(e){
            jsonReturn = JSON.parse(e)[0];
    }.bind(this),
    onFailure:function(e){
            this.showMessage("Error retrieving Annotation, please check your trieveSingleAnnot.php");
        }.bind(this)
    }).get({'annotId':annotId});

    return jsonReturn;
};
annotools.prototype.populateForm= function(annotationTemplateJson, annotationTextJson, mode) {
    var form = "";
    for (var key in annotationTemplateJson) {
        if (annotationTemplateJson.hasOwnProperty(key) && key != "_id") {
            form += "<p class='labelText'>"+key+": </p>";
            var val = annotationTemplateJson[key];
            if (val == "text") {
                form += "<input type='text' size='45' name='"+key+"' id='"+key+"'";
                if (mode == "edit") {
                    form += " value='"+annotationTextJson[key]+"'";
                }
                form += "\><br \>";
            } else {
                var options = val['enumerable'].replace(/ /g,"").split(",");
                if (val['multi'] == "true" && mode != "filter") {
                    for (var i = 0; i < options.length; i ++) {
                        form += "<input type='checkbox' name='"+key+"' id='"+options[i]+"' value='"+options[i]+"'";
                        if (mode == "edit" && annotationTextJson[key].indexOf(options[i])) {
                            form += " checked='true'";
                        }
                        form += ">"+options[i]+"</input>";
                    }
                } else {
                    for (var i = 0; i < options.length; i ++) {
                        form += "<input type='radio' name='"+key+"' id='"+options[i]+"' value='"+options[i]+"'";
                        if (mode == "edit" && annotationTextJson[key] == options[i]) {
                            form += " checked='true'";
                        }
                        form += ">"+options[i]+"</input>";
                    }
                }
            }
        }
    }
    return form;
};

function handleWorkOrder(annot){
    console.log(annot);
}

annotools.prototype.promptForWorkOrder = function(newAnnot, mode, annotools, ctx){
    console.log(newAnnot);
    console.log(mode);
    console.log(annotools);
    console.log(ctx);
    
    var panel = jQuery("#panel").show();  
    var iid = this.iid;
        var x = annotools.imagingHelper.physicalToDataX(annotools.imagingHelper.logicalToPhysicalX(newAnnot.x));
        var y = annotools.imagingHelper.physicalToDataY(annotools.imagingHelper.logicalToPhysicalY(newAnnot.y)); 
        var w = (annotools.imagingHelper.physicalToDataX(annotools.imagingHelper.logicalToPhysicalX((newAnnot.x+newAnnot.w)))) - x;
        var h = (annotools.imagingHelper.physicalToDataY(annotools.imagingHelper.logicalToPhysicalY(newAnnot.y+newAnnot.h))) - y;
        x = parseInt(x);
        y = parseInt(y);
        w = parseInt(w);
        h = parseInt(h);

        panel.html(function(){
          
            return "<h4> Work Order </h4> <ul><li> x1: " + x  + "</li> <li> y1: " +y+ "</li> <li> w: "+ w+"</li> <li>h: "+h +"</li> <li>Algorithm: Test1</li></ul> <br /> <button id='submitWorkOrder'>Submit</button> <button id='cancelWorkOrder'>Cancel</button>";

        });

        var order ={
        "input":
            {
                "host": "dragon.cci.emory.edu",
                "port": 9099,
                "path": "/services/TCGA/GeoJSONMetaData/query/getFileLocationByIID",
                "case_id": iid, 
                "x": x,
                "y": y,
                "w": w,
                "h": h,
                "format": "JPG",
                "iipServer": "http://dragon.cci.emory.edu/fcgi-bin/iipsrv.fcgi"
            },
        "output":
            {
                "format": "mask",
                "host": "dragon.cci.emory.edu",
                "port": 9099,
                "path": "/services/DynamicServices/Annotations/submit/json"
            }
        };
    console.log(order);    

    jQuery("#cancelWorkOrder").click(function(){
        console.log("here");
        jQuery("#panel").hide();
        annotools.drawLayer.hide();
        annotools.addMouseEvents();      
    });


    jQuery("#submitWorkOrder").click(function(){
        console.log("events...");

        //annotools.drawCanvas.removeEvents('mouseup');
        //annotools.drawCanvas.removeEvents('mousedown');
        //annotools.drawCanvas.removeEvents('mousemove');
        annotools.drawLayer.hide();
        annotools.addMouseEvents();      
        //annotools.removeMouseEvents();
        //annotools.getMultiAnnot();            
        
        var order ={
        "input":
            {
                "host": "dragon.cci.emory.edu",
                "port": 9099,
                "path": "/services/TCGA/GeoJSONMetaData/query/getFileLocationByIID",
                "case_id": iid, 
                "x": x,
                "y": y,
                "w": w,
                "h": h,
                "format": "JPG",
                "iipServer": "http://dragon.cci.emory.edu/fcgi-bin/iipsrv.fcgi"
            },
        "output":
            {
                "format": "mask",
                "host": "dragon.cci.emory.edu",
                "port": 9099,
                "path": "/services/DynamicServices/Annotations/submit/json"
            }
        };
        jQuery.post("api/Data/workOrder.php", order)
            .done(function(res){
                console.log(res);
                panel.html(function(){
                annotools.addMouseEvents();
                    return "Order Submitted!";
                    
                });
                
            });
        console.log("submit");
        console.log(newAnnot);
        console.log(order);
        
    }.bind(newAnnot));    
}


annotools.prototype.promptForAnnotation= function(newAnnot, mode, annotools, ctx){
 


    jQuery("#panel").show("slide");
    console.log(newAnnot);
    jQuery("#panel").html("" +
        "<div id = 'panelHeader'> <h4>Enter a new annotation </h4></div>"
    +   "<div id='panelBody'>" 
            +"<form id ='annotationsForm'>"
            +"</form>" 

    +   "</div>"
    );

    var formSchema = {
        "schema": {
            "site": {
              "type": "checkboxes",
              "title": "Tumor Site(select all the apply)",
              "items":{
                  "type": "string",
                   "enum": [
                       "Upper_Outer_Quadrant",
                       "Lower_Outer_Quadrant",
                       "Upper_Inner_Quadrant",
                       "Upper_Inner_Quadrant",
                       "Central",
                       "Nipple"
                   ]
              }
            },
            "grade": {
                  "type": "string",
                  "title": "Nuclear Grade:",
                    "enum": [
                      "Grade-I",
                      "Grade-II",
                      "Grade-III(High)"
                      ]
            },
            "necrosis": {
                  "type": "string",
                  "title": "Necrosis:",
                    "enum": [
                      "NotIdentified",
                      "Present-Focal",
                      "Present-Central"
                      ]
            }    
        },
        "form": [
            "*",
            {
                "type": "submit",
                "title": "Submit"
            },
            {
                "type": "button",
                "title": "Cancel",
                "onClick": function(e) {
                    console.log(e);
                    e.preventDefault();
                    //console.log("cancel");
                    cancelAnnotation();
                }
            }
        ]
    };

    //console.log(newAnnot);

    formSchema.onSubmit = function(err,val){
        //console.log(err);
        //console.log(val);

        //console.log("submitted");
        //console.log(val);
        newAnnot.properties = {};
        newAnnot.properties.annotations = val;
        //console.log(val);
        //add new annotation
                
        annotools.addnewAnnot(newAnnot);
     
        //restore original state
        jQuery("#panel").hide("slide");
        annotools.drawLayer.hide();
        annotools.addMouseEvents();      
    }
    /*
    formSchema.onSubmit = function(err,val){
        console.log(err);
        console.log(val);



        console.log("submitted");
        
        //add new annotation
        annotools.addnewAnnot(newAnnot);
        
        //restore original state
        jQuery("#panel").hide("slide");
        annotools.drawLayer.hide();
        annotools.addMouseEvents();      
    }
    */
    var cancelAnnotation = function(){
        console.log("cancel handler");
        jQuery("#panel").hide("slide");
        annotools.drawLayer.hide();
        annotools.addMouseEvents();      
    }

    jQuery("#annotationsForm").jsonForm(formSchema);





};



annotools.prototype.promptForAnalysis= function(annotools, analysisBox) {
    var title = "Analysis Tool";
    var form = "<select id='algorithm'>";
    form += "<option value='canny_edge'>Canny Edge</option>";
    form += "<option value='marching_cubes'>Marching Cubes</option>";
    form += "</select>";
    var SM = new SimpleModal();
    SM.addButton("Confirm", "btn primary", function() {
        var algorithm = $('algorithm').value;
        this.hide();
        annotools.promptForParameters(annotools, analysisBox, algorithm);
    });
    SM.addButton("Cancel", "btn secondary", function() {
        annotools.addMouseEvents();
        this.hide();
        return false;
    });
    SM.show({
        "model":"modal",
        "title":title,
        "contents":form,
    });
};
annotools.prototype.promptForParameters= function(annotools, analysisBox, algorithm) {
    var title = "Enter the parameters";
    var form = "<form>";
    var field = [];
    var parameters = "{ ";
/*====================test samples, will need to be retrived from API calls===============*/
    var sample = "{ \"param_1\" : \"text\" , \"param_2\" : \"text\" }";
    var sampleJson = JSON.parse(sample);
/*===================================*/
    switch (algorithm) {
        case "canny_edge":
            for (var key in sampleJson) {
                field.push(key);
                form += "<p class='labelText'>"+key+"</p><input type='text' size='45' name='"+key+"' id='"+key+"'/><br />";
                parameters += "\""+key+"\" : ";
                parameters += "__"+key+"__, ";
            }
            break;
        case "marching_cubes":
            for (var key in sampleJson) {
                field.push(key);
                form += "<p class='labelText'>"+key+"</p><input type='text' size='45' name='"+key+"' id='"+key+"'/><br />";
                parameters += "\""+key+"\" : ";
                parameters += "__"+key+"__, ";
            }
            break;
    }
    form += "</form>";
    parameters = parameters.substring(0, parameters.length-2)+" }";
    var SM = new SimpleModal();
    SM.addButton("Confirm", "btn primary", function() {
        for (var i = 0; i < field.length; i ++) {
            var fieldElem = $$(document.getElementsByName(field[i]));
            var replacement = "\""+$(field[i]).value+"\"";
            parameters = parameters.replace("__"+field[i]+"__", replacement);
        }
        var submission = "{ \"Algorithm\" : \""+algorithm+"\", \"x\" : \""+analysisBox.x+"\", \"y\" : \""+analysisBox.y+"\", \"w\" : \""+analysisBox.w+"\", \"h\" : \""+analysisBox.h+"\", \"Parameters\" : "+parameters+" }";
        console.log(submission);
        submission = JSON.parse(submission);
/*============after this point, submission is ready to be handed over to bindaas=========*/
        annotools.addMouseEvents();
        this.hide();
        return false;
    });
    SM.addButton("Cancel", "btn secondary", function() {
        annotools.addMouseEvents();
        this.hide();
        return false;
    });
    SM.show({
        "model":"modal",
        "title":title,
        "contents":form,
    });
};
annotools.prototype.addMouseEvents= function() {
    console.log("adding mouse events");
    //console.log(this.annotationHandler);
    window.addEventListener('mousemove',    this.annotationHandler.handleMouseMove, false);
    window.addEventListener('mousedown',    this.annotationHandler.handleMouseDown, false);
    window.addEventListener('mouseup',      this.annotationHandler.handleMouseUp, false);
    //window.addEventListener('mouseup',      this.getAnnot(), false);
};
annotools.prototype.removeMouseEvents= function() {
    console.log("removing events");
    //console.log(this.annotationHandler);
    window.removeEventListener('mousemove',    this.annotationHandler.handleMouseMove, false);
    window.removeEventListener('mousedown',    this.annotationHandler.handleMouseDown, false);
    window.removeEventListener('mouseup',      this.annotationHandler.handleMouseUp, false);
    //window.removeEventListener('mouseup',      this.getAnnot(), false);
};
