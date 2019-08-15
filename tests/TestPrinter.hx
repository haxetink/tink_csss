package ;

import tink.csss.*;

using StringTools;
using tink.CoreApi;

class TestPrinter extends Base {
	function test() {
		var p = new Printer(''),
				cases = @:privateAccess TestParser.cases;

		for (selector in cases)
			if (selector != null)
				assertStructEq(selector, Parser.parse(p.selector(selector)).sure());
				
	}
}