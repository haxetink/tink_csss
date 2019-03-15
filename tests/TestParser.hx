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
		
		':hover' => [[{ pseudos: [State(Hover)] }]],
		'::hover' => [[{ pseudos: [State(Hover)] }]],
		'::foo' => null,
		'::hover::hover' => [[{ pseudos: [State(Hover), State(Hover)] }]],
		
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
		
		':first-child' => [[{ pseudos: [Nth(false, 0, 1, false)] }]],
		':last-child' => [[{ pseudos: [Nth(false, 0, 1, true)] }]],
		':first-of-type' => [[{ pseudos: [Nth(true, 0, 1, false)] }]],
		':last-of-type' => [[{ pseudos: [Nth(true, 0, 1, true)] }]],
		
		':nth-child(-2n)' => [[{ pseudos: [Nth(false, -2, 0, false)] }]],
		':nth-child(-2n+4)' => [[{ pseudos: [Nth(false, -2, 4, false)] }]],
		':nth-child(2n-4)' => [[{ pseudos: [Nth(false, 2, -4, false)] }]],
		':nth-child(2n+4)' => [[{ pseudos: [Nth(false, 2, 4, false)] }]],
		
		':nth-child(n+ 4)' => [[{ pseudos: [Nth(false, 1, 4, false)] }]],
		':nth-child(n -4)' => [[{ pseudos: [Nth(false, 1, -4, false)] }]],
		':nth-child(-n-4  )' => [[{ pseudos: [Nth(false, -1, -4, false)] }]],
		':nth-child( -n)' => [[{ pseudos: [Nth(false, -1, 0, false)] }]],
		':nth-child(n)' => [[{ pseudos: [Nth(false, 1, 0, false)] }]],
		':nth-child(4)' => [[{ pseudos: [Nth(false, 0, 4, false)] }]],
		':nth-child(-4)' => [[{ pseudos: [Nth(false, 0, -4, false)] }]],
		':nth-child(  )' => null,
		
		//TODO: add tests for the really complex stuff
	];
	
	function assertStructEq<A>(expected:A, found:A) {
		function compare(e:Dynamic, f:Dynamic):Bool
			return 
				switch Type.typeof(e) {
					case TNull, TInt, TBool, TFloat, TUnknown, TClass(String): e == f;
					case TObject:
						var ret = true;
						//TODO: consider checking surplus fields
						for (field in Reflect.fields(e)) 
							if (field != '__id__' && !compare(Reflect.field(e, field), Reflect.field(f, field))) {
								ret = false;
								break;
							}
						ret;
					case TEnum(enm):
						Std.is(f, enm) 
						&& 
						compare(Type.enumIndex(e), Type.enumIndex(f))
						&&
						compare(Type.enumParameters(e), Type.enumParameters(f));
					case TClass(Array):
						var ret = compare(e.length, f.length);
						if (ret)
							for (i in 0...e.length)
								if (!compare(e[i], f[i])) {
									ret = false;
									break;
								}
						ret;
					case TClass(_) if (Std.is(e, haxe.Constraints.IMap)):
						var e:Map.IMap<Dynamic, Dynamic> = e,
							f:Map.IMap<Dynamic, Dynamic> = f;
							
						var ret = true;
						function find(orig:Dynamic) {
							for (copy in f.keys())
								if (compare(orig, copy)) 
									return copy;
							return orig;
						}
						if (ret)
							for (k in e.keys())
								if (!compare(e.get(k), f.get(find(k)))) {
									ret = false;
									break;
								}
						e.toString();
						ret;
					default:
						throw 'assert';
				}

		if (compare(expected, found)) assertTrue(true);
		else fail('expected something like $expected, found $found');
	}
	
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