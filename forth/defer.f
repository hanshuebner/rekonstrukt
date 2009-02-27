: alias ( xt -- ) create , does> @ execute ;
: noop ( -- ) ;
: defer ( <name> -- ) ['] noop alias ;
: is ( xt <name> -- ) ' >body ! ;
