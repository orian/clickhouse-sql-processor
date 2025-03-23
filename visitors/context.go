package visitors

type ContextKind string

var (
	ContextKindWhere   ContextKind = "WHERE"
	ContextKindHaving  ContextKind = "HAVING"
	ContextKindSelect  ContextKind = "SELECT"
	ContextKindGroupBy ContextKind = "GROUP BY"
)

// ASTContext helps to propertly handle semantics of SQL fields and expression parsing.
// e.g. GROUP BY 1 - one in this context means the first field from SELECT
type ASTContext struct {
	Kind ContextKind
}

func (a *ASTContext) With(kind ContextKind) (onExit func()) {
	prev := a.Kind
	a.Kind = kind
	return func() {
		a.Kind = prev
	}
}
