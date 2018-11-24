package ;

import tink.csss.Selector;
import tink.csss.Parser;
import tink.core.Error;
using tink.core.Outcome;


private enum Pseudo {
	Not(s:Selector<Pseudo>);
	Nth(matchType:Bool, factor:Int, offset:Int, backward:Bool);
	State(s:ElementState);
	Custom(name:String, args:Array<String>);
}

class TestParser extends Base {
	static function parse(s:String)
		return Parser.parseWith(
			s, 
			{
				not: function (selector) return Success(Not(selector)),
				nth: function (matchType, factor, offset, backward) return Success(Nth(matchType, factor, offset, backward)),
				state: function (s) return Success(State(s)),
				custom: function (name, args) return Success(Custom(name, args))
			}
		);		
	
	static function make(?tag, ?id, ?classes, ?attrs, ?pseudos, ?combinator):SelectorPart<Pseudo> 
		return {
			universal: tag == '*',
			id: id,
			tag: if (tag == '*') null else tag,
			classes: if (classes == null) [] else classes,
			attrs: if (attrs == null) [] else attrs,
			pseudos: if (pseudos == null) [] else pseudos,
			combinator: combinator,
		}

	static function pseudo(s:String, ?args:Array<String>) {
		var parts = s.split(',');
		var name = parts.shift();
		args = 
			if (args == null) parts;
			else parts.concat(args);
			
		return Custom(name, args);
	}
	
	static function attr(name:String, ?value:String, ?op:AttrOperator):AttrFilter 
		return {
			name: name,
			value: value,
			op: 
				if (op != null) op
				else if (value == null) None
				else Exactly
		}
		
	static var cases = [
		'#id' => [[make(null, 'id')]],
		'*' => [[make('*')]],
		'tag' => [[make('tag')]],
		'.class' => [[make(['class'])]],
		'.class1.class2' => [[make(['class1','class2'])]],
		
		'*tag' => null,
		'tag*' => null,
		'tag[foo]tag' => null,
		
		'tag#id.class1.class2' => [[make('tag', 'id', ['class1', 'class2'])]],
		
		':foo' => [[make([pseudo('foo')])]],
		'::foo' => [[make([pseudo('foo')])]],
		'::foo::foo' => [[make([pseudo('foo'), pseudo('foo')])]],
		':foo(bar)' => [[make([pseudo('foo,bar')])]],
		':foo(bar,baz)' => [[make([pseudo('foo,bar,baz')])]],
		//TODO: ':foo(bar(bar),baz)' => [[make([pseudo('foo,bar(bar),baz')])]],
		':foo(bar,baz):xoo' => [[make([pseudo('foo,bar,baz'), pseudo('xoo')])]],
		
		'[attr]' => [[make([attr('attr')])]],
		'[attr1][attr2]' => [[make([attr('attr1'), attr('attr2')])]],
		'[attr=foo]' => [[make([attr('attr', 'foo')])]],
		'[attr="foo"]' => [[make([attr('attr', 'foo')])]],
		"[attr='foo']" => [[make([attr('attr', 'foo')])]],
		"[attr='fo]o']" => [[make([attr('attr', 'fo]o')])]],
		'[attr~=foo]' => [[make([attr('attr', 'foo', WhitespaceSeperated)])]],
		'[attr|=foo]' => [[make([attr('attr', 'foo', HyphenSeparated)])]],
		'[attr^=foo]' => [[make([attr('attr', 'foo', BeginsWith)])]],
		'[attr$=foo]' => [[make([attr('attr', 'foo', EndsWith)])]],
		'[attr*=foo]' => [[make([attr('attr', 'foo', Contains)])]],
		
		'tag1>tag2' => [[make('tag1', Child), make('tag2')]],
		'tag1 tag2' => [[make('tag1', Descendant), make('tag2')]],
		'tag1+tag2' => [[make('tag1', AdjacentSibling), make('tag2')]],
		'tag1~tag2' => [[make('tag1', GeneralSibling), make('tag2')]],
		'tag1,tag2' => [[make('tag1')], [make('tag2')]],
		'tag1,tag2,' => [[make('tag1')], [make('tag2')]],
		'tag1,tag2, ' => [[make('tag1')], [make('tag2')]],
		'tag1,tag2,,' => null,
		
		'' => null,
		',' => null,
		'#' => null,
		'.' => null,
		
		':not()' => null,
		':not' => null,
		':not(div>ul:first-child)' => [[make([Not(parse('div>ul:first-child').sure())])]],
		
		':first-child' => [[make([Nth(false, 0, 1, false)])]],
		':last-child' => [[make([Nth(false, 0, 1, true)])]],
		':first-of-type' => [[make([Nth(true, 0, 1, false)])]],
		':last-of-type' => [[make([Nth(true, 0, 1, true)])]],
		
		':nth-child(-2n)' => [[make([Nth(false, -2, 0, false)])]],
		':nth-child(-2n+4)' => [[make([Nth(false, -2, 4, false)])]],
		':nth-child(2n-4)' => [[make([Nth(false, 2, -4, false)])]],
		':nth-child(2n+4)' => [[make([Nth(false, 2, 4, false)])]],
		
		':nth-child(n+4)' => [[make([Nth(false, 1, 4, false)])]],
		':nth-child(n-4)' => [[make([Nth(false, 1, -4, false)])]],
		':nth-child(-n-4)' => [[make([Nth(false, -1, -4, false)])]],
		':nth-child(-n)' => [[make([Nth(false, -1, 0, false)])]],
		':nth-child(n)' => [[make([Nth(false, 1, 0, false)])]],
		':nth-child(4)' => [[make([Nth(false, 0, 4, false)])]],
		':nth-child(-4)' => [[make([Nth(false, 0, -4, false)])]],
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
				this.throws(function () parse(c).sure(), Error)
			else
				assertStructEq(cases.get(c), parse(c).sure());
		}
		assertTrue(true);
	}
	
}