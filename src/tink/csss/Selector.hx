package tink.csss;

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

//TODO: with the next Haxe update, these should become inline enums
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