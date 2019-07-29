package ;

import tink.csss.Selector;

using tink.CoreApi;

class TestParser extends Base {
	static function parse(s:String) 
		return tink.csss.Parser.parse(s);	
	
	static function attr(name:String, ?value:String, ?op:AttrOperator):AttrFilter 
		return {
			name: name,
			value: value,
			op: 
				if (op != null) op
				else if (value == null) None
				else Exactly
		}
		
	static var cases:Map<String, Selector> = [
		'#id' => [[{ id: 'id' }]],
		'#bar' => [[{ id: 'bar' }]],
		'*' => [[{ tag: null }]],
		'div' => [[{ tag: 'div' }]],
		'.class' => [[{ classes: ['class'] }]],
		'.class1.class2' => [[{ classes: ['class1', 'class2'] }]],
		
		'*tag' => null,
		'tag*' => null,
		'tag[foo]tag' => null,
		
		'tag#id.class1.class2' => [[{ tag: 'tag', id: 'id', classes: ['class1', 'class2'] }]],
		
		':hover' => [[{ pseudos: [Hover] }]],
		'::hover' => null,
		'::marker' => [[{ pseudos: [Marker] }]],
		':after' => [[{ pseudos: [After] }]],
		'::after' => [[{ pseudos: [After] }]],
		':foo' => null,
		':hover:hover' => [[{ pseudos: [Hover, Hover] }]],
		
	  '[attr]' => [[{ attrs: [attr('attr')] }]],
		'[attr1][attr2]' => [[{ attrs: [attr('attr1'), attr('attr2')] }]],
		'[attr=foo]' => [[{ attrs: [attr('attr', 'foo')] }]],
		'[attr="foo"]' => [[{ attrs: [attr('attr', 'foo')] }]],
		"[attr='foo']" => [[{ attrs: [attr('attr', 'foo')] }]],
		"[attr='fo]o']" => [[{ attrs: [attr('attr', 'fo]o')] }]],
		'[attr~=foo]' => [[{ attrs: [attr('attr', 'foo', WhitespaceSeperated)] }]],
		'[attr|=foo]' => [[{ attrs: [attr('attr', 'foo', HyphenSeparated)] }]],
		'[attr^=foo]' => [[{ attrs: [attr('attr', 'foo', BeginsWith)] }]],
		'[attr$=foo]' => [[{ attrs: [attr('attr', 'foo', EndsWith)] }]],
		'[attr*=foo]' => [[{ attrs: [attr('attr', 'foo', Contains)] }]],
		'[attr="fo\\\"o"]' => [[{ attrs: [attr('attr', "fo\"o")] }]],

		'tag1> tag2' => [[{ tag: 'tag1', combinator: Child }, { tag: 'tag2' }]],
		'tag1   tag2' => [[{ tag: 'tag1', combinator: Descendant }, { tag: 'tag2' }]],
		'tag1		+ tag2' => [[{ tag: 'tag1', combinator: AdjacentSibling }, { tag: 'tag2' }]],
		'tag1 ~tag2' => [[{ tag: 'tag1', combinator: GeneralSibling }, { tag: 'tag2' }]],
		'tag1, tag2' => [[{ tag: 'tag1' }], [{ tag: 'tag2' }]],
		'tag1  , tag2' => [[{ tag: 'tag1' }], [{ tag: 'tag2' }]],
		'tag1 ,tag2' => [[{ tag: 'tag1' }], [{ tag: 'tag2' }]],
		// 'tag1,tag2,' => [[{ tag: 'tag1' }], [{ tag: 'tag2' }]],
		// 'tag1,tag2, ' => [[{ tag: 'tag1' }], [{ tag: 'tag2' }]],
		// 'tag1,tag2,,' => null,
		
		'' => null,
		',' => null,
		'#' => null,
		'.' => null,
		
		':not()' => null,
		':not' => null,
		':not(div>ul:first-child)' => [[{ pseudos: [Not(parse('div>ul:first-child').sure())] }]],
		
		':first-child' => [[{ pseudos: [FirstChild] }]],
		':last-child' => [[{ pseudos: [LastChild] }]],
		':first-of-type' => [[{ pseudos: [FirstOfType] }]],
		':last-of-type' => [[{ pseudos: [LastOfType] }]],
		
		':nth-child(-2n)' => [[{ pseudos: [NthChild(-2, 0)] }]],
		':nth-child(-2n+4)' => [[{ pseudos: [NthChild(-2, 4)] }]],
		':nth-child(2n-4)' => [[{ pseudos: [NthChild(2, -4)] }]],
		':nth-child(2n+4)' => [[{ pseudos: [NthChild(2, 4)] }]],
		
		':nth-child(n+ 4)' => [[{ pseudos: [NthChild(1, 4)] }]],
		':nth-child(n -4)' => [[{ pseudos: [NthChild(1, -4)] }]],
		':nth-child(-n-4  )' => [[{ pseudos: [NthChild(-1, -4)] }]],
		':nth-child( -n)' => [[{ pseudos: [NthChild(-1, 0)] }]],
		':nth-child(n)' => [[{ pseudos: [NthChild(1, 0)] }]],
		':nth-child(4)' => [[{ pseudos: [NthChild(0, 4)] }]],
		':nth-child(-4)' => [[{ pseudos: [NthChild(0, -4)] }]],
		':nth-child(  )' => null,
		
		//TODO: add tests for the really complex stuff
	];
	
	function testAll() {
		for (c in cases.keys()) {
			var parsed = cases.get(c);
			if (parsed == null)
				this.throws(function () parse(c).sure(), #if macro haxe.macro.Expr.Error #else Error #end)
			else
				assertStructEq(cases.get(c), parse(c).sure());
		}
		assertTrue(true);
	}
	
}