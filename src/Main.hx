package;

import kha.System;

class Main {
	public static function main() {
		System.start({title: "kha-3d-test", width: 640, height: 480}, init);
	}

	static function init(_) {
		final game = new Game();
		System.notifyOnFrames(game.render);
	}
}