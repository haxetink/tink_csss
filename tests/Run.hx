package ;

import haxe.unit.*;

using tink.core.Outcome;

class Run {
	static var tests:Array<TestCase> = [
		new TestParser(),
	];
	
	#if !macro
	static function main() {
		travix.Logger.exit(
			if (testAtCompileTime() && runTests()) 0
			else 500
		);
	}
	#end
	static function runTests() {
		var runner = new TestRunner();
		for (test in tests)
			runner.add(test);
		return runner.run();		
	}
	macro static function testAtCompileTime() {
		return macro $v{runTests()};
	}
}