package ;

import tink.csss.*;

using StringTools;
using tink.CoreApi;

class TestPrinter extends Base {
	function test() {
		var p = new Printer('');

		for (raw => selector in @:privateAccess TestParser.cases)
			if (selector != null) 
				assertStructEq(selector, Parser.parse(p.selector(selector)).sure());
	}
}