package;

import kha.Color;
import kha.Framebuffer;
import kha.Shaders;
import kha.graphics4.ConstantLocation;
import kha.graphics4.FragmentShader;
import kha.graphics4.IndexBuffer;
import kha.graphics4.PipelineState;
import kha.graphics4.Usage;
import kha.graphics4.VertexBuffer;
import kha.graphics4.VertexData;
import kha.graphics4.VertexShader;
import kha.graphics4.VertexStructure;
import kha.math.FastMatrix3;
import kha.math.FastMatrix4;
import kha.math.FastVector3;

class Game {
    // An array of 3 vectors representing 3 vertices to form a triangle
    static var vertices:Array<Float> = [
        -1.0, -1.0, 0.0, // Bottom-left
         1.0, -1.0, 0.0, // Bottom-right
         0.0,  1.0, 0.0  // Top
    ];

    // Indices for our triangle, these will point to vertices above
    static var indices:Array<Int> = [
        0, // Bottom-left
        1, // Bottom-right
        2  // Top
    ];

    var vertexBuffer:VertexBuffer;
    var indexBuffer:IndexBuffer;
    var pipeline:PipelineState;

    var mvpId:ConstantLocation;
    var mvp:FastMatrix4;

	public function new () {
        // Define vertex structure
        final structure = new VertexStructure();
        structure.add('pos', VertexData.Float3);

        // Save length - we only store position in vertices for now
        // Eventually there will be texture coords, normals,...
        var structureLength = 3;

        // Compile pipeline state
        // Shaders are located in 'Sources/Shaders' directory
        // and Kha includes them automatically
        pipeline = new PipelineState();
        pipeline.inputLayout = [structure];
        pipeline.fragmentShader = Shaders.threed_test_frag;
        pipeline.vertexShader = Shaders.threed_test_vert;
        pipeline.compile();

        // Get a handle for our "MVP" uniform
        mvpId = pipeline.getConstantLocation("MVP");

        // Projection matrix: 45° Field of View, 4:3 ratio, 0.1-100 display range
        // final projection = FastMatrix4.perspectiveProjection(45.0, 4.0 / 3.0, 0.1, 100.0);
		// Or, for an ortho camera
		final projection = FastMatrix4.orthogonalProjection(-10.0, 10.0, -10.0, 10.0, 0.0, 100.0); // In world coordinates

        // Camera matrix
        final view = FastMatrix4.lookAt(
            new FastVector3(4, 3, 3), // Position in World Space
            new FastVector3(0, 0, 0), // and looks at the origin
            new FastVector3(0, 1, 0) // Head is up
        );

        // Model matrix: an identity matrix (model will be at the origin)
        final model = FastMatrix4.identity();

        mvp = FastMatrix4.identity();
        mvp = mvp.multmat(projection);
        mvp = mvp.multmat(view);
        mvp = mvp.multmat(model);
        
        // Create vertex buffer
        vertexBuffer = new VertexBuffer(
            Std.int(vertices.length / 3), // Vertex count - 3 floats per vertex
            structure, // Vertex structure
            Usage.StaticUsage // Vertex data will stay the same
        );
  
        // Copy vertices to vertex buffer
        final vbData = vertexBuffer.lock();
        for (i in 0...vbData.length) {
            vbData.set(i, vertices[i]);
        }
        vertexBuffer.unlock();
    
        // Create index buffer
        indexBuffer = new IndexBuffer(
            indices.length, // 3 indices for our triangle
            Usage.StaticUsage // Index data will stay the same
        );
    
        // Copy indices to index buffer
        final iData = indexBuffer.lock();
        for (i in 0...iData.length) {
            iData[i] = indices[i];
        }
        indexBuffer.unlock();
    }

	public function render(frames:Array<Framebuffer>) {
		// A graphics object which lets us perform 3D operations
		final g4 = frames[0].g4;

		// Begin rendering
        g4.begin();

        // Bind state we want to draw with
        g4.setPipeline(pipeline);

        // Clear screen to black
		g4.clear(Color.Magenta);

        // Bind data we want to draw
        g4.setVertexBuffer(vertexBuffer);
        g4.setIndexBuffer(indexBuffer);

        // Send our transformation to the currently bound shader, in the "MVP" uniform
        g4.setMatrix(mvpId, mvp);

        // Draw!
        g4.drawIndexedVertices();

		// End rendering
		g4.end();
    }
}
