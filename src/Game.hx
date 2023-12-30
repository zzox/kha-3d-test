package;

import kha.Color;
import kha.Framebuffer;

class Game {
	public function new () {}

	public function render(frames:Array<Framebuffer>) {
		// A graphics object which lets us perform 3D operations
		final g = frames[0].g4;

		// Begin rendering
        g.begin();

        // Clear screen to black
		g.clear(Color.Magenta);

		// End rendering
		g.end();
    }
}
