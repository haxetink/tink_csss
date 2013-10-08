# Tinkerbell CSS Selectors

This library deals with parsing and representing CSS selectors.
It uses a parser derived from [selecthx](https://code.google.com/p/selecthx/), although it is greatly simplified and slightly more flexible.

The library is quite thoroughly tested and has only `tink_core` as a dependency.

# Selector

The data representation is pretty straight forward and is completely described in the `Selector` module.

```
typedef Selector<A> = Array<SelectorOption<A>>;

typedef SelectorOption<A> = Array<SelectorPart<A>>;

typedef SelectorPart<A> = {
	universal:Bool,
	?id:String,
	?tag:String,
	classes:Array<String>,
	attrs:Array<AttrFilter>,
	pseudos:Array<A>,
	?combinator:Combinator,
}

typedef AttrFilter = {	
	var name:String;
	var value:String;
	var operator:AttrOperator;
}

enum Pseudo {
	Not(s:Selector<Pseudo>);
	Nth(matchType:Bool, factor:Int, offset:Int, backward:Bool);
}

enum AttrOperator {
	None;
	Exactly;
	WhitespaceSeperated;
	HyphenSeparated;
	BeginsWith;
	EndsWith;
	Contains;
}

enum Combinator {
    Descendant;
	Child;
	AdjacentSibling;
	GeneralSibling;
}
```

You may note that `Selector` has a type parameter. Normally, you would just use `Selector<Pseudo>` but since CSS lends itself well to applying rules to any kind of hierarchies, you may want to spin off a CSS flavour with other pseudo selectors - arguably the easiest way to add more functionality without interfering with standard syntax.

# Parser

For parsing, the library provides the following API:

```
class Parser {
	static public function parse(source:String, ?pos:Pos):Outcome<Selector<Pseudo>, Error>
	static public function parseWith<A>(source:String, pseudos:Plugin<A>, ?pos:Pos):Outcome<Selector<A>, Error>
}

typedef Plugin<A> = {
	function not(s:Selector<A>):Outcome<A, String>;
	function nth(matchType:Bool, factor:Int, offset:Int, backward:Bool):Outcome<A, String>;
	function custom(name:String, args:Array<String>):Outcome<A, String>;
}
```

To parse with your own pseudo selector rules, you would use `parseWith` and supply an adequate `Plugin`. That is also how `parse` itself is implemented in fact.
