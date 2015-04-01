package tink.csss;

import tink.csss.Selector;
import tink.core.Error;

using tink.core.Outcome;
using StringTools;

typedef Plugin<A> = {
	function not(s:Selector<A>):Outcome<A, String>;
	function nth(matchType:Bool, factor:Int, offset:Int, backward:Bool):Outcome<A, String>;
	function custom(name:String, args:Array<String>):Outcome<A, String>;
}

class Parser<A> {
	public var pos(default, null):Int;
	public var max(default, null):Int;
	var source:String;
	var pseudos:Plugin<A>;
	var srcPos:Pos;
	function new(source, pseudos, srcPos) {
		//TODO: Utf8 support on neko/macro
		this.pos = 0;
		this.srcPos = srcPos;
		this.source = source;
		this.max = source.length;
		this.pseudos = pseudos;
	}
	
	static public function parse(source, ?pos) 
		return parseWith(source, {
			not: function (s) return Success(Not(s)),
			nth: function (matchType, factor, offset, backward) return Success(Nth(matchType, factor, offset, backward)),
			custom: function (name, _) return Failure('Unknown pseudo class :$name')
		}, pos);
	
	static public function parseWith<A>(source, pseudos:Plugin<A>, ?pos):Outcome<Selector<A>, Error>
		return 
			try Success(new Parser(source, pseudos, pos).parseAll())
			catch (e:Error) Failure(e);

	
	function white() 
		while (pos < max && source.fastCodeAt(pos) < 33) pos++;
	
	inline function read()
		return 
			if (pos < max) source.fastCodeAt(pos++);
			else 0;
	
	inline function peek() 
		return 
			if (pos < max) source.fastCodeAt(pos);
			else 0;
	
	public function parseAll() {
		var cur = [];
		var ret = [cur];
		var run = true;
		
		while (run) {
			white();
			var s = parseSimple();
			
			white();
			cur.push(s);
			s.combinator = 
				switch read() {
					case 0:
						run = false;
						null;
					case ','.code: 
						white();
						run = peek() != 0;
						if (run)
							ret.push(cur = []);
						null;
					case '>'.code: Child;
					case '+'.code: AdjacentSibling;
					case '~'.code: GeneralSibling;
					default:
						pos--;
						Descendant;
				}
		}
		
		return ret;
	}
	
	static function makeFilter(s:String) {
		var h = new Map();
		haxe.Utf8.iter(s, function (code:Int) h.set(code, true));
		return function (s) return h.exists(s);
	}
	
	static var IDENT_END = makeFilter('#*., =\t\r\n[]()+~>:|^$!' + String.fromCharCode(0));
	static var ALPHA = makeFilter('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz');
	
	function readWhile(filter) {
		var start = pos;
		while (filter(peek())) pos++;
		return this.source.substring(start, pos);
	}
	
	function readUntil(filter) {
		var start = pos;
		while (!filter(peek())) pos++;
		return this.source.substring(start, pos);
	}
	
	function readIdent() {
		var ret = readUntil(IDENT_END);
		return
			if (ret == '') Failure(mkError('Identifier expected'));
			else Success(ret);
	}
	
	function mkError(msg:String) 
		return Error.withData('$msg @$pos in $source', { msg: msg, pos: pos, source: source }, srcPos);
	
	function expect(s:String) 
		if (!allow(s)) error('Expected $s');
	
	function allow(s:String) {
		return
			if (source.substr(pos, s.length) == s) {
				pos += s.length;
				true;
			}
			else false;
	}
	function error(msg:String):Dynamic 
		return mkError(msg).throwSelf();
	
	function readString() {
		var delim = read();
		var ret = readUntil(function (c) return c == delim);//TODO: deal with escaping
		read();
		return ret;
	}
	static var CHILD_RULES = [
		'nth-child' => [false, false],
		'nth-of-type' => [true, false],
		'nth-last-child' => [false, true],
		'nth-last-of-type' => [true, true],
	];
	public function parseSimple() {
		var part:SelectorPart<A> = { universal: false, classes: [], attrs: [], pseudos: [] };
		
		while (true) //TODO: I'm not sure it makes sense to parse the basic stuff in the loop as well. AFAIK `[attr]tag` is not valid
			switch read() {
				case '*'.code:
					if (part.universal || part.tag != null)
						error('Can declare tag only once');
					part.universal = true;
				case '#'.code:
					part.id = readIdent().sure();
				case '.'.code:	
					part.classes.push(readIdent().sure());
				case alpha if (ALPHA(alpha)):
					pos--;
					if (part.universal || part.tag != null)
						error('Can declare tag only once');
					part.tag = readIdent().sure();//TODO: possibly too lenient
				case '['.code:
					white();
					//TODO: we could use a trick here, turning [!foo] into :not([foo]) although that would currently cause stringly typing
					var name = readIdent().sure();
					white();
					var op = 
						switch read() {
							case '~'.code: expect('='); WhitespaceSeperated;
							case '|'.code: expect('='); HyphenSeparated;
							case '^'.code: expect('='); BeginsWith;
							case '$'.code: expect('='); EndsWith;			
							case '*'.code: expect('='); Contains;
							case '='.code: Exactly; 
							case ']'.code: None;
							default: error('Expected attribute operator');
						}
						
					var value =
						if (op == None) null;
						else {
							white();
							
							var s = switch peek() {
								case '"'.code, "'".code:
									readString();
								default:
									readUntil(function (c) return c == ']'.code);
							}
							
							white();
							expect(']');
							s;
						}
					part.attrs.push({ name: name, value: value, operator: op });
				case ':'.code:
					allow(':');
					var name = readIdent().sure();
					var args = [];
					
					if (allow('(')) {
						//TODO: ballance parens - or not?
						var end = makeFilter(',)');
						do {
							args.push(readUntil(end).trim());
						} while (allow(','));
						expect(')');
					}
					
					function argCount(count:Int) 
						if (args.length != count)
							error(':$name requires $count arguments');
					
					function add(o) 
						switch o {
							case Success(a): part.pseudos.push(a);
							case Failure(s): error(s);
						}
					
					function nth(matchType, factor, offset, backward, ?count) {
						add(pseudos.nth(matchType, factor, offset, backward));
						if (count != null)
							argCount(count);
					}
					
					switch name {
						case 'not': 
							if (args.length == 0)
								error(':not requires an argument');
							add(pseudos.not([for (a in args)
								new Parser(a, pseudos, srcPos).parseAll()[0]
							]));
							
						case 'first-child': nth(false, 0, 1, false, 0);
						case 'last-child': nth(false, 0, 1, true, 0);
						case 'first-of-type': nth(true, 0, 1, false, 0);
						case 'last-of-type': nth(true, 0, 1, true, 0);
						case 'only-child': nth(false, 0, 0, false, 0);
						case 'only-of-type': nth(true, 0, 0, false, 0);
						case 'odd': nth(false, 2, 1, false, 0);
						case 'even': nth(false, 2, 0, false, 0);
						case complex if (CHILD_RULES.exists(complex)):
							argCount(1);
							function parse(s:String)
								return 
									if (s.startsWith('+')) parse(s.substr(1))
									else Std.parseInt(s);//neko can't handle leading +
							var progression = 
								switch args[0] {
									case 'odd': [2, 1];
									case 'even': [2, 0];
									case v: 
										var parts = v.replace(' ', '').replace('\t', '').split('n');
										switch parts {
											case [offset]:
												if (offset == '') 
													error('empty expression not accepted for $name');
												[0, parse(offset)];
											case [n, offset]:
												if (n == '-') n = '-1';
												else if (n == '') n = '1';
												if (offset == '') offset = '0';
												[parse(n), parse(offset)];
											default: error('Cannot parse argument $v for $name');	
										}
								}
								
							var rule = CHILD_RULES.get(complex);
							nth(rule[0], progression[0], progression[1], rule[1]);
						default:
							add(pseudos.custom(name, args));
					}
					
				case v:
					if (v != 0) pos--;
					break;
			}
			
		switch part {
			case { id: id, tag: tag, universal: false, classes: [], attrs: [], pseudos: [] } 
				if (id == null && tag == null):
					error('Selector expected');
			default:
		}
		
		return part;
	}	
}