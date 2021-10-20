// Mandala1.scad
// by David Phillip Oster Inspired by https://www.instructables.com/A-Mathematical-Art-Piece/ 10/20/2021

// ---- Constants ----

// a line segment connects two pins. The pins are modeled as tiny squares
pinDim = 0.01;

// divide the circle into N segments of equal arc. segmentN Should be even.
segmentN=24; // [6:2:100]

// the shape is bounded by a square with sides this length:
outerSquareDim=120;

// check to show the grid.
isGrid = true;

// the number of layers to build up.
numLayers = 4; // [0:20]

/*[Hidden]*/

// along each radius, the number of concentric circles.
ringRad=[for(i=[15:6:outerSquareDim/sqrt(2)]) i];

//
colors = ["red", "green", "white", "blue", "gray"];

// ---- Helpers ----

// given two 2-D points, draw a line segment connecting them.
module segment(p1, p2){
  hull(){
    translate(p1)circle(r=pinDim, $fn=4);
    translate(p2)circle(r=pinDim, $fn=4);
  }
}

// given an vector of 2-D points, connect them with line segments.
module polyline(v){
  if(2 <= len(v)){
    for(i=[0:len(v)-2]){
      segment(v[i], v[i+1]);
    }
  }
}

// Draw an arc, radius r, from ang1 to ang2, simulated by numDivisions line segments.
module arcline(r, ang1, ang2, numDivisions = segmentN){
  points = [ for(theta = [ang1:(ang2-ang1)/numDivisions:ang2])
      [r*cos(theta), r*sin(theta)] ];
  polyline(points);
}

// Draw a square centered on the origin, dim on a side.
module squareline(dim){
  polyline([
    [dim/2, dim/2],
    [-dim/2, dim/2],
    [-dim/2, -dim/2],
    [dim/2, -dim/2],
    [dim/2, dim/2],
   ]);
}

module test_polyline(){  polyline([ [0,4], [4,4], [4,0], ]); }

module test_arcline(){ arcline(20, 10, 350); }

module test_squareline(){ squareline(6); }

module test_helpers(){
  test_polyline();
  test_arcline();
  test_squareline();
}

// ---- Step 1 - draw the grid. ----

// polar coordinate grid with radial lines and circles.
module baseGrid(){
  r=outerSquareDim*sqrt(2)/2;

  // radial lines.
  for(i=[0:segmentN-1]) {
    theta = 360*i/(segmentN);
    segment([0,0], [r*cos(theta), r*sin(theta)]);
  }

  // concentric circles.
  for(j = [0:len(ringRad)-1]){
    arcline(ringRad[j], 0, 360);
  }
}

// The full grid has an enclosing square. (Clipping is done in main, defined below.)
module grid(){
  color("gray")union(){
    squareline(outerSquareDim);
    baseGrid();
  }
}

// ---- Step 2: Draw the zig zag rings ----

// zigzag between every other segment at radius small to the next segment in radius big.
// set offset to 1 to start at segment 1 instead of segment 0.

module zigzagring2(smallR, bigR, offsetN) {
  for(i=[0:2:segmentN-1]) {
    index=i+offsetN;
    if (index < segmentN){
      thetaSmall = 360*index/(segmentN);
      thetaBig = 360*(index+1)/(segmentN);
      thetaSmall2 = 360*(index+2)/(segmentN);
      polyline([
          [smallR*cos(thetaSmall), smallR*sin(thetaSmall)],
          [bigR*cos(thetaBig), bigR*sin(thetaBig)],
          [smallR*cos(thetaSmall2), smallR*sin(thetaSmall2)],
          ]
        );
    }
  }
}

// zigzag between every other segment in ring N, and ring N +1.
// Offset to rotate the zigzag by offset segments.
module zigzagring(rN, offsetN) {
  smallR = rN < 0 ? 0 : ringRad[rN];
  bigR = ringRad[rN+1];
  zigzagring2(smallR, bigR, offsetN);
}

// draw segments from each of the 3 corners of the square to the inner radius.
module outerspokes(innerRad){
  for(i=[-1:2:1], j=[-1:2:1]){
    segment([i*outerSquareDim/2, j*outerSquareDim/2], [i*innerRad,j*innerRad]);
  }
}

// ---- Step 3: Putting it all together ----

// draws the full mandala as a 2D object, r lets you thicken the lines.
module mandala2D(r=0.01) {
  offset(r){
    squareline(outerSquareDim);
    outerspokes(ringRad[5]);
    zigzagring(-1, 1);  // draw spoke from center
    zigzagring(0,0);
    zigzagring(1,1);
    zigzagring2(ringRad[2], ringRad[5], 0);

    zigzagring(4,0);
    zigzagring(5,1);

    zigzagring(6,0);
    zigzagring(7,1);
  }
}

// extrude mandala2D into a 3D object
module mandala(r=1/4){
  linear_extrude(height=1){
    mandala2D(r);
  }
}

// stack and color the successively offset mandala.
module mandala3D() {
  if (isGrid) { linear_extrude(height=0.1)grid(); }
  if (0 == numLayers) {
    mandala();
  } else {
    for(i=[0:numLayers]){
      color(colors[i%len(colors)])translate([0,0,numLayers-i])mandala(r=3*i/(numLayers+1));
    }
  }
}

// ---- Main: clip to our cube ----

module main(){
  intersection(){
    cube([outerSquareDim+3*pinDim, outerSquareDim+3*pinDim, numLayers*100], center=true);
    mandala3D();
  }
}

main();
