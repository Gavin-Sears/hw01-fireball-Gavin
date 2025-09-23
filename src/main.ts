import {vec3, vec4, mat4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  'Load Scene': loadScene, // A function pointer, essentially
  'Reset': setDefaultValues, 
  tesselations: 5,
  'energy': 0.1,
  'life': 1.1,
  'vitality': 1.0
};

let icosphere: Icosphere;
let square: Square;
let cube: Cube;
let prevTesselations: number = 5;
let startTime = performance.now();
let gui = new DAT.GUI();
let canvas = <HTMLCanvasElement> document.getElementById('canvas');
let renderer = new OpenGLRenderer(canvas);
let gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
let camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));
let mouseRay = vec4.fromValues(0.0, 0.0, 0.0, 0.0);

function hextoVec4(hexVal: string): vec4 {
  let truncColor: string = hexVal.slice(1);

  let r: number = parseInt((truncColor.charAt(0) + truncColor.charAt(1)), 16) / 255.0;
  let g: number = parseInt((truncColor.charAt(2)) + truncColor.charAt(3), 16) / 255.0;
  let b: number = parseInt((truncColor.charAt(4) + truncColor.charAt(5)), 16) / 255.0;

  let col: vec4 = vec4.fromValues(r, g, b, 1);
  return col;
}

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  //square = new Square(vec3.fromValues(0, 0, 0));
  //square.create();
  //cube = new Cube(vec3.fromValues(0, 0, 0))
  //cube.create();
}

function setDefaultValues() {
  controls.tesselations = 5;
  controls['energy'] = 0.5;
  controls['life'] = 1.1;
  controls['vitality'] = 1.0;
  for (const contr of gui.__controllers) {
    contr.updateDisplay();
  }
}

function handleMouseEvent(event: any) {
    const rect = canvas.getBoundingClientRect();
    const x = event.clientX - rect.left; // Mouse X relative to canvas
    const y = event.clientY - rect.top;  // Mouse Y relative to canvas
    
    const xVal = (x / rect.width) * 2.0 - 1.0;
    const yVal = (y / rect.height) * 2.0 + 1.0;

    mouseRay = vec4.fromValues(xVal * 2.0, -yVal * 2.0, 0.0, 0.0);
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  canvas.addEventListener('mousemove', handleMouseEvent);

  // Add controls to the gui
  //const gui = new DAT.GUI();
  gui.add(controls, 'Load Scene');
  gui.add(controls, 'Reset');
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'energy', 0.0, 1.0);
  gui.add(controls, 'life', 0.1, 10.0);
  gui.add(controls, 'vitality', 0.0, 10.0);

  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);

  const Explosion = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/Explosion-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/Explosion-frag.glsl'))
  ]);

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();

    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }

    renderer.render(
      camera, 
      Explosion, 
      (performance.now() - startTime) / 1000.0, 
      controls['energy'],
      controls['life'],
      controls['vitality'],
      mouseRay,
      [
      icosphere
      //cube
      // square,
      ]
    );
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
