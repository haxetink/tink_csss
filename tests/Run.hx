package ;

import haxe.unit.*;

using tink.core.Outcome;

class Run {
	static var tests:Array<TestCase> = [
		new TestParser(),
	];
	
	static function main() {
		var runner = new TestRunner();
		for (test in tests)
			runner.add(test);
		runner.run();
	}	
}