import kha.Assets;
import kha.Framebuffer;
import kha.Image;
import kha.Scheduler;
import kha.Shaders;
import kha.System;
import kha.graphics4.CompareMode;
import kha.graphics4.ConstantLocation;
import kha.graphics4.CullMode;
import kha.graphics4.IndexBuffer;
import kha.graphics4.PipelineState;
import kha.graphics4.TextureUnit;
import kha.graphics4.Usage;
import kha.graphics4.VertexBuffer;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;
import kha.input.KeyCode;
import kha.input.Keyboard;
import kha.input.Mouse;
import kha.math.FastMatrix4;
import kha.math.FastVector3;

class Game {
    var lastTime:Float;
    var isMouseDown:Bool;

    var position:FastVector3 = new FastVector3(0, 0, 5); // Initial position: on +Z
    var horizontalAngle:Float = 3.14; // Initial horizontal angle: toward -Z
    var verticalAngle:Float = 0.0; // Initial vertical angle: none

    var mouseDeltaX:Float = 0.0;
    var mouseDeltaY:Float = 0.0;
    var mouseX:Float = 0.0;
    var mouseY:Float = 0.0;

    var speed:Float = 3.0; // 3 units / second
	var mouseSpeed:Float = 0.005;

    var moveForward:Bool;
    var moveBackward:Bool;
    var strafeLeft:Bool;
    var strafeRight:Bool;
    var rotateLeft:Bool;
    var rotateRight:Bool;

    var vertexBuffer:VertexBuffer;
    var indexBuffer:IndexBuffer;
    var pipeline:PipelineState;

    var mvpId:ConstantLocation;
    var mvp:FastMatrix4;
    var textureId:TextureUnit;
    var image:Image;
    var viewMatrixID:ConstantLocation;
    var modelMatrixID:ConstantLocation;
    var lightID:ConstantLocation;

    var model:FastMatrix4;
    var view:FastMatrix4;
    var projection:FastMatrix4;

	public function new () {
        Assets.loadEverything(create);

        // Projection matrix: 45° Field of View, 4:3 ratio, 0.1-100 display range
        projection = FastMatrix4.perspectiveProjection(45.0, 4.0 / 3.0, 0.1, 100.0);
        // Or, for an ortho camera
        // final projection = FastMatrix4.orthogonalProjection(-10.0, 10.0, -10.0, 10.0, 0.0, 100.0); // In world coordinates

        // Camera matrix
        view = FastMatrix4.lookAt(
            new FastVector3(4, 3, 3), // Position in World Space
            new FastVector3(0, 0, 0), // and looks at the origin
            new FastVector3(0, 1, 0) // Head is up
        );

        // Model matrix: an identity matrix (model will be at the origin)
        model = FastMatrix4.identity();

        mvp = FastMatrix4.identity();
        mvp = mvp.multmat(projection);
        mvp = mvp.multmat(view);
        mvp = mvp.multmat(model);
    }

    function create () {
        // Define vertex structure
        final structure = new VertexStructure();
        structure.add('pos', VertexData.Float3);
        structure.add('uv', VertexData.Float2);
        structure.add('nor', VertexData.Float3);

        // Save length - we only store position in vertices for now
        // Eventually there will be texture coords, normals,...
        final structureLength = 8;

        // Compile pipeline state
        // Shaders are located in 'Sources/Shaders' directory
        // and Kha includes them automatically
        pipeline = new PipelineState();
        pipeline.inputLayout = [structure];
        pipeline.fragmentShader = Shaders.threed_test_frag;
        pipeline.vertexShader = Shaders.threed_test_vert;
        pipeline.compile();

        // Set depth mode
        pipeline.depthWrite = true;
        pipeline.depthMode = CompareMode.Less;

        // Set culling
        pipeline.cullMode = CullMode.Clockwise;

        // Get a handle for our "MVP" uniform
        // MVP is movel view projection
        mvpId = pipeline.getConstantLocation('MVP');

        // Get a handle for texture sample
        textureId = pipeline.getTextureUnit('myTextureSampler');
        viewMatrixID = pipeline.getConstantLocation("V");
        modelMatrixID = pipeline.getConstantLocation("M");
        lightID = pipeline.getConstantLocation("lightPos");

        image = Assets.images.uvmap;

        final obj = new ObjLoader(Assets.blobs.suzanne_obj);

        // Create vertex buffer
        vertexBuffer = new VertexBuffer(
            Std.int(obj.data.length / structureLength), // Vertex count
            structure, // Vertex structure
            Usage.StaticUsage // Vertex data will stay the same
        );

        // Copy data to vertex buffer
        var vbData = vertexBuffer.lock();
        for (i in 0...vbData.length) {
            vbData[i] = obj.data[i];
        }
        vertexBuffer.unlock();

        // Create index buffer
        indexBuffer = new IndexBuffer(
            obj.indices.length, // Number of indices for our cube
            Usage.StaticUsage // Index data will stay the same
        );
    
        // Copy indices to index buffer
        var iData = indexBuffer.lock();
        for (i in 0...iData.length) {
            iData[i] = obj.indices[i];
        }
        indexBuffer.unlock();

        // Add mouse and keyboard listeners
        Mouse.get().notify(onMouseDown, onMouseUp, onMouseMove, null);
        Keyboard.get().notify(onKeyDown, onKeyUp);

        // Used to calculate delta time
        lastTime = Scheduler.time();

        System.notifyOnFrames(render);
    }

    public function update () {
        // Compute time difference between current and last frame
        var deltaTime = Scheduler.time() - lastTime;
        lastTime = Scheduler.time();

        // Compute new orientation
        if (isMouseDown) {
            horizontalAngle += mouseSpeed * mouseDeltaX * -1;
            verticalAngle += mouseSpeed * mouseDeltaY * -1;
        }

        // Direction: Spherical coordinates to Cartesian coordinates conversion
        var direction = new FastVector3(
            Math.cos(verticalAngle) * Math.sin(horizontalAngle),
            Math.sin(verticalAngle),
            Math.cos(verticalAngle) * Math.cos(horizontalAngle)
        );

        // Right vector
        var right = new FastVector3(
            Math.sin(horizontalAngle - 3.14 / 2.0),
            0,
            Math.cos(horizontalAngle - 3.14 / 2.0)
        );

        // Up vector
        var up = right.cross(direction);

        // Movement
        if (moveForward) {
            var v = direction.mult(deltaTime * speed);
            position = position.add(v);
        }
        if (moveBackward) {
            var v = direction.mult(deltaTime * speed * -1);
            position = position.add(v);
        }
        if (strafeRight) {
            var v = right.mult(deltaTime * speed);
            position = position.add(v);
        }
        if (strafeLeft) {
            var v = right.mult(deltaTime * speed * -1);
            position = position.add(v);
        }
        if (rotateLeft) {
            model = model.multmat(FastMatrix4.rotationY(-0.01));
        }
        if (rotateRight) {
            model = model.multmat(FastMatrix4.rotationY(0.01));
        }

        // Look vector
        var look = position.add(direction);

        // Camera matrix
        view = FastMatrix4.lookAt(
            position, // Camera is here
            look, // and looks here : at the same position, plus "direction"
            up // Head is up (set to (0, -1, 0) to look upside-down)
        );

        // Update model-view-projection matrix
        mvp = FastMatrix4.identity();
        mvp = mvp.multmat(projection);
        mvp = mvp.multmat(view);
        mvp = mvp.multmat(model);

        mouseDeltaX = 0;
        mouseDeltaY = 0;
    }

    public function render(frames:Array<Framebuffer>) {
        // A graphics object which lets us perform 3D operations
        final g4 = frames[0].g4;

        // Begin rendering
        g4.begin();

        // Bind state we want to draw with
        g4.setPipeline(pipeline);

        // Clear screen to black, also reset depth
        g4.clear(Color.fromFloats(0.0, 0.0, 0.0), 1.0);

        // Bind data we want to draw
        g4.setVertexBuffer(vertexBuffer);
        g4.setIndexBuffer(indexBuffer);

        g4.setTexture(textureId, image);
        // Send our transformation to the currently bound shader, in the "MVP" uniform
        g4.setMatrix(mvpId, mvp);

        g4.setMatrix(modelMatrixID, model);
        g4.setMatrix(viewMatrixID, view);
    
        // Set light position to (4, 4, 4)
        g4.setFloat3(lightID, 4, 4, 4);

        // Draw!
        g4.drawIndexedVertices();

        // End rendering
		g4.end();
    }

    function onMouseDown(button:Int, x:Int, y:Int) {
        isMouseDown = true;
    }

    function onMouseUp(button:Int, x:Int, y:Int) {
        isMouseDown = false;
    }

    function onMouseMove(x:Int, y:Int, movementX:Int, movementY:Int) {
        mouseDeltaX = x - mouseX;
        mouseDeltaY = y - mouseY;

        mouseX = x;
        mouseY = y;
    }

    function onKeyDown(key:KeyCode) {
        if (key == KeyCode.Up) moveForward = true;
        else if (key == KeyCode.Down) moveBackward = true;
        else if (key == KeyCode.Left) strafeLeft = true;
        else if (key == KeyCode.Right) strafeRight = true;
        else if (key == KeyCode.Q) rotateLeft = true;
        else if (key == KeyCode.E) rotateRight = true;
    }

    function onKeyUp(key:KeyCode) {
        if (key == KeyCode.Up) moveForward = false;
        else if (key == KeyCode.Down) moveBackward = false;
        else if (key == KeyCode.Left) strafeLeft = false;
        else if (key == KeyCode.Right) strafeRight = false;
        else if (key == KeyCode.Q) rotateLeft = false;
        else if (key == KeyCode.E) rotateRight = false;
    }
}
