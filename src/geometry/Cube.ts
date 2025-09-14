import {vec3, vec4} from 'gl-matrix';
import Drawable from '../rendering/gl/Drawable';
import {gl} from '../globals';

class Cube extends Drawable {
  indices: Uint32Array;
  positions: Float32Array;
  normals: Float32Array;
  center: vec4;

  constructor(center: vec3) {
    super(); // Call the constructor of the super class. This is required.
    this.center = vec4.fromValues(center[0], center[1], center[2], 1);
  }

  create() {

    let cubeIndices: number[] = [];
    for (let i = 0; i < 6; ++i)
    {
        let offset = 4 * i;

        cubeIndices.push(0 + offset)
        cubeIndices.push(1 + offset)
        cubeIndices.push(2 + offset)

        cubeIndices.push(3 + offset)
        cubeIndices.push(2 + offset)
        cubeIndices.push(1 + offset)
    }
    this.indices = new Uint32Array(cubeIndices);

    let cubeNormals: number[] = [];
    for (let i = 0; i < 6; ++i)
    {
        for (let j = 0; j < 4; ++j)
        {
            cubeNormals.push((i == 0 ? 1 : i == 1 ? -1 : 0))
            cubeNormals.push((i == 2 ? 1 : i == 3 ? -1 : 0))
            cubeNormals.push((i == 4 ? 1 : i == 5 ? -1 : 0))
            cubeNormals.push(0)
        }
    }
    this.normals = new Float32Array(cubeNormals);

    let cubePositions: number[] = [
                                    // norm = 1, 0, 0, 0
                                    0.5, 0.5, -0.5, 1,
                                    0.5, 0.5, 0.5, 1,
                                    0.5, -0.5, -0.5, 1,
                                    0.5, -0.5, 0.5, 1,
                                    // norm = -1, 0, 0, 0
                                    -0.5, 0.5, 0.5, 1,
                                    -0.5, 0.5, -0.5, 1,
                                    -0.5, -0.5, 0.5, 1,
                                    -0.5, -0.5, -0.5, 1,
                                    // norm = 0, 1, 0, 0
                                    0.5, 0.5, -0.5, 1,
                                    -0.5, 0.5, -0.5, 1,
                                    0.5, 0.5, 0.5, 1,
                                    -0.5, 0.5, 0.5, 1,
                                    // norm = 0, -1, 0, 0
                                    0.5, -0.5, 0.5, 1,
                                    -0.5, -0.5, 0.5, 1,
                                    0.5, -0.5, -0.5, 1,
                                    -0.5, -0.5, -0.5, 1,
                                    // norm = 0, 0, 1, 0
                                    0.5, 0.5, 0.5, 1,
                                    -0.5, 0.5, 0.5, 1,
                                    0.5, -0.5, 0.5, 1,
                                    -0.5, -0.5, 0.5, 1,
                                    // norm = 0, 0, -1, 0
                                    -0.5, 0.5, -0.5, 1,
                                    0.5, 0.5, -0.5, 1,
                                    -0.5, -0.5, -0.5, 1,
                                    0.5, -0.5, -0.5, 1
                                ];
    this.positions = new Float32Array(cubePositions);

    this.generateIdx();
    this.generatePos();
    this.generateNor();

    this.count = this.indices.length;
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.bufIdx);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, this.indices, gl.STATIC_DRAW);

    gl.bindBuffer(gl.ARRAY_BUFFER, this.bufNor);
    gl.bufferData(gl.ARRAY_BUFFER, this.normals, gl.STATIC_DRAW);

    gl.bindBuffer(gl.ARRAY_BUFFER, this.bufPos);
    gl.bufferData(gl.ARRAY_BUFFER, this.positions, gl.STATIC_DRAW);

    console.log(`Created cube`);
  }
};

export default Cube;
